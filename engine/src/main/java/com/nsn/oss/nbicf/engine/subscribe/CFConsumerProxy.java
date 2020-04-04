package com.nsn.oss.nbicf.engine.subscribe;

import com.nsn.oss.nbicf.sdk.message.CFConsumer;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.integration.channel.PublishSubscribeChannel;
import org.springframework.integration.dsl.IntegrationFlow;
import org.springframework.integration.dsl.IntegrationFlows;
import org.springframework.integration.dsl.channel.MessageChannels;
import org.springframework.integration.dsl.context.IntegrationFlowContext;
import org.springframework.integration.jms.dsl.Jms;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.listener.DefaultMessageListenerContainer;
import org.springframework.messaging.MessageHandler;

import javax.jms.ConnectionFactory;

public class CFConsumerProxy implements CFConsumer {

    private ConnectionFactory connectionFactory;
    private String topicName;
    private IntegrationFlowContext integrationFlowContext;
    private PublishSubscribeChannel publishSubscribeChannel;

    public CFConsumerProxy(IntegrationFlowContext integrationFlowContext, ConnectionFactory connectionFactory, String topicName) {
        this.connectionFactory = connectionFactory;
        this.topicName = topicName;
        this.integrationFlowContext = integrationFlowContext;
        publishSubscribeChannel = new PublishSubscribeChannel();
    }

    private void registryIntegrationFlowIntoContext(DefaultMessageListenerContainer listener, MessageHandler handler) {
        JmsTemplate jt = new JmsTemplate();
        jt.setPubSubDomain(true);
        jt.setConnectionFactory(connectionFactory);
        jt.setSessionTransacted(false);
        jt.setDefaultDestinationName(topicName);

        IntegrationFlow flow = IntegrationFlows.from(
            Jms.messageDrivenChannelAdapter(listener))
            .channel(MessageChannels.publishSubscribe().get())
            .handle(handler)
            .get();
        this.integrationFlowContext.registration(flow).register();
    }

    @Override
    public void subscribe(MessageHandler handler) {
        DefaultMessageListenerContainer container = new DefaultMessageListenerContainer();
        container.setSessionTransacted(true);
        container.setDestinationName(topicName);
        container.setPubSubDomain(true);
        container.setConnectionFactory(this.connectionFactory);
        registryIntegrationFlowIntoContext(container,handler);
    }
}
