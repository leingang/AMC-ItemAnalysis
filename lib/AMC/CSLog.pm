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

package AMC::CSLog;

use 5.008;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self;
}

sub parse {
    my ($self,$file_name) = @_;
    open my $fh, "$file_name" or die "Could not open $file_name: $!";
    my $result = [];
    while (<$fh>) {
        $_ =~ /case:([^:]*):(\d+),(\d+)\}\{(.*)\}$/;
        my $rec = {
            'question_name' => $1,
            'question_number' => $2,
            'answer_number' => $3,
            'answer_label' => $4
        };
        push @$result, $rec;
    }
    return $result;
}



1;

__END__

=pod

=encoding utf8


=head1 NAME

AMC::CSLog - Parse the AMC .cs log


=head1 SYNOPSIS

In a perl program:

    use AMC::CSLog;

    $parser = AMC::CSLog->new();
    $rows = $parser->parse($file_name);

    for $row (@$rows) {
        $question_name = $row->{'question_name'}
        $answer_number = $row->{'answer_number'}
        $answer_label = $row->{'answer_label'}
        for $answer_num (@{$data->{$question_name}}) {
            printf "Question '%s', answer #%d, label: %s", 
                $question_name,
                $answer_number, $answer_label;
        }
    }

=head1 SUBROUTINES/METHODS


=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AMC::CSLog


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

LICENSE AND COPYRIGHT

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

