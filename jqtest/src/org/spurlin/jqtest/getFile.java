package org.spurlin.jqtest;
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


import java.io.*;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class getFile
 */
public class getFile extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private InputStream in;


	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public getFile() {
		super();
		// TODO Auto-generated constructor stub
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		response.setContentType("text/xml");
		ServletOutputStream out = response.getOutputStream();

		String fn = request.getParameter("filename");
		BufferedInputStream bis = null;
		BufferedOutputStream bos = null;
		int i = 0;
		int j = 0;
		try {
			in = new FileInputStream(fn);
			bis = new BufferedInputStream(in);
			bos = new BufferedOutputStream(out);
			byte[] buff = new byte[2048];
			while (-1 != (i = bis.read(buff, 0, buff.length))) {
				bos.write(buff, 0, i);
				j += i;
			}
		} catch (final IOException e) {
			System.out.println("IOException.");
			throw e;
		} finally {
			if (bis != null)
				bis.close();
			if (bos != null)
				bos.close();
		}

		System.out.println(fn + "\t j=" + j);

	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
	}

}
