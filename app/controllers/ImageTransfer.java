package controllers;

import models.ScreenShot;
import play.mvc.Controller;

public class ImageTransfer extends Controller {
	
	public static void addScreenShot(ScreenShot sshot ) {
		   sshot.save();
		   System.err.println( sshot.getName() );
		   shots();
		}

	public static void shots()
	{
		render();
	}
}
