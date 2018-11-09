
package AMC::Export::ItemAnalysis;

use AMC::Basic;
use AMC::Export;
use AMC::ItemAnalysis::capture;
use YAML::Tiny;
use Statistics::Descriptive;

use Encode;

@ISA=("AMC::Export");

use Data::Dumper;# for debugging

sub new {
    print "new: BEGIN\n";
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
    bless ($self, $class);
    return $self;
}

sub load {
    my ($self)=@_;
    print "load: BEGIN", "\n";
    $self->SUPER::load();
    $self->{'_capture'}=$self->{'_data'}->module('capture');
    bless $self->{'_capture'}, 'AMC::ItemAnalysis::capture';
    print "load: about to save variables...";
    for my $var ('darkness_threshold','darkness_threshold_up') {
        $self->{'_capture'}->{$var} = $self->{'_scoring'}->variable_transaction($var);
    }
    print "done\n";
    print "load: END\n";
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
    print "get_data:BEGIN\n";
    $self->SUPER::pre_process();
    # put this in $self instead
    # $o = {};
    # $o->{'items'} = []; # replace with $self->{'questions'}
    # $o->{'submissions'} = []; # replace with $self->{'submissions'}
    # $o->{'totals'} = $self->{'marks'}; # just use $self->{'marks'}
    $self->{'submissions'} = [];
    $exam_name = $self->{'out.nom'} ? $self->{'out.nom'} : "Untitled Exam" ;

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
        }
        push @{$self->{'submissions'}}, $submission;
    }

    # exam summary statistics and metadata
    $self->{'summary'} = {};
    $self->{'metadata'} = {};
    if ($max) { $self->{'summary'}->{'ceiling'} = $max; }
    if ($exam_name) { $self->{'metadata'}->{'title'} = $exam_name; }
    return;

}

# Do the analysis.  These keys/values should be set:
# For each question in @{$self->{'questions'}},
# - mean: average
# - max: maximum score achieved
# - ceiling: maximum score possible
# - discrimintation: correlation of item with total
# - difficulty: mean/ceiling
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
    $scoring = $self->{'_scoring'};

    # analyze the total     
    $marks = $self->{'marks'};
    @totals = map {$_->{'mark'}} @$marks;
    $total_stats = Statistics::Descriptive::Full->new();
    $total_stats->add_data(@totals);
    $summary = $self->{'summary'};
    #TODO: Rub the next five lines DRY.
    $summary->{'mean'} = $total_stats->mean();
    $summary->{'median'} = $total_stats->median();
    $summary->{'standard_deviation'} = $total_stats->standard_deviation();
    $summary->{'min'} = $total_stats->min();
    $summary->{'max'} = $total_stats->max();
    $summary->{'count'} = $total_stats->count();

    # analyze each question
    for my $question (@{$self->{'questions'}}) {
        $title = $question->{'title'};
        $number = $question->{'question'};
        @question_scores = map {$_->{$title}->{'score'}} @{$self->{'submissions'}};
        $question_stats = Statistics::Descriptive::Full->new();
        $question_stats->add_data(@question_scores);
        # TODO: Rub the next six lines DRY.
        $question->{'mean'} = $question_stats->mean();
        $question->{'median'} = $question_stats->median();
        $question->{'standard_deviation'} = $question_stats->standard_deviation();
        $question->{'min'} = $question_stats->min();
        $question->{'max'} = $question_stats->max();
        $question->{'count'} = $question_stats->count();
        $question->{'ceiling'} = $scoring->question_maxmax($number);
        $question->{'difficulty'} = $question->{'mean'} / $question->{'ceiling'};
        # Compute correlation of this item with the total.
        my ($b, $a, $r, $rms) = $total_stats->least_squares_fit(@question_scores);
        $question->{'discrimination'} = $r;

        # create the histogram
        # We do this by sorting the reponses by the answers and collecting the total scores.
        # there might be a map / filter / accumulate way to do this,
        # but remember that the scoring_base may depend on the question *and* the student.
        $histogram = $question->{'histogram'} = {};
        # the next two lines iterate $response over @{$self->{'submissions'}} but with an index $i.
        # Maybe there's a better way. See https://stackoverflow.com/a/974819/297797
        $total_by_response = {};    
        for my $i (0 .. $#{$self->{'submissions'}}) {
            $submission = $self->{'submissions'}->[$i];    
            $response = $submission->{$title};
            $sb = $response->{'scoring_base'};
            for my $answer (@{$sb->{'answers'}}) {
                $an = $answer->{'answer'}; # answer number
                unless (defined $histogram->{$an}) {
                    $histogram->{$an} = {};
                    $total_by_response->{$an} = [];
                }
                if ($answer->{'ticked'}) {
                    push @{$total_by_response->{$an}}, $marks->[$i]->{'mark'};
                }
                # TODO: Figure out the answer's *weight*
                # This comes from the strategy, but it's coded.
                # perhaps some code in AMC::DataModule::scoring takes care of that?
            }
        }
        $total_by_response_stats = Statistics::Descriptive::Sparse->new;
        for my $an (keys %{$histogram}) {
            $total_by_response_stats->clear;
            $total_by_response_stats->add_data(@{$total_by_response->{$an}});
            $histogram->{$an}->{'mean'} = $total_by_response_stats->mean;
            $histogram->{$an}->{'count'} = $total_by_response_stats->count;
            $histogram->{$an}->{'frequency'} =
                $total_by_response_stats->count / $self->{'summary'}->{'count'};
        }        
    }
}


sub export {    
    my ($self,$fichier)=@_;
    my $sep=$self->{'out.separateur'};
    # this setting comes from the GUI.  We may want to report the number of
    # absentees somewhere, but there's no need to add them to the analysis.
    # So we'll just reset it to zero.
    $self->{'noms.useall'} = 0;
    print "export: BEGIN\n";

    # open(OUT,">:encoding(".$self->{'out.encodage'}.")",$fichier);

    $self->pre_process();
    $self->analyze();

    $data = {
        'metadata' => $self->{'metadata'},
        'summary' => $self->{'summary'},
        'items' => $self->{'questions'},
        'submissions' => $self->{'submissions'},
        'totals' => $self->{'marks'}
    };

    # We're just going to dump it to the output file    
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($fichier);
    # print OUT Dumper($data);
    
    #close(OUT);
}

1;
