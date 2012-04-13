package processes;

public class ServerSwitch {
	private boolean isRunning = true;
	public void setRunning( boolean running ) { isRunning = running; }
	public boolean isRunning() { return isRunning; }
}
