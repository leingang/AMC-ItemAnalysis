#!/usr/bin/env perl -T
=head1 NAME

12-rit-mt1.t - Test regression of an item with the total for a sample midterm

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 DESCRIPTION

I have a bug where the RIT is not being counted properly.

=cut

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use AMC::Export::ItemAnalysis;

my $whoami = scalar getpwuid($<);
if ($whoami eq 'matthew') {
    plan tests => 2;
} 
else {
    plan skip_all => "Only instructor can run tests on private data";
}

my $project_dir = "/Users/matthew/Box/MC-Projects/20191 Discrete Mathematics/mt1";
my $data_dir = $project_dir . "/data";
my $fich_noms = "/Volumes/GoogleDrive/My Drive/Courses/MATH-UA 120 Discrete Mathematics/MATH-UA 120 Fall 2018/Students/2018-09-18/amc.csv";
my $output_file = $project_dir . "/exports/mt1-item-analysis.tex";
my $ex = AMC::Export::ItemAnalysis->new();
$ex->set_options("fich",
        "datadir"=>$data_dir,
        "noms"=>$fich_noms,
        );
$ex->export($output_file);

my $qname = 'MC-quantifiers';
my @questions = grep {$_->{'title'} eq $qname}  @{$ex->{'questions'}};
is (scalar(@questions),1,"Exactly one question matches title");
my $q = shift(@questions);
cmp_ok (
    sprintf("%.8f",$q->{'discrimination'}), '==', 0.38474137, 
    "RIT matches Excel calculation"
);