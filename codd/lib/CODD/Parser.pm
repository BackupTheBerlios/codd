#!/usr/bin/perl -sw
##
## CODD::Parser - Find code owners from source files. 
## (derived from Code::Contribution::Distribution v0.28) 
##
## $Date: 2001/10/22 06:01:20 $
## $Revision: 1.1 $
## $State: Exp $
## $Author: hackworth $
## 
## Copyright (c) 1998-2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.


package CODD::Parser;
use Persistence::Object::Simple; 
use Data::Structure::ZRList; 
use Data::Dumper;
use File::Recurse; 
use Math::BigInt; 

use vars qw( $AUTOLOAD $VERSION ); 

@ISA          = ( Persistence::Object::Simple ); 
( $VERSION )  = '$Revision: 1.1 $' =~ /\s(\d+\.\d+)\s/;  
my $FILETYPES = '(?:\.c|\.c\.in|\.pm|\.pl|\.PL|\.S|\.cgi|\.py|\.java|\.class|\.cc|\.cpp|\.tcl|\.el|\.sh|\.m4)$'; 
my $DOCS      = '(README|AUTHORS|CHANGES|ANNOUNCE|ACKNOWLEDGEMENTS)';
my $ID        = "CODD - v$VERSION"; 

sub new {

    my ( $class, %args ) = @_; 
    my ( $dir, $fn, $path ); 

    if ( $args{ Package } ) { 
        $dir = $args{ Package }; 
        $dir =~ s:([^/]+)/?$::; 
        $fn = "$1" . ".codd"; 
    }

    $dir = $args{ Dir  } || $dir;
    $dir =~ s:/$::;
    $fn  = $args{ Codd } || $fn; 
    $path = $dir ? "$dir/$fn" : $fn; 
    $args{ Package } =~ s:/$::;

    my $self = $class->SUPER::new ( __Fn => $path ); 

    $self->package   ( $args{ Package } ) if $args{ Package }; 
    $self->version   ( $VERSION         ) unless $self->version; 
    $self->codd      ( $fn ) unless $self->codd; 
    $self->verbose   ( $args{ Verbose } ) if $args{ Verbose }; 
    $self->filetypes ( $args { Filetypes } || $FILETYPES ); 
    $self->docs      ( $args { Docs } || $DOCS );
    $self->id        ( $ID ); 
    return $self; 

}

sub ownergrep {

    my ( $self, %args ) = @_; 
    my $packagesize = new Math::BigInt '0'; 

    my ( @codefiles, @docfiles );
    my $docs = $self->docs; 
    recurse { /$docs/io && push @docfiles, $_ } $self->package (); 
    my $ft = $self->filetypes; 
    recurse { /$ft/io && push @codefiles, $_ } $self->package (); 
    print "Processing package -- ", $self->package, ", 
                                    $#codefiles + 
                                    $#docfiles files.\n\n";  

    for ( @docfiles ) { 

        my $docfile = $_;
        open C, $_; 
        my @code = <C>;  my $code = join'', @code; chomp @code; 
        close C; 

        print "    o greping $_..." if $self->verbose; 
        my $cr     = $self->copyrights ( \@code ) if $code =~ /copyright/i; 
        my $emails = $self->emails ( \@code ) if $code =~ /\@/; 
        my $logins = $self->logins ( \@code ) if $code =~ /Header|Id/i; 
        push @$cr, @$emails, @$logins;
        print " [" . scalar @$cr . "]\n";
        $docfile =~ s:[^/]+$::;
        $self->{_doccredits}->{ $docfile } = \@$cr;
        undef $cr;
    }

    for ( @codefiles ) { 

        my $codefile = $_;
        open C, $codefile; 
        my @code = <C>;  my $code = join'', @code; chomp @code; 
        my @tmp = stat ( C ); 
        my $size = $tmp[ 7 ]; 
        $packagesize += $size; 
        close C; 

        print "    o greping $_, $size bytes... " if $self->verbose; 
        my $cr     = $self->copyrights ( \@code ) if $code =~ /copyright/i; 
        my $emails = $self->emails ( \@code ) if $code =~ /\@/; 
        my $logins = $self->logins ( \@code ) if $code =~ /Header|Id/i; 
        push @$cr, @$emails;

        my ( $id, $login, @dlogins, @d2logins );
        MATCH: for $login ( @$logins ) { 
            for $id ( @$cr ) { 
                if ( $id =~ /$login/i ) {
                    push @$cr, $id; 
                    $self->{_packagemem}->{$login} = $id; 
                    print "*";
                    next MATCH;
                } 
            }
            push @dlogins, $login;
        }
    
        for ( @dlogins ) { 
            if ( exists $self->{_packagemem}->{$_} ) { 
                print '#';
                push @$cr, $self->{_packagemem}->{$_}; 
            } else { push @d2logins, $_ } 
        }
               
        for ( @d2logins ) {  push @$cr, "login-$_" }
        for ( @$cr ) { $_ = lc };
        if ( scalar @$cr == 0 ) { 
            $codefile =~ s:[^/]+$::;
            my $dc = $self->document_credit ( $codefile ); 
            if ($dc) { 
                print "+"; 
                push @$cr, @$dc;
            }
        } 

        my $ownerset = new Data::Structure::ZRList; 
        for ( @$cr ) { $ownerset->add ( $_ ) }
        my $total = scalar @$ownerset;

        if ( $total == 0 ) { 
            $self->{ uncredited } = $self->{ uncredited } + $size; 
            print "!"; 
        } else { 
            for ( @$ownerset ) { 
                $self->{ $_ } = $self->{ $_ } + int ( $size / $total ) 
            }
        }

        print " [$total]\n";  
        undef $cr;

    } 

    $self->packagesize ( $packagesize ); 
    $self->commit (); 
    print "\nUPDATED ", $self->codd, ", $packagesize bytes.\n\n" 
          if $self->verbose; 

}


sub document_credit { 

    my ( $self, $dir ) = @_; 
    
    while ( $dir =~ m:[^/]: ) { 
        if ( exists $self->{_doccredits}->{ $dir } ) { 
            return $self->{_doccredits}->{ $dir };
        } else { $dir =~ s:[^/]+/$::; $dir =~ s:/(?=/):: };
    }

    return undef;


}

sub copyrights { 

    my ( $self, $code ) = @_; 
    my @copy; 

    for ( @$code ) {
        if (/copyright/i && $_ !~ /\@/) { 
            ( m%.*copyright (?:\(c\))?[\d\,\-\s\:]+(?:by\s+)?([^\d]*)%i ) 
              && push @copy, $1; 
        }
    }

    # -- tidy up.
    my $index = -1; 
    for ( @copy ) { 
        $index++; $_ = lc; 
        s:all rights reserved::g;
        s:\s+$::; s:[\(<"\[\\\*].*$::;
        s:([a-z]{2,})\..*$:$1:; s:^by::; 
        s:\.\s{2,}.*::; s:\s{3,}.*$::; 
        s:\.\s+all .*::; s:[\-\.,\n\s]+$::; 
        if ( /\s+(?:and)\s+/i )  { 
            my @names = split /\s+(?:and|\&)\s+/i;
            push @copy, @names; 
            splice @copy, $index, 1
        }
        splice @copy, $index, 1 unless m:[a-z]+:; 
    }

    return \@copy; 

}

sub logins { 

    my ( $self, $code ) = @_; 
    my @ids; 

    LINE: for ( @$code ) { 
        next LINE unless /Id|Header/i; 
        my @m = $_ =~ /(?:Id|Header).*?\d\d\:\d\d\:\d\d (\S+?) \S+?/gi;
        push @ids, @m if @m; 
    }

    return \@ids;

}

sub emails { 

    my ( $self, $code ) = @_; 
    my @emails; 
    
    LINE: for ( @$code ) { 
        next LINE unless /\@/; 
        my @m = $_ =~ /([\d\w_\=\.\%]+?\@[\d\w\._\-]+?\.\w+?)(?=[\s:>\n\r\)]|$)/gi;
        for ( @m ) { s:^.*<::; push @emails, $_ }; 
    }

    return \@emails;

}
    
sub AUTOLOAD { 

        my ( $self, $value ) = @_;
        my $key = $AUTOLOAD;  $key =~ s/.*://;

        if ( $value ) { $self->{ "__$key" } = $value }

        return $self->{ "__$key" };   

}

'True Value' 


