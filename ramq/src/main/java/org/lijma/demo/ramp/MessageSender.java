package org.lijma.demo.ramp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.connection.CorrelationData;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class MessageSender implements RabbitTemplate.ConfirmCallback {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Value("${listeners.demo.exchange}")
    private String exchange;

    @Value("${listeners.demo.route}")
    private String route;

    @Override
    public void confirm(CorrelationData correlationData, boolean ack, String cause) {
        log.info("message confirmed, correlation data : {}, ack:{}",correlationData,ack);
    }


    public void sendMessage(String message){
        rabbitTemplate.convertAndSend(exchange, route, message);
    }

}
