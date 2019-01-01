
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

=head2 plugin

Create a tarball that can be installed as an AMC.  
See L<https://github.com/leingang/AMC-ItemAnalysis/issues/12>.

Based on the C<ACTION_ppmdist> subroutine from
L<Module::Build::Base>.

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

sub ACTION_plugin {
    my $self = shift;
    my $plugin_name = $self->plugin_name;

}

=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 SUPPORT

Look at the submodules.

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

