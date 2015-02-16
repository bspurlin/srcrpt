#
#
#    Copyright ©, 2004-2011, International Business Machines
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
#    You should have received a copy of the GNU General Public License
#    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.
#

#
# Author: Bill Spurlin wj@spurlin.org
#

use Digest::MD5 qw(md5 md5_hex);
use UsefulCommands;
use SrcRpt;
use Getopt::Std;

@argv = @ARGV;

getopts('RrHhqQvVnNf:F:o:O:d:D:c:C:I:x:X:t:T:y:Y:');
usage() if $opt_h;
usage() unless ($opt_f || $opt_F || $opt_r || $opt_R) ;
usage() unless ($opt_d || $opt_D || $opt_I) ;

$startdir = $opt_d?$opt_d:$opt_D;

$filenamesfile = $opt_I;
if ($filenamesfile) {
    die "No such file $filenamesfile $!" unless -f $filenamesfile;
}

if (($filenamesfile && $startdir) || ! ($filenamesfile || $startdir)) {
    die "You must have either -d <startdir> or -I <filenames file> but not both";
}

$dir2 = 0;
$dir2 = $opt_c if $opt_c;
$dir2 = $opt_C if $opt_C;

if ($] >= 5.006) {
    $fn = "2.out.xml";
    $fn = $opt_o if $opt_o;
    $fn = $opt_O if $opt_O;
    if ($] >= 5.008) { 
	eval "open(STDOUT, '>:utf8', \"$fn\")" or die "Can't redirect STDOUT: $!";
    } else {
	print STDERR "Caution: your version of Perl is $].
It is recommended that $0 be run with Perl version 5.8.1 or greater.\n";
	open STDOUT, ">$fn"  or die "Can't redirect STDOUT: $!";
    }
} else {
    die "Perl 5.6 or greater is required to run $0.  You have version $]";
}

$pseudo = 1;
$pseudo = 0 if ($opt_n || $opt_N || $opt_r || $opt_R) ;

$trailing = 0;
$trailing = $opt_t if $opt_t;
$trailing = $opt_T if $opt_T;

$scan = SrcRpt->new("pseudo",$pseudo,"trailing",$trailing,"startdir",$startdir);


if ($dir2) {
    die "Cannot find SrcRptDiff.pm" unless require SrcRptDiff;
    $scan->{dir2} = $dir2;
    $scan->{prefix} = $scan->{prefix} . '|' . $scan->{dir2};
    $scan = SrcRptDiff->new($scan);
}

if ($opt_r || $opt_R) {
    die "Cannot find SrcRptCopyright.pm" unless require SrcRptCopyright;
    $scan = SrcRptCopyright->new($scan);
}


#
# Exclude either suffixed (xclude) or prefixed (Xclude) files
#

$scan->{xclude} = $opt_x;
$scan->{Xclude} = $opt_X;

$scan->{xcluded_dirs} = $opt_y;
$scan->{xcluded_dirs} = $scan->{xcluded_dirs} . "," . $opt_Y if $opt_Y;

if ($scan->{xcluded_dirs}) {
    $scan->{xcluded_dirs} =~ s/,/|/g;
    $scan->{xcluded_dirs} =~ s/\./\\./g;
    $scan->{xcluded_dirs} =~ s/^\|//;
    $scan->{xcluded_dirs} =~ s/\|$//;
}

$scan->set_entities("characters.ent");

print '<?xml version="1.0" encoding="iso-8859-1"?>';
print '
<!DOCTYPE  srcrpt [
<!ENTITY % external.file SYSTEM "characters.ent">
    %external.file;
]>
';

$scan->start_tag("srcrpt"); print "\n";
$scan->start_tag("srchead"); print "\n";
$time=localtime(time);
$scan->start_tag( "timestamp",
		 "source_report.pl\tv. $SrcRpt::VERSION\t$time",
		 "username", 
		 $UsefulCommands::my_username,
		 "hostname", 
		 $UsefulCommands::my_hostname);
$scan->end_tag("timestamp");
$scan->start_tag("commandline","@argv\n");
$scan->end_tag("commandline");

#
# Scan the keyword file.
# The keyword file is
# a text file of one keyword/keyphrase per line.
#

$kwfn = $opt_f if $opt_f;
$kwfn = $opt_F if $opt_F;

$scan->read_keyword_file($kwfn);

print STDERR "$scan->{regexp}\n";

$scan->start_tag("keywords"); print "\n";
for $term ($scan->set_search_terms()) {
    my @attrs = ("keyid",$scan->{search_terms}{$term});
    if ($scan->{is_regexp}{$term}) {
	push @attrs, ("is_regexp",1);
    } else {
	push @attrs, ("is_regexp",0);
    }
    if ($term =~ /[<&\"]/) {
	$term = $scan->normalize($term);
	push @attrs, ("normal",1);
    }
    $scan->start_tag("term",$term,@attrs);
    $scan->end_tag("term");
}
$scan->end_tag("keywords");

if ($filenamesfile) {
    print STDERR "Using $filenamesfile for files to scan\n";
    open F, $filenamesfile or die "Cannot open $filenamesfile $!";
    $scan->start_tag("startdir",$filenamesfile . ($scan->{dir2} ? "\t" . $scan->{dir2} : '') );
    $scan->end_tag("startdir");
    $scan->files_from_file($filenamesfile);
} else {
    print STDERR "Searching under $scan->{startdir} ",$scan->{dir2} ? "\t" . $scan->{dir2} : ''," for files to scan";
    $scan->start_tag("startdir");print "\n";
    $scan->start_tag("dir",$scan->{startdir});
    $scan->end_tag("dir");
    if ($scan->{dir2}) {
	$scan->start_tag("dir",$scan->{dir2});
	$scan->end_tag("dir");
    }
    $scan->end_tag("startdir");
    @{$scan->{startdirs}} = split ",", $scan->{startdir};
    for my $startdir (@{$scan->{startdirs}}) {
	die "No such directory $startdir $!" unless -d $startdir;
	$startdir =~ s/$scan->{dirsep}$//;
	$startdir =~ s/\\/\//g;
	$scan->{prefix} = $startdir;
	$scan->r_find($startdir);
    }
    @{$scan->{dir2s}} = split ",", $scan->{dir2};
    for my $dir2 (@{$scan->{dir2s}}) {
	die "No such directory $dir2 $!" unless -d $dir2;
	$dir2 =~ s/$scan->{dirsep}$//;
	$dir2 =~ s/\\/\//g;
	$scan->{prefix} = $dir2;
	$scan->r_find($dir2) if $dir2;
    } 
}

print STDERR "\n";

$nfiles = $#{$scan->{files}};
@{$scan->{xcludes}} = ();

if ($scan->{xclude}) {
    my $xclude = $scan->{xclude};
    @{$scan->{xcludes}} = split ",", $scan->{xclude};
    $xclude =~ s/\,/\|/g;
    my @files;
    for my $file (@{$scan->{files}}) {
	if ($$file[1] =~ /($xclude)$/i) {
	    push @{$scan->{xcluded_files}}, $$file[0] . $scan->{dirsep} . $$file[1];
	}else {
	    push @files, $file;
	}
    }
    @{$scan->{files}} = @files;
}

if ($scan->{Xclude}) {
    my $xclude = $scan->{Xclude};
    push @{$scan->{xcludes}}, split ",", $scan->{Xclude};
    $xclude =~ s/\,/\|/g;
    my @files;
    for my $file (@{$scan->{files}}) {
	if ($$file[1] =~ /(^|$scan->{dirsep})($xclude)[^$scan->{dirsep}]*$/i) {
	    push @{$scan->{xcluded_files}}, $$file[0] . $scan->{dirsep} . $$file[1];
	} else {
	    push @files, $file;
	}
    }
    @{$scan->{files}} = @files;
}

$scan->start_tag("excluded","","n",$nfiles - $#{$scan->{files}});print "\n";
for my $suffix (@{$scan->{xcludes}}) {
    $scan->start_tag("prefixorsuffix",$suffix);
    $scan->end_tag("prefixorsuffix");
}
$scan->end_tag("excluded");

$scan->start_tag("excludedfiles","");print "\n";
for my $xcludedfile (@{$scan->{xcluded_files}}) {
    $scan->start_tag("excludedfile","","name",$scan->normalize($xcludedfile));
    $scan->end_tag("excludedfile");
}
$scan->end_tag("excludedfiles");

print STDERR  "\nIgnoring ",
    $#{$scan->{binary_files}} + 1 + $nfiles - $#{$scan->{files}},
    " binary or otherwise excluded files. Scanning ",
    $#{$scan->{files}} + 1,
      " files\n";

$scan->start_tag("nfiles",$#{$scan->{files}} + 1);
$scan->end_tag("nfiles");
$scan->end_tag("srchead");

#
# Print a progress bar while scanning the files
#

$bar_inc =  ($#{$scan->{files}} + 1) / $scan->{linelength}; 
print STDERR "\n0";
$i =  $scan->{linelength} - 5;
while ($i--) {
    print STDERR '_';
}

print STDERR '100',"\n";
print "\n\n"; 

$scan->start_tag("hits") ;
print "\n";

for $f (@{$scan->{files}}) {
    next unless $f;
    $x = int(($i++ / $bar_inc));
    print STDERR "#" if ($lastx != $x);
    $lastx = $x;
    my $top = $$f[0];
    my $basefn = $$f[1];
    my $fn1 =  $top . $scan->{dirsep} . $basefn;
    $scan->scan_n_tag($fn1,$top,$basefn);
}

#
#  If the number of scannable files is less than the length of the progress bar, fill up the extra space
#  fixed 2006-06-02, Andrea C. Martinez (acm@us.ibm.com)
#
my $emptyProgressBar = ($scan->{linelength} -($#{$scan->{files}}+1))-1;
if ($emptyProgressBar > 0) {
    for ($emptyProgressBarCount = $emptyProgressBar; $emptyProgressBarCount > 0; $emptyProgressBarCount--) {
	print STDERR "#";
    }
}

# --end of fix--

print STDERR "\n";

$scan->end_tag("hits");

$scan->start_tag("uniqlines");print "\n";

$scan->do_uniqlines();

$scan->end_tag("uniqlines");print "\n";

$scan->start_tag("summary"); print "\n";

$scan->create_hits();

$scan->end_tag("summary");

$scan->do_license_files;

$scan->do_binary_files;

$scan->end_tag("srcrpt");

if ($opt_q || $opt_Q) {
    if (require HTML::Parser) { 
	require ScanDir;
	my $chunks = ScanDir::init();
	$create_scandir = ScanDir->new($scan->{startdir}, $scan->{dir2}, $fn);
	if ($chunks) {
	    $create_scandir = Chunked->new($create_scandir, $chunks);
	}
	$create_scandir->parse();
    } else {
	print STDERR "Create Scan Directory is not available without HTML::Parser\n";
    }
}

sub usage {

print "$0 Version $SrcRpt::VERSION\n
Usage:

perl $0 -h 
perl $0 -r -d <search dir> [ -o <output file>  ]
perl $0 -f <keyword file> -d <search dir> [ -o <output file> ]
perl $0 -f <keyword file> -d <search dir> -c <diff dir> [ -o <output file> ]
\n",
'
In addition the following options may be used:

[ -n ]  [ -x <exclude suffix>][,... ] [ -X <exclude prefix>][,... ] [ -y <exclude directory> ] [ -t <number of trailing characters ] [ -q ]

Where -n turns off the pseudo-keywords "URL" and "email", -x and -X are used to exclude filenames matching
the specified suffixes and prefixes, -y excludes any directory of the specified name (and all subdirectories), -t specifies the number of trailing characters to include by default after a keyphrase expression match and -q allows the creation of a scan directory, with or without chunked files, for compression and transmission. 

"-n" is set by default, turning off the pseudo-keywords "URL" and "email", with "-r" (the Copyright Holder report).

In the following example, a keywords file "keywords_2004_03_29.txt" will be
used to scan all non-binary files in a source tree beginning at 
directory lucene-1.3-final  with XML output. The output file will
be named (in the absence of the -o switch) "2.out.xml".

perl source_report.pl -f keywords_2004_03_29.txt -d lucene-1.3-final  

In this example a report on the diffs between two Perl versions is produced:

perl source_report.pl -f keywords.txt -d perl-5.8.3 -c perl-5.8.6 -o 2.out.perl5.8.3.perl5.8.6.diff.2.xml

In the following example using the keywords file "keywords_2005_07_28.txt", 
a diff scan between two versions of Jakarta log4j is produced ignoring xml and html files:

perl source_report.pl -f keywords_2005_07_28.txt -d jakarta-log4j-1.1.1 -c jakarta-log4j-1.1.3 -x xml,html -o log4j-1.1.1.diff.1.1.3.srcrpt.2.xml

This example forces 80 characters of context after every keyphrase hit and excludes all files beginning with "Change"
as well as all directores named "doc".

perl source_report.pl -d TimeDate-1.16 -f keywords_2005_07_28.txt -t 80 -o TimeDate-1.16.srcrpt.5.xml -X Change -y doc

Here the copyright scan is run on a directory called "build.buildforge.1", excluding filenames with certain prefixes and suffixes:

perl source_report.pl -r  -d build.buildforge.1 -X Makefile -x phpt,.mk,makefile,.sh,ignore,.in -o php.build.buildforge.copyr.4.srcrpt.xml
';
exit 0;
}

#
# End
#

1;
