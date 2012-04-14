package controllers;

import play.*;
import play.data.validation.Required;
import play.mvc.*;

import processes.RunHeadless;
import processes.ServerSwitch;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.net.BindException;
import java.net.ServerSocket;
import java.util.*;

import javax.swing.SwingUtilities;

import models.*;

public class Application extends Controller {
	
	public static HashMap<String,Integer> teacherToPort = new HashMap<String,Integer>();
	public static HashMap<Integer,String> portToModelName = new HashMap<Integer,String>();	
	public static HashMap<Integer,ServerSwitch> portToServerSwitch = new HashMap<Integer,ServerSwitch>();
	
	public static int portPointer = 9172;
	
	
	private static List<String> getAllModelsInPath(String path)
	{
		Vector<String> retn = new Vector<String>();
		File folder = new File(path);
		File[] listOfFiles = folder.listFiles(); 

		for (File f : listOfFiles) 
		{
			if (f.isFile()) 
			{
				String test = f.getName().toLowerCase();
				if ( test.endsWith(".nlogo") )
				{
					retn.add(f.getName());
				}
			}
		}
		return retn;
	}

	
    public static void teacher() {
    	List<String> models = getAllModelsInPath(".");
    	for (String model: models)
    		System.err.println(model);
        render(models);
    }
    
    public static void student() {
    	//get the teachers from the database and determine which have active sessions
    	List<Teacher> teachers = Teacher.findAll();
    	ArrayList<String>activeteachers = new ArrayList<String>();
    	ArrayList<String>inactiveteachers = new ArrayList<String>();
    	
    	for (Teacher t : teachers)
    	{
    		if ( teacherToPort.containsKey(t.username) )
    			activeteachers.add( t.username );
    		else
    			inactiveteachers.add(t.username);
    	}
    	
    	render(activeteachers, inactiveteachers );
    }
    
    public static void index() {
    	render();
    }
    
    private static Integer getNextOpenPort()
    {
       	
    	portPointer++;
    	//TODO: figure out how to give Headless the port i want it to use.  then change this...
    	ServerSocket s = null;
    	while ( s == null && portPointer < 9183)  //right now, hubnet will fail to load > 9183
    	{
	    	try { 
	    		s = new ServerSocket(portPointer);
	    	}
	        catch (Exception ioe)
	        {
	        	ioe.printStackTrace();
	        	portPointer++;
	        }
    	}
        try {
			if (s != null )
			{ s.close(); }
		} catch (IOException e) {
			e.printStackTrace();
		}
    	
    	return portPointer;
    }
    
    public static void teacherLogin( @Required String uname, @Required String pass, @Required String modelname )
    {
    	
    	if(validation.hasErrors()) {
            flash.error("ERROR: Please enter all fields:  Username, Password, and Model");
            teacher();
        }
    	//authenticate the teacher; get back their real name
    	//if there is a session for this teacher, kill it.
    	
    	Teacher t = Teacher.connect(uname, pass);
    	if (t == null)
    	{
    		flash.error("ERROR: Login Failed");
    		teacher();
    	}
    
    	String teacherhandle = uname;  //will be the return.
    	
    	if ( teacherToPort.containsKey(teacherhandle) )
		{
			Integer toRemove = teacherToPort.get(teacherhandle);
			teacherToPort.remove(teacherhandle);
			try {
				portToServerSwitch.get(toRemove).setRunning(false);  
			}
			catch (Exception e) { 
				e.printStackTrace();
			}
			portToModelName.remove(toRemove);
		}
    	
    	Integer portToUse = getNextOpenPort();
    	
    	ServerSwitch switcher = new ServerSwitch();
    	
    	RunHeadless rh = new RunHeadless( modelname, portToUse, switcher );
    	teacherToPort.put(teacherhandle, portToUse);
    	portToServerSwitch.put(portToUse, switcher);
    	portToModelName.put(portToUse, modelname);
    	teacherclient( teacherhandle, modelname, portToUse.toString() );
    }
    

    public static void teacherclient( String teachername, String modelname, String port)
    {
    	render(teachername, modelname, port);
    }
    
    public static void studentclient( String studentname, String teachername, String model, String port)
    {
    	render(studentname, teachername, model, port );
    }
    
    public static void studentLogin( @Required String studentname,  @Required String teachername)
    {
    	if(validation.hasErrors()) {
            flash.error("ERROR: Please indicate both Username and Teacher");
            student();
        }
    	
    	Integer port = teacherToPort.get(teachername);
    	String model = portToModelName.get(port);
    	studentclient( studentname, teachername, model, port.toString());
    }
    
    
}