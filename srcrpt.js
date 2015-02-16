/*

    Copyright ©, 2004-2015, International Business Machines

    This file is part of SrcRpt.
  
    SrcRpt is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 2.0.

    SrcRpt is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.

*/


function processPath(P) {
    	    var tmpArray = P.split("\\");
            var x = tmpArray.join("/");
	    return x;
}

function uqfn(s) {
    var RXp = /[^\\\/]+$/gm;
    var aa;
    if (aa = s.match(RXp)) {
	return aa[0];
    } else {
	return s;
    }
}

// processFilename is a generic File menu function.  
// Specific HTML implementation (e. g., a.html for "Save...", z4.html for "Open"), 
// must have an exitDialog function.

function processFilename() {
    var s = document.fileform.filename.value;
    var S = uqfn(s);
    s = processPath(s);
    exitDialog(s,CWD);
    div1.innerHTML="";
    close();
}

function fileuritostring (L) {
    var RXp = /^file:\/+/;
    L = L.replace(RXp,'');
    RXp = /\%20/g;
    L = L.replace(RXp,' ');
    return L;
}

function currdir() {
    var L = window.location.href;
    L = fileuritostring(L);
    RXp = /\/[^\/]+$/;
    L = L.replace(RXp,'');
    return L ;
}

function menuDialog (F,h,w) {
    var rv = window.showModelessDialog(
				       F,
				       window,
       'dialogHeight:' + h + 'px;dialogWidth:' + w + 'px;resizable:yes'
    );
    return rv;
}
