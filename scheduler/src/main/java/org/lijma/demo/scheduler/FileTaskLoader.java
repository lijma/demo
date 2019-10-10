package org.lijma.demo.scheduler;

import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.List;

public class FileTaskLoader {

    public void load() throws FileNotFoundException {
        File file = new File("tasks.yaml");
        FileInputStream inputStream = new FileInputStream(file);
        Yaml yaml = new Yaml(new Constructor(DemoTask.class));
        Tasks tasks = yaml.load(inputStream);
    }

    class Tasks{
        List<DemoTask> tasks;
        public List<DemoTask> getTasks() {
            return tasks;
        }
        public void setTasks(List<DemoTask> tasks) {
            this.tasks = tasks;
        }
    }


}
