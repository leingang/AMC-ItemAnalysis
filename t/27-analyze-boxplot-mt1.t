#!/usr/bin/env perl -T
=head1 NAME

27-analyze-boxplot-mt1.t - Test boxplot statistics of an item with the total for a
sample midterm, using the C<analyze> subroutine.

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 DESCRIPTION

This computes the item analysis for an old midterm and checks the 
following statistics:

=over

=item the median (data point in the middle of the distribution)

=item first quartile (data point 25% of the way from lowest to highest)

=item third quartile (data point 75% of the way from lowest to highest)

=item the I<upper threshold>, the score associated to the third
quartile plus 1.5 times the interquartile range

=item the I<lower threshold>, the score associated to the first
quartile minus 1.5 times the interquartile range

=item the I<upper extreme>, the greatest data point less than or equal
to the upper threshold

=item the I<lower extreme>, the least data point greater than or equal
to the lower threshold

=back

In a box plot, the center is drawn at the median, and the upper and
lower hinges are drawn at the quartiles.  There are differing
conventions about where the whiskers are drawn; we intend to draw them
at the upper and lower extremes described above.  This is apparently
Tukey's suggestion.

Each statistic is compared with values computed by Excel.

An important edge case is when the interquartile range is zero.  
This happens when over 50% of the data points are equal to the median.
The result should be that all the statistics (Q1, Q3, upper and lower
thresholds, upper and lower extemes) are equal.

=head1 SEE ALSO

L<http://vita.had.co.nz/papers/boxplots.pdf>

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
use FindBin qw($Bin);

use AMC::Export::ItemAnalysis;

# These data are all protected by federal privacy laws so we have to keep them
# out of the repository.  
my $project_dir = "/Users/matthew/Box/MC-Projects/20191 Discrete Mathematics/mt1";
my $course_dir = "/Volumes/GoogleDrive/My Drive/Courses/MATH-UA 120 Discrete Mathematics/MATH-UA 120 Fall 2018";
my $data_dir = $project_dir . "/data";
my $fich_noms = $course_dir . "/Students/2018-09-18/amc.csv";
# but summary statistics can be in source control
my $stat_file = $Bin. "/boxplot.csv";

# parse the file of golden statistics to compare against
my $stats = {};
my $csv = Text::CSV->new();
open my $fh, "<", $stat_file or die "$stat_file: $!";
$csv->header($fh, {munge_column_names=>"none"});
while (my $row = $csv->getline_hr($fh)) {
    $stats->{$row->{'name'}} = $row;
}
# for outputting, we get the largest string length
my @qnames = grep { $_ ne 'Mark' } keys %$stats;
my $qname_max_length = max(map { length($_) } @qnames );
my $nq = scalar @qnames;
my @stats = grep { $_ ne 'name' } $csv->column_names();


# only run tests if user has authority to see the data
my $whoami = scalar getpwuid($<);
if ($whoami eq 'matthew') {
    plan tests => 7 * $nq;
} 
else {
    plan skip_all => "Only instructor can run tests on private data";
}

my $ex = AMC::Export::ItemAnalysis->new();
$ex->set_options("fich","datadir"=>$data_dir,"noms"=>$fich_noms);
$ex->analyze();

for my $qname (@qnames) {
    my $expected = $stats->{$qname};
    my $qname_padded = sprintf("%${qname_max_length}s", $qname);
    my @questions = grep { $_->{'title'} eq $qname }  @{$ex->{'questions'}};
    # is (scalar(@questions),1,"$qname_padded - Exactly one question matches title");
    my $question = shift(@questions);
    my $fmt = "%.6f";
    for (@stats) {
        cmp_ok (
            sprintf($fmt,$question->{$_}), '==',
            sprintf($fmt,$expected->{$_}),
            "$qname_padded - $_ matches Excel calculation"
        );        
    }
}



















