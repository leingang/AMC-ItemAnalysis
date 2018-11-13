
package AMC::Export::ItemAnalysis;

use AMC::Basic;
use AMC::Export;
use AMC::Scoring;
use AMC::ItemAnalysis::capture;
use File::Basename;
use YAML::Tiny;
use Statistics::Descriptive;

use Encode;
use Storable 'dclone';

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
    $self->{'_score'} = AMC::Scoring::new(
        'seuil'    => $self->{'_capture'}->{'darkness_threshold'},
        'seuil_up' => $self->{'_capture'}->{'darkness_threshold_up'},
        '_scoring' => $self->{'_scoring'},
        '_capture' => $self->{'capture'}
    );
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
# grouping questions and answers. For exemple :
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
            # NOTE: This may not work in NOTA answers. 
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

    # analyze the total     
    $marks = $self->{'marks'};
    @totals = map {$_->{'mark'}} @$marks;
    $total_stats = Statistics::Descriptive::Full->new();
    $total_stats->add_data(@totals);
    $summary = $self->{'summary'};
    $self->compute_summary_statistics($total_stats,$summary);

    # analyze each question
    for my $question (@{$self->{'questions'}}) {
        $title = $question->{'title'};
        @question_scores = map {$_->{$title}->{'score'}} @{$self->{'submissions'}};
        $question_stats = Statistics::Descriptive::Full->new();
        $question_stats->add_data(@question_scores);
        $self->compute_summary_statistics($question_stats,$question);        
       	if ($question->{'ceiling'} != 0) {
            $question->{'difficulty'} = $question->{'mean'} / $question->{'ceiling'};
            $question->{'difficulty_class'} = $self->classify_difficulty($question);
	      }
        $question->{'type_class'} = $self->classify_type($question);
        # Compute correlation of this item with the total.
        my ($b, $a, $r, $rms) = $total_stats->least_squares_fit(@question_scores);
        $question->{'discrimination'} = $r;
        $question->{'discrimination_class'} = $self->classify_discrimination($question);

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
                # TODO: Figure out the answer's *weight*
                # This comes from the strategy, but it's coded.
                # perhaps some code in AMC::DataModule::scoring takes care of that?
            }
        }
        $total_by_response_stats = Statistics::Descriptive::Sparse->new;
        $weight_by_response_stats = Statistics::Descriptive::Sparse->new;
        for my $an (keys %{$histogram}) {
            $total_by_response_stats->clear;
            $total_by_response_stats->add_data(@{$total_by_response->{$an}});
            $histogram->{$an}->{'mean'} = $total_by_response_stats->mean;
            $histogram->{$an}->{'count'} = $total_by_response_stats->count;
            $histogram->{$an}->{'frequency'} =
                $total_by_response_stats->count / $self->{'summary'}->{'count'};
            $weight_by_response_stats->clear;
            $weight_by_response_stats->add_data(@{$weight_by_response->{$an}});
            $histogram->{$an}->{'weight'} = $weight_by_response_stats->mean;
        }        
    }
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
# Possible improvements: return value, select stats...
sub compute_summary_statistics {
    my ($self,$analyzer,$dest) = @_;
    for (qw(mean median standard_deviation min max count)) {
        $dest->{$_} = $analyzer->$_();
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
    
    my %suffix_to_function = ('.yaml' => 'yaml', '.tex' => 'latex', '.pdf' => 'pdf');
    my @suffixes = keys %suffix_to_function;
    my ($filename, $dirs, $suffix) = fileparse($fichier,@suffixes);
    my $export_function = 'export_' . $suffix_to_function{$suffix};
    $self->$export_function($fichier);
}

sub export_yaml {
    my ($self,$fichier)=@_;
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

# export latex file
# 
# Decided against using a templating engine since we are only writing a single file.
# I may regret that later.
sub export_latex {
    my ($self,$fichier) = @_;
    # preamble to table first row
    open(my $fh, '>', $fichier) or die "Could not open file '$fichier' $!";
    # We use single quote here so we don't have to escape all the backslashes.
    print $fh  q(
\documentclass{article}
\usepackage{helvet}
\renewcommand{\familydefault}{\sfdefault}
\usepackage[letterpaper,margin=0.5in]{geometry}
\usepackage{tikz}
\tikzset{
    bar/.style={xscale=2,yscale=0.25,draw=black,fill=gray},
    correct/.style={fill=green!50!black},
    incorrect/.style={fill=red!50!white}
}
\usepackage{pgfplots}
\usepackage{longtable}
\usepackage{siunitx}
\newlength{\itemrowsep}
\setlength{\itemrowsep}{2ex}

\begin{document}
\begin{longtable}{rSSrlSlSSSrSl}
\hline
\bfseries Item 
& \bfseries Mean 
& \bfseries StDev 
& \multicolumn{2}{c}{\bfseries Difficulty}
& \multicolumn{2}{c}{\bfseries Discrimination}
& \bfseries ans 
& \bfseries Weight 
& \bfseries Means 
& \multicolumn{2}{c}{\bfseries Frequencies}
& \bfseries Distribution \\\\
\hline
);
    # print stats for each item:

    for my $i (0 .. $#{$self->{'questions'}}) {
        $q = $self->{'questions'}->[$i];
        print $fh  $i+1, " & "; # was $q->{'title'} but that's too long
        print $fh  sprintf ("%.2f", $q->{'mean'}), " & ";
        print $fh  sprintf ("%.2f", $q->{'standard_deviation'}), " & ";
        print $fh  sprintf ("%3d", $q->{'difficulty'} * 100), " & ";
        print $fh  $q->{'difficulty_class'} , " & "; 
        print $fh  sprintf ("%.2f", $q->{'discrimination'}), " & ";
        print $fh  $q->{'discrimination_class'} , " & "; 
        my $row = 0;
        @answers = sort keys (%{$q->{'histogram'}});
        for my $k (@answers) {
            $a = $q->{'histogram'}->{$k};
            if ($row++) {
                print $fh '\\\\', "\n", q(\\multicolumn{7}{c}{} & );
            }
            print $fh $k, " & ";
            print $fh sprintf("%.2f", $a->{'weight'}), " & ";
            print $fh sprintf("%.2f", $a->{'mean'}), " & ";
            print $fh $a->{'count'}, " & ";
            print $fh sprintf("\\SI{%.2f}{\\percent}", $a->{'frequency'} * 100), " & ";
            $bar_key = $a->{'correct'} ? "correct" : "incorrect";
            print $fh sprintf("\\tikz{\\draw[bar,$bar_key] (0,0) rectangle (%.2f,1);}", $a->{'frequency'});
        }
        print $fh '\\\\[\itemsep]', "\n";
    }
    # end of item table
    print $fh q(\end{longtable}), "\n\n";
    # print a problem metadata table
    print $fh q(\begin{tabular}{rrc}), "\n";
    print $fh q(\hline), "\n";
    print $fh q(\bfseries Item number & \bfseries Item name & \bfseries Item type), '\\\\', "\n";
    print $fh q(\hline), "\n";
    for my $i (0 .. $#{$self->{'questions'}}) {
        $q = $self->{'questions'}->[$i];
        print $fh $i+1, " & ";
        print $fh $q->{'title'}, " & ";
        print $fh $q->{'type_class'};
        print $fh '\\\\', "\n"; 
    }
    print $fh q(\end{tabular}), "\n";
    print $fh q(\end{document}), "\n";
    close $fh;
}

1;
