package org.lijma.demo.ramp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
@EnableRabbit
@Slf4j
public class Main {

    public static void main(String[] args){

        ConfigurableApplicationContext ac = SpringApplication.run(Main.class,args);
        log.info("application start successfully");
        ac.getBean(MessageSender.class).sendMessage("test");

    }

}
