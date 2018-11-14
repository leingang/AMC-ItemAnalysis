#!/usr/bin/env perl -T
=head1 NAME

90-SD-r.t - Test Statistics::Descriptive module for correlation

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=cut

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Statistics::Descriptive;


# plan tests=>1;

my @y = (93,78,78,77,91,87,80,95,83,72,65,94,66,80,79,78,99,97,97,78,99,65,82,94,88,74,67,82,78,61,64,68,93,71,80,93,79,78,90,80,60,82,89,97,67);
my $ys = Statistics::Descriptive::Full->new();
$ys->add_data(@y);

my @ynew = $ys->get_data();
is_deeply(\@ynew,\@y,"get_data preserves order immediately");
$ys->mean();
@ynew = $ys->get_data();
is_deeply(\@ynew,\@y,"get_data preserves order after mean");

SKIP: {
    skip "apparent bug in Statistics::Descriptive";
    $ys->median();
    @ynew = $ys->get_data();
    is_deeply(\@ynew,\@y,"get_data preserves order after median");
}
done_testing();
