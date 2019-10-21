package org.lijma.demo.ramp;

import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class Config {

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory){
         RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
         return rabbitTemplate;
    }

}
