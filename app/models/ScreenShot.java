package models;

import java.io.File;
import java.util.List;

import javax.persistence.Entity;

import play.db.jpa.Model;
import play.db.jpa.Blob;

@Entity
public class ScreenShot extends Model {

	public String title;
	public String name;
	public Blob scrimage; 
	
	
	
	public String getName() { return name; }
	
	public static List<ScreenShot>getAll()
	{
		return  ScreenShot.find("order by title desc").fetch();	
	}
	
	
	public static ScreenShot findByTitle( String atitle)
	{
		if ( ScreenShot.count() == 0 )
			return null;
		ScreenShot s = find( "byTitle", atitle ).first();
		if ( s != null )
			return s;
		else
			return getAll().get(0);
		
	}
}
