package org.lijma.demo.scheduler;

import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.annotation.SchedulingConfigurer;
import org.springframework.scheduling.config.CronTask;
import org.springframework.scheduling.config.ScheduledTaskRegistrar;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;

public class SchedulerRepository implements SchedulingConfigurer {

    private ScheduledTaskRegistrar taskRegistrar;
    private Map<String, ScheduledFuture<?>> tasks = new ConcurrentHashMap<>();


    @Override

    public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
            this.taskRegistrar = taskRegistrar;
    }

    public void addTask(String id, CronTask task){
        if (isTaskExisted(id)){
            // throw
        }

        TaskScheduler taskScheduler = taskRegistrar.getScheduler();
        ScheduledFuture future = taskScheduler.schedule(task.getRunnable(),task.getTrigger());
        tasks.put(id,future);
    }

    public boolean isTaskExisted(String taskId){
        return tasks.containsKey(taskId);
    }

    public void cancel(String taskId){
        ScheduledFuture future = tasks.get(taskId);
        if (future != null){
            future.cancel(true);
            tasks.remove(taskId);
        }
    }
}
