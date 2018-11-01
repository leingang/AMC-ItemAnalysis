
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
# $out->{'responses'}->[$i]->{$t}->{'index'}: question number (an id for the question? or on the exam?)
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
    print "get_data:BEGIN\n";
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
    # - last argument is "plain" or not.  
    $self->codes_questions(\@codes,\@questions,1);

    # begin loop on each student record
    for my $m (@$marks) {
        push @{$o->{'totals'}}, $m->{'mark'};
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
        push @{$o->{'responses'}}, $score_rec;
    }

    if ($max) { $o->{'max'} = $max; }
    if ($exam_name) { $o->{'title'} = $exam_name; }
    return $o;

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

    $data = $self->get_data;

    # We're just going to dump it to the output file    
    my $yaml = YAML::Tiny->new($data);
    $yaml->write($fichier);
    # print OUT Dumper($data);
    
    #close(OUT);
}

# overloading just to track a transaction error
sub pre_process {
    print "pre_process: BEGIN\n";
    my ($self)=@_;

    $self->{'sort.keys'}=$sorting{lc($1)}
      if($self->{'sort.keys'} =~ /^\s*([lmin])/i);
    $self->{'sort.keys'}=[] if(!$self->{'sort.keys'});

    $self->load();

    print "pre_process: EXPP\n";
    $self->{'_scoring'}->begin_read_transaction('EXPP');

    my $lk=$self->{'_assoc'}->variable('key_in_list');
    my %keys=();
    my @marks=();
    my @post_correct=$self->{'_scoring'}->postcorrect_sc;

    # Get all students from the marks table

    my $sth=$self->{'_scoring'}->statement('marks');
    $sth->execute;
  STUDENT: while(my $m=$sth->fetchrow_hashref) {
      next STUDENT if((!$self->{'noms.postcorrect'}) &&
		      $m->{student}==$post_correct[0] &&
		      $m->{'copy'}==$post_correct[1]);

      $m->{'abs'}=0;
      $m->{'student.copy'}=studentids_string($m->{'student'},$m->{'copy'});

      # Association key for this sheet
      $m->{'student.key'}=$self->{'_assoc'}->get_real($m->{'student'},$m->{'copy'});
      $keys{$m->{'student.key'}}=1;

      # find the corresponding name
      my ($n)=$self->{'noms'}->data($lk,$m->{'student.key'},test_numeric=>1);
      if($n) {
	$m->{'student.name'}=$n->{'_ID_'};
	$m->{'student.line'}=$n->{'_LINE_'};
	$m->{'student.all'}={%$n};
        # $n->{$lk} should be equal to $m->{'student.key'}, but in
        # some cases (older versions), the code stored in the database
        # has leading zeroes removed...
        $keys{$n->{$lk}}=1;
      } else {
	for(qw/name line/) {
	  $m->{"student.$_"}='?';
	}
      }
      push @marks,$m;
    }

    # Now, add students with no mark (if requested)

    if($self->{'noms.useall'}) {
      for my $i ($self->{'noms'}->liste($lk)) {
	if(!$keys{$i}) {
	  my ($name)=$self->{'noms'}->data($lk,$i,test_numeric=>1);
	  push @marks,
	    {'student'=>'',
	     'copy'=>'',
	     'student.copy'=>'',
	     'abs'=>1,
	     'student.key'=>$name->{$lk},
	     'mark'=>$self->{'noms.abs'},
	     'student.name'=>$name->{'_ID_'},
	     'student.line'=>$name->{'_LINE_'},
	     'student.all'=>{%$name},
	    };
	}
      }
    }

    # sorting as requested

    debug "Sorting with keys ".join(", ",@{$self->{'sort.keys'}});
    $self->{'marks'}=[sort { $self->compare($a,$b); } @marks];

    $self->{'_scoring'}->end_transaction('EXPP');
    print "pre_process: END\n";
}

1;
