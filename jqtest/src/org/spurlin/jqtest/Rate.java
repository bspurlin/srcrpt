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
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.bind.*;

/**
 * Servlet implementation class Rate
 */
public class Rate extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private InputStream in;
	private OutputStream out;
	private JAXBContext ctxt;
	private ObjectFactory of;
	private Ratetest rt;
	private int n;
	private double average;

	/**
	 * @throws FileNotFoundException
	 * @throws JAXBException
	 * @see HttpServlet#HttpServlet()
	 */
	public Rate() throws FileNotFoundException, JAXBException {
		super();
		// TODO Auto-generated constructor stub
		System.out.println("constructor");
		ctxt = JAXBContext.newInstance("org.spurlin.jqtest");
		of = new ObjectFactory();
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {

	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		response.setContentType("text/xml");
		PrintWriter o = response.getWriter();
		int r = Integer.parseInt(request.getParameter("rating"));
		Unmarshaller um;
		Marshaller mar;
		try {
			String rp = this.getServletContext().getRealPath("ratetest.xml");
			um = ctxt.createUnmarshaller();
			mar = ctxt.createMarshaller();
			in = new FileInputStream(rp);
			rt = (Ratetest) um.unmarshal(in);
			in.close();
			out = new FileOutputStream(rp);
			n = rt.getNumber();
			System.out.println("Before: " + n + "in="  );
			n++;
			rt.setNumber(n);
			rt.setTotal( rt.getTotal() + r  );
			mar.marshal(rt, out);
			out.close();
		} catch (JAXBException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		o.println( "<ratings><average>" + rt.getTotal()/n + "</average><count>" + rt.getNumber() + "</count></ratings>"  );
	}

}
