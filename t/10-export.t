#!/usr/bin/env perl -T
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
# with AMC-ItemAnalysis.  If not, see <https://www.gnu.org/licenses/>.use 5.006;
use strict;
use warnings;
use Test::More;

use AMC::Export::ItemAnalysis;

my $whoami = scalar getpwuid($<);
if ($whoami eq 'matthew') {
    plan tests => 1;
} 
else {
    plan skip_all => "Only instructor can run tests on private data";
}

my $project_dir = "/Users/matthew/Box/MC-Projects/20191 Discrete Mathematics/q07.scratch";
my $data_dir = $project_dir . "/data";
my $fich_noms = $project_dir . "/amc.csv";
my $output_file = $project_dir . "/exports/q07-itemanalysis.pl";
my $ex = AMC::Export::ItemAnalysis->new();
$ex->set_options("fich",
        "datadir"=>$data_dir,
        "noms"=>$fich_noms,
        );
ok($ex->export($output_file),"Export succeeded.  View $output_file for results.");
    
