package com.nsn.oss.nbicf.engine;
import com.nsn.oss.nbicf.engine.subscribe.SubscribeFactoryServiceImpl;
import com.nsn.oss.nbicf.sdk.message.CFConsumer;
import com.nsn.oss.nbicf.sdk.message.CFProducer;
import com.nsn.oss.nbicf.sdk.message.ServiceType;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageHandler;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;
import static junit.framework.TestCase.assertEquals;


@RunWith(SpringRunner.class)
@ContextConfiguration(classes = TestSubscribeFactoryImpl.Config.class)
public class TestSubscribeFactoryImpl {

    @Autowired
    private SubscribeFactoryServiceImpl subscribeFactory;
    private static FakeProducer fp = new FakeProducer();

    @Test
    public void ProducersCouldProduceMessage(){
        CFProducer cfProducer = subscribeFactory.createCFProducer(ServiceType.NOTIFICATION_FM);
        cfProducer.produce(MessageBuilder.withPayload("hello test").build());
        assertEquals(fp.message.getPayload(), "hello test");
    }

    @Configuration
    static class Config {
        @Bean
        SubscribeFactoryServiceImpl getSubscribeFactoryImpl() {
            return new SubscribeFactoryServiceImpl();
        }

        @Bean
        ProducerFactory getProduerFactory(){
            return new ProducerFactory() {
                @Override
                public CFProducer createProducer(ServiceType serviceType) {
                    return fp;
                }
            };
        }

        @Bean
        ConsumerFactory getConsumerFactory(){
            return new ConsumerFactory() {
                @Override
                public CFConsumer createConsumer(ServiceType serviceType) {
                    return null;
                }
            };
        }

    }

    static class FakeProducer implements CFProducer{
        public Message message;

        @Override
        public void produce(Message t) {
            message = t;
        }
    }

    static class FakeConsumer implements CFConsumer{
        public Message message;

        public void subscribe(MessageHandler handler) {
            handler.handleMessage(message);
        }
    }



}
