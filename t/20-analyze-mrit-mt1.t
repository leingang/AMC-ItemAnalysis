#!/usr/bin/env perl -T
=head1 NAME

20-analyze-mrit-mt1.t - Test mean and correlation of an item with the total for a
sample midterm, using C<analyze> subroutine.

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 DESCRIPTION

This computes the item analysis report for an old midterm and compares
the mean and correlation of each item with the total.  It compares each
with values computed by another method (C<pandas>).

=cut

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Text::CSV;
use List::Util qw[min max];

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
    plan tests => 3 * $nq;
} 
else {
    plan skip_all => "Only instructor can run tests on private data";
}

my $ex = AMC::Export::ItemAnalysis->new();
$ex->set_options("fich","datadir"=>$data_dir,"noms"=>$fich_noms);
$ex->pre_process();
$ex->analyze();

for my $qname (@qnames) {
    my $qname_padded = sprintf("%${qname_max_length}s", $qname);
    my @questions = grep { $_->{'title'} eq $qname }  @{$ex->{'questions'}};
    is (scalar(@questions),1,"$qname_padded - Exactly one question matches title");
    my $q = shift(@questions);
    TODO: {
        local $TODO = 'See https://github.com/leingang/AMC-ItemAnalysis/issues/11';
        cmp_ok (
            sprintf("%.6f",$q->{'mean'}), '==',
            sprintf("%.6f",$stats->{$qname}->{'mean'}),
            "$qname_padded - mean matches Excel calculation"
        );
        cmp_ok (
            sprintf("%.6f",$q->{'discrimination'}), '==', 
            sprintf("%.6f",$stats->{$qname}->{'rit'}),
            "$qname_padded - RIT matches Excel calculation"
        );
    }
}
