package ScanDir;
use HTML::Parser; # relying on the ubiquity of gaas' module, and its ability to parse XML
use UsefulCommands;

#
#    Copyright ©, 2004-2015, International Business Machines
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

#    You should have received a copy of the GNU General Public License
#    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.#
# 


#
# Author: Bill Spurlin wj@spurlin.org
#

#
# ScanDir and its derived class Chunked create a directory including all the necessary files
# associated with a SrcRpt scan, including those files in the source code that have hits.
# The created directory and its contents may then be conveniently compressed for transmission.
# Optionally "chunked" versions of the source code files wil be created.
#

$DBG_SCANDIR = 0x400;

$file_started = 0;

$dirsep = "";
$object = undef;

sub new  {
    my $class = shift;
    $object = {};
    $object->{startdir} = shift;
    $object->{dir2} = shift;
    $object->{fn} = shift;
    $object->{debug} = ($ENV{SRCRPT_DBG} & $DBG_SCANDIR) == $DBG_SCANDIR;
    $object->{i} = 0;
    
    $object->{dirsep} = '/';

    $object->{startdir} =~ s/$object->{dirsep}$//;
    $object->{dir2} =~ s/$object->{dirsep}$//;

    $object->{copycmd} = $UsefulCommands::copycmd;
    $object->{mkdircmd} = $UsefulCommands::mkdircmd;
    $tag = "";

    $object->{abs_prefix} = "^$object->{dirsep}|^[a-zA-Z]:$object->{dirsep}";
    ( $object->{new_startdir}, $object->{prefix_to_be_stripped} )  = strip_prefix($object->{startdir});
    $object->{created_scan_dir} = "SrcRpt." . $$ . "." . $object->{new_startdir};
    if ($object->{dir2}) { 
	($object->{new_startdir2}, $object->{prefix2_to_be_stripped}) = strip_prefix($object->{dir2});
	$object->{created_scan_dir} .= ".diff." . $object->{new_startdir2} ;
    }
    undef %lines;
    $object->{cfn} = $object->{created_scan_dir} . $object->{dirsep} . $object->{fn};
    bless $object, $class;    
    $x = "$object->{mkdircmd} \"$object->{created_scan_dir}\"";
    `$x`;
    print STDERR "mkdir ". $object->{created_scan_dir} . "\n", $x, "\n";
    open CFN, ">$object->{cfn}" or die "$@ $! $object->{cfn}";
    print CFN '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n";

    push @distfiles,(
		     "a.html",
		     "b.html",
		     "x*.html",
		     "y*.html",
		     "z*.html",
		     "characters.ent",
		     "*.xsl",
		     "index.hta",
		     "srcrpt.js",
		     "README.html"
		 );

    for my $dfn (@distfiles) {
	$dfn =~ s?\/?\\?g;
	$dfn = $^O =~ /Win/ ? "\"$dfn\"" : $dfn; 
	my $cmd = $object->{copycmd} . "  $dfn " .  "\"" . $object->{created_scan_dir} . "\"";
	print STDERR "$cmd\n";
	$x = `$cmd`;
	print STDERR $x;
    }
    return $object;
}

# init() is a class method meant to be invoked before the construction of a ScanDir object.
# Depending on the return value of $chunked either a ScanDir or a Chunked object
# will be constructed by the caller.

sub strip_prefix {
    my $startdir = shift;
    my $new_src_dir = $startdir;
    my $prefix_to_be_stripped = "";
    if ($startdir =~ /($object->{abs_prefix}?)(.*$object->{dirsep})(.*)/) {
	print STDERR "strip_prefix: 1=$1\t2=$2\t3=$3\n" if $object->{debug};
	$prefix_to_be_stripped = $1 . $2;
	$new_src_dir = $3;
    }
    return ( $new_src_dir, $prefix_to_be_stripped ); 
}

sub init {
    my $chunks = 0;
    print STDERR "Creating scan directory...";
    die "Creating a scan directory requires HTML::Parser" unless require HTML::Parser;
    print STDERR 
	"Do you wish to create chunked files in the scan directory? [y] or [n] ";
  CHUNKEDORNOT: my $line = <STDIN>;
    chomp $line;
    if ($line eq 'y') {
	$chunks = 500;    #  default chunking level
    } elsif ($line eq 'n') {
	print STDERR "Copying whole (non-chunked) source files to scan directory\n";
	$chunks = 0;
    } else {
	print STDERR "Please enter 'y' or 'n'\n";
	goto CHUNKEDORNOT;
    }
    if ($chunks) {
	print STDERR "Creating chunked files in scan directory\n";
      N_CHUNK: print STDERR "Enter the number of characters to be included before and after each hit in a chunk, or press <Enter> to accept the default of 500 characters.\n";
	$line = <STDIN>;
	chomp $line;
	if ($line) {
	    $chunks = $line;
	}
	$chunks =~ s/[^\d]//g;
	print STDERR "Including $chunks characters before and after each hit in a chunk. If this is correct enter [y]\n";
	$line = <STDIN>;
	chomp $line;
	if ($line eq 'y' || $line eq 'Y') {
	    print STDERR "Chunking $chunks characters ...\n";
	} else {
	    goto N_CHUNK;
	}
    }
    return $chunks;
}

sub parse {
    my $this = shift;
    $p = HTML::Parser->new(
			   start_h => [\&start, "tagname, attr, text"],
			   end_h   => [\&end,   "tagname, text"],
			   text_h => [\&text,   "text"],
			   declaration_h => [sub {print CFN shift}, "text"],
			   marked_sections => 1
			   );
    $p->xml_mode(1);
    $p->parse_file($object->{fn});
}

# HTML::Parser method

sub start{
    $tag = shift;
    my $attr = shift;
    my $text = shift;
    if ($tag eq "file"){
	$parsefn = ${$attr}{"name"};
    #print STDERR "file element $parsefn\n";
        $file_started = 1;
        $text =~ s/$object->{prefix_to_be_stripped}//g if $object->{prefix_to_be_stripped};
        $text =~ s/$object->{prefix2_to_be_stripped}//g if $object->{prefix2_to_be_stripped};
    }
    if ($file_started && $tag eq "line") {
	$lines{$tag}++;
	push @filposs, ${$attr}{filpos};
	#print STDERR "$_[0] ",%{$attr},"\tlinesoftag=$lines{$tag}\n" ; 
    }
    print CFN "$text"; 
}

# HTML::Parser method

sub end{
    print CFN "$_[1]\n";
    if ($file_started && $_[0] eq "file") {
	$file_started = 0;
	if ( $lines{$tag}) {
	    $parsefn  =~ s/\//$object->{dirsep}/g;
	    my $madedir = $object->mkdir_if_nec($parsefn);
	    $object->file_method($parsefn, $madedir,@filposs);
	    @filposs = ();
	    #print STDERR "parsefn=$parsefn\t param=$_[0]\t tag=$tag\tlinesoftag=$lines{$tag}\n";
	    $lines{$tag} = 0;
	} else {
	    #print STDERR "NOHITS in $tag\t$parsefn\n";
	}
    } 
}

sub text{
    my $t = shift;
    chomp $t;
    if ($t) {
	print CFN "$t";
    }
}

# When recursively copying a directory tree some filesystems will require
# explicit directory creation

sub mkdir_if_nec {
    my $this = shift;
    my $fqp = shift;
    $fqp =~ s/\//$this->{dirsep}/g;
    my $fn;
    my $cmd;
    my $ppath;
    my $stripped_qp = $fqp;
    $stripped_qp =~ s/$object->{prefix_to_be_stripped}// if $object->{prefix_to_be_stripped};
    $stripped_qp =~ s/$object->{prefix2_to_be_stripped}// if $object->{prefix2_to_be_stripped};
    print STDERR "mkdir_if_nec: fqp=$fqp\tstripped_qp=$stripped_qp\n"  if $this->{debug};
    my @path = split '\\'.$this->{dirsep},$stripped_qp;
    if (-f $fqp){
        $fn = pop @path;
        print STDERR "mkdir_if_nec: $fn @path\n" if $this->{debug};
        if ($this->{created_scan_dir}) {
            my $pqp = "";
            for my $dir (@path) {
                $pqp .= $dir . $this->{dirsep};
                $ppath = $this->{created_scan_dir} . $this->{dirsep}. $pqp;
		if ( ! -d $ppath ) {
		    $cmd = "$this->{mkdircmd} \"$ppath\"";
		    print STDERR "mkdir_if_nec: $cmd\n" if $this->{debug};
		    `$cmd`;
		}
            }
        }
    } else {
        print STDERR "Error $fqp is not a regular file\n";
    }
    return $ppath;
}

# default ScanDir file_method copies the whole file into the scan directory
# to be overridden by derived classes that manipulate the file in some way,
# e. g., by chunking it.

sub file_method {
    my $this = shift;
    my $fn = shift;
    my $madedir = shift;
    if ($^O =~ /Win/) {
		$fn =~ s/\//\\/g;
		$madedir =~ s/\//\\/g;
    }
    my $cmd = $this->{copycmd} . " \"$fn\" \"$madedir\"";
    $this->{i}++;
    print STDERR "$cmd\n" if $this->{debug};
    print STDERR "." unless $this->{i} % 10;
    `$cmd`;
}

#______________________________ End ScanDir ______________________________________


package Chunked;
use ScanDir;
@ISA = ScanDir;

sub new {
    my $class = shift;
    my $this = shift; # requires a constructed ScanDir object
    $this->{n_chunk} = shift;
    bless $this, $class;
}    

# Overrides ScanDir file_method().  Creates a chunked file.and writes it to the scan directory

sub file_method {
    my $this = shift;
    my $fn = shift;
    my $madedir = shift;
    my @filpos = @_;
    $fn =~ /([^\/\\]+)$/;
    my $ofn = $madedir . $1;
    print STDERR "\n$fn\t$ofn\n" if $this->{debug};
# otkirby identifed and contributed error handling for long (+255 character) filename write problem on Windows 2008-10-09
    if (!open FO,">$ofn") {
	my $fnlen = length($ofn);
	warn "Skipping $ofn because it can't be written: $! $@.  This file name has $fnlen characters.";
	return;
    }
    open FI,$fn or die "$! $@";
    $fn =~ s/\\/\//g;
    my @pos = sort {$a <=> $b} @filpos;
    my @s = stat FI;
    my $length = $s[7]; print STDERR "length=$length\n" if $this->{debug};
    my $i = 0;
    my $context = "";
    my $l = 0;
    my $m = 0;
    my $last_x = 0;
    my @xs;
    my $i = 0;
    while ($x = $pos[$i]) {
	push @xs, $x;
	print STDERR "[$x,$last_x]" if $this->{debug};
	$l = $xs[0] - $this->{n_chunk} < 0 ? 0 : $xs[0] - $this->{n_chunk};
	if ($i == 0) { $last_x = $x }
	$m = $last_x + $this->{n_chunk} > $length ? $length : $last_x + $this->{n_chunk};
	if (($x - 2*$this->{n_chunk}) > $last_x ) { 
	    print STDERR "[BAZOOKA [",$i == $#pos,"]- @xs - $l,$m]" if $this->{debug};
	    @xs = $x;
	    seek(FI,$l,0);
	    $context = ""; 
	    read(FI,$context,$m - $l);
	    print FO "\nXXXXXXXXXXXXXXXXXXXXXXX\n$context\nXXXXXXXXXXXXXXXXXXXXXXX\n";
	}
	if ($i == $#pos ){
	    $l = $xs[0] - $this->{n_chunk} < 0 ? 0 : $xs[0] - $this->{n_chunk};
	    $m = $x + $this->{n_chunk} > $length ? $length : $x + $this->{n_chunk};
	    print STDERR "[ZUBA $l,$m]" if $this->{debug};
	    seek(FI,$l,0);
	    $context = ""; 
	    read(FI,$context,$m - $l);
	    print FO "\nXXXXXXXXXXXXXXXXXXXXXXX\n$context\nXXXXXXXXXXXXXXXXXXXXXXX\n";
	}
	$last_x = $x;
	print STDERR "\n" if $this->{debug};
	$i++;
    }
    close FI;
    close FO;
}   

#______________________________ End Chunked ______________________________________
1;
