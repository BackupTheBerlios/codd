#!/usr/bin/perl -sw
##
## CODD::Analyzer - Analyze Codd Distributions (CODDs)
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

package CODD::Analyzer;
use CODD::Parser;
use Persistence::Object::Simple; 
use Data::Structure::ZRList; 
use Data::Dumper;
use File::Recurse; 
use Math::BigInt; 

use vars qw( $AUTOLOAD $VERSION ); 

@ISA          = ( Persistence::Object::Simple ); 
( $VERSION )  = $CODD::Parser::VERSION;
my $ID        = "Code Contribution Distribution Data Analyser - v$VERSION"; 

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

sub merge { 

    my ( $self, $coddname ) = @_; 
    my   $class = ref $self; 
    my   $total = $self->packagesize || new Math::BigInt '0'; 

    my $codd = $class->new ( Codd => $coddname ); 

    for ( keys %$codd ) { 
        unless ( /^__/ ) { 
            $self->{ $_ } += $codd->{ $_ }; 
        }
    } 

    if ( $codd->packagesize ) { 
        $total += $codd->packagesize;
        $self->packagesize ( $total ); 
    } 

}

    
sub AUTOLOAD { 

        my ( $self, $value ) = @_;
        my $key = $AUTOLOAD;  $key =~ s/.*://;

        if ( $value ) { $self->{ "__$key" } = $value }

        return $self->{ "__$key" };   

}

'True Value' 


