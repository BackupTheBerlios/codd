#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.1 2001/06/24 16:14:30 grex Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'CODD',
    VERSION_FROM => 'lib/Code/Contribution/Distribution.pm', 
    EXE_FILES    => [ "bin/codd-render",
                      "bin/codd-create",
                      "bin/codd-truenames",
                      "bin/codd-benford",
                      "bin/codd-create-package",
                      "bin/codd-merge",
                      "bin/codd-dupes",
                    ],
    
);
