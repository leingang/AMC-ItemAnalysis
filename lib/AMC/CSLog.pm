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
=pod

=encoding utf8

=head1 NAME

AMC::CSLog - Parse the amc-compiled.cs log

=head1 SYNOPSIS

    my $cslog_parser = AMC::CSLog->new();
    my $labels = $cslog_parser->parse($cslog_file_name);
    for (@$labels) {
        my $question_name = $_->{'question_number'};
        my $answer_number = $_->{'answer_number'};
        my $answer_label  = $_->{'answer_label'};
        printf "Question %d, answer %d, has label '%s'\n",
            $question_number, $answer_number, $answer_label;
         
=cut 

package AMC::CSLog;

use 5.008;
use strict;
use warnings;

=head1 METHODS

=head2 new

Constructor.  No arguments, returns a reference to an object 
of this class.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self;
}

=head2 parse

C<< $obj->parse($file_name) >> parses a F<amc-compiled.cs> file.
This file is created by one of the AMC jobs and has lots of lines 
of the form

    \answer{1/3:case:MC-counterex-div:10,1}{A}

I don't know what the first number is for.  The second number, the one
after the slash, is probably the page number the question appears on.
The string between the second and third colons, is the string
identifier of the question.  After the third colon come the question
number (identifier in the database) and the answer number.  Finally,
between the last two braces is the answer label.

The method returns an arrayref of hashrefs.  Each referenced hash has
keys C<question_name>, C<question_number>, C<answer_numbe>, and
C<answer_label>.

=cut

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

