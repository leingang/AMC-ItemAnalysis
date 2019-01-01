#!/usr/bin/env perl
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

# my $temp_dir = File::Temp->newdir(CLEANUP=>0);
my $tarball_path = File::Spec->catdir($build->plugin_name . ".tar.gz");

$build->dispatch("build");
# No return value for this action, so can't use is() 
# ok($build->_do_in_dir($temp_dir,
#     sub {
#         $build->dispatch("plugin")
#             or die "Error building plugin in in directory '$temp_dir': $!";
#     }
# ));

$build->dispatch("plugin") or die "Error building plugin: $!";
is(-f $tarball_path,1,"Tarball exists: $tarball_path");


done_testing();


