package com.ibm.srcrpt;

/*

    Copyright ©, 2004-2011, International Business Machines

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

    Author Bill Spurlin, wj@spurlin.org

 */

import java.io.*;

import org.apache.commons.io.*;

import javax.servlet.Servlet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class GetFileByPathWithType extends HttpServlet implements Servlet  {

	private static final long serialVersionUID = 1;
	
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String fn = request.getParameter("fn");
		String type = request.getParameter("type");
		File file = new File(fn);
		FileReader ins = new FileReader(file);
		OutputStream outs = response.getOutputStream();
		response.setContentType("text/" + type);
		IOUtils.copy(ins, outs, "true");

	}
	
}
