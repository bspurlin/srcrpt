package Compare;
use HTML::Parser; # relying on the ubiquity of gaas' module, and its ability to parse XML
use UsefulCommands;

# Compare.pm

#
#    Copyright ©, 2008, International Business Machines
#
#    This file is part of SrcRpt.
#  
#    SrcRpt is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 2.0.
#
#    SrcRpt is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.#
#


#
# Author: Bill Spurlin wj@spurlin.org
#


#
# Compare two SrcRpt XML files and set the analysis attribute
# of the Uniqline to "nI" in the output file
# (which is otherwise a copy of the second input file) 
# if the UL occurs in both input files.
#

#
# Compare 
#

$DBG_COMPARE = 0x800;

$ul_started = 0;

$dirsep = "";
$object = undef;

sub new  {
    my $class = shift;
    $object = {};
    $object->{file1} = shift;
    $object->{file2} = shift;
    $object->{dirsep} = '/';
    my $f1 = $object->{file1};
    my $f2 = $object->{file2};
    $f1 =~ s/$object->{dirsep}(.+?)$/$1/;
    $f2 =~ s/$object->{dirsep}(.+?)$/$1/;
    $object->{ofn} = $f1. ".compare." . $f2;
    $object->{ofn} =~ s/\.xml\./\./i;
    open OFN, ">$object->{ofn}" or die "$! $@ $object->{ofn}";
    print OFN '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n";
    $object->{debug} = $ENV{SRCRPT_DBG} & $DBG_COMPARE;
    $object->{i} = 0;
    
    $object->{copycmd} = $UsefulCommands::copycmd;
    $object->{mkdircmd} = $UsefulCommands::mkdircmd;
    $tag = "";
    bless $object, $class;    
    goto HERE;
HERE:
    return $object;
}

sub parse1 {
    my $this = shift;
    $p = HTML::Parser->new(
			   start_h => [\&start1, "tagname, attr, text"],
			   end_h   => [\&end1,   "tagname, text"],
			   text_h => [\&text1,   "text"],
			   marked_sections => 1
			   );
    $p->xml_mode(1);
    $p->unbroken_text(1);
    $p->parse_file($object->{file1});
}

sub parse2 {
    my $this = shift;
    $p = HTML::Parser->new(
			   start_h => [\&start2, "tagname, attr, text"],
			   end_h   => [\&end2,   "tagname, text"],
			   declaration_h => [sub {print OFN shift}, "text"],
			   text_h => [\&text2,   "text"],
			   marked_sections => 1
			   );
    $p->xml_mode(1);
    $p->unbroken_text(1);
    $p->parse_file($object->{file2});
}


sub start1{
    $tag = shift;
    my $attr = shift;
    my $text = shift;
    if ($tag eq "uniqline"){
	$ulid = ${$attr}{"id"};
	$note = ${$attr}{"note"};
	# print STDERR "ul id=$ulid $text\n";
        $ul_started = 1;
    }
}

sub start2{
    $tag = shift;
    my $attr = shift;
    my $text = shift;
    if ($tag eq "uniqline"){
	$ulstarttag = $text;
        $ul_started = 1;
    } else {
	print OFN "$text"; 
    }
}

sub end1 {
    if ($_[0] eq "uniqline") {
	$ul_started = 0;
    } 
}


sub end2 {
    if ($_[0] eq "uniqline") {
	$ul_started = 0;
    } 
    print OFN "$_[1]\n";
}

sub text1{
    my $t = shift;
    if ($ul_started) {
	$object->{uls}{$t}{"note"} =  $note;
	$object->{uls}{$t}{"ulid"} = $ulid;
	# print STDERR "text1: $t\n";
    }
}

sub text2{
    my $t = shift; $t =~ s/^[\r\n]+$//;
    chomp $t;
    if ($t) {
	if ($ul_started) {
	    if ( $object->{uls}{$t}{"ulid"} ) {
		$ulstarttag =~ s/uniqline/uniqline analysis=\"nI\" /;
	    }
	    print OFN $ulstarttag;
	    print OFN "$t";
	    $ul_started = 0;
	} else {
	    print OFN "$t";
	}
    }
}


1;
