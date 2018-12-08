#perl -T
=head1

is-range.t - code to check if a list is range

=cut
use strict;
use warnings;
use Test::More;
use List::Util qw(reduce);

sub is_range {
    my $i = 0;
    return reduce { $a && ($b == $i++)} 1, @_;
}

ok(is_range(0,1,2));
ok(is_range(0,1,2,3,4,5));
ok(is_range(0,1,2,3,4.0,5));
ok(not(is_range(0,2)));
ok(not(is_range(0,1,2,4)));

done_testing();