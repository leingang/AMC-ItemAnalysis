#!perl -T
=head1 NAME

00-load.t - Test loading of all library modules

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=cut
#
# Copyright (C) 2018 Matthew Leingang <leingang@nyu.edu>
#
# This file is part of AMC-ItemAnalysis
#
# AMC-ItemAnalysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# AMC-ItemAnalysis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with AMC-ItemAnalysis.  If not, see <https://www.gnu.org/licenses/>.
use 5.006;
use strict;
use warnings;
use Test::More;

my @modules = qw(AMC::ItemAnalysis AMC::Export::ItemAnalysis AMC::Export::register::ItemAnalysis AMC::ItemAnalysis::capture);
plan tests => $#modules+1;  

foreach (@modules) {
    use_ok( $_ );
}

diag( "Testing AMC::ItemAnalysis $AMC::ItemAnalysis::VERSION, Perl $], $^X" );
