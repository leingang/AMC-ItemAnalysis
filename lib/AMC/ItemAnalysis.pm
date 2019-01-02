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

package AMC::ItemAnalysis;

use 5.008;
use strict;
use warnings;

# This project uses Semantic Versioning <http://semver.org>. Major versions
# introduce significant changes to the API, and backwards compatibility is not
# guaranteed. Minor versions are for new features and backwards-compatible
# changes to the API. Patch versions are for bug fixes and internal code
# changes that do not affect the API. Version 0.x should be considered a
# development version with an unstable API, and backwards compatibility is not
# guaranteed for minor versions.
#
# David Golden's recommendations for version numbers <http://bit.ly/1g8EbKi>
# are used, e.g. v0.1.2 is "0.001002" and v1.2.3dev4 is "1.002002_004".
# The first line enables parsers to find the version identifier as a string.
# The second line converts it to a numeric value at runtime.
## no critic (BuiltinFunctions::ProhibitStringyEval)
our $VERSION = '0.006000_000';
$VERSION = eval $VERSION;
## use critic

1;

__END__

=pod

=encoding utf8


=head1 NAME

AMC::ItemAnalysis - A suite of auto-multiple-choice plugins for doing item analysis.

=head1 VERSION

Version 0.004000_001


=head1 SYNOPSIS

From the AMC GUI, go to the Reports tab and select one of the "Item Analysis"
options from the dropdown menu.  Click "Export" and after completion, open the
F<exports> directory.  A file called F<foo-item-analysis.ext> will be there,
where F<foo> is the "short name" of your AMC project, and F<ext> depends on 
which format you have chosen.

From the command line, you can execute

	auto-multiple-choice export --module ItemAnalysis_ext \
	    --data project-data-dir \
        --fich-noms students-list.csv \
        --o output-file

Here C<ext> is one of C<LaTeX> or C<YAML>, depending on your desired output
format.


=head1 SUBROUTINES/METHODS

At the moment, AMC::ItemAnalysis doesn't have any subroutines or methods.


=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 SUPPORT

Look at the submodules.


=head1 SEE ALSO

L<AMC::Export::ItemAnalysis>, L<AMC::Export::ItemAnalysis_LaTeX>, L<AMC::Export::ItemAnalysis_YAML>


=head1 ACKNOWLEDGEMENTS


Many thanks to Alexis Bienvenüe who created AMC and helped me with developing this plugin.


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

