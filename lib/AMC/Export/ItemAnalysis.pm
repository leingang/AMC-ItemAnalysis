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

AMC::Export::ItemAnalysis - Abstract class for exporting item analyses

=cut 

package AMC::Export::ItemAnalysis;

use strict;
use warnings;
use AMC::Basic;
use AMC::CSLog;
use AMC::Export;
use AMC::Scoring;
use AMC::ItemAnalysis::capture;
use File::Basename;
use List::Util qw(sum first min max reduce);
use Statistics::Descriptive;

use Encode;
use Storable q(dclone);

use parent q(AMC::Export);

use Data::Dumper;    # for debugging

=head1 METHODS

=head2 new

Create the object.  

No arguments.  Returns a reference.

=cut

sub new {

    # print "new: BEGIN\n";
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->{'out.nom'}        = "";
    $self->{'out.code'}       = "";
    $self->{'out.encodage'}   = 'utf-8';
    $self->{'out.separateur'} = ",";
    $self->{'out.decimal'}    = ",";
    $self->{'out.entoure'}    = "\"";
    $self->{'out.ticked'}     = "";
    $self->{'out.columns'}    = 'student.copy,student.key,student.name';
    $self->{'noms.useall'}    = 0;
    bless( $self, $class );
    return $self;
}

=head2 analyze

Do the item analysis.  

No arguments.  No return—instead keys in the hashref are set.

After C<< $obj->analyze() >>, C<$obj> contains this data:

=over

=item C<< $obj->{'questions'} >> is a reference to an array of hashrefs,
one for each question in the exam.  Each question's hashref contains
the following keys:

=over

=item C<question>: the question's numerical ID (from the database) for
the question.

=item C<mean>: the average score on that question

=item C<max>: the maximum score B<achieved> by students on the question

=item C<ceiling>: the maximum score B<possible> on the question

=item C<min>: the minimum score achieved by students on the question

=item C<discrimination>: the correlation (Pearson's I<r>) of
the question score with the exam total.  This is a number between -1
and 1.  The closer it is to 1, the closer the question is to “predicting”
success on the entire exam.  

=item C<discrimination_class>: natural language description of the the
question's discrimination.  Current values are “Good“, “Fair”, or ”Poor”.

=item C<difficulty>: the quotient of the mean by the ceiling.  More
difficult items will have a difficulty closer to zero.

=item C<difficulty_class>: natural language description of the the
question's discrimination.  Current values are “Easy”, “Moderate”, or
”Hard”.

=item C<responses>: a hashref of hashrefs keyed by the answer number
(as a string).  For each key C<$a>, the following keys are set:

=over

=item C<label>: the label for the answer.  Normally this is a letter
like 'A', 'B', 'C', etc.  This key helps with formatting the report.

=item C<count>: the number of students selecting this answer

=item C<frequency>: the portion of students selecting this answer.
This is a number between 0 and 1.

=item C<mean>: the mean of the total for the students who selected this
answer

=item C<weight>: the change in total score for this answer.  In a regular
multiple choice question, this is probably the problem score for correct
answers and zero for incorrect answers.  For multiple choice questions
with multiple correct answers, this is probably the problem score divided
by the number of answers.  See L</weight_student_scoring_base> below.

=back

=back

=item C<< $obj->{'summary'} >> is a reference to an hash of summary statistics,
on the exam total:

=over

=item C<mean>: The mean or average of the exam total

=item C<standard_deviation>: the standard deviation of the exam total.
The higher the standard deviation, the more spread out the scores are
around the mean.

=item C<min>: the minimum score achieved

=item C<max>: the maximum score achieved

=item C<ceiling>: the maximum score possible

=item C<count>: the number of exams taken

=back

=item C<< $obj->{'submissions'} >> is a reference to an array of 
hashrefs, one for each exam submitted.

=item C<< $obj->{'metadata'} >> is a reference to a hash of metadata
about the exam itself.

=back

=cut

sub analyze {
    my ($self) = @_;
    $self->pre_process();

    # analyze the total
    my $marks       = $self->{'marks'};
    my @totals      = map { $_->{'mark'} } @$marks;
    my $total_stats = Statistics::Descriptive::Full->new();
    $self->{'_debug.total_stats'} = $total_stats;
    $self->{'_debug.totals'}      = \@totals;
    $total_stats->add_data(@totals);
    my $summary = $self->{'summary'};
    compute_summary_statistics( $total_stats, $summary );

    # analyze each question
    my $question_stats = Statistics::Descriptive::Full->new();
    for my $question ( @{ $self->{'questions'} } ) {
        my $title  = $question->{'title'};
        my $number = $question->{'question'};
        my @question_scores =
          map { $_->{$title}->{'score'} } @{ $self->{'submissions'} };
        $self->{ '_debug.' . $title . '.scores' } = \@question_scores;

        # print "DEBUG: question_scores: ", join(",",@question_scores), "\n";
        $question_stats->clear();
        $question_stats->add_data(@question_scores);

        # Compute correlation of this item with the total.
        my ( $b, $a, $r, $rms ) = $question_stats->least_squares_fit(@totals);
        $question->{'discrimination'} = $r;
        $question->{'discrimination_class'} =
          classify_discrimination($question);
        compute_summary_statistics( $question_stats, $question );
        if ( $question->{'ceiling'} != 0 ) {
            $question->{'difficulty'} =
              $question->{'mean'} / $question->{'ceiling'};
            $question->{'difficulty_class'} = classify_difficulty($question);
        }

# create the response hash
# We do this by sorting the reponses by the answers and collecting the total scores.
# there might be a map / filter / accumulate way to do this,
# but remember that the scoring_base may depend on the question *and* the student.
        my $responses = $question->{'responses'} = {};

# the next two lines iterate $response over @{$self->{'submissions'}} but with an index $i.
# Maybe there's a better way. See https://stackoverflow.com/a/974819/297797
        my $total_by_response  = {};
        my $weight_by_response = {};
        for my $i ( 0 .. $#{ $self->{'submissions'} } ) {
            my $submission = $self->{'submissions'}->[$i];
            my $response   = $submission->{$title};
            my $sb         = $response->{'scoring_base'};
            for my $answer ( @{ $sb->{'answers'} } ) {
                my $an = $answer->{'answer'};    # answer number
                unless ( defined $responses->{$an} ) {
                    $responses->{$an}              = {};
                    $responses->{$an}->{'correct'} = $answer->{'correct'};
                    $total_by_response->{$an}      = [];
                    $weight_by_response->{$an}     = [];
                }
                push @{ $weight_by_response->{$an} }, $answer->{'weight'};
                if ( $answer->{'ticked'} ) {
                    push @{ $total_by_response->{$an} }, $marks->[$i]->{'mark'};
                }
            }
        }
        my $total_by_response_stats  = Statistics::Descriptive::Sparse->new;
        my $weight_by_response_stats = Statistics::Descriptive::Full->new;
        for my $an ( keys %{$responses} ) {
            $total_by_response_stats->clear;
            $total_by_response_stats->add_data(
                @{ $total_by_response->{$an} } );
            $responses->{$an}->{'mean'}  = $total_by_response_stats->mean;
            $responses->{$an}->{'count'} = $total_by_response_stats->count;
            $responses->{$an}->{'frequency'} =
              $total_by_response_stats->count / $self->{'summary'}->{'count'};
            $weight_by_response_stats->clear;
            $weight_by_response_stats->add_data(
                @{ $weight_by_response->{$an} } );

        # You would think that $weight_by_response->{$an} would be a constant
        # array, but see the note above referring to Issue #2
        # <https://github.com/leingang/AMC-ItemAnalysis/issues/2>
        # We use the median to get the most expected answer for the answer's
        # weight (independent of student).  Mode might also be an option,
        # but I don't know of a test where it would succeed and median wouldn't.
            $responses->{$an}->{'weight'} = $weight_by_response_stats->median;
        }
        $question->{'type_class'} = $self->classify_type($question);
    }
    $self->{'summary'}->{'alpha'} = $self->alpha();
    $self->_add_labels();
}

=head2 export 

Export to a file.  One parameter: the file name.  No return.

This is more of a virtual method.  Since there is no 
C<AMC::Export::register::ItemAnalysis> module, this will never
get called by the GUI.  But in case you want a dump (from L<Data::Dumper>) 
of the data in a file, here it is.

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
    open( my $fh, ">:encoding(" . $self->{'out.encodage'} . ")", $fichier );
    print $fh Dumper($data);
    close($fh);
}

=head1 PRIVATE METHODS

These methods aren't intended for end users.  They're documented just
to make sure we know what's going on.

=head2 load

Load database connection and set data submodules.

=cut

sub load {
    my ($self) = @_;

    # print "load: BEGIN", "\n";
    $self->SUPER::load();
    $self->{'_capture'} = $self->{'_data'}->module('capture');
    bless $self->{'_capture'}, 'AMC::ItemAnalysis::capture';

    # print "load: about to save variables...";
    for my $var ( 'darkness_threshold', 'darkness_threshold_up' ) {
        $self->{'_capture'}->{$var} =
          $self->{'_scoring'}->variable_transaction($var);
    }
    $self->{'_score'} = AMC::Scoring::new(
        'seuil'    => $self->{'_capture'}->{'darkness_threshold'},
        'seuil_up' => $self->{'_capture'}->{'darkness_threshold_up'},
        '_scoring' => $self->{'_scoring'},
        '_capture' => $self->{'capture'}
    );

    # print "done\n";
    # print "load: END\n";
}

=head2 pre_process

Import exam, question, and submission data.

This method should be considered internal.  Any external method that needs 
pre-processing should call this method.

FIXME: prevent this method from being called more than once.  It takes 
a while to run.

C<< $self->{'marks'}  >> is populated by C<AMC::Export::pre_process>.
It is an arrayref, with one item for each student.  For each C<$i>, 
#<< $self->{'marks'}->[$i] >> has keys C<total> and C<max>, along with
a bunch of other stuff.

C<< $self->{'questions'} >> is populated by the result of 
C<AMC::DataModule::scoring::codes_questions>,
with one item for each (non-indicative) question.  For each C<$i>,
C<< $self->{'questions'}->[$i] >> has keys/values

=over

=item C<title>: unique string identifying the question

=item C<question>: integer ID in database

=back

C<< $self->{'submissions'} >> is populated by looking up each student's
responses and results. These come from 
C<AMC::DataModule::scoring::question_result> and 
C<AMC::ItemAnalysis::capture::question_response>.  The $ith element of
C<< $self->{'submissions'} >> is the complete list of responses for the
student in the $ith element of C<< $self->{'marks'} >>.  For each C<$i>, 
C<< $self->{'submissions'}->[$i] >> is a hashref, keyed on question 
titles. For each question title C<$k>, 
C<< $self->{'submissions'}->[$i]->{$k} >> has keys/values

=over

=item C<score>: score by student C<$i> on question C<$k>

=item C<response>: response by student C<$i> on question C<$k>

=item C<index>: question number (not sure if this is in the DB or on
the student's paper).

=back

C<< $self->{'metadata'} >>  will contain any metadata we can discover
about the exam.
So far, that is only the C<title>.

B<TODO:> get additional metadata from the TeX file, if possible.
(Exam date maybe?)

C<< $self->{'summary'} >> will contain any summary statistics about the
exam total score. This method only sets a C<ceiling> key/value (maximum 
possible score, where as C<max> is maximum achieved score).  
Later methods will add to it.

=cut

sub pre_process {
    my ($self) = @_;

    # print "get_data:BEGIN\n";
    $self->SUPER::pre_process();

    # this setting comes from the GUI.  We may want to report the number of
    # absentees somewhere, but there's no need to add them to the analysis.
    # So we'll just reset it to zero.
    $self->{'noms.useall'} = 0;

    # put this in $self instead
    # $o = {};
    # $o->{'items'} = []; # replace with $self->{'questions'}
    # $o->{'submissions'} = []; # replace with $self->{'submissions'}
    # $o->{'totals'} = $self->{'marks'}; # just use $self->{'marks'}
    $self->{'submissions'} = [];
    my $exam_name = $self->{'out.nom'} ? $self->{'out.nom'} : "Untitled Exam";

    $self->{'_scoring'}->begin_read_transaction('IAgt');

    my $marks = $self->{'marks'};
    my @codes;
    my @questions;

    # populate @codes and @questions lists.
    # I think:
    # - @codes is student identifying codes,
    # - @questions is exam questions.
    # - last argument is "plain" or not.
    #
    # Do we need @codes?
    $self->codes_questions( \@codes, \@questions, 1 );
    for my $question (@questions) {
        $question->{'ceiling'} =
          $self->{'_scoring'}->question_maxmax( $question->{'question'} );
    }
    $self->{'questions'} = \@questions;

    # look for the first mark that has a max
    # (Assumes all student exams have the same max.)
    my $max = undef;
    for my $m (@$marks) {
        last if ( $max = $m->{'max'} );
    }

   # Loop on each student mark record
   # Since we're looping through @$marks and appending to both @{$o->{'totals'}}
   # and @{$o->{'submissions'}}, those arrays will be lined up by student.
   # For now, there's no need to record the student number, copy number,
   # or any personally identifying information about the student as a key.
    for my $m (@$marks) {

        # @sc is a list of the student number and copy number
        # It can't be a hash key but we could stringify it.
        my @sc  = ( $m->{'student'}, $m->{'copy'} );
        my $ssb = $self->{'_scoring'}->student_scoring_base(
            @sc,
            $self->{'_capture'}->{'darkness_threshold'},
            $self->{'_capture'}->{'darkness_threshold_up'}
        );
        $self->weight_student_scoring_base( $sc[0], $ssb );
        my $submission = {};
        for my $q (@questions) {
            my $qn = $q->{'question'};    # Question number
            my $qt = $q->{'title'};       # Question name
            my $response = $self->{'_capture'}->question_response( @sc, $qn );
            my $result   = $self->{'_scoring'}->question_result( @sc, $qn );
            $submission->{$qt} = {
                'index'    => $qn,
                'score'    => $result->{'score'},
                'max'      => $result->{'max'},
                'response' => $response,

        # we're adding the scoring base here mainly for introspection/debugging.
        # Remove it later?
                'scoring_base' => $ssb->{'questions'}->{$qn}
            };
            $q->{'type'} = $ssb->{'questions'}->{$qn}->{'type'};
        }
        push @{ $self->{'submissions'} }, $submission;
    }

    $self->{'_scoring'}->end_transaction('IAgt');

    # exam summary statistics and metadata
    $self->{'summary'}  = {};
    $self->{'metadata'} = {};
    if ($max)       { $self->{'summary'}->{'ceiling'} = $max; }
    if ($exam_name) { $self->{'metadata'}->{'title'}  = $exam_name; }
    return;

}

=head2 weight_student_scoring_base 

Add weights to the student scoring base.

The C<student_scoring_base> contains useful data to compute questions scores for a
particular student (identified by $student and $copy), as a reference to a hash
grouping questions and answers. For example:

    'main_strategy'=>"",
    'questions'=>
    { 1 =>{ 'question'=>1,
            'title' => 'questionID',
            'type'=>1,
            'indicative'=>0,
            'strategy'=>'',
            'answers'=>[ { 'question'=>1, 'answer'=>1,
                        'correct'=>1, 'ticked'=>0, 'strategy'=>"b=2" },
                        {'question'=>1, 'answer'=>2,
                        'correct'=>0, 'ticked'=>0, 'strategy'=>"" },
                    ],
        },
    ...
    }

This subroutine adds to each answer the score that would be earned for 
I<just that box> were it ticked.

B<NOTE:> For multiple choice questions with multiple correct answer, 
this might give unexpected results.  For instance, if the student ticks 
one correct answer and leaves the rest blank, flipping the ticked answer
leaves no box ticked.  This results in an empty response and score of zero.  
So the weight of a single answer could be quite high, rather than just 
the total question value divided by the number of answers.

Nevertheless, this is probably the best way to assign a weight to a
single student's single answer to a single question.  AMC does not
assume that every student has the same scoring base (not even modulo
permutations of answers).

See L<Issue 2|https://github.com/leingang/AMC-ItemAnalysis/issues/2>

=cut

sub weight_student_scoring_base {
    my ( $self, $student, $ssb ) = @_;
    my $scorer = $self->{'_score'};
    while ( my ( $k, $q ) = each( %{ $ssb->{'questions'} } ) ) {

        # baseline question score
        $scorer->prepare_question($q);
        $scorer->set_type(0);
        my ( $old_xx, $old_why ) = $scorer->score_question( $student, $q, 0 );

        # clone the question so we can test scores for
        # individually ticked boxes
        if ( $q->{'type'} == 1 ) {

            # mutiple choice question with a single correct
            # answer.  To find the weight, we zero out all answers
            # in the clone and tick answer $i.
            my $qc = dclone $q;
            for my $i ( 0 .. $#{ $q->{'answers'} } ) {

                # zero out 'ticked' for all answers in the clone
                # except $i
                for my $j ( 0 .. $#{ $q->{'answers'} } ) {
                    $qc->{'answers'}->[$j]->{'ticked'} = ( $i == $j ? 1 : 0 );
                }
                $scorer->prepare_question($qc);
                $scorer->set_type(0);
                my ( $new_xx, $new_why ) =
                  $scorer->score_question( $student, $qc, 0 );
                $q->{'answers'}->[$i]->{'weight'} = $new_xx;
            }
        }
        elsif ( $q->{'type'} == 2 ) {

            # multiple choice question with multiple correct answers
            # and *not* ticking boxes could lead to points.
            # So we compute the weight of each by flipping it and comparing
            # to the original.
            for my $i ( 0 .. $#{ $q->{'answers'} } ) {

                # for my $j (0 .. $#{$q->{'answers'}}) {
                #     $orig_ticked = $q->{'answers'}->[$j]->{'ticked'};
                #     $qc->{'answers'}->[$j]->{'ticked'}
                #         = ($i == $j ? (1 - $orig_ticked) : $orig_ticked);
                # }
                # reclone
                my $qc = dclone $q;
                $scorer->prepare_question($qc);
                $scorer->set_type(0);
                $qc->{'answers'}->[$i]->{'ticked'} =
                  1 - $q->{'answers'}->[$i]->{'ticked'};
                my ( $new_xx, $new_why ) =
                  $scorer->score_question( $student, $qc, 0 );
                $q->{'answers'}->[$i]->{'weight'} = abs( $old_xx - $new_xx );
            }
        }
        else {
            die "Bad question type!";
        }
    }
}

=head2 alpha

Compute Cronbach's alpha for the entire exam.

No parameters.  It's basically an object property that's evaluated.

Uses the formula from 
L<the Wikipedia page|https://en.wikipedia.org/wiki/Cronbach%27s_alpha>.
The mplementation is not the most efficient, but I had trouble getting others
to work.

=cut

sub alpha {
    my $self = shift;
    my $K    = scalar @{ $self->{'questions'} };
    return if ( $K == 0 ); # no reliability for a test with no items!
    return 1 if ( $K == 1 ); # if there is only one item it is totally reliable!
    my $total_variance = $self->{'summary'}->{'standard_deviation'} *
      $self->{'summary'}->{'standard_deviation'};
    return if ( $total_variance == 0 ); # if all scores are the same
    my @stdevs = map { $_->{'standard_deviation'} } @{ $self->{'questions'} };
    my @variances        = map { $_ * $_ } @stdevs;
    my $sum_of_variances = sum @variances;
    return $K / ( $K - 1 ) * ( 1 - $sum_of_variances / $total_variance );
}

=head2 classify_difficulty

Classify the difficulty of an item 

Parameter: hashref of question statistics.

ScorePak® arbitrarily classifies item difficulty as “easy” if the index is
85% or above; “moderate” if it is between 51 and 84%; and “hard” if it is 
50% or below.  This suroutine makes the same classification.  Which means
as long as a key C<difficulty> is passed, the routine will return a
meaningful classification.

=cut

sub classify_difficulty {
    my $q    = shift;
    my $diff = $q->{'difficulty'};
    if ( $diff >= 0.85 ) {
        return "Easy";
    }
    elsif ( $diff >= 0.5 ) {
        return "Moderate";
    }
    else {
        return "Hard";
    }
}

=head2 classify_discrimination

Classify the discrimination of an item 

ScorePak® classifies item discrimination as “good” if the index is above 
.30; “fair” if it is between .10 and .30; and “poor” if it is below .10.
This suroutine makes the same classification.  Which means
as long as a key C<discrimination> is passed, the routine will return a
meaningful classification.

=cut 

sub classify_discrimination {
    my $q    = shift;
    my $diff = $q->{'discrimination'};
    if ( $diff >= 0.3 ) {
        return "Good";
    }
    elsif ( $diff >= 0.1 ) {
        return "Fair";
    }
    else {
        return "Poor";
    }
}

# compute correlation between two Statistics::Descriptive variables
#
# This was put in just to test the module's own calculation.
# FIXME: put it somewhere else like in a Statistics::Descriptive test.
sub _correlation {
    my ( $self, $x_stats, $y_stats ) = @_;
    my @x        = $x_stats->get_data();
    my @y        = $y_stats->get_data();
    my @xy       = map { $x[$_] * $y[$_] } ( 0 .. $#x );
    my $xy_stats = Statistics::Descriptive::Full->new();
    $xy_stats->add_data(@xy);
    return ( $xy_stats->mean() - ( $x_stats->mean() ) * ( $y_stats->mean() ) )
      / ( $x_stats->standard_deviation() * $y_stats->standard_deviation() );
}

=head2 classify_type 

Classify the type of a question

Parameter: hashref of question data/metadata.  

Returns 'MC', 'MS', or 'FR' accordingly:

=over 

=item C<MC>: question is fixed response (B<m>ultiple B<c>hoice) with a single
correct answer.

=item C<MS>: question is fixed response with multiple correct answers
(B<m>ultiple B<s>election)

=item C<FR>: question is "open" or B<f>ree B<r>esponse.

=back 

CAVEAT: This routine isn't all that reliable.  It correctly identifies MC
problems and true MS problems.  But numeric problems are still identified as 
MS problems, because that is how they are implemented in AMC's database.

The routine delegates to L</question_is_open> the identification of FR
questions, but that is also suspect.  

The issue is that these types of questions are only declared in the source
file.

=cut

# TODO: create some tests for this function based on mt1
# Also a quiz that has numeric questions, like Honors Calc III Q13 (?)
sub classify_type {
    my ( $self, $q ) = @_;
    if ( $self->question_is_open($q) ) {
        return 'FR';
    }
    elsif ( $q->{'type'} == 1 ) {

        # TODO: fix above with an AMC constant
        return 'MC';
    }
    elsif ( $q->{'type'} == 2 ) {
        return 'MS';
    }
    else {
        return $q->{'type'};
    }
}

=head2 question_is_open

C<< $obj->question_is_open($q) >> Decides if $q is “open” or free 
response

Parameter: hashref of question data/metadata

We see if the list is a range consisting all of all integers from zero
to the maximum.  This will succeed in all my use cases.  If someone
makes a free-response problem which skips some values, or has
non-integer values, this will fail.

=cut

sub question_is_open {
    my ( $self, $q ) = @_;

    # print "q:", Dumper($q);
    # return ($q->{'title'} =~ /^FR/);
    # won't work until the answers have been loaded, obvs.
    my @answers = keys %{ $q->{'responses'} };

    # print "answers: ", Dumper(\@answers);
    my @weights =
      sort { $a <=> $b } map { $q->{'responses'}->{$_}->{'weight'} } @answers;

    # print $q->{'title'}, " weights: ", Dumper(\@weights);
    my $i = 0;
    return reduce { $a && ( $b == $i++ ) } 1, @weights;
}

=head2 compute_summary_statistics

C<compute_summary_statistics($analyzer,$dest)> will compute summary
statistics for the data in C<$analyzer> and store it in the hashref
C<$dest>.

C<$analyzer> is expected to be an object of class
L<Statistics::Descriptive>, or at least something that has methods
of the names described blow.

These keys are set in C<$dest>: C<mean>, C<median>, 
C<standard_deviation>, C<min>, C<max>, and C<count>.

=cut 

sub compute_summary_statistics {
    my ( $analyzer, $dest ) = @_;
    for (qw(mean standard_deviation min max count)) {
        $dest->{$_} = $analyzer->$_();
    }

    # these methods sort the data, which messes with
    # correlations.  So we do them on a copy.
    my $analyzer_copy = Statistics::Descriptive::Full->new();
    $analyzer_copy->add_data( $analyzer->get_data() );
    $dest->{'median'} = $analyzer_copy->median();
    my @sorted = $analyzer_copy->get_data;
    my ( $Q1, $Q3, $lower, $upper );
    $dest->{'Q1'}              = $Q1    = $analyzer_copy->quantile(1);
    $dest->{'Q3'}              = $Q3    = $analyzer_copy->quantile(3);
    $dest->{'lower_threshold'} = $lower = $Q1 - 1.5 * ( $Q3 - $Q1 );
    $dest->{'upper_threshold'} = $upper = $Q3 + 1.5 * ( $Q3 - $Q1 );
    my @trimmed  = ();
    my @outliers = ();

    # partition @sorted into two arrays to weed out
    # outliers but keep the good ones.
    # See https://stackoverflow.com/a/8618040/297797
    # for the algorithm and notes.
    for (@sorted) {
        if ( ( $_ >= $lower ) && ( $_ <= $upper ) ) {
            push @trimmed, $_;
        }
        else {
            push @outliers, $_;
        }
    }
    $dest->{'upper_extreme'} = max @trimmed;
    $dest->{'lower_extreme'} = min @trimmed;
    $dest->{'outliers'}      = \@outliers;
}

# REALLY PRIVATE METHODS
# ----------------------

# These methods won't be publicly documented.
# They begin with an underscore so Test::Pod::Coverage
# won't complain about that.

# add answer labels to responses hash
#
# Uses the C<AMC::CSLog> module to parse the project's F<amc-compiled.cs>
# log file.
sub _add_labels {
    my $self            = shift;
    my $project_dir     = dirname( $self->{'fich.datadir'} );
    my $cslog_file_name = $project_dir . "/amc-compiled.cs";
    if ( -e $cslog_file_name ) {
        my $cslog_parser = AMC::CSLog->new();
        my $labels       = $cslog_parser->parse($cslog_file_name);
        for (@$labels) {
            my $question_name = $_->{'question_name'};
            my $answer_number = $_->{'answer_number'};
            my $answer_label  = $_->{'answer_label'};
            my $question      = first { $_->{'title'} eq $question_name }
            @{ $self->{'questions'} };
            $question->{'responses'}->{$answer_number}->{'label'} =
              $answer_label;
        }
    }
}

1;
