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
use Archive::Tar;

use AMC::Plugin::Build;

plan tests => 6;

my $build_foo = AMC::Plugin::Build->new(
    module_name => 'AMC::ItemAnalysis',
    plugin_name => 'foo'
);
is ($build_foo->plugin_name,'foo','plugin_name override works');

my $build = AMC::Plugin::Build->new( module_name =>'AMC::ItemAnalysis' );
is ($build->plugin_name,'ItemAnalysis','plugin_name defaults correctly');

# my $temp_dir = File::Temp->newdir(CLEANUP=>0);
my $tarball_path = File::Spec->catdir($build->plugin_name . ".tar.gz");

# This routine has no return value so can't test for success
$build->dispatch("build");

$build->dispatch("plugin") or die "Error building 'plugin': $!";

# Check if the tarball exists
is(-f $tarball_path,1,"Tarball exists: $tarball_path")
    or die "$!";

# Check if the tarball is a tarball
isa_ok(my $tar = Archive::Tar->new($tarball_path,1),'Archive::Tar')
    or die "$!";

# Check if the tarball has the files that we expect it to.
# Not sure how to encode this to make it 
# (a) thorough 
# (b) not rely on hardcoded file names
# (c) not self-referential i.e., GIGO-proof
# So right now we just look for one directory 'perl'
# and a README
my @files = $tar->list_files;
my @needs = (File::Spec->catfile($build->plugin_name,'perl'));
foreach (@needs) {
    my $needed = $_;
    is(grep(/^$needed$/, @files),1,"Tarball contains $needed");
}

is(grep(/README/, @files),1,"Tarball contains a README");



