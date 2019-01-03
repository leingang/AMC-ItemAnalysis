
=pod

=encoding utf8

=head1 NAME

AMC::ItemAnalysis::capture - Add methods to AMC::DataModule::capture

=cut

## no critic (Capitalization)
# Following the AMC distribution's conventions
package AMC::ItemAnalysis::capture;
## use critic

use strict;
use warnings;
use parent q(AMC::DataModule::capture);
use Data::Dumper;    # for debugging
use Readonly;        # for constants

Readonly my $EMPTY => q{};

=head1 METHOD

=head2 question_response

C<< $obj->question_response($student,$copy,$question) >> looks up
the response from a student on a question.

Parameters:

=over

=item C<$student>: student number

=item C<$copy>: copy number

=item C<$question>: question hashref

=back

Returns: a string of concatenated responses by letter.  If a student marks
answers 1 and 3, 'AC' will be the returned.

=cut

sub question_response {

    # print "question_response: BEGIN\n";
    my ( $self, $student, $copy, $question ) = @_;

    # print "question_response: \$student:", $student, "\n";
    # print "question_response: \$copy:", $copy, "\n";
    # print "question_response: \$question:", Dumper($question), "\n";
    my $dt  = $self->{'darkness_threshold'};
    my $dtu = $self->{'darkness_threshold_up'};

    # print "question_response: \$dt:", $dt, "\n";
    # print "question_response: \$dtu:", $dtu, "\n";
    my $t  = $EMPTY;
    my @tl = $self->ticked_list( $student, $copy, $question, $dt, $dtu );

    # print "question_response: \@tl:", Dumper(\@tl), "\n";
    if ( $self->has_answer_zero( $student, $copy, $question ) ) {
        if ( shift @tl ) {
            $t .= '0';
        }
    }
    for my $i ( 0 .. $#tl ) {
        $t .= $self->_i_to_a( $i + 1 ) if ( $tl[$i] );
    }

    # print "question_response: END. \$t=", $t, "\n";
    return $t;
}

# convert number to letter
# stolen from AMC::Export::CSV

sub _i_to_a {
    my ( $self, $i ) = @_;
    Readonly my $LENGTH_OF_ALPHABET => 26;
    if ( $i == 0 ) {
        return ('0');
    }
    else {
        my $s = $EMPTY;
        while ( $i > 0 ) {
            $s = chr( ord('a') + ( ( $i - 1 ) % $LENGTH_OF_ALPHABET ) ) . $s;
            $i = int( ( $i - 1 ) / $LENGTH_OF_ALPHABET );
        }
        $s =~ s/^([[:lower:]]+)/uc($1)/e;
        return ($s);
    }
}

1;
