import models.Teacher;
import play.jobs.Job;
import play.jobs.OnApplicationStart;
import play.test.Fixtures;



@OnApplicationStart
public class Bootstrap extends Job {
 
    public void doJob() {
        //Check if the (teacher) database is empty
        if(Teacher.count() == 0) {
        	Fixtures.deleteDatabase();
            Fixtures.loadModels("seeddata.yml");
        }
    }
 
}