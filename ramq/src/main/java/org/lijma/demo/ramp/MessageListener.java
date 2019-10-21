package org.lijma.demo.ramp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.Exchange;
import org.springframework.amqp.rabbit.annotation.Queue;
import org.springframework.amqp.rabbit.annotation.QueueBinding;
import org.springframework.amqp.rabbit.annotation.RabbitHandler;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

@Component
@RabbitListener(
        containerFactory = "rabbitListenerContainerFactory",
        bindings = {@QueueBinding(
                value = @Queue(name = "${listeners.demo.queue}", durable = "true"),
                exchange = @Exchange(name = "${listeners.demo.exchange}"),
                key = "${listeners.demo.route}"
        )}
)
@Slf4j
public class MessageListener {


    @RabbitHandler
    public void process(String message) {
        log.info("message received : {}", message);
    }

    @RabbitHandler
    public void process(byte[] msg) {
        log.info("message received : {}", new String(msg, StandardCharsets.UTF_8));
    }

}
