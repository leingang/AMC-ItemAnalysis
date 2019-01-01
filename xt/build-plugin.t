#perl -T
=head1

build-plugin.t - test the AMC::Plugin::Build module

=cut

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp;

use AMC::Plugin::Build;

my $build_foo = AMC::Plugin::Build->new(
    module_name => 'AMC::ItemAnalysis',
    plugin_name => 'foo'
);
is ($build_foo->plugin_name,'foo','plugin_name override works');

my $build = AMC::Plugin::Build->new( module_name =>'AMC::ItemAnalysis' );
is ($build->plugin_name,'ItemAnalysis','plugin_name defaults correctly');

my $temp_dir = File::Temp->newdir();
my $tarball_path = File::Spec->catdir($temp_dir,$build->plugin_name . ".tar.gz");

$build->dispatch("build");
# No return value for this action, so can't use is() 
# TODO: search $temp_dir for the plugin tarball
# File::Find does more than search, though.
ok($build->dispatch("plugin",destdir=>$temp_dir));
is(-f $tarball_path,1,"Tarball exists: $tarball_path");


done_testing();


