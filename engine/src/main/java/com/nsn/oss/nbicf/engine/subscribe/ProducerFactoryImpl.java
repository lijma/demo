package com.nsn.oss.nbicf.engine.subscribe;

import com.nsn.oss.nbicf.engine.ProducerFactory;
import com.nsn.oss.nbicf.sdk.message.CFProducer;
import com.nsn.oss.nbicf.sdk.message.ServiceType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.integration.dsl.context.IntegrationFlowContext;
import org.springframework.stereotype.Service;

import javax.jms.ConnectionFactory;

@Service
public class ProducerFactoryImpl implements ProducerFactory {

    @Autowired
    private ConnectionFactory jmsFactory;

    @Autowired
    private IntegrationFlowContext integrationFlowContext;

    @Override
    public CFProducer createProducer(ServiceType serviceType) {
        return new CFProducerProxy(integrationFlowContext,jmsFactory,serviceType.toString());
    }

}
