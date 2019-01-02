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

AMC::Export::ItemAnalysis_LaTeX - Export item analysis to a LaTeX file.

=head1 SYNOPSIS

From a script:

    use AMC::Export::ItemAnalysis_LaTeX;

    my $project_dir = "/path/to/MC-Projects/exam";
    my $data_dir = $project_dir . "/data";
    my $fich_noms = $project_dir . "/students-list.csv";
    my $output_file = $project_dir . "/exports/exam-item-analysis.tex";
    my $ex = AMC::Export::ItemAnalysis_LaTeX->new();
    $ex->set_options("fich","datadir"=>$data_dir,"noms"=>$fich_noms);
    $ex->export($output_file);

From the command line:

    cd /path/to/MC-Projects/exam
    auto-multiple-choice export --module ItemAnalysis_LaTeX \
        --data data \
        --fich-noms students-list.csv \
        --o exports/exam-item-analysis.tex

=cut 

package AMC::Export::ItemAnalysis_LaTeX;

use parent q(AMC::Export::ItemAnalysis);

=head1 METHOD

=head2 export

Exports the analysis to a LaTeX file.  The sole argument
is the name of the output file to write to.

=cut

sub export {
    my ( $self, $fichier ) = @_;
    $self->analyze();
    open( my $fh, '>', $fichier ) or die "Could not open file '$fichier' $!";

    # Sort by question ID number.  I guess this is pretty close to the
    # order they appear in the source file.
    @questions_sorted =
      sort { $a->{'question'} <=> $b->{'question'} } @{ $self->{'questions'} };
    $self->{'questions'} = \@questions_sorted;

    # preamble to table first row
    # We use single quote here so we don't have to escape all the backslashes.
    $exam_name = $self->{'metadata'}->{'title'};
    $doc_title = ( $exam_name ? $exam_name . ' ' : '' ) . 'Item Analysis';
    print $fh sprintf q(
\documentclass{article}
);
    print $fh "\\title{${doc_title}}\n";
    print $fh q(
\author{Prepared by auto-multiple-choice}
\usepackage{helvet}
\renewcommand{\familydefault}{\sfdefault}
\usepackage[letterpaper,margin=0.5in]{geometry}
\usepackage{tikz}
\usepackage{pgfplots}
\pgfplotsset{compat=1.16}
\usetikzlibrary{pgfplots.statistics}
% colors
\colorlet{correct}{green!50!black}
\colorlet{incorrect}{red!50!white}
\colorlet{submedian}{incorrect}
\colorlet{supermedian}{blue!50!white}
\tikzset{
    bar/.style={xscale=2,yscale=0.25,draw=black,fill=gray},
    correct/.style={draw=black,fill=correct},
    incorrect/.style={draw=black,fill=incorrect},
}
\pgfplotsset{
    boxplot/.cd,
        every lower box/.style={draw=submedian,fill=submedian},
        every upper box/.style={draw=supermedian,fill=supermedian},
        every lower whisker/.style={ultra thick,draw=submedian},
        every upper whisker/.style={ultra thick,draw=supermedian},
        every median/.style={black},
}
\pgfplotsset{
    main scatterplot/.style={
        width=0.8\textwidth,
        xlabel=Difficulty,
        ylabel=Discrimination,
        xmin=0,xmax=100,
        ymin=0,ymax=1,
        xtick={50,85},
        ytick={0.1,0.3},
        xticklabel=\empty,
        yticklabel=\empty,
        tick style={grid=major},
        clip=false,
        every axis plot/.append style={only marks,nodes near coords,point meta=\thisrow{item}},
        /tikz/x interval/.style={font=\small},
        /tikz/y interval/.style={font=\small,rotate=90,anchor=south},
        after end axis/.code={
            \node[x interval] at (xticklabel cs:0.5) {Moderate};
            \node[x interval] at (xticklabel cs:0.9225) {Easy};
            \node[x interval] at (xticklabel cs:0.07079) {Hard};
            \node[y interval] at (yticklabel* cs:0.05) {Poor};
            \node[y interval] at (yticklabel* cs:0.2) {Fair};
            \node[y interval] at (yticklabel* cs:0.65) {Good};
        }        
    },
    question boxplot/.style={
        y=0.33cm,
        enlarge x limits,
        xtick=\empty,ytick=\empty,
        % draw the full axis but hide it
        axis x line=bottom,x axis line style={draw=white},
        axis y line=none,
        anchor={xticklabel* cs:0},
        scatter,
        visualization depends on={sqrt(\thisrow{freq}) \as \perpointmarksize},
        point meta={x > \boxplotvalue{median}},
        colormap={relativetomedian}{color=(submedian) color=(supermedian)},
        scatter/use mapped color={draw=mapped color,fill=mapped color},        
        scatter/@pre marker code/.append style={/tikz/mark size=\perpointmarksize},
        boxplot/draw/box/.code={
            \draw [/pgfplots/boxplot/every box/.try,
                   /pgfplots/boxplot/every lower box/.try]
                (boxplot box cs:\pgfplotsboxplotvalue{lower quartile},0)
                rectangle
                (boxplot box cs:\pgfplotsboxplotvalue{median},1); 
            \draw [/pgfplots/boxplot/every box/.try,
                   /pgfplots/boxplot/every upper box/.try]
                (boxplot box cs:\pgfplotsboxplotvalue{median},0)
                rectangle
                (boxplot box cs:\pgfplotsboxplotvalue{upper quartile},1); 
        },
        boxplot/draw/lower whisker/.code={
            \draw[/pgfplots/boxplot/every lower whisker/.try] (boxplot cs:\pgfplotsboxplotvalue{lower whisker})
              -- (boxplot cs:\pgfplotsboxplotvalue{lower quartile});
        },
        boxplot/draw/upper whisker/.code={
            \draw[/pgfplots/boxplot/every upper whisker/.try] (boxplot cs:\pgfplotsboxplotvalue{upper quartile})
              -- (boxplot cs:\pgfplotsboxplotvalue{upper whisker});
        }
    },
}
\usepackage{longtable}
\usepackage{siunitx}
\newlength{\itemrowsep}
\setlength{\itemrowsep}{2ex}

\begin{document}
\maketitle

\section{Item metadata}
);

    # print a problem metadata table
    print $fh q(\begin{tabular}{rrc}), "\n";
    print $fh q(\hline),               "\n";
    print $fh
      q(\bfseries Item number & \bfseries Item name & \bfseries Item type),
      '\\\\', "\n";
    print $fh q(\hline), "\n";
    for my $i ( 0 .. $#{ $self->{'questions'} } ) {
        $q = $self->{'questions'}->[$i];
        print $fh $i + 1, " & ";
        print $fh $q->{'title'}, " & ";
        print $fh $q->{'type_class'};
        print $fh '\\\\', "\n";
    }
    print $fh q(\end{tabular}), "\n";

    # print the main table
    print $fh q(

\section{Item statistics}

\subsection{Fixed response questions}

\begin{longtable}{rSSrlSlcSSrSl}
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
\hline\endhead
);

    # print stats for each multiple choice item:
    for my $i ( 0 .. $#{ $self->{'questions'} } ) {
        $q = $self->{'questions'}->[$i];
        next if ( $q->{'type_class'} eq 'FR' );
        print $fh $i + 1, " & ";    # was $q->{'title'} but that's too long
        print $fh sprintf( "%.2f", $q->{'mean'} ), " & ";
        print $fh sprintf( "%.2f", $q->{'standard_deviation'} ), " & ";
        print $fh sprintf( "%3d", $q->{'difficulty'} * 100 ), " & ";
        print $fh $q->{'difficulty_class'}, " & ";
        print $fh sprintf( "%.2f", $q->{'discrimination'} ), " & ";
        print $fh $q->{'discrimination_class'}, " & ";
        my $row = 0;
        @answers = sort keys( %{ $q->{'responses'} } );

        for my $k (@answers) {
            $a = $q->{'responses'}->{$k};
            if ( $row++ ) {
                print $fh '\\\\', "\n", q(\\multicolumn{7}{c}{} & );
            }
            $label = ( defined( $a->{'label'} ) ? $a->{'label'} : $k );
            print $fh $label, " & ";
            print $fh sprintf( "%.2f", $a->{'weight'} ), " & ";
            print $fh sprintf( "%.2f", $a->{'mean'} ),   " & ";
            print $fh $a->{'count'}, " & ";
            print $fh
              sprintf( "\\SI{%.2f}{\\percent}", $a->{'frequency'} * 100 ),
              " & ";
            $bar_key = $a->{'correct'} ? "correct" : "incorrect";
            print $fh
              sprintf( "\\tikz{\\draw[bar,$bar_key] (0,0) rectangle (%.2f,1);}",
                $a->{'frequency'} );
        }
        print $fh '\\\\[\itemsep]', "\n";
    }

    # end of item table
    print $fh q(\end{longtable}), "\n\n";

    # print stats for each free response item:
    print $fh q(
\subsection{Free response questions}

\begin{longtable}{rSSrlSlc}
\hline
\bfseries Item 
& \bfseries Mean 
& \bfseries StDev 
& \multicolumn{2}{c}{\bfseries Difficulty}
& \multicolumn{2}{c}{\bfseries Discrimination}
& \bfseries Distribution
\\\\\hline\endhead
    );
    for my $i ( 0 .. $#{ $self->{'questions'} } ) {
        $q = $self->{'questions'}->[$i];
        next unless ( $q->{'type_class'} eq 'FR' );
        print $fh $i + 1, " & ";    # was $q->{'title'} but that's too long
        print $fh sprintf( "%.2f", $q->{'mean'} ), " & ";
        print $fh sprintf( "%.2f", $q->{'standard_deviation'} ), " & ";
        print $fh sprintf( "%3d", $q->{'difficulty'} * 100 ), " & ";
        print $fh $q->{'difficulty_class'}, " & ";
        print $fh sprintf( "%.2f", $q->{'discrimination'} ), " & ";
        print $fh $q->{'discrimination_class'}, " & ";
        print $fh sprintf
          "\\tikz[baseline]{\\begin{axis}[question boxplot,xmin=0,xmax=%0.1f]",
          $q->{'ceiling'};
        print $fh q(\addplot+[boxplot prepared={);
        print $fh sprintf "lower whisker=%d, lower quartile=%0.1f, "
          . "median=%0.1f, upper quartile=%0.1f, upper whisker=%d",
          $q->{'lower_extreme'}, $q->{'Q1'}, $q->{'median'},
          $q->{'Q3'}, $q->{'upper_extreme'};
        print $fh q(}]);

        if ( scalar( @{ $q->{'outliers'} } == 0 ) ) {
            print $fh q(coordinates {};);
        }
        else {
            # build a frequency hash of the outliers
            my %count;
            foreach ( @{ $q->{'outliers'} } ) {
                $count{$_}++;
            }

  # serialize a table coordinate stream for pgfplots
  # looks like:
  #     table[y=y,row sep=\\,col sep=comma] {y,freq\\1,1\\2,3\\}; \end{axis}}}\\
            print $fh q(table[y=y,row sep=\\\\,col sep=comma] {y,freq\\\\);
            foreach ( sort keys %count ) {
                print $fh sprintf "%0.1f,%d\\\\", $_, $count{$_};
            }
            print $fh q(};);
        }
        print $fh q(\end{axis}}\\\\), "\n";
    }
    print $fh q(\end{longtable});

    # print the scatterplot
    print $fh q(
\section{Scatterplot}

\begin{center}
\begin{tikzpicture}
    \begin{semilogxaxis}[main scatterplot]
        \addplot table [x=diff,y=disc] {  
);
    print $fh "item mean sd diff diffc disc discc\n";
    for my $i ( 0 .. $#{ $self->{'questions'} } ) {
        $q = $self->{'questions'}->[$i];
        print $fh $i + 1, " ";    # was $q->{'title'} but that's too long
        print $fh sprintf( "%.2f", $q->{'mean'} ), " ";
        print $fh sprintf( "%.2f", $q->{'standard_deviation'} ), " ";
        print $fh sprintf( "%3d", $q->{'difficulty'} * 100 ), " ";
        print $fh $q->{'difficulty_class'}, " ";
        print $fh sprintf( "%.2f", $q->{'discrimination'} ), " ";
        print $fh $q->{'discrimination_class'}, "\n";
    }
    print $fh q(
        };
    \end{semilogxaxis}
\end{tikzpicture}
\end{center}        
    );

    # print summary statistics especially alpha
    print $fh q(
\section{Reliability}

);
    print $fh "Cronbach's \$\\alpha\$: ",
      sprintf( "%.2f", $self->{'summary'}->{'alpha'} ), "\n";
    print $fh q(\end{document}), "\n";
    close $fh;
}

1;
__END__

=pod

=head1 NOTES

At this time there is no templating of the LaTeX file, or hooks 
to include customization.  After creating the file, you can edit
it or compile it right away.  

If you edit the file and include other information, it's probably
best to save the file under a different name.  Otherwise future
exports will clobber your edits.

Note that the LaTeX file makes use of the C<longtable> package,
which multiple passes through the document to properly balance 
columns and pages.  Three runs seems to be the maximum needed.

The AMC GUI give an option to open the exported file immediately
after the export completes.  This is by selecting “open the file”
from the drop-down menu after “and then.”  Due to limitations in
AMC's configuration system, there is no way to specify which 
program should open the file.  So selecting “open the file” will
not have any effect.  Selecting “open the directory” will at
least do that, and then you can double-click on the file to 
open it in your favorite TeX editor.

=head1 SEE ALSO

L<AMC::ItemAnalysis>, L<AMC::Export::ItemAnalysis>, 
L<AMC::Export::ItemAnalysis_YAML>


=head1 AUTHOR

Matthew Leingang, C<< <leingang@nyu.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-19 Matthew Leingang

AMC-ItemAnalysis is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

AMC-ItemAnalysis is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
AMC-ItemAnalysis.  If not, see <https://www.gnu.org/licenses/>.

