
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


# Import exam, question, and response data into $self.
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
# $self->{'responses'} is populated by looking up each student's responses and results.
# These come from AMC::DataModule::scoring::question_result and 
# AMC::ItemAnalysis::capture::question_response.  The $ith element of $self->{'responses'}.
# is the complete list of responses for the student in the $ith element of $self->{'marks'}. 
# For each $i, $self->{'responses'}->[$i] is a hashref, keyed on question titles.
# For each question title $k, $self->{'responses'}->[$i]->{$k} has keys/values
# - score: score by student $i on question $k
# - response: response by student $i on question $k
# - index: question number (not sure if this is in the DB or on the student's paper).
#
# $self->{'metadata'} will contain any metadata we can discover about the exam.
# - title: title of the exam
# TODO: get additional metadata from the TeX file, if possible.
#
# $self->{'summary'} will contain any summary statistics about the exam total score.
# This method only sets a 'max' key/value.
# Later methods will add to it.

sub pre_process {
    my ($self) = @_;
    print "get_data:BEGIN\n";
    $self->SUPER::pre_process();
    # put this in $self instead
    # $o = {};
    # $o->{'items'} = []; # replace with $self->{'questions'}
    # $o->{'responses'} = []; # replace with $self->{'responses'}
    # $o->{'totals'} = $self->{'marks'}; # just use $self->{'marks'}
    $self->{'responses'} = [];
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
    # and @{$o->{'responses'}}, those arrays will be lined up by student.
    # For now, there's no need to record the student number, copy number,
    # or any personally identifying information about the student as a key.
    for my $m (@$marks) {
        # push @{$o->{'totals'}}, $m->{'mark'};
        # @sc is a list of the student number and copy number
        # It can't be a hash key but we could stringify it.
        my @sc=($m->{'student'},$m->{'copy'});
        $score_rec = {};
        for my $q (@questions) {
            $response = $self->{'_capture'}->question_response(@sc,$q->{'question'});
            $result = $self->{'_scoring'}->question_result(@sc,$q->{'question'});
            $score_rec->{$q->{'title'}} = {
                'index' => $q->{'question'},
                'score' => $result->{'score'},
                'max' => $result->{'max'},
                'response' => $response
            };
        }
        push @{$self->{'responses'}}, $score_rec;
    }

    # exam summary statistics and metadata
    $self->{'summary'} = {};
    $self->{'metadata'} = {};
    if ($max) { $self->{'summary'}->{'max'} = $max; }
    if ($exam_name) { $self->{'metadata'}->{'title'} = $exam_name; }
    return;

}

# Do the analysis.  These keys/values should be set:
# For each question in @{$self->{'questions'}},
# - mean: average
# - max: maximum score
# - discrimintation: correlation of item with total
# - difficulty: mean/max
# - histogram: a hashref keyed by the answer type
# 
# For each answer $a to question $i,
# $self->{'question'}->[$i]->{'histogram'}->{$a} has keys/values:
# - count: number of students selecting this response
# - mean: mean of total for those students who selected this response
# - weight: score for students who selected this response
#           (I think this can be found in student_scoring_base)
sub analyze {
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

    $data = {
        'metadata' => $self->{'metadata'},
        'summary' => $self->{'summary'},
        'items' => $self->{'questions'},
        'responses' => $self->{'responses'},
        'totals' => $self->{'marks'}
    };

    # We're just going to dump it to the output file    
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($fichier);
    # print OUT Dumper($data);
    
    #close(OUT);
}

1;
