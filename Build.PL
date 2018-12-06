#
# Copyright (C) 2018 Matthew Leingang <leingang@nyu.edu>
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
    
use 5.008;
use strict;
use warnings;

use Module::Build;
use Software::License;


my $class = Module::Build->subclass(code => q(
    # Subclass Module::Build to add a `librst` command that will generate
    # reStructuredText files from the project's POD documentation.   
    
    use strict;
    use warnings;
    
    use File::Basename qw(fileparse);
    use File::Find;
    use File::Spec;
    use File::Path qw(make_path);
    use Pod::POM;
    use Pod::POM::View::Restructured;
    
    our $parser = Pod::POM->new();
    our $docroot = 'doc';  # TODO: get from project configuration 
    
    sub make_rst {
        # Callback for find() to convert any POD in a file to an .rst file.
        # The POD can be a regular Perl file or a separate .pod file, but
        # not both (e.g. if Foo.pod exists, Foo.pm should not contain any
        # POD).
        return if -d $_;
        my $pom = $parser->parse_file($_);
        return if not @{$pom->content()};
        my $rst = $pom->present(new Pod::POM::View::Restructured->new());
        my $rst_path = File::Spec->catfile($docroot,$_);
        # $rst_path =~ s/$File::Find::dir/$docroot/;  # path
        $rst_path =~ s/\.[^\.]*$/.rst/;  # file extension
        my ($basename, $directories) = fileparse $rst_path;
        if (! -d $directories) { make_path $directories or die "Failed to create path: $directories";}
        open (my $stream, '>:utf8', $rst_path) or die "Failed to open stream: $rst_path";
        print $stream $rst;
        close $stream;
        print "Documentation written to $rst_path\n";
    }
    
    sub ACTION_librst {
        find({wanted => \&make_rst, no_chdir => 1}, 'lib/');
    }
));

my $prefix = $ENV{HOME} . "/.AMC.d/plugins/ItemAnalysis";
my $builder = $class->new(
    module_name         => 'AMC::ItemAnalysis',
    license             => 'GPL_3',
    dist_author         => q(Matthew Leingang <leingang@nyu.edu>),
    dist_version_from   => 'lib/AMC/ItemAnalysis.pm',
    release_status      => 'unstable',
    configure_requires => {
        'Pod::POM' => 0,
        'Pod::POM::View::Restructured' => 0,  # required for `librst` action
        # need subclass() method and license declaration by Software::License subclass
        'Module::Build' => 0.36_14,  
    },
    test_requires      => {
        'perl' => '!= 5.6.0, != 5.6.1, != 5.6.2', # Text::CSV::header does not work in perl-5.6.x (says POD)
        'Text::CSV' => 0,
        'Data::Dumper' => 0,
        'List::Util' => 0 # Needs max
    },
    requires => {
        'List::Util' => 0 # Needs sum
    },
    add_to_cleanup     => ['_build/', 'blib/', 'MYMETA.*', 'AMC-ItemAnalysis-*'],
    create_makefile_pl => 'small',
    create_packlist    => 0,
    install_base       => $prefix,
    install_path       => { lib => $prefix . '/perl' });


$builder->create_build_script();
