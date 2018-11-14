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

my @x = (3,2,4,5,6);
my @y = (9,7,12,15,17);
my $xs = Statistics::Descriptive::Full->new();
$xs->add_data(@x);
my $ys = Statistics::Descriptive::Full->new();
$ys->add_data(@y);
my ($a, $b, $r, $rms) = $ys->least_squares_fit(@x);
cmp_ok (sprintf("%.6f",$r),'==',0.997054);

# These are the scores on a single item (MC-quantifiers)
# and the total for a midterm
@x = (3,0,3,3,3,3,3,3,3,3,3,3,0,3,3,3,3,3,3,3,3,0,3,3,3,3,3,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3);
$xs->clear();
$xs->add_data(@x);
@y = (93,78,78,77,91,87,80,95,83,72,65,94,66,80,79,78,99,97,97,78,99,65,82,94,88,74,67,82,78,61,64,68,93,71,80,93,79,78,90,80,60,82,89,97,67);
$ys->clear();
$ys->add_data(@y);
($a, $b, $r, $rms) = $ys->least_squares_fit(@x);
cmp_ok (sprintf("%.8f",$r), '==', 0.38474137);

# Should get the same thing in the other direction too
($a, $b, $r, $rms) = $xs->least_squares_fit(@y);
cmp_ok (sprintf("%.8f",$r), '==', 0.38474137);
done_testing();
