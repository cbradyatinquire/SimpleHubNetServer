package models;

import javax.persistence.Entity;

import play.data.validation.Required;
import play.db.jpa.Model;

@Entity
public class Teacher extends Model {
	
	@Required
	public String username;
	
	@Required
	public String password;
	
	public static Teacher connect(String uname, String pass) {
		return find("byUsernameAndPassword", uname, pass).first();
	}
	
	public String toString() {
		return username;
	}


}
