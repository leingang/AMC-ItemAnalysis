# additional methods to this package
package AMC::ItemAnalysis::capture;

use parent q(AMC::DataModule::capture);
use Data::Dumper;# for debugging

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
    # print "question_response: BEGIN\n";
    my ($self,$student,$copy,$question)=@_;
    # print "question_response: \$student:", $student, "\n";
    # print "question_response: \$copy:", $copy, "\n";
    # print "question_response: \$question:", Dumper($question), "\n";
    my $dt = $self->{'darkness_threshold'};
    my $dtu = $self->{'darkness_threshold_up'};
    # print "question_response: \$dt:", $dt, "\n";
    # print "question_response: \$dtu:", $dtu, "\n";
    my $t='';
    my @tl=$self->ticked_list($student,$copy,$question,$dt,$dtu);
    # print "question_response: \@tl:", Dumper(\@tl), "\n";
    if($self->has_answer_zero(@$student,$copy,$question)) {
        if(shift @tl) {
            $t.='0';
        }
    }
    for my $i (0..$#tl) {
        $t.=$self->i_to_a($i+1) if($tl[$i]);
    }
    # print "question_response: END. \$t=", $t, "\n";
    return $t;
}

1;