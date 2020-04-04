package com.nsn.oss.nbicf.engine.subscribe;

import com.nsn.oss.nbicf.engine.ConsumerFactory;
import com.nsn.oss.nbicf.engine.ProducerFactory;
import com.nsn.oss.nbicf.sdk.message.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.integration.config.EnableIntegration;
import org.springframework.stereotype.Service;

@Service
public class SubscribeFactoryServiceImpl implements SubscribeFactoryService {

    @Autowired
    private ProducerFactory producerFactory;

    @Autowired
    private ConsumerFactory consumerFactory;

    @Override
    public CFProducer createCFProducer(ServiceType serviceType) {
        return producerFactory.createProducer(serviceType);
    }

    @Override
    public CFConsumer createCFConsumer(ServiceType serviceType) {
        return consumerFactory.createConsumer(serviceType);
    }

}
