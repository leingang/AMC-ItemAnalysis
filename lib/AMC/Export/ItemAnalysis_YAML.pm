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

package AMC::Export::ItemAnalysis_YAML;

# use AMC::Basic;
# use AMC::Export;
# use Encode;

use parent q(AMC::Export::ItemAnalysis);

sub export {    
    my ($self,$fichier)=@_;
    $self->analyze();    
    my $data = {
        'metadata' => $self->{'metadata'},
        'summary' => $self->{'summary'},
        'items' => $self->{'questions'},
        'submissions' => $self->{'submissions'},
        'totals' => $self->{'marks'}
    };
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($fichier);
}

1;