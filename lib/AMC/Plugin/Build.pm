
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
    ./Build dist

The compressed tarball can now be imported into AMC.

=head1 SUBROUTINES/METHODS

Same as in the parent.


=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 SUPPORT

Look at the submodules.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 Matthew Leingang

AMC-ItemAnalysis is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

AMC-ItemAnalysis is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
AMC-ItemAnalysis.  If not, see <https://www.gnu.org/licenses/>.

