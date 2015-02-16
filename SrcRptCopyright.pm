package SrcRptCopyright;

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


#
# Author: Bill Spurlin wj@spurlin.org
#



#
# A derivation of SrcRpt intended to report solely on copyright holders.
# Not intended to replace, but to supplement keyphrase scanning.
#
# A grammar, of sorts, of copyright statements
# See US Patent 8640101
#
# TBD: integrate with keyphrase scanning
# TBD: inherit from SrcRptDiff for diff-copyright holder scans
#

@ISA = SrcRpt;
use SrcRpt;

#
# SrcRptCopyright methods
#


sub new {
    my $class = shift;
    my $object = shift;
    $object->{n} = 200;
    $object->{pseudo} = 0;

# The copyright symbol in its several guises:
# ©|(c)|&#169;|&copy;

    $object->{regexp_symbol} = '[\s\r\n,]\xA9[\s\r\n,]|\(c\)|\x26\#169\;|\x26copy\x3B';
    $object->{regexp_long} = '(?:.{0,16}copyright.{0,128}|(?:' .$object->{regexp_symbol}  . '))';
    $object->{regexp_short} = '(?:copyright{1,28})';

    $object->{trailing} = 1;
    bless $object, $class;
    $object->set_search_terms('copyright!');
    return $object;
}

# debugging bitmap

$DBG_COPYRIGHT_STATEMENT = 0x100;
$DBG_FIND_MULT = 0x200;


sub read_keyword_file {
    my $this = shift;
    $this->start_tag("keywordfile","none");
    $this->end_tag("keywordfile");
    $this->set_search_regexp($this->{regexp_long});
}

sub set_search_regexp {
    my $this = shift;
    my $regexp_i = shift;
    $this->{regexp} = qr/(?:\W|\b)($regexp_i)(?:\W|\b)/ims;
    push @{$this->{search_regexps}}, ( [ ($regexp_i, "copyright")  ]);
    return $this->{regexp};
}

sub process_lines {
    my $this = shift;
    my @rv = @_;
    my $filpos;
    my $term;
    my $match_l;
    my $context;
    my @statements; 
    my $n_copyr;
    my $n_symbol;
    my $rv;
    my $match;
    my $debug = (($this->{debug} & $SrcRpt::DBG_PROCESS_LINES) == $SrcRpt::DBG_PROCESS_LINES) ? 
	1 : 
	0;
    for (@rv) {  
	@statements = ();
	if ($debug)  {
	    print STDERR "process_lines: filpos=$$_[$SrcRpt::FILEPOS]\tterm=$$_[$SrcRpt::TERM]\tmatch_l=$$_[$SrcRpt::MATCH_L]\tcontext=$$_[$SrcRpt::CONTEXT]\n";
	}
	$filpos=$$_[$SrcRpt::FILEPOS]; 
	$term=$$_[$SrcRpt::TERM]; 
	$match_l=$$_[$SrcRpt::MATCH_L];
	$context=$$_[$SrcRpt::CONTEXT]; 
	($n_copyr,$n_symbol) = $this->detect_mult($context);
	if ($n_copyr > 0 || $n_symbol > 0 ) {
	    if ($n_copyr < $n_symbol) {
		push @statements , $this->find_mult_statements($context, $this->{regexp_symbol},$n_copyr, $n_symbol);
	    } else {
		push @statements , $this->find_mult_statements($context, $this->{regexp_short}, $n_copyr, $n_symbol);
	    }
	} else {
	    push @statements, $this->copyright_statement($context);
	}

	for $c (@statements) { 		print STDERR "process_lines: c=$c\n" if $debug;

	    $c =~/^\s*([^\s]+\s*[^\s\(\@\<]*\s*[^\s\(\@\<]*)/; 
	    if ($1){ 
		$term = $1; 
		$this->set_search_terms($term);
		if ($term =~ /(\w{4,})\s/) {
		    $match = $1;
		} else {
		    $match = $term;
		}
		$this->set_match($c,$match,$term);
		$this->count($c,$term);
		$this->start_tag("line","$term","filpos",$filpos,"keyid",$this->{search_terms}{$term},"ulid",$this->{ids}{$c},"match",$match);
		$this->end_tag("line");
	    } else {
		$match = $match_l;
		$match = $1 if $context =~ /(copyright)/i;
		$term = 'copyright!';
		$this->set_match($context,$match,$term);
		$this->count($context,$term);
		$this->start_tag("line","$term","filpos",$filpos,"keyid",$this->{search_terms}{$term},"ulid",$this->{ids}{$context},"match",$match);
		$this->end_tag("line");
	    }
	    
	}
    }
}

#
# Recognize the several permutations of a copyright statement
#


sub copyright_statement {
    my $this = shift;
    my $context = shift;
    my $rv;
    my @contexts = ();
    my $symbol1;
    my $b4symbol1;
    my $date1;
    my $copyright1;
    my $copyright_by;

    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	print STDERR "\n\nDBG copyright_statement\ncontext=$context\n";
    }

    if ($context =~ /(.*)((copyright).+)/ims){ 
        # If the symbol precedes the word copyright, what precedes must be
	# concatenated before the copyright.  See note 59.
	my $prec = $1;
	$context = $2; 
	$copyright1 = $3;
	$context = $prec . $context if ($prec =~ /$this->{regexp_symbol}/) ;
    } 

    if ($context =~ /(copyright[\s\*\/\n\r]{1,6}by)/ims){$copyright_by = 1};

    $context =~	s/(\d\dyy|199x|yyyy)/1999/eims;
    my @datex = $this->copyright_date($context);
    $date1 = $datex[0];
    my @gmdate = gmtime();
    my $thisyear = $gmdate[5] + 1900;
    my $firstdate = $1 if ($date1 =~ /(\d\d\d\d)/ms);
    return 0 if $firstdate > $thisyear; 

    if ($context =~ /(.*)($this->{regexp_symbol})(.*)/ims) {
	$symbol1 = $2;
	$b4symbol1 = $1;
	$aftrsymbol = $3;
	if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	    print STDERR "copyright_statement symbol:$symbol1\tb4: $b4symbol1\taftr: $aftrsymbol\n";
	}
	$context = $aftrsymbol; # make the context what comes after the symbol, but see b4symbol below

    };

    if ($date1 && !($copyright1 && $symbol1 )) {
	return 0 if  $context =~ /(copyright.+[\n\r]{3,}.+$date1?)/imsg; # too many blank lines between copyright and date to be a statement
	return 0 if  $context =~ /(copyright.+(\n[\/*\s]{1,3}){3,}.+$date1?)/imsg;
	if  ($context =~ /(copyright.{92,}$date1)/imsg && $context !~ /(copyright.{1,91}$date1?)/is) {
	    return 0;
	};         # too many characters between copyright and date to be a statement
    }

    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	print STDERR "copyright_statement date: $date1\n";
    }
    
    unless ( ($copyright1 && $date1) || ($copyright1 && $symbol1 ) || ($symbol1 && $date1) || $copyright_by) {
	if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	    print STDERR "NOT  copyright_statement\tcopyright=$copyright1\tsymbol=$symbol1\tdate=$date1\n\n";
	}
	return 0;
    }

    for my $date (@datex) {
	$b4symbol1 =~ s/\Q$date\E//g;             #remove the dates from context
	$context =~ s/\Q$date\E//g;
    }
    $context =~ s/\(\)//g;                        #remove any parens that may have surrounded the date  

    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	print STDERR "copyright_statement: CONTEXTNOW=$context\n";
    }

    if($symbol1) {
	if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	    print STDERR "copyright_statement symbol=$symbol1\n";
	}
	if(! $date1) {
	    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
		print STDERR "copyright_statement NODATE\n";
	    }
	}
    }

    $holder = $context;
    $holder = $this->process_holder($holder);
    unless ($holder) { # if process_holder() fails to come up with a holder, try it again with what came before the symbol
	$holder = $b4symbol1;
	$holder = $this->process_holder($holder);
    }     
    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	print STDERR "HOLDER=\"$holder\"\n\n";
    }
    return $holder;
}



sub set_search_terms {
    my $this = shift;
    for my $term (@_) {
	$this->{search_terms}{$term} = $this->{search_term_order}++ unless $this->{search_terms}{$term};
    }
    return sort {uc($a) cmp uc($b)} keys %{$this->{search_terms}}
}

sub detect_mult {
    my $this = shift;
    my $context = shift;
    my $re = "copyright";
    @n_copyr = ($context =~ /$re/ig);
    my $re = $this->{regexp_symbol};
    @n_symbol = ($context =~ /$re/ig);
    return ($#n_copyr,$#n_symbol);
}

sub find_mult_statements {  # Recurses looking for copyright statements.
    my $this = shift;
    my $context = shift;
    my $regexp = shift;
    my $n_copyr = shift;
    my $n_symbol = shift;
    my $i = 0;
    my @contexts;
    my @crv;
    if (($this->{debug} & $SrcRptCopyright::DBG_FIND_MULT) == $SrcRptCopyright::DBG_FIND_MULT)  {
	print STDERR "find_mult ncopyr=$n_copyr\tnsymbol=$n_symbol\tregexp=$regexp\tcontext=$context\n\n";
    }
    # Flip to the short regexp
    $this->set_search_regexp($regexp);
    my $c = $context;
    my $x;
    while ($c =~s/((?:$regexp).+?)(?=(?:$regexp))/ /ims) {
	$x = $1;
	$i++;
	if (($this->{debug} & $SrcRptCopyright::DBG_FIND_MULT) == $SrcRptCopyright::DBG_FIND_MULT)  {
	    print STDERR $i," find_mult: $x\t\n";
	}
	push @crv , 
	$this->do_search_terms(" ".$x,$this->{regexp}, 100);
    }
    if ($c =~ /($regexp)/ims && $i > 0) {
	if (($this->{debug} & $SrcRptCopyright::DBG_FIND_MULT) == $SrcRptCopyright::DBG_FIND_MULT)  {
	    print STDERR 1+$i++," find_mult: remainder=$c\t\n" ;
	}
	push @crv , 
	$this->do_search_terms(" ".$c,$this->{regexp}, 100);
    }
    $i = 0;

    for (@crv) {
	my $context = $$_[$SrcRpt::CONTEXT];
	($n_copyr,$n_symbol) = $this->detect_mult($context);
	if ($n_copyr > 0 || $n_symbol > 0 ) {
	    if ($n_copyr < $n_symbol) {
		push @contexts , $this->find_mult_statements($context, $this->{regexp_symbol},$n_copyr, $n_symbol);
	    } else {
		push @contexts , $this->find_mult_statements($context, $this->{regexp_short}, $n_copyr, $n_symbol);
	    }
	} else {
	    $rv = $this->copyright_statement($context);
	    next unless $rv;
	    push @contexts, $rv;
	}
    }

    #Flop back to the long regexp
    $this->set_search_regexp($this->{regexp_long});
    return @contexts;
}

sub process_holder {
    my $this = shift;
    my $holder = shift;
    my $email;
    $holder =~ s/0x(\d|[a-f])+//gi;
    $holder =~ s/\&lt\;\S+\&gt\;//gicoms unless $context =~ /$this->{emailregexp}/gims;
    $holder =~ s/(^.*copyright\s*)//ims;
    # replace "all rights reserved by (someone) with (someone)
    if($holder =~ /all[\s-\*\#\n\r\\\/]+rights[\s-\*\#\n\r\\\/]+reserved[\s-\*\#\n\r\\\/]+by(.+)/i){$holder = $1};
    $holder =~ s/\s*by[\s\n]+/ /icoms; #replace "by" and "the" with space
    $holder =~ s/\s*the\s+/ /ims;
    $holder =~ s/\s*this.+//icoms; #remove "this" and everything after
    # remove any remaining "all rights " and everything after
    $holder =~ s/all[\s-\*\#\n\r\\\/]+rights[\s-\*\#\n\r\\\/]+reserved.*/ /i;
    $holder =~ s/[\s-\*\#\n\r\\\/]+licen[cs].*//icoms;
    if ($holder =~ s/^(.+\s\w\.\s[^.]+)/$1/icoms) {           #try to cope with middle initials

    } elsif ($holder =~ s/^(.*\w\.\w\.\s[^.]+)/$1/icoms) {   #initials not separated by whitespace
	
    } elsif ($holder =~ s/^(.*\w\.\s\w+\s[^.]+)/$1/icoms) {   #first initials separated by whitespace
	
    } elsif ($holder =~ /\&lt\;\s*a\s+href\s*=\\*\"*(.+?)\\*\"*\s*\&gt\;/i) { #make the holder a link target   
	$holder = $1;
    } elsif ($holder =~ /($this->{emailregexp})/igms) {  #spare an email address
	$email = $1; 
    } else {
	$holder  =~ s/\..+$//icoms;
    }
    $holder =~ s/\*//g;
    $holder =~ s/^[|,\s\/;:-]+/\n/;     #remove these leading chars
    $holder =~ s/[\r\n]\s*[\r\n].+//icoms;
    $holder =~ s/[\'\r\n*\/]/ /g;
    $holder =~ s/([A-Z]+_[A-Z]+_?)+/ /g;             #remove certain macro identifiers
    $holder =~ s/(\(\"|\"\))/ /g;                    #remove parens with quotes
    $holder =~ s/[,.\s\";]+$//icoms;                 #remove these trailing chars
    $holder =~ s/^\s*#//icoms;                       #remove initial comment chars in shell scripts
    $holder =~ s/[\*-;\/\}\+{\&\]=]+$//;             #remove trailing chars
    $holder =~ s/[\"\?\\].+$//;                      #remove these chars and everything after 
    $holder =~ s/\&lt\;(.+?)\&gt\;/$1/g;
    if ($holder =~ /\w\s?\&amp\;\s?\w/ims) {
    } else {    
	$holder =~ s/[;&#].+//icoms;
    }
    $holder =~ s/\s+$//;
    $holder =~ s/(.+?)\s\s\s\s.+/$1/;
    $holder =~ s/(.+?)====.+/$1/;
    $holder =~ s/\\n$//;
    $holder =~ s/[,\s\.\]-]+$//;                #remove trailing chars
    $holder =~ s/\s{2,}/ /g;
    $holder =~ s/^\s+//;
    $holder =~ s/^.$//;				#A holder consisiting of a single character is not enough to be comprehensible
    my @aa = $holder =~ /(\([^)]{1,8}\))/gm;	#A holder having more than on expression in parens is not a holder
    $holder = 0 if ($#aa > 0);
    $holder =~ s/.*\b(ibm)\b.*/IBM/i;
    $holder = $email unless $holder;
    return $holder;
 }

sub copyright_date {
    my $this = shift;
    my $context = shift;
    my $regexp_date = '(?:19|20)\d[\d\s*-/,\n\r]*';
    my $regexp_date_2 = '\d\d(?:\d\d)?\/\d\d\/\d\d(?:\d\d)?';
    my $regexp_date_3 = '\d\d[-/\s]\w\w\w[-/\s]\d\d(?:\d\d)?';
    my $regexp_date_4 = '\d\d\/\d\d(?:\d\d)';
    my $regexp_date_5 = '\d\d\d\d\s+and\s+\d\d\d\d';
    my $regexp_date_6 = '\w\w\w\.?\s{1,2}\d{1,2},\s{0,2}\d\d\d\d';
    my $i;
    my @aa;
    my @ab;
    @aa = ($context =~ /(?:$regexp_date_6)|(?:$regexp_date_5)|(?:$regexp_date_4)|(?:$regexp_date_3)|(?:$regexp_date_2)|(?:$regexp_date)/igcoms);
    for (@aa) {
	s/[*\s\/]+$//gms;
	s/\*\*.+//gms;
	s/^\d\d\d,.*//gms;
    };
    if (($this->{debug} & $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT) == $SrcRptCopyright::DBG_COPYRIGHT_STATEMENT)  {
	print STDERR "DATEX $#aa\n";
	for (@aa) {
	    print STDERR $i++;
	    print STDERR "\t$_\n";
	}
    }
    if ($aa[0]) {
	for (@aa) {
	    push @ab,$_ unless length == 3;
	}
	return @ab;
    } else {
	return 0;
    }
}

1;
