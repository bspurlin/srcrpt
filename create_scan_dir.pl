use HTML::Parser ();
use Getopt::Std;
use ScanDir;


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



getopts('vf:F:d:D:c:C:n:o:');

$startdir = $opt_d?$opt_d:$opt_D;
die "No such directory $startdir $!" unless -d $startdir;

$fn = "2.out.xml";
$fn = $opt_f if $opt_f;
$fn = $opt_F if $opt_F;
die "No such file $fn $!" unless -f $fn;

$dir2 = 0;
$dir2 = $opt_c if $opt_c;
$dir2 = $opt_C if $opt_C;
$startdir =~ s/\\/\//g;
$dir2 =~ s/\\/\//g;

$chunks = ScanDir::init();
$create_scandir = ScanDir->new($startdir, $dir2, $fn);
if ($chunks) {
	$create_scandir = Chunked->new($create_scandir, $chunks);
}
$create_scandir->parse();
