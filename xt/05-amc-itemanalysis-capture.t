#!perl -T

=head1 NAME

05-amc-itemanalysis-capture.t - Test the AMC::ItemAnalysis::capture module

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 SYNOPSIS

Within this directory:

    prove -I ../lib 05-amc-itemanalysis-capture.t

Within the project root directory:

    prove -l 05-amc-itemanalysis-capture.t

Or as part of the entire test suite:

    perl Build.PL
    ./Build test

=cut

#
# Copyright (C) 2018-19 Matthew Leingang <leingang@nyu.edu>
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

use AMC::ItemAnalysis::capture;

## no critic(ProhibitMagicNumbers)
my %numbers = (
    1  => 'A',
    2  => 'B',
    3  => 'C',
    4  => 'D',
    5  => 'E',
    26 => 'Z',
    27 => 'AA',
);
## use critic
plan tests => scalar %numbers;

foreach ( sort keys %numbers ) {
    is(
        AMC::ItemAnalysis::capture::_i_to_a( {}, $_ )
        ,    ## no critic(ProtectPrivateSubs)
        $numbers{$_},
        "_i_to_a($_)"
    );
}

done_testing();
