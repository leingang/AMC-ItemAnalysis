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

AMC::Export::register::ItemAnalysis_LaTeX - Register an export plugin into 
the AMC interface that exports item analysis to a LaTeX file.

=head1 SYNOPSIS

This module code is loaded and executed by F<AMC-gui.pl>. 

=head1 SEE ALSO

L<AMC::Export::register>

=cut

package AMC::Export::register::ItemAnalysis_LaTeX;

use AMC::Export::register;
use AMC::Basic;

# AMC 1.3 uses GTK3; older version Gtk2
use Gtk3;

@ISA = ("AMC::Export::register");

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    bless( $self, $class );
    return $self;
}

sub name {
    return ('Item Analysis (LaTeX)');
}

sub extension {
    return ('-item-analysis.tex');
}

sub options_from_config {
    my ( $self, $config ) = @_;
    my $enc =
         $config->get("encodage_csv")
      || $config->get("defaut_encodage_csv")
      || "UTF-8";
    return (
        "encodage"   => $enc,
        "columns"    => $config->get('export_csv_columns'),
        "decimal"    => $config->get('delimiteur_decimal'),
        "separateur" => ',',
        "ticked"     => $config->get('export_csv_ticked'),
        "nom"        => $config->get('nom_examen'),
        "code"       => $config->get('code_examen')
    );
}

sub options_default {
    return (
        'export_csv_separateur' => ',',
        'export_csv_ticked'     => '',
        'export_csv_columns'    => 'student.copy,student.key,student.name',
    );
}

sub build_config_gui {
    my ( $self, $w, $cb ) = @_;

    # Gtk2 version
    # my $t=Gtk2::Table->new(3,2);
    # Gtk3 version: The $homogeneous argument used to default to FALSE.
    # I guess it needs to be set explicitly now.
    my $t = Gtk3::Table->new( 3, 2, 0 );
    my $widget;
    my $y = 0;
    my $renderer;

    ## Separator is hard wired to be ','
    # $t->attach(Gtk2::Label->new(__"Separator"),
    #      0,1,$y,$y+1,["expand","fill"],[],0,0);
    # $widget=Gtk2::ComboBox->new_with_model();
    # $renderer = Gtk2::CellRendererText->new();
    # $widget->pack_start($renderer, TRUE);
    # $widget->add_attribute($renderer,'text',COMBO_TEXT);
    # $cb->{'export_csv_separateur'}=cb_model("TAB"=>'<TAB>',
    # 				  ";"=>";",
    # 				  ","=>",");
    # $w->{'export_c_export_csv_separateur'}=$widget;
    # $t->attach($widget,1,2,$y,$y+1,["expand","fill"],[],0,0);
    # $y++;

    ## Ticked boxes: no
# $t->attach(Gtk2::Label->new(__"Ticked boxes"),0,1,$y,$y+1,["expand","fill"],[],0,0);
# $widget=Gtk2::ComboBox->new_with_model();
# $renderer = Gtk2::CellRendererText->new();
# $widget->pack_start($renderer, TRUE);
# $widget->add_attribute($renderer,'text',COMBO_TEXT);
# $cb->{'export_csv_ticked'}=cb_model(""=>__"No",
# 			      "01"=>(__"Yes:")." 0;0;1;0",
# 			      "AB"=>(__"Yes:")." AB",
# 			     );
# $w->{'export_c_export_csv_ticked'}=$widget;
# $t->attach($widget,1,2,$y,$y+1,["expand","fill"],[],0,0);
# $y++;

    ## Columns from Names file: hard-wired
    # $widget=Gtk2::Button->new_with_label(__"Choose columns");
    # $widget->signal_connect(clicked => \&main::choose_columns_current);
    # $t->attach($widget,0,2,$y,$y+1,["expand","fill"],[],0,0);
    # $y++;

    $t->show_all;
    return ($t);
}

sub weight {
    return (.9);
}

# hide the "standard export options" (student sort order dropdown,
# include absentees checkbox) in the Reports tab
sub hide {
    return ( 'standard_export_options' => 1 );
}

1;
