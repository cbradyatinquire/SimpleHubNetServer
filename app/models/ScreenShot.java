package models;

import javax.persistence.Entity;

import play.db.jpa.Model;
import play.db.jpa.Blob;

@Entity
public class ScreenShot extends Model {

	public String title;
	public String name;
	public Blob scrimage; 
	
	
	public String getName() { return name; }
}
