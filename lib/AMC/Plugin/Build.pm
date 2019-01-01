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

package AMC::Plugin::Build;

use 5.008;
use strict;
use warnings;

use parent qw(Module::Build);

1;
=pod

=encoding utf8


=head1 NAME

AMC::Plugin::Build - Prepare an auto-multiple-choice plugin from source


=head1 SYNOPSIS

    perl Build.PL
    ./Build
    ./Build test
    ./Build plugin

The compressed tarball can now be imported into AMC.

=head1 SUBROUTINES/METHODS

=head2 ACTION_plugin

Create a tarball that can be installed as an AMC plugin.
See L<https://github.com/leingang/AMC-ItemAnalysis/issues/12>.

Based on the C<ACTION_ppmdist> subroutine from
L<Module::Build::Base>.

=cut

sub ACTION_plugin {
    my $self = shift;
    my $plugin_name = $self->plugin_name;
    my $plugin_dir = $self->plugin_dir;
    my $plugin_tarball = $plugin_dir . ".tar.gz";
    $self->delete_filetree($plugin_dir);
    $self->log_info( "Creating $plugin_dir\n" );
    $self->add_to_cleanup( $plugin_dir, $plugin_tarball );
 
    my %types = ( # translate types/dirs to those expected by ppm
    lib     => 'perl',
    # arch    => 'arch',
    # bin     => 'bin',
    # script  => 'script',
    bindoc  => 'man/man1',
    libdoc  => 'man/man3',
    binhtml => undef,
    libhtml => undef,
    );
 
    foreach my $type ($self->install_types) {
        next if exists( $types{$type} ) && !defined( $types{$type} );
 
        my $dir = File::Spec->catdir( $self->blib, $type );
        next unless -e $dir;
 
        my $files = $self->rscan_dir( $dir );
        foreach my $file ( @$files ) {
        next unless -f $file;
        my $rel_file =
            File::Spec->abs2rel( File::Spec->rel2abs( $file ),
                                File::Spec->rel2abs( $dir  ) );
        my $to_file  =
            File::Spec->catfile( $plugin_dir,
                                exists( $types{$type} ) ? $types{$type} : $type,
                                $rel_file );
        $self->copy_if_modified( from => $file, to => $to_file );
        }
    }
    
    # foreach my $type ( qw(bin lib) ) {
    #     $self->htmlify_pods( $type, File::Spec->catdir($ppm, 'blib', 'html') );
    # }

    # copy in any READMEs
    my $files = $self->rscan_dir('.','README');
    my $dir = '.';
    foreach my $file ( @$files ) {
        next unless -f $file;
        my $rel_file =
            File::Spec->abs2rel( File::Spec->rel2abs( $file ),
                                File::Spec->rel2abs( $dir  ) );
                my $to_file = File::Spec->catfile($plugin_dir,$file);
        $self->copy_if_modified( from => $file, to => $to_file );
    }

    $self->make_tarball( $plugin_dir, $plugin_name);

    $self->delete_filetree( $plugin_dir );    
}

=head2 plugin_name

The name of the plugin.

It can be specified at construction by the C<plugin_name> keyword argument.

If not earlier specified, this method split the module name by C<::> and
returns the last part.  

=cut

sub plugin_name {
    my $self = shift;
    my $properties = $self->{'properties'};
    if (my $plugin_name = $properties->{'plugin_name'}) {
        return $plugin_name;
    }
    elsif (my $module_name = $self->module_name) {
        my @parts = split /::/, $module_name;
        return pop @parts;
    }
}

=head2 plugin_dir

The directory the plugin tarball unzips to.  Defaults to the the plugin name.

=cut

sub plugin_dir {
    my $self = shift;
    return $self->plugin_name;
}


=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-19 Matthew Leingang

AMC-ItemAnalysis is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

AMC-ItemAnalysis is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
AMC-ItemAnalysis.  If not, see <https://www.gnu.org/licenses/>.

