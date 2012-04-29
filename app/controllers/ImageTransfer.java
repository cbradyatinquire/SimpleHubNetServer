package controllers;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import models.ScreenShot;
import play.db.jpa.JPABase;
import play.libs.MimeTypes;
import play.mvc.Controller;

public class ImageTransfer extends Controller {
	
	public static void addScreenShot(ScreenShot sshot ) {
		   sshot.save();
		   shots();
		}
	
	/*public static void addViewScreen(  String title, File attachment ) {
		String mimeType = MimeTypes.getContentType(attachment.getName());
		
		System.err.println("title = " + title + " and mime type = " + mimeType);
		renderJSON("title = " + title + " and mime type = " + mimeType);
	}*/
	
	
	public static void addViewScreen(  ScreenShot sshot, String aname ) {
		
		sshot.title=aname;
		sshot.name = sshot.scrimage.getFile().getName();
		sshot.save();
		renderJSON("RECEIEVED"+sshot.title);
	}

	public static void getImageByTitle( String title )
	{
		final ScreenShot screen = ScreenShot.findByTitle(title); 
		   response.setContentTypeIfNotSet(screen.scrimage.type());
		   java.io.InputStream binaryData = screen.scrimage.get();
		   renderBinary(binaryData);
	}
	
	
	public static void shots()
	{
			List<ScreenShot> allss = ScreenShot.getAll(); 
			
			if ( allss.size() > 0 )
			{
				ArrayList<String> titles = new ArrayList<String>();
				for ( ScreenShot s : allss)
				{
					titles.add( s.title );
				}
				render( titles );
			}
			else
			{
				render();
			}
	}
	
	
	public static void activity()
	{
		render();
	}
	
}
