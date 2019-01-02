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

=pod

=encoding utf8

=head1 NAME

AMC::Export::ItemAnalysis_YAML - Export item analysis to a LaTeX file.

=head1 SYNOPSIS

From a script:

    use AMC::Export::ItemAnalysis_YAML;

    my $project_dir = "/path/to/MC-Projects/exam";
    my $data_dir = $project_dir . "/data";
    my $fich_noms = $project_dir . "/students-list.csv";
    my $output_file = $project_dir . "/exports/exam-item-analysis.yaml";
    my $ex = AMC::Export::ItemAnalysis_YAML->new();
    $ex->set_options("fich","datadir"=>$data_dir,"noms"=>$fich_noms);
    $ex->export($output_file);

From the command line:

    cd /path/to/MC-Projects/exam
    auto-multiple-choice export --module ItemAnalysis_YAML \
        --data data \
        --fich-noms students-list.csv \
        --o exports/exam-item-analysis.yaml

=cut 

package AMC::Export::ItemAnalysis_YAML;

use strict;
use warnings;
use YAML::Tiny;

use parent q(AMC::Export::ItemAnalysis);

=head1 METHOD

=head2 export

Exports the analysis to a YAML file.  The sole argument
is the name of the output file to write to.

The file produced is pretty much a serialization of the
hashrefs populated by C<< $obj->analyze() >>.

=cut

sub export {
    my ( $self, $fichier ) = @_;
    $self->analyze();
    my $data = {
        'metadata'    => $self->{'metadata'},
        'summary'     => $self->{'summary'},
        'items'       => $self->{'questions'},
        'submissions' => $self->{'submissions'},
        'totals'      => $self->{'marks'}
    };
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($fichier);
}

1;
__END__

=pod

=head1 NOTES

The AMC GUI give an option to open the exported file immediately
after the export completes.  This is by selecting “open the file”
from the drop-down menu after “and then.”  Due to limitations in
AMC's configuration system, there is no way to specify which 
program should open a YAML file.  So selecting “open the file” will
not have any effect.  Selecting “open the directory” will at
least do that, and then you can double-click on the file to 
open it in your favorite text editor.

=head1 SEE ALSO

L<AMC::ItemAnalysis>, L<AMC::Export::ItemAnalysis>, 
L<AMC::Export::ItemAnalysis_LaTeX>


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

