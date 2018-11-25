#!/usr/bin/env perl -T
=head1 NAME

35-parse-cslog.t - Parse an AMC .cs log for answer labels.

=head1 AUTHOR

Matthew Leingang <leingang@nyu.edu>

=head1 DESCRIPTION

This computes the item analysis report for an old midterm and checks
the label of each answer for each question.  It compares each
with the expected values stored in a CSV file.

=head1 SEE ALSO

L<https://github.com/leingang/AMC-ItemAnalysis/issues/2>

=cut
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

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use FindBin q($Bin);
use Text::CSV;
use List::Util q(first);

use AMC::CSLog;

plan tests => 132;
my $parser = AMC::CSLog->new();
my $labels = $parser->parse("$Bin/amc-compiled.cs");

# parse the file of labels to compare against
my $labels_file = $Bin . "/labels.csv";
my $csv = Text::CSV->new();
open my $fh, "<", $labels_file or die "$labels_file: $!";
$csv->header($fh);
while (my $row = $csv->getline_hr($fh)) {
    my $question_name = $row->{'name'};
    while (my($answer_number, $answer_label) = each(%$row)) {
        next if $answer_number eq 'name';
        next if $answer_label eq '';
        my $rec = first {
            $_->{'question_name'} eq $question_name
            && $_->{'answer_number'} eq $answer_number
        } @$labels;
        is ($answer_label, $rec->{'answer_label'},
            sprintf "Question '%s', answer '%d'", $question_name, $answer_number);
    }
}
done_testing();