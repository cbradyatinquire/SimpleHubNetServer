package processes;

import org.nlogo.headless.HeadlessWorkspace;


public class RunHeadless { 
	public ServerSwitch mySwitch;
	private String modelName;
	private Integer portNumber;
	private HeadlessWorkspace workspace;
	private ModelRunner myRunner;
	private Thread th;
	
	private class ModelRunner implements Runnable {

		@Override
		public void run() {
			while( mySwitch.isRunning() ) {
		    	  workspace.command("go");
		      }
			System.err.println("Model " + modelName + ", which was running on port  #" + portNumber.toString() + " is no longer running.");
			
			workspace.command("hubnet-reset");  
			//TODO: How the #$#*$#*  to close the server.
		}
	}
	
	public RunHeadless( String mname, Integer port, ServerSwitch ss) {
		mySwitch = ss;
		modelName = mname;
		portNumber = port;
	    workspace = HeadlessWorkspace.newInstance( );
	    
	    try {
	      workspace.open(mname);
	      workspace.command("carefully [ run \"startup\" ] []");
	      workspace.command("hubnet-reset");
	      workspace.command("setup");
	      System.out.println("The model is open and set up...");
	      myRunner = new ModelRunner();
	      th = new Thread( myRunner );
	      th.start();
	    }
	    catch(Exception ex) {
	      ex.printStackTrace();
	    }
	  }

	
}
