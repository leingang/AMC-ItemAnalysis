#!perl -T
=head1 NAME

00-load.t - Test loading of all library modules

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=cut

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
