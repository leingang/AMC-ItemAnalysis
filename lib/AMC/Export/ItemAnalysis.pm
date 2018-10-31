# additional methods to this package
package AMC::DataModule::capture::ItemAnalysis;

use parent "AMC::DataModule::capture";

# convert number to letter
# stolen from AMC::Export::CSV
sub i_to_a {
  my ($self,$i)=@_;
  if($i==0) {
    return('0');
  } else {
    my $s='';
    while($i>0) {
      $s = chr(ord('a')+(($i-1) % 26)) . $s;
      $i = int(($i-1)/26);
    }
    $s =~ s/^([a-z])/uc($1)/e;
    return($s);
  }
}


# The response from a student on a question
#
# $student : student number
# $copy : copy number
# $question : question hashref
# 
# returns: string of concatenated responses by letter
# or maybe string of 0/1 separated by ;?  
# might depend on FR/MC 
sub question_response {
    my ($self,$student,$copy,$question)=@_;
    my $dt = $self->{'darkness_threshold'};
    my $dtu = $self->{'darkness_threshold_up'};
    my $t='';
    my @tl=$self->ticked_list($student,$copy,$question->{'question'},$dt,$dtu);
    if($self->has_answer_zero(@$student,$copy,$question->{'question'})) {
        if(shift @tl) {
            $t.='0';
        }
    }
    for my $i (0..$#tl) {
        $t.=$self->i_to_a($i+1) if($tl[$i]);
    }
    return $t;
}

# main package
package AMC::Export::ItemAnalysis;

use AMC::Basic;
use AMC::Export;

use Encode;

@ISA=("AMC::Export");

use Data::Dumper;# for debugging

sub new {
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
    $self->SUPER::load();
    $self->{'_capture'}=$self->{'_data'}->module('capture');
    bless $self->{'_capture'}, 'AMC::DataModule::capture::ItemAnalysis';
    for my $var ('darkness_threshold','darkness_threshold_up') {
        $self->{'_capture'}->{$var} = $self->{'_scoring'}->variable($var);
    }
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



# Export data structure
# =====================
# $self->get_data() produces a large hashref $out
#
# $out->{'title'}: title of the exam
# $out->{'mean'}: mean total score
# $out->{'max'}: max total score
# $out->{'responses'}: arrayref, indexed by (student number?) $i
# OR: hashref keyed by _ID_?  
# $out->{'responses'}->[$i]: hashref, keyed by question title $t
# $out->{'responses'}->[$i]->{$t}: hashref
# $out->{'responses'}->[$i]->{$t}->{'score'}: score by person $i on item $t
# $out->{'responses'}->[$i]->{$t}->{'response'}: response by person $i on item $t
# $out->{'totals'}: arrayref, indexed exactly as $out->{'responses'}
# $out->{'totals'}->[$i]: mark
# $out->{'items'}: arrayref, indexed by $i
# OR: hashref, keyed by title $t
# wondering: how to preserve item order?  
# $out->{'items'}->[$i]->{'title'}: title
# $out->{'items'}->[$i]->{'mean'}: mean
# $out->{'items'}->[$i]->{'max'}: max
# $out->{'items'}->[$i]->{'discrimination'}: correlation of item with total
# $out->{'items'}->[$i]->{'difficulty'}: mean/max
# $out->{'items'}->[$i]->{'histogram'}: hashref with key $k$
# (either A, B, C or '1', '2', '3', I think)
# $out->{'items'}->[$i]->{'histogram'}->{$k}->{'count'}
# $out->{'items'}->[$i]->{'histogram'}->{$k}->{'mean'}
# $out->{'items'}->[$i]->{'histogram'}->{$k}->{'weight'}
sub get_data {
    my ($self) = @_;
    $o = {};
    $o->{'items'} = [];
    $o->{'responses'} = [];
    $o->{'totals'} = [];
    
    # $self->{'_scoring'}->begin_read_transaction('XIA'); # do I need this?
    # BREADCRUMB: getting sql transaction errors right around here
    my $dt=$self->{'_scoring'}->variable('darkness_threshold');
    my $lk=$self->{'_assoc'}->variable('key_in_list');


    $exam_name = $self->{'out.nom'} ? $self->{'out.nom'} : "Untitled Exam" ;
    $marks = $self->{'marks'};
    # look for the first mark that has a max
    for my $m (@$marks) {
        last if ($max = $m->{'max'});
    }

    my @codes;
    my @questions;
    # populate @codes and @questions lists.
    # I think:
    # - @codes is student identifying codes,
    # - @questions is exam questions.
    # - last argument is "plain" (no ticks) or not (yes ticks).
    $self->codes_questions(\@codes,\@questions,0);

    # begin loop on each student record
    for my $m (@$marks) {
        push @{$o->{'totals'}}, $m->{'mark'};
        # @sc is a list of the student number and copy number
        # It can't be a hash key but we could stringify it.
        my @sc=($m->{'student'},$m->{'copy'});
        $score_rec = {};
        for my $q (@questions) {
            $score_rec->{$q->{'title'}} = {
                'score' => $self->{'_scoring'}->question_score(@sc,$q->{'question'}),
                'response' =>$self->{'_capture'}->question_response(@sc,$q->{'question'})
            };
        }
        push @{$o->{'responses'}}, $score_rec;
    }

    if ($max) { $o->{'max'} = $max; }
    if ($exam_name) { $o->{'title'} = $exam_name; }
    return $o;

}

sub export {
    my ($self,$fichier)=@_;
    my $sep=$self->{'out.separateur'};

    open(OUT,">:encoding(".$self->{'out.encodage'}.")",$fichier);

    $self->pre_process();

    $data = $self->get_data;

    # We're just going to dump it to the output file    
    print OUT Dumper($data);
    
    close(OUT);
}

1;
