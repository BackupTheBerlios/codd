######## ------- CLASS  ZRList ------------------------------------------------
########       PURPOSE  Zero Redundancy, Case Insesitive List that behaves 
########                like a 'hash' when acccessed via method as_key ()
########     COPYRIGHT  (C) 1998, Vipul Ved Prakash. <mail@vipul.net>  
########   CONSTRUCTOR  new () 
######## ----------------------------------------------------------------------

package Data::Structure::ZRList;

%HOL = (); 

## -- CONSTRUCTOR  new () ----------------------------------------------------
##      ARGUMENTS  None.
##       FUNCTION  Creates a new ZRList Object.
## ---------------------------------------------------------------------------

sub new { 
    return bless []; 
} 

## ------ METHOD  add () ----------------------------------------------------- 
##     ARGUMENTS  qw/Object-reference Scalar/
##      FUNCTION  Adds the Scalar to the ZRList. 
## ---------------------------------------------------------------------------

sub add { 
    my ($self, $item, $case) = @_;  
    grep { 
        my $check = $_; $check =~ s/^\s*//; $check =~ y/A-Z/a-z/ unless $case;
        push @$self, $check unless $check eq '' || grep {$_ eq $check} @$self; 
    } ref ($item) ? @$item : ($item); 
} 

## ------ METHOD  sub () ----------------------------------------------------- 
##     ARGUMENTS  qw/Object-reference Scalar/
##      FUNCTION  Removes the Scalar from the ZRList. 
## ---------------------------------------------------------------------------

sub sub { 
    my ($self, $item, $case) = @_; $item =~ y/A-Z/a-z/ unless $case;
    my @temp = grep {$_ ne $item} @$self; 
    @$self = @temp; 
} 

## ------ METHOD  iexists () ------------------------------------------------- 
##     ARGUMENTS  qw/Object-reference Scalar/
##      FUNCTION  Checks whether the Scalar is in the ZRList.
## ---------------------------------------------------------------------------

sub iexists {
    my ($self, $item, $case) = @_; $item =~ y/A-Z/a-z/ unless $case;
    return 1 if grep {$_ eq $item} @$self; 
    return undef; 
} 


## ------ METHOD  as_key () -------------------------------------------------- 
##     ARGUMENTS  qw/Object-reference Key [Scalar-value]/
##      FUNCTION  Provides read/write access to a private hash indexed by the
##                List items. 
## ---------------------------------------------------------------------------

sub as_key { 
    my ($self, $key, $item) = @_; 
    $HOL{$self}{$key} = $item if $item; 
    return $HOL{$self}{$key}; 
}
        
## ------ METHOD  as_string () ----------------------------------------------- 
##     ARGUMENTS  Object Reference. 
##      FUNCTION  Returns a comma separated list of all items.
## ---------------------------------------------------------------------------

sub as_string { 
    my $self = shift; 
    return join', ', @$self;  
} 

sub as_fmt_list { 
	my $self = shift; 
	my $return; 
	for (@$self) { 
		$return .= "o $_\n"
    }
	return $return; 
}

"True Value";

