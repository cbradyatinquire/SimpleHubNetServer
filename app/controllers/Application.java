package controllers;

import play.*;
import play.mvc.*;

import processes.RunHeadless;
import processes.ServerSwitch;

import java.io.File;
import java.lang.reflect.InvocationTargetException;
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
    	//here get the teachers from the database that have active sessions
    	ArrayList<String>activeteachers = new ArrayList<String>();
    	activeteachers.add("Uri");
    	activeteachers.add("Corey");
    	//here get the teachers from the database that DO NOT have active sessions
    	ArrayList<String>inactiveteachers = new ArrayList<String>();
    	activeteachers.add("Paulo");
    	activeteachers.add("Pratim");
    	render(activeteachers, inactiveteachers );
    }
    
    public static void index() {
    	render();
    }
    
    private static Integer getNextOpenPort()
    {
       	//TODO: really do stuff instad of this
    	portPointer++;
    	
    	
    	return portPointer;
    }
    
    public static void teacherLogin( String uname, String pass, String modelname )
    {
    	//authenticate the teacher; get back their real name
    	//if there is a session for this teacher, kill it.
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
    	//change to  use  this argument :)
    	final String args[] = { modelname, portToUse.toString() };
    	ServerSwitch switcher = new ServerSwitch();
    	//Thread nthread =  new Thread( new Runnable() { public void run() {RunHeadless.main(args); } });
    	//nthread.start();
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
    
    public static void studentLogin( String studentname, String teachername)
    {
    	Integer port = teacherToPort.get(teachername);
    	String model = portToModelName.get(port);
    	studentclient( studentname, teachername, model, port.toString());
    }
    
    
}