package com.nsn.oss.nbicf.engine.subscribe;

import com.nsn.oss.nbicf.engine.ConsumerFactory;
import com.nsn.oss.nbicf.sdk.message.CFConsumer;
import com.nsn.oss.nbicf.sdk.message.ServiceType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.integration.config.EnableIntegration;
import org.springframework.integration.dsl.context.IntegrationFlowContext;
import org.springframework.stereotype.Service;

import javax.jms.ConnectionFactory;

@Service
public class ConsumerFactoryImpl implements ConsumerFactory {

    @Autowired
    private ConnectionFactory jmsFactory;

    @Autowired
    private IntegrationFlowContext integrationFlowContext;

    @Override
    public CFConsumer createConsumer(ServiceType serviceType) {
        return new CFConsumerProxy(integrationFlowContext,jmsFactory,serviceType.toString());
    }


}
