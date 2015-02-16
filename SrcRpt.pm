package SrcRpt;

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
#   You should have received a copy of the GNU General Public License
#    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.#
#

# SrcRpt.pm

#
# Author: Bill Spurlin wj@spurlin.org
#


$VERSION = "0.3050 ";

use File::stat;
use UsefulCommands;
require Exporter;

@ISA = qw(Exporter);
%search_terms = ();
@search_regexps = ();
@files = ();
@binary_files = ();
@xcluded_files = ();
%found;
%ents;
%match;
%ids;
@xcluded_dirs;

sub new {
    my $class = shift;
    my $object = {};
    %$object = @_;
    $object->{linelength} =                     75;
    $object->{urlregexp} =                      '(http|ftp|https):\/\/(\w|-)+\.(\w|-|\.|\/)+';
    $object->{emailregexp} =                    '(\w|-|\.)+\@(\w|-)+(\.(\w|-)+)+';
    $object->{email} =                          "email";
    $object->{URL} =                            "URL";
    $object->{files} =                          \@files;
    $object->{search_terms} =                   \%search_terms;
    $object->{search_term_order} =              0;
    $object->{search_regexps} =                 \@search_regexps;
    $object->{binary_files} =                   \@binary_files;
    $object->{xcluded_files} =                  \@xcluded_files;
    $object->{regexp} =                         'NONE';
    $object->{dirsep} =                         '/';
    $object->{id} =                             1;
    $object->{found} =                          \%found;
    $object->{ents} =                           \%ents;
    $object->{match} =                          \%match;
    $object->{ids} =                            \%ids;
    $object->{debug} = $ENV{SRCRPT_DBG};
    $object->{MAX_FILE_SIZE} = 
	$ENV{SRCRPT_MAX_FILE_SIZE} ? 
	$ENV{SRCRPT_MAX_FILE_SIZE}: 
	20000000;
    $object->{found_large_file} = 0;
    $object->{n} = 100;
    $object->{xcluded_dirs} =                   \@xcluded_dirs;
    bless $object, $class;
    return $object;
}

$line_id = 1;


# debugging bitmap

$DBG_DO_SEARCH = 0x1;
$DBG_R_FIND = 0x2;
$DBG_COUNT = 0x4;
$DBG_GET_TERM_FROM_MATCH = 0x8;
$DBG_CREATE_HITS = 0x10;
$DBG_DO_UNIQLINES = 0x20;
$DBG_PROCESS_LINES = 0x40;
$DBG_NORMALIZE = 0x80;

#
# r_find
#
# Recursively find all files below the starting directory.
# Place the FQP's (binary and non) in arrays.
#
# INPUT			$path to top of directory to be searched
# OBJECT ARRAY	@files containing fqp of all files to be scanned
# OBJECT ARRAY	@binary_files containing fqp of all non-scanned
#

sub r_find {
    my $this = shift;
    my $path = shift; 
    my $debug_r_find;
    my $i = 0; 
    if (($this->{debug} & $SrcRpt::DBG_R_FIND) == $SrcRpt::DBG_R_FIND)  {
	$debug_r_find = 1;
	print STDERR "\n"; 
    } else {
	$debug_r_find = 0;
    }
    print STDERR "r_find: path=$path\n" if $debug_r_find;
    my @localentries = `$UsefulCommands::dircmd \"$path\"`;
    my $dirsep = $this->{dirsep};
    my @rv = ();
    map chomp,@localentries;
    if ($this->{xcluded_dirs}) {
	@localentries = grep (!/^($this->{xcluded_dirs})$/, @localentries);
    }
    print STDERR "localentries:  @localentries\n" if $debug_r_find;
    for (@localentries) {
		 my $fqp = $path . $dirsep . $_;
		 if ( -d $fqp && ! -l $fqp) { 
		     $this->r_find($fqp);
# Don't scan "binaries", symlinks or PDF's
		 } elsif ( @rv = $this->file_method($fqp) ) { 
		     push @{$this->{files}},[ @rv ];
		     $i++;
		     print STDERR "." unless $i % 10;
		 } else {
		     push @{$this->{binary_files}}, $fqp;
		 }
	     }
}


sub file_method{
    my $this = shift;
    my $file = shift;
    $file =~ s/\\/\//g;
    if ( -f $file && 
	 ! -l $file && 
	 ! -B $file && 
	 $file !~ /pdf$/i &&
	 ! $this->large_file($file)){
	my $dirsep = $this->{dirsep};
	$file =~ /(^$this->{prefix}?)$dirsep(.+)/;
	my $top = $1;
	my $basefn = $2;
	$this->{found}{$basefn}{$top} = 1;
	return ($top, $basefn) ;
    } else {
	return ()
    }
}

sub large_file {
    my $this = shift;
    my $fn = shift;
    my $sb = stat($fn); 
    my $size = $sb->size;
    my $rv = 0;
    if ($size  > $this->{MAX_FILE_SIZE}) {
	print STDERR "\nCAUTION: SrcRpt may not be able to scan a large file.\n" 
	    unless $this->{found_large_file};
	$this->{found_large_file} = 1;
	print STDERR 
	    "$fn is of size $size: Include it in scan? [y] or [n] ";
	SCANORNOT: my $line = <STDIN>;
	chomp $line;
	if ($line eq 'y') {
	    print STDERR "Including $fn in scan\n";
	    $rv = 0;
	} elsif ($line eq 'n') {
	    print STDERR "Adding $fn to \"binary files\", i. e., files not scanned.\n";
	    $rv = 1;
	} else {
	    print STDERR "Please enter 'y' or 'n'\n";
	    goto SCANORNOT;
	}
    }
    return $rv;
}

sub empty_tag {
    my $this = shift;
    print $this->tag_n_attrs(@_ ) . "/>\n";
}

sub start_tag {
    my $this = shift;
    my $tag = shift;
    my $data = shift;
    my $out_tag = $this->tag_n_attrs($tag,@_ );
    $out_tag = $out_tag . '>';
    print $out_tag;
# Problem: an extra-long line without whitespace can cause
# wrapping to fail in table cells.
# The assumption in the following kluge is that if an extra-long line shows
# up it must contain a URL with POST paramaters delimited by "&".
    if (length($data) > $this->{linelength} && $data =~ /$this->{urlregexp}/ ) {
	my @chunks = split /\s+/,$data;
	for my $chunk (@chunks) {
	    if(length($chunk) > $this->{linelength} && $chunk  =~ /(.+?)(\&amp\;)/) {
		$chunk = $1;
	    }
	    $data = join " ",@chunks;
	}

    }
    print $data;
}


sub tag_n_attrs {
    my $this = shift;
    my @args = @_;
    my @caller=caller();
    my $tag = shift;
    my $att; my $value;
    my $out_tag = '<' . $tag;
    while($att = shift) {
	$value = shift;
	$out_tag = $out_tag . " $att=\"$value\"";
	die "@caller can't have attribute $att without value\nargs to tag_n_attrs = @args" unless defined($value);
    }
    return $out_tag;
}

sub end_tag {
    my $this = shift;
    my $tag = shift;
    print '</' . $tag . ">\n";
}

sub do_license_files {
    my $this = shift;
    $this->start_tag("licensefiles");print "\n";
    for my $f (@{$this->{files}}) {
	if ($$f[1] =~ /licen[cs]/i) {
	    $this->start_tag("licensefile",$$f[0] . $this->{dirsep} . $$f[1]);
	    $this->end_tag("licensefile");
	}
    }
    $this->end_tag("licensefiles");
}

sub do_binary_files {
    my $this = shift;
    $this->start_tag("binaries");print "\n";	
    for my $f (@{$this->{binary_files}}) {
	$this->start_tag("binary",$this->normalize($f));
	$this->end_tag("binary");
    }
    $this->end_tag("binaries");
}


#
# do_search_terms
#
# INPUT $file entire contents of file
# INPUT $re the regular expression on which we are searching
# INPUT $n maximum number of characters before and after a match in a context
#
# OUTPUT array @rv of ( [$p,$term,$match_l,$context] ) where
#     $p = file position pointer; depth into file
#     $term = search term matched
#     $match_l = actual match (case sensitive: term "Apache" matches match_l "apache")
#     $context = the context (often a line) matched

$FILEPOS = 0;
$TERM =    1;
$MATCH_L = 2;
$CONTEXT = 3;


#
# NOTE need to scan a file that does not have end of line characters.
#

sub do_search_terms {
    my $this = shift;
    my $file = shift;
    my $re = shift;
    my $n = shift;
    my $context;
    my $token;
    my $p;
    my $l;
    my $term_regexp;
    my $offset;
    my $orig_context = "";
    my $prev_start_context = 0;
    my $prev_term = "";
    my $debug_do_search;
    if (($this->{debug} & $SrcRpt::DBG_DO_SEARCH) == $SrcRpt::DBG_DO_SEARCH)  {
	$debug_do_search = 1;
	print STDERR "do_search:$re\n";
    } else {
	$debug_do_search = 0;
    }
    my $match_l = 0;
    my $context_length = 0;
    my $end_context = 0;
    my $start_context = 0;
    my @rv;
    $_ = $file;
    my $fl = length($file);
    my $i = 0;
    my $context_char = "";
    while  (/$re/cg) {
	$p = pos;
	pos() = $p - 1;
	$token = $1;
	($term,$term_regexp) = $this->get_term_from_match($token);
	$l = length($token);
	pos() = $p if $l == 1;  # 1-character keyword (e. g. @ ) causing trouble
	$i = 0;
	$start_context = $p - $l;
	while ($i < $n && $start_context >= 0) {
	  $context_char = substr($file,$start_context,1);
	  if ($context_char eq "\n" || $context_char eq "\r" || $start_context == 0) {
	    #print STDERR "CONTEXT START start_context=$start_context\n";
	    last;
	  } else {
	    $start_context--; 
	    #print STDERR "START: context_char=$context_char\n";
	  }
	  $i++;
	}
	$i = 0;
	$end_context = $p;
	while ($i < $n && $end_context <= $fl) {
	  $context_char = substr($file,$end_context,1);

# Test for $i at the beginning of the next line determines the minimum number of 
# trailing characters to insert behind the hit before testing for the end of context.
# E. g., "AUTHOR" on a line by itself would be followed by at least one EOL character before
# the information of interest if $this->{trailing} == 1.

	  if ($i > $this->{trailing} && ($context_char eq "\n" || $context_char eq "\r" || $end_context == $fl) ) {
	    #print STDERR "CONTEXT END end_context=$end_context\n";
	    last;
	  } else {
	    $end_context++; 
	    #print STDERR "END: context_char=$context_char\n";
	  }
	  $i++;
	}
	$context_length = $end_context -  $start_context;
	$context = substr $file,$start_context ,$context_length;
	
	if ($prev_start_context == $start_context && $prev_term eq $term) {
	   next;
	 }
	$prev_start_context = $start_context;
	$prev_term = $term;

	#
	# Reduce classpaths and tags canonical form
	#

	if ($context =~ /((?:[\w]+\/){3,}[-\w\.]+)/ || $context =~ /((?:[\w]+\.){3,}[-\w\.]+)/) {
	  my $classpath=$1;
	  if ($classpath =~ /$term_regexp/) {
	    print STDERR "CLASSPATHcontext=$context\tterm=$term\tregexp=$term_regexp\t1=$1\n" if $debug_do_search;
	    $context = $classpath;
	  }
	}
	print STDERR "context_length=$context_length\ncontext=\"$context\n\"\tterm_regexp=$term_regexp\tterm=\"$term\"\tp=$p\n" if $debug_do_search;

	$token =~ s/^\s+//;
	if ($token =~ /^(\S+)[\n\r]*/) {
           $match_l = $1;
	   $match_l =~ s/[\"]//g;
        } else {
           $token =~ /^(\S+)\!*/;
           $match_l = $1;
        }
	$context = $this->normalize($context);
	print STDERR "NORMAL term=$term\ncontext=$context\tmatch_l=$match_l\t\n" if $debug_do_search;
	push @rv, ( [$p,$term,$match_l,$context] );
    }
    return @rv;
}


sub normalize {
    my $this = shift;
# eliminate leading and trailing spaces
    my $line = shift;
    $line =~ s/^\s+//ms;
    $line =~ s/^(\&nbsp\;)+//ms;
    $line =~ s/\s+$//ms;
    $line =~ s/(\&nbsp\;)+$//ms;
    my @bogus_ents;
    my $fixed_ent;
    if (($this->{debug} & $SrcRpt::DBG_NORMALIZE) == $SrcRpt::DBG_NORMALIZE)  {
	print STDERR "normalize 1: line=$line\t\n";
    }
    if ($line =~ /\&/) {
	$line =~ s/\&(?!([\w\d\#]+)([\;]+))/\&amp\;/gms;
	if (($this->{debug} & $SrcRpt::DBG_NORMALIZE) == $SrcRpt::DBG_NORMALIZE)  {
	    print STDERR "normalize 2: line=$line\t\n";
	}
	while ($line =~ /(\&[\w\d\#]+\;)/g) {
	    my $match = $1;
	    if ($this->{ents}{$match}) {
		# $match is a valid character entity
	    } else {
		# $match not in characters.ent
		push @bogus_ents,$match;    
	    }
	}
	for my $ent (@bogus_ents) {
	    $fixed_ent = $ent;
	    $fixed_ent =~ s/\&/\&amp\;/;
	    $line =~ s/\Q$ent\E/$fixed_ent/;
	}
    }
    $line =~ s/\</\&lt\;/gms;
    $line =~ s/\>/\&gt\;/gms;
    
    chomp $line;
    $line =~ s/[\x0B-\x1F\x00-\x08]//gms;
    return $line;
}

sub do_pseudo {
    my $this = shift;
    my $input = shift;
    my $re = shift;
    my $pseudo_k = shift;
    my $match_l = shift;
    my $context;
    my $p;
    my $l;
    my @rv;
    $_ = $input;

# Can't use /o modifier because $re varies - sigh

    while  (/(?:\W|\b)($re)(?:\W|\b)/igc) {
	$p = pos;
	pos() = $p - 1;
	$context = $1;
	$match_l = $context;
	if (length($match_l > 50)) {
		$match_l = substr($match_l,0,50);
	}
	push @rv, ( [$p,$pseudo_k,$match_l,$context] );
    }
    return @rv;
}


sub set_match {
    my $this = shift;
    my $context = shift;
    my $match = shift;
    my $term = shift;
    $this->{match}{$context . $term} = $match;
}

sub count {
    my $this = shift;
    my $context = shift;
    my $term = shift;
    if (($this->{debug} & $SrcRpt::DBG_COUNT) == $SrcRpt::DBG_COUNT)  {
	print STDERR "count: context=$context\tterm=$term\n";
    }
    $$term{$context}++;
    $this->{ids}{$context} = $this->set_id($context) unless $this->{ids}{$context};
    return $context;
}


sub set_id {
    my $this = shift;
    return $this->{id}++;
} 


sub get_term_from_match {
    my $this = shift;
    my $term = shift;
    my @my_search_regexps = @{$this->{search_regexps}}; 
    my $rv = 0;
    my $re;
    my $orig_re;
    for my $x (@my_search_regexps) {
	$re = $$x[0];
	$orig_re = $re;
	if ($re =~ /\*/) { 

	} else { 
	    $re = "\^" . $re . "\$"; 
	};
	if (($this->{debug} & $SrcRpt::DBG_GET_TERM_FROM_MATCH) == $SrcRpt::DBG_GET_TERM_FROM_MATCH)  {
	    print STDERR "get_term_from_match: term=$term regexp=$re $$x[1]\n";
	}
	if ($term =~ /($re)/ims) {
	    $rv = $$x[1] ; 
	    last;
	};
    }
    return $rv,$orig_re;
}

#
# set_search_terms()
#
# INPUT: list of search terms to be added to the object's list
# OUTPUT: the object's list of search terms in the order entered.
#
# Must be idempotent for derviations that add search terms 
# (potentially the same search term more than once)
#


sub set_search_terms {
    my $this = shift;
    for my $term (@_) {
	    if ($term =~ s/\s*QQ\s*//gi) {
			$this->{is_regexp}{$term} = 1;
    	}
		$this->{search_terms}{$term} = $this->{search_term_order}++;
    }
    return sort {$this->{search_terms}{$a} <=> $this->{search_terms}{$b}} keys %{$this->{search_terms}};
}

sub read_keyword_file {
    my $this = shift;
    my $kwfn = shift;
    open F, $kwfn or die "$! $kwfn";
    $this->start_tag("keywordfile",$kwfn);
    $this->end_tag("keywordfile");
    while(<F>) {
	next if /^\s*\#/;
	s/\s*\#.*// unless /qq/i;
	s/\s+$//;
	s/^\s+//;
	next if /^\s*$/;
	s/\r//g;
	chomp;
	$this->set_search_terms($_);
    }
    $this->set_search_regexp($this->set_search_terms());
    if ($this->{pseudo}) {
	$this->set_search_terms( $this->{email} ,$this->{URL} );
    }
}

#
# Create a regular expression $x
# from the keywords. Escape
# regexp operators
#

sub set_search_regexp {
    my $this = shift;
    my @search_terms = @_;
    for my $term (@search_terms) {

my $id = 
	my $regexp_i = "";    
	$regexp_i .= '(?:';
	my $y = $term;
	$y = lc($y);
	if ($this->{is_regexp}{$term}) {

	} else {
	    $y =~ s/([\.\(\)])/\\$1/g;
	    $y =~ s/\s+/[\\-\\s\\*\\#\\n\\r\\\/]\{1,8\}/g;
	    $y =~ s/\!/.\{0,8\}\?/g;
	}
	$regexp_i .= "$y)";

	push @{$this->{search_regexps}}, ( [ ($regexp_i, $term)  ]);
    }

    my $regexp;
    for (@{$this->{search_regexps}}) {
	$regexp .= $$_[0] . "|";
    }
    if ($this->{pseudo}) {
	push @{$this->{search_regexps}}, 
	( [ ($this->{emailregexp},$this->{email}) ] ), 
	( [ ($this->{urlregexp},$this->{URL}) ] );
    }
    $regexp =~ s/\|$//;
#    Note that the gc modifiers have to go after the evaluation of the compiled regexp in do_search_terms()
    $this->{regexp} = qr/(?:\W|\b)($regexp)(?:\W|\b)/ims;
    return $this->{regexp};
}

sub create_hits {
    my $this = shift;
    for my $keyword ($this->set_search_terms()) {

	my $match_l = 0;
	my @hits = ();
	my $hit;
	@keys = sort {$$keyword{$b} <=> $$keyword{$a}} keys %$keyword;
	my $keyword_less_bang = $keyword;
	$keyword_less_bang =~ s/\!//; 
	$this->start_tag("keyword","","keyid",$this->{search_terms}{$keyword});	
	print "\n";
	for $hit (@keys) {
	    $match_l = $this->{match}{$hit . $keyword};
	    if (($this->{debug} & $SrcRpt::DBG_CREATE_HITS) == $SrcRpt::DBG_CREATE_HITS)  {
		print STDERR (
			      "create_hits: hit=",
			      $hit,"\thitcount=",
			      $$keyword{$hit},"\tid=",
			      $this->{ids}{$hit},
			      "\tmatch=",
			      $match_l,
			      "\n");
	    }
	    $this->empty_tag("hit","hitcount",$$keyword{$hit},"ulid",$this->{ids}{$hit},"match",$match_l);
	}
	$this->end_tag("keyword");
	print "\n\n";
    }
}


sub do_uniqlines {
    my $this = shift;
    my @keys = sort {$this->{ids}{$b} <=> $this->{ids}{$a}} keys %{$this->{ids}};
    for my $uniqline (@keys) {
	if (($this->{debug} & $SrcRpt::DBG_DO_UNIQLINES) == $SrcRpt::DBG_DO_UNIQLINES)  {
	    print STDERR "do_uniqlines: uniqline=$uniqline\tid=$this->{ids}{$uniqline}\n";
	}

	# W3C xml:id spec requires id attribute in an XML document to have a unique value.
	# For now, have uniqline be the only element with an id attribute.

	$this->start_tag("uniqline",$uniqline,"id",$this->{ids}{$uniqline});
	$this->end_tag( "uniqline");
    }
}

sub scan_file {
    my $this = shift;
    my $fn = shift;
    my $regexp = shift;
    my $compare = shift;
    open FF, $fn or die "SrcRpt::scan_file: $fn $!";
    my $superline = "";
    my @rv;
    while (<FF>) {
	$superline .= $_;
    }
    push @rv, $this->do_search_terms($superline,$regexp,$this->{n});
    if ($this->{pseudo}) { 
	push @rv, $this->do_pseudo($superline,
				   $this->{urlregexp},
				   $this->{URL},
				   ":");
	push @rv, $this->do_pseudo($superline,
				   $this->{emailregexp},
				   $this->{email},				   
				   "@");
    }
    close FF;
    return @rv;
}

sub get_line_id {
    my $this = shift;
    return $line_id++;
}

sub scan_n_tag {
    my $this = shift;
    my $fn = shift;
    my @rv;
    $this->start_tag("file","","name",$this->normalize($fn)) ;
    print "\n";
    @rv = $this->scan_file($fn, $this->{regexp});
    $this->process_lines(@rv);
    $this->end_tag("file");
}

sub process_lines {
    my $this = shift;
    my @rv = @_;
    my $filpos;
    my $term;
    my $match_l;
    my $context;
    for (@rv) {  #
	if (($this->{debug} & $SrcRpt::DBG_PROCESS_LINES) == $SrcRpt::DBG_PROCESS_LINES)  {
	    print STDERR "process_lines: @$_\n";
	}
	$filpos=$$_[$FILEPOS]; 
	$term=$$_[$TERM]; 
	$match_l=$$_[$MATCH_L];
	$context=$$_[$CONTEXT]; 
        $this->set_match($context,$match_l,$term);
	$this->count($context,$term);
	$this->empty_tag(
		"line",
		"filpos",
		$filpos,
		"keyid",
		$this->{search_terms}{$term},
		"ulid",
		$this->{ids}{$context},
		"match",
		$match_l
		);
    }
}


sub set_entities {
    my $this = shift;
    my $fn = shift;
#
# Create a data structure of the external character entities
# for later use in normalize().
#

    open C, $fn or die "$! $0 $?";
    while (<C>) {
	/\<\!ENTITY\s+(\S+)\s+\"(\&\#\d+\;)\">/;
	$this->{ents}{$2} = 1;
	$this->{ents}{"\&" . $1 . "\;"} = 1;
    }
    
#
# Character entities lt, gt, amp may not be included
# in an external entity declaration 
# without upsetting some parsers, notably MSXML3,
# so they are explicitly incuded here
# for later normalization since they are not
# included in characters.ent.
#
    
    for ("&gt;","&#62;","&amp;","&#38;","&lt;","&#60;") {
	$this->{ents}{$_} = 1;
    }



}

sub files_from_file {
    my $this = shift;
    my $fn = shift;
    my @rv;
    my $line = 0;
    open F, $fn or die "Cannot open $fn $!";
    FILE: while (<F>) {
	s/\s*\#.+//;
	s/\s+$//;
	s/^\s+//;
	next if /^\s*$/;
	s/\r//g;
	chomp;
	if (! $line ) {
	    $line = $_;
	    $line =~   /(.+?)$this->{dirsep}/;
	    if ($1 && -d $1) {
		$this->{prefix} = $1;
		$this->{startdir} = $this->{prefix};
	    } else {
		die "Cannot derive initial directory name from first line \"$line\" in file $fn ";
	    }
	}
	if (-d ) {
	    print STDERR "$_: Cannot scan directories. Continuing ...\n";
	    next FILE;
	}
	if (-l) {
	    print STDERR "$_: Cannot scan symbolic links. Continuing ...\n";
	    next FILE;
	}
	if (-B) {
	    print STDERR "$_: Cannot scan binaries. Continuing ...\n";
	    push @{$this->{binary_files}}, $_;
	    next FILE;
	}
	if (/pdf$/i) {
	    print STDERR "$_: Cannot scan pdf's. Continuing ...\n";
	    push @{$this->{binary_files}}, $_;
	    next FILE;
	}
	if (! -f ) {
	    print STDERR "Cannot find $_: Continuing ...\n";
	    push @{$this->{binary_files}}, $_;
	    next FILE;
	}
	@rv = $this->file_method($_); 
	push @{$this->{files}},[ @rv ];
    }
}


1;
