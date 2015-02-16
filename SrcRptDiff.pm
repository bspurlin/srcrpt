package SrcRptDiff;

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
# A derivation of SrcRpt (see below) to allow "diff scans"
# color-coded in the analyzer.
#


@ISA = SrcRpt;

%colors;
$COLOR = 4;

#
# SrcRptDiff methods
#

sub new {
    my $class = shift;
    my $object = shift;
    $object->{defaultcolor} = "#FFFFFF";
    $object->{colors} = \%colors;
    bless $object, $class;
    return $object;
}

sub set_colors {
    my $this = shift;
    my $context = "0";
    my $color = "0";
    for (@_) {
	$color = $$_[$SrcRptDiff::COLOR];
	$context = $$_[$SrcRpt::CONTEXT];
	$this->{colors}{$context} = $color;
    }
}

sub do_uniqlines {
    my $this = shift;
    my $color;
    my @keys = sort {$this->{ids}{$b} <=> $this->{ids}{$a}} keys %{$this->{ids}};
    for my $uniqline (@keys) {
	if (($this->{debug} & $SrcRpt::DBG_DO_UNIQLINES) == $SrcRpt::DBG_DO_UNIQLINES)  {
	    print STDERR "do_uniqlines: ",
	    "uniqline=$uniqline\tid=$this->{ids}{$uniqline}\tcolor=$this->{colors}{$uniqline}\n";
	}
	$color = $this->{colors}{$uniqline};
	$color = $this->colormap($color);
	$this->start_tag("uniqline",$uniqline,"id",$this->{ids}{$uniqline},"color",$color);
	$this->end_tag( "uniqline");
    }
}

sub colormap {
    my $this = shift;
    my $color = shift;
    if ($color == 0 || $color eq undef ) {
	$color = $this->{defaultcolor};
    } elsif ($color == 1) {
	$color = '#80FFFF';
    } elsif ($color == 2) {
	$color = '#FF80FF';
    } elsif ($color == 3) {
	$color = '#808080';
    } else {
	$color = $this->{defaultcolor};
    }
    return $color;
}

sub scan_n_tag {
    my $this = shift;
    my $fn1 = shift;
    my $top = shift;
    my $basefn = shift;
    my %dup_hits;
    undef %dup_hits;
    my @rv;
    my @rv1 = ();
    my @rv2 = ();
    my $f1 = 0 + $this->{found}{$basefn}{$this->{startdir}};
    my $f2 = 0 + $this->{found}{$basefn}{$this->{dir2}};
    my $color;
    my $newcolor;
    if ($top eq $this->{startdir}) {
	$color = 0x01;
    } elsif ($top eq $this->{dir2}) {
	$color = 0x02;
    } else {die "scan_n_tag: top=$top startdir=$this->{startdir} dir2=$this->{dir2}\n";}
    if ($f1 && $f2) {  # file is in both directories.
	# check to see if files are identical.
	my $otherdir = $top eq $this->{startdir} ? $this->{dir2} : $this->{startdir};
	my $fn2 = $otherdir . $this->{dirsep} . $basefn;
	open(FILE1, $fn1) or die "Cant open $fn1";
	binmode(FILE1);
	my $d1 = Digest::MD5->new->addfile(*FILE1)->hexdigest;
	open(FILE2, $fn2) or die "Cant open $fn2";
	binmode(FILE2);
	my $d2 = Digest::MD5->new->addfile(*FILE2)->hexdigest;
	my $ident = 0 + ($d1 eq $d2);
	if ($ident) { # Don't have to scan - we have done a comparison
	    # and the files are identical.
            # uncomment the 2 lines below if you want to tag identical files
	    # $this->start_tag("file","","name",$this->normalize($fn1),"color", $this->{defaultcolor}) ;
	    # $this->end_tag("file");
	} else { #The files differ;
	    $this->start_tag("file","","name",$this->normalize($fn1));
	    @rv1 = $this->scan_file($fn1, $this->{regexp});
	    @rv2 = $this->scan_file($fn2, $this->{regexp});
	    @rv = ();
	    undef %dup_hits;
	    my $context1;
	    my $context2;
	    HIT1: for my $hit1 (@rv1) {
		$context1 = $$hit1[$SrcRpt::CONTEXT]; 
		next HIT1 if $dup_hits{$context1};
	        HIT2: for my $hit2 (@rv2) {
		    $context2 = $$hit2[$SrcRpt::CONTEXT];
		    next HIT2 if $dup_hits{$context2};
		    if ($context1 eq $context2) {
			$dup_hits{$context1}++;
			next HIT1;
			# We are not interested in identical contexts,
			# but we will miss a difference consisting of 
			# a context that has moved within the file.
		    }else{
			
		    }
		}
	    }
	    
	    # Remember that rv1/fn1 is every file in both source trees,
	    # not just the first source tree.
	    
	    for (@rv1) {			
		if ($dup_hits{$$_[$SrcRpt::CONTEXT]}) {
		} else {
		    $newcolor = $color | $this->{colors}{$$_[$SrcRpt::CONTEXT]};
		    $$_[$SrcRptDiff::COLOR] = $newcolor; 
		    $this->{colors}{$$_[$SrcRpt::CONTEXT]} = $newcolor;
		    $newcolor = 0;
		    push @rv,$_;
		}
	    }	    
	    print "\n";
	    $this->process_lines(@rv);
	    $this->end_tag("file");
	}
    } else { #the file is in one but not the other - scan it.
	$this->start_tag(
			 "file",
			 "",
			 "name",
			 $this->normalize($fn1),
			 "color",
			 $this->colormap($color)
			 );
	@rv = $this->scan_file($fn1, $this->{regexp});
	for (@rv) {
	    $newcolor = $color | $this->{colors}{$$_[$SrcRpt::CONTEXT]};
	    $$_[$SrcRptDiff::COLOR] = $newcolor; 
	    $this->{colors}{$$_[$SrcRpt::CONTEXT]} = $newcolor;
	    $newcolor = 0;
	}
	$this->process_lines(@rv);
	$this->end_tag("file");
    }

}

1;
