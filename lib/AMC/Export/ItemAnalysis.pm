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

package AMC::Export::ItemAnalysis;

use AMC::Basic;
use AMC::Export;
use AMC::Scoring;
use AMC::ItemAnalysis::capture;
use File::Basename;
use List::Util "sum";
use YAML::Tiny;
use Statistics::Descriptive;

use Encode;
use Storable 'dclone';

@ISA=("AMC::Export");

use Data::Dumper;# for debugging

sub new {
    # print "new: BEGIN\n";
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->{'out.nom'}="";
    $self->{'out.code'}="";
    $self->{'out.encodage'}='utf-8';
    $self->{'out.separateur'}=",";
    $self->{'out.decimal'}=",";
    $self->{'out.entoure'}="\"";
    $self->{'out.ticked'}="";
    $self->{'out.columns'}='student.copy,student.key,student.name';
    $self->{'noms.useall'}=0;
    bless ($self, $class);
    return $self;
}

sub load {
    my ($self)=@_;
    # print "load: BEGIN", "\n";
    $self->SUPER::load();
    $self->{'_capture'}=$self->{'_data'}->module('capture');
    bless $self->{'_capture'}, 'AMC::ItemAnalysis::capture';
    # print "load: about to save variables...";
    for my $var ('darkness_threshold','darkness_threshold_up') {
        $self->{'_capture'}->{$var} = $self->{'_scoring'}->variable_transaction($var);
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

# format a number
sub parse_num {
    my ($self,$n)= @_;
    if($self->{'out.decimal'} ne '.') {
	$n =~ s/\./$self->{'out.decimal'}/;
    }
    return($self->parse_string($n));
}

sub parse_string {
    my ($self,$s)=@_;
    if($self->{'out.entoure'}) {
	$s =~ s/$self->{'out.entoure'}/$self->{'out.entoure'}$self->{'out.entoure'}/g;
	$s=$self->{'out.entoure'}.$s.$self->{'out.entoure'};
    }
    return($s);
}


# Import exam, question, and submission data into $self.
#
# This method should be considered internal.  Any external method that needs 
# pre-processing should call this method.
#
# FIXME: prevent this method from being called more than once.
# 
# $self->{'marks'} is populated in AMC::Export::pre_process().  It is an arrayref,
# with one item for each student.  For each $i, 
# $self->{'marks'}->[$i] has keys 'total' and 'max', along with a bunch of other stuff.
#
# $self->{'questions'} is populated by the result of AMC::DataModule::scoring::codes_questions,
# with one item for each (non-indicative) question.  For each $i,
# $self->{'questions'}->[$i] has keys/values
# - title: unique string identifying the question
# - question: integer ID in database
#
# $self->{'submissions'} is populated by looking up each student's responses and results.
# These come from AMC::DataModule::scoring::question_result and 
# AMC::ItemAnalysis::capture::question_response.  The $ith element of $self->{'submissions'}.
# is the complete list of responses for the student in the $ith element of $self->{'marks'}. 
# For each $i, $self->{'submissions'}->[$i] is a hashref, keyed on question titles.
# For each question title $k, $self->{'submissions'}->[$i]->{$k} has keys/values
# - score: score by student $i on question $k
# - response: response by student $i on question $k
# - index: question number (not sure if this is in the DB or on the student's paper).
#
# $self->{'metadata'} will contain any metadata we can discover about the exam.
# - title: title of the exam
# TODO: get additional metadata from the TeX file, if possible.
#
# $self->{'summary'} will contain any summary statistics about the exam total score.
# This method only sets a 'ceiling' key/value (maximum possible score, where as 'max'
# is maximum achieved score).  Later methods will add to it.
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
    $exam_name = $self->{'out.nom'} ? $self->{'out.nom'} : "Untitled Exam" ;

    $self->{'_scoring'}->begin_read_transaction('IAgt');
    
    $marks = $self->{'marks'};
    my @codes;
    my @questions;
    # populate @codes and @questions lists.
    # I think:
    # - @codes is student identifying codes,
    # - @questions is exam questions.
    # - last argument is "plain" or not.  
    #
    # Do we need @codes?
    $self->codes_questions(\@codes,\@questions,1);
    for my $question (@questions) {
       $question->{'ceiling'} = $self->{'_scoring'}->
           question_maxmax($question->{'question'});
    }
    $self->{'questions'} = \@questions;

    # look for the first mark that has a max
    # (Assumes all student exams have the same max.)
    for my $m (@$marks) {
        last if ($max = $m->{'max'});
    }

    # Loop on each student mark record
    # Since we're looping through @$marks and appending to both @{$o->{'totals'}}
    # and @{$o->{'submissions'}}, those arrays will be lined up by student.
    # For now, there's no need to record the student number, copy number,
    # or any personally identifying information about the student as a key.
    for my $m (@$marks) {
        # @sc is a list of the student number and copy number
        # It can't be a hash key but we could stringify it.
        my @sc=($m->{'student'},$m->{'copy'});
        $ssb = $self->{'_scoring'}->student_scoring_base(
            @sc,
            $self->{'_capture'}->{'darkness_threshold'},
            $self->{'_capture'}->{'darkness_threshold_up'}
        );
        $self->weight_student_scoring_base($sc->[0],$ssb);
        $submission = {};
        for my $q (@questions) {
            my $qn = $q->{'question'}; # Question number
            my $qt = $q->{'title'};    # Question name
            $response = $self->{'_capture'}->question_response(@sc,$qn);
            $result = $self->{'_scoring'}->question_result(@sc,$qn);
            $submission->{$qt} = {
                'index' => $qn,
                'score' => $result->{'score'},
                'max' => $result->{'max'},
                'response' => $response,
                # we're adding the scoring base here mainly for introspection/debugging.
                # Remove it later?
                'scoring_base' => $ssb->{'questions'}->{$qn}
            };
            $q->{'type'} = $ssb->{'questions'}->{$qn}->{'type'};
        }
        push @{$self->{'submissions'}}, $submission;
    }

    $self->{'_scoring'}->end_transaction('IAgt');

    # exam summary statistics and metadata
    $self->{'summary'} = {};
    $self->{'metadata'} = {};
    if ($max) { $self->{'summary'}->{'ceiling'} = $max; }
    if ($exam_name) { $self->{'metadata'}->{'title'} = $exam_name; }
    return;

}

# add weights to the student scoring base
# the C<student_scoring_base> useful data to compute questions scores for a
# particular student (identified by $student and $copy), as a reference to a hash
# grouping questions and answers. For example:
#
# 'main_strategy'=>"",
# 'questions'=>
# { 1 =>{ 'question'=>1,
#         'title' => 'questionID',
#         'type'=>1,
#         'indicative'=>0,
#         'strategy'=>'',
#         'answers'=>[ { 'question'=>1, 'answer'=>1,
#                        'correct'=>1, 'ticked'=>0, 'strategy'=>"b=2" },
#                      {'question'=>1, 'answer'=>2,
#                        'correct'=>0, 'ticked'=>0, 'strategy'=>"" },
#                    ],
#       },
#  ...
# }
# This subroutine adds to each answer the score that would be earned for 
# *just that box* were it ticked
sub weight_student_scoring_base {
    my ($self, $student, $ssb) = @_;
    $scorer = $self->{'_score'};
    while (my ($k,$q) = each (%{$ssb->{'questions'}})) {
        # baseline question score
        $scorer->prepare_question($q);
        $scorer->set_type(0);
        ($old_xx,$old_why) = $scorer->score_question($student,$q,0);
        # clone the question so we can test scores for
        # individually ticked boxes
        if ($q->{'type'} == 1) {
            # mutiple choice question with a single correct 
            # answer.  To find the weight, we zero out all answers
            # in the clone and tick answer $i.
            $qc = dclone $q;
            for my $i (0 .. $#{$q->{'answers'}}) {
                # zero out 'ticked' for all answers in the clone
                # except $i
                for my $j (0 .. $#{$q->{'answers'}}) {
                    $qc->{'answers'}->[$j]->{'ticked'} = ($i == $j ? 1 : 0);
                }
                $scorer->prepare_question($qc);
                $scorer->set_type(0);
                ($new_xx,$new_why) = $scorer->score_question($student,$qc,0);
                $q->{'answers'}->[$i]->{'weight'} = $new_xx;
            }
        }
        elsif ($q->{'type'} == 2) {
            # multiple choice question with multiple correct answers
            # and *not* ticking boxes could lead to points.
            # So we compute the weight of each by flipping it and comparing
            # to the original.
            #
            # NOTE: this might give unexpected results.  For instance, if the
            # student ticks one correct answer and leaves the rest blank, flipping
            # the ticked answer leaves no box ticked.  This results in an empty
            # response and score of zero.  So the weight of a single answer could
            # be quite high, rather than just the total question value divided by 
            # the number of answers.
            #
            # Nevertheless, this is probably the best way to assign a weight to a
            # single student's single answer to a single question.  AMC does not
            # assume that every student has the same scoring base (not even modulo
            # permutations of answers).
            #
            # See <https://github.com/leingang/AMC-ItemAnalysis/issues/2>
            for my $i (0 .. $#{$q->{'answers'}}) { 
                # for my $j (0 .. $#{$q->{'answers'}}) {
                #     $orig_ticked = $q->{'answers'}->[$j]->{'ticked'};
                #     $qc->{'answers'}->[$j]->{'ticked'} 
                #         = ($i == $j ? (1 - $orig_ticked) : $orig_ticked);
                # }
                # reclone
                $qc = dclone $q;
                $scorer->prepare_question($qc);
                $scorer->set_type(0);
                $qc->{'answers'}->[$i]->{'ticked'} = 1 - $q->{'answers'}->[$i]->{'ticked'};
                ($new_xx,$new_why) = $scorer->score_question($student,$qc,0);
                $q->{'answers'}->[$i]->{'weight'} = abs($old_xx-$new_xx);
            }
        }
        else {
            die "Bad question type!";
        }
    }
}

# Do the analysis.  These keys/values should be set:
# For each question in @{$self->{'questions'}},
# - mean: average
# - max: maximum score achieved
# - ceiling: maximum score possible
# - discrimination: correlation of item with total
# - discrimination_class: English classification of discrimination
# - difficulty: mean/ceiling
# - difficulty_class: English classification of difficulty.
# - histogram: a hashref keyed by the answer type
# 
# For each answer $a to question $i,
# $self->{'questions'}->[$i]->{'histogram'}->{$a} has keys/values:
# - count: number of students selecting this response
# - mean: mean of total for those students who selected this response
# - weight: score for students who selected this response
#           (I think this can be found in student_scoring_base)
sub analyze {
    my ($self) = @_;
    $self->pre_process();
    # analyze the total     
    $marks = $self->{'marks'};
    @totals = map {$_->{'mark'}} @$marks;
    $total_stats = Statistics::Descriptive::Full->new();
    $self->{'_debug.total_stats'} = $total_stats;
    $self->{'_debug.totals'} = \@totals;
    $total_stats->add_data(@totals);
    $summary = $self->{'summary'};
    $self->compute_summary_statistics($total_stats,$summary);

    # analyze each question
    $question_stats = Statistics::Descriptive::Full->new();
    for my $question (@{$self->{'questions'}}) {        
        $title = $question->{'title'};
        $number = $question->{'question'};
        @question_scores = map {$_->{$title}->{'score'}} @{$self->{'submissions'}};
        $self->{'_debug.' . $title . '.scores'} = \@question_scores;
        # print "DEBUG: question_scores: ", join(",",@question_scores), "\n";
        $question_stats->clear();
        $question_stats->add_data(@question_scores);
        # Compute correlation of this item with the total.
        my ($b, $a, $r, $rms) = $question_stats->least_squares_fit(@totals);
        $question->{'discrimination'} = $r;
        $question->{'discrimination_class'} = $self->classify_discrimination($question);
        # FIXME: DRY this up.  The routine below alters the data in $question_stats, though.
        # $self->compute_summary_statistics($question_stats,$question);        
        $question->{'mean'} = $question_stats->mean();
        $question->{'standard_deviation'} = $question_stats->standard_deviation();
        $question->{'min'} = $question_stats->min();
        $question->{'max'} = $question_stats->max();
        $question->{'count'} = $question_stats->count();
       	if ($question->{'ceiling'} != 0) {
            $question->{'difficulty'} = $question->{'mean'} / $question->{'ceiling'};
            $question->{'difficulty_class'} = $self->classify_difficulty($question);
	    }
        $question->{'type_class'} = $self->classify_type($question);


        # create the histogram
        # We do this by sorting the reponses by the answers and collecting the total scores.
        # there might be a map / filter / accumulate way to do this,
        # but remember that the scoring_base may depend on the question *and* the student.
        $histogram = $question->{'histogram'} = {};
        # the next two lines iterate $response over @{$self->{'submissions'}} but with an index $i.
        # Maybe there's a better way. See https://stackoverflow.com/a/974819/297797
        $total_by_response = {};   
        $weight_by_response = {}; 
        for my $i (0 .. $#{$self->{'submissions'}}) {
            $submission = $self->{'submissions'}->[$i];    
            $response = $submission->{$title};
            $sb = $response->{'scoring_base'};
            for my $answer (@{$sb->{'answers'}}) {
                $an = $answer->{'answer'}; # answer number
                unless (defined $histogram->{$an}) {
                    $histogram->{$an} = {};
                    $histogram->{$an}->{'correct'} = $answer->{'correct'};
                    $total_by_response->{$an} = [];
                    $weight_by_response->{$an} = [];
                }
                push @{$weight_by_response->{$an}}, $answer->{'weight'};
                if ($answer->{'ticked'}) {
                    push @{$total_by_response->{$an}}, $marks->[$i]->{'mark'};
                }
            }
        }
        $total_by_response_stats = Statistics::Descriptive::Sparse->new;
        $weight_by_response_stats = Statistics::Descriptive::Full->new;
        for my $an (keys %{$histogram}) {
            $total_by_response_stats->clear;
            $total_by_response_stats->add_data(@{$total_by_response->{$an}});
            $histogram->{$an}->{'mean'} = $total_by_response_stats->mean;
            $histogram->{$an}->{'count'} = $total_by_response_stats->count;
            $histogram->{$an}->{'frequency'} =
                $total_by_response_stats->count / $self->{'summary'}->{'count'};
            $weight_by_response_stats->clear;
            $weight_by_response_stats->add_data(@{$weight_by_response->{$an}});
            # You would think that $weight_by_response->{$an} would be a constant
            # array, but see the note above referring to Issue #2
            # <https://github.com/leingang/AMC-ItemAnalysis/issues/2>
            # We use the median to get the most expected answer for the answer's 
            # weight (independent of student).  Mode might also be an option,
            # but I don't know of a test where it would succeed and median wouldn't.            
            $histogram->{$an}->{'weight'} = $weight_by_response_stats->median;
        }        
    }
    $self->{'summary'}->{'alpha'} = $self->alpha();
}


# compute Cronbach's alpha for the entire exam.
#
# Uses the formula from L<https://en.wikipedia.org/wiki/Cronbach%27s_alpha>
# 
# implementation is not the most efficient, but I had trouble getting others
# to work.
sub alpha {
    my $self = shift;
    my $K = scalar @{$self->{'questions'}};
    return undef if ($K == 0); # no reliability for a test with no items!
    return 1 if ($K == 1); # if there is only one item it is totally reliable!
    my $total_variance = $self->{'summary'}->{'standard_deviation'} * $self->{'summary'}->{'standard_deviation'}; 
    return undef if ($total_variance == 0); # if all scores are the same 
    my @stdevs = map { $_->{'standard_deviation'} } @{$self->{'questions'}}; 
    my @variances = map { $_ * $_ } @stdevs;
    my $sum_of_variances = sum @variances;
    return $K/($K-1)*(1 - $sum_of_variances/$total_variance);
}

# classify the difficulty of an item 
#
# ScorePak® arbitrarily classifies item difficulty as “easy” if the index is
# 85% or above; “moderate” if it is between 51 and 84%; and “hard” if it is 
# 50% or below.
sub classify_difficulty {
    my ($self,$q) = @_;
    $diff = $q->{'difficulty'};
    if ($diff >= 0.85) {
        return "Easy"
    }
    elsif ($diff >= 0.5) {
        return "Moderate"
    }
    else {
        return "Hard"
    }
}

# compute correlation between two Statistics::Descriptive variables 
# just to test;
sub correlation {
    my ($self,$x_stats,$y_stats) = @_;
    my @x = $x_stats->get_data();
    my @y = $y_stats->get_data();
    my @xy = map {$x[$_] * $y[$_]} (0 .. $#x);
    $xy_stats = Statistics::Descriptive::Full->new();
    $xy_stats->add_data(@xy);
    return ($xy_stats->mean() - ($x_stats->mean())*($y_stats->mean())) /
        ($x_stats->standard_deviation()*$y_stats->standard_deviation())
}


# classify the discrimination of an item 
#
# ScorePak® classifies item discrimination as “good” if the index is above 
# .30; “fair” if it is between .10 and.30; and “poor” if it is below .10.
sub classify_discrimination {
    my ($self,$q) = @_;
    $diff = $q->{'discrimination'};
    if ($diff >= 0.3) {
        return "Good"
    }
    elsif ($diff >= 0.1) {
        return "Fair"
    }
    else {
        return "Poor"
    }
}

# classify the type of a problem
#
# Returns 'MC', 'MS', or 'FR' accordingly
sub classify_type {
    my ($self,$q) = @_;
    if ($self->question_is_open($q)) {
        return 'FR'
    }
    elsif ($q->{'type'} == 1) {
        # TODO: fix above with an AMC constant
        return 'MC'
    }
    elsif ($q->{'type'} == 2) {
        return 'MS'
    }
    else {
        return $q->{'type'};
    }
}

# decide if a quesition is 'open' 
# or free response
# 
# for now, we parse the title
# but better would be to parse the source file
# at load time.
sub question_is_open {
    my ($self,$q) = @_;
    return ($q->{'title'} =~ /^FR/);
}


# compute summary statistics for a data set
#
# helper routine to turn two repeated lines of code into one
#
# arguments:
#     $analyzer (Statistics::Descriptive): object that computes the stats
#     $dest: destination for those statistics
#
# FIXME: seems to alter the data.
# Possible improvements: return value, select stats...
sub compute_summary_statistics {
    my ($self,$analyzer,$dest) = @_;
    for (qw(mean median standard_deviation min max count)) {
        $dest->{$_} = $analyzer->$_();
    }
}

# export to file
#
# Since there is no AMC::Export::register::ItemAnalysis module, this will never
# get called by the GUI.  But in case you want a dump from Data::Dumper of the
# data in a file, here it is.
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
    open(OUT,">:encoding(".$self->{'out.encodage'}.")",$fichier);
    print OUT Dumper($data);
    close(OUT);
}

1;
