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

package AMC::Export::ItemAnalysis_LaTeX;

# use AMC::Basic;
# use AMC::Export;
# use Encode;

use parent q(AMC::Export::ItemAnalysis);

# export latex file
# 
# Decided against using a templating engine since we are only writing a single file.
# I may regret that later.
sub export {    
    my ($self,$fichier)=@_;
    $self->analyze();
    open(my $fh, '>', $fichier) or die "Could not open file '$fichier' $!";
    # Sort by question ID number.  I guess this is pretty close to the
    # order they appear in the source file.
    @questions_sorted = sort { $a->{'question'} <=> $b->{'question'} } @{$self->{'questions'}};
    $self->{'questions'} = \@questions_sorted;
    # preamble to table first row
    # We use single quote here so we don't have to escape all the backslashes.
    $exam_name = $self->{'metadata'}->{'title'};
    $doc_title = ($exam_name ? $exam_name . ' ' : '' ) . 'Item Analysis';
    print $fh  sprintf q(
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
\tikzset{
    bar/.style={xscale=2,yscale=0.25,draw=black,fill=gray},
    correct/.style={fill=green!50!black},
    incorrect/.style={fill=red!50!white},
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
    }
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
    
    # print the main table
    print $fh q(

\section{Item statistics}

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
            $label = (defined($a->{'label'}) ? $a->{'label'} : $k);
            print $fh $label, " & ";
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

    # print the scatterplot
    print $fh q(
\section{Scatterplot}

\begin{center}
\begin{tikzpicture}
    \begin{semilogxaxis}[main scatterplot]
        \addplot table [x=diff,y=disc] {  
);
    print $fh "item mean sd diff diffc disc discc\n";
    for my $i (0 .. $#{$self->{'questions'}}) {
        $q = $self->{'questions'}->[$i];
        print $fh  $i+1, " "; # was $q->{'title'} but that's too long
        print $fh  sprintf ("%.2f", $q->{'mean'}), " ";
        print $fh  sprintf ("%.2f", $q->{'standard_deviation'}), " ";
        print $fh  sprintf ("%3d", $q->{'difficulty'} * 100), " ";
        print $fh  $q->{'difficulty_class'} , " "; 
        print $fh  sprintf ("%.2f", $q->{'discrimination'}), " ";
        print $fh  $q->{'discrimination_class'} , "\n";
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
    print $fh "Cronbach's \$\\alpha\$: ", sprintf("%.2f",$self->{'summary'}->{'alpha'}), "\n";
    print $fh q(\end{document}), "\n";
    close $fh;       
}

1;