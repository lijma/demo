package com.nsn.oss.nbicf.engine.subscribe;

import com.nsn.oss.nbicf.sdk.message.CFProducer;
import org.springframework.integration.channel.PublishSubscribeChannel;
import org.springframework.integration.dsl.IntegrationFlow;
import org.springframework.integration.dsl.IntegrationFlows;
import org.springframework.integration.dsl.channel.MessageChannels;
import org.springframework.integration.dsl.context.IntegrationFlowContext;
import org.springframework.integration.jms.dsl.Jms;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.messaging.Message;

import javax.jms.ConnectionFactory;

public class CFProducerProxy implements CFProducer {

    private ConnectionFactory connectionFactory;
    private String topicName;
    private IntegrationFlowContext integrationFlowContext;
    private PublishSubscribeChannel publishSubscribeChannel;

    public CFProducerProxy(IntegrationFlowContext integrationFlowContext, ConnectionFactory connectionFactory, String topicName) {
        this.connectionFactory = connectionFactory;
        this.topicName = topicName;
        this.integrationFlowContext = integrationFlowContext;
        registryIntegrationFlowIntoContext();
    }

    private void registryIntegrationFlowIntoContext() {
        publishSubscribeChannel = MessageChannels.publishSubscribe().get();
        JmsTemplate jt = new JmsTemplate();
        jt.setPubSubDomain(true);
        jt.setConnectionFactory(connectionFactory);
        jt.setSessionTransacted(true);
        jt.setDefaultDestinationName(topicName);

        IntegrationFlow flow = IntegrationFlows.from(publishSubscribeChannel)
            .handle(Jms.outboundAdapter(jt))
            .get();

        integrationFlowContext.registration(flow).register();
    }

    @Override
    public void produce(Message t) {
        publishSubscribeChannel.send(t);
    }



}
