package UsefulCommands;



#
#    Copyright ©, 2004-2008, International Business Machines
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
# Set some useful system commands, depending 
# whether we are on Windows or Unix.
#

if ($^O =~ /Win/) {
    if (-e 'c:\windows\system32\cmd') {
	$syscmd = 'c:\windows\system32\cmd';
    } elsif (-e $ENV{ComSpec}) {
	$syscmd = $ENV{ComSpec};
    } else {
	$syscmd = 'cmd';
    }
    $my_hostname = $ENV{computername};
    $my_username = $ENV{username};
    $dirsep='\\';
    $tmpdir = $ENV{tmp};
    $dircmd = "$syscmd /c dir /b";
    $copycmd = "$syscmd /c copy";
    $xcopycmd = "$syscmd /c xcopy /E /O /K";
    $xrmdircmd = "$syscmd /c RD /S /Q";
    $delcmd = "$syscmd /c DEL";
    $mkdircmd = "$syscmd /c MKDIR";
} else {
    $my_hostname = `uname -n`;
    chomp $my_hostname;
    $my_username = $ENV{LOGNAME} ? $ENV{LOGNAME} : $ENV{USERNAME}; # Cygwin - USERNAME
    chomp $my_username;
    $dirsep='/';
    $tmpdir='/tmp';
    $dircmd = "ls -A";
    $copycmd = "cp";
    $xcopycmd = "cp -pr";
    $xrmdircmd = "rmdir -rf";
    $delcmd = "rm -f";
    $mkdircmd = "mkdir -p";
}

$my_username = $my_username ? $my_username : "username_not_available";
$my_hostname = $my_hostname ? $my_hostname : "hostname_not_available";


1;
