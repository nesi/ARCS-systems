package net.sf.webdav;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

public class WebdavListener implements HttpSessionListener {

	public void sessionCreated(HttpSessionEvent arg0) {
		// TODO Auto-generated method stub
		
	}

	public void sessionDestroyed(HttpSessionEvent event) {
		HttpSession session = event.getSession();
		System.out.println("session destroyed: "+session.getId());
		Map credentials = (Map)session.getAttribute(WebdavServlet.CREDENTIALS);
		List creds= new ArrayList(credentials.values());
		SRBStorage srb=null;
		for (int i=0;i<creds.size();i++){
			srb=(SRBStorage)creds.get(i);
			srb.disconnect();
		}
		
		
	}

}
