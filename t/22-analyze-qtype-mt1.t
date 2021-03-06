#!/usr/bin/env perl -T
=head1 NAME

20-analyze-qtype-mt1.t - Test question metadata,
using the C<analyze> subroutine.

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 DESCRIPTION

This computes the item analysis report for an old midterm and checks
the problem type.

=head1 SEE ALSO

L<https://github.com/leingang/AMC-ItemAnalysis/issues/11>

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
use Data::Dumper;
use Text::CSV;
use List::Util q(max);
use FindBin q($Bin);

use AMC::Export::ItemAnalysis;

# These data are all protected by federal privacy laws so we have to keep them
# out of the repository.  
my $project_dir = "/Users/matthew/Box/MC-Projects/20191 Discrete Mathematics/mt1";
my $course_dir = "/Volumes/GoogleDrive/My Drive/Courses/MATH-UA 120 Discrete Mathematics/MATH-UA 120 Fall 2018";
my $data_dir = $project_dir . "/data";
my $fich_noms = $course_dir . "/Students/2018-09-18/amc.csv";
my $output_file = $project_dir . "/exports/mt1-item-analysis.tex";
my $stat_file = $project_dir . "/exports/prit.csv";

# parse the file of golden statistics to compare against
my $stats = {};
my $csv = Text::CSV->new();
open my $fh, "<", $stat_file or die "$stat_file: $!";
$csv->header($fh);
while (my $row = $csv->getline_hr($fh)) {
    $stats->{$row->{'name'}} = $row;
}
# for outputting, we get the largest string length
my @qnames = sort keys %$stats;
my $qname_max_length = max(map { length($_) } @qnames );
my $nq = scalar @qnames;

# only run tests if user has authority to see the data
my $whoami = scalar getpwuid($<);
if ($whoami eq 'matthew') {
    plan tests => $nq;
} 
else {
    plan skip_all => "Only instructor can run tests on private data";
}

my $ex = AMC::Export::ItemAnalysis->new();
$ex->set_options("fich","datadir"=>$data_dir,"noms"=>$fich_noms);
$ex->analyze();

for my $qname (@qnames) {
my $qname_padded = sprintf("%${qname_max_length}s", $qname);
my @questions = grep { $_->{'title'} eq $qname }  @{$ex->{'questions'}};
my $q = shift(@questions);
is (
    $q->{'type_class'},
    $stats->{$qname}->{'type_class'},
    "$qname_padded - type_class matches hand coding"
);
}
