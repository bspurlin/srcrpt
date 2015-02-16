package org.spurlin.jqtest;

/*

    Copyright © 2011, International Business Machines

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


import javax.xml.bind.*;

import java.io.*;

public class Test {
	public static void main(String[] args) throws IOException, JAXBException {
		ObjectFactory of = new ObjectFactory();
		Ratetest rt = of.createRatetest();
		rt.setNumber(1);
		rt.setTotal(2.2);
		System.out.println("Here\t" + rt.getTotal());

		FileOutputStream out = new FileOutputStream("ratetest.xml");

		JAXBContext ctxt = JAXBContext.newInstance("org.spurlin.jqtest");
		Marshaller m = ctxt.createMarshaller();
		m.setProperty( Marshaller.JAXB_FORMATTED_OUTPUT, true );
		m.marshal(rt, out);
		
	}
}
