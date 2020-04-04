package com.nsn.oss.nbicf.engine;

import com.nsn.oss.nbicf.sdk.message.CFProducer;
import com.nsn.oss.nbicf.sdk.message.ServiceType;

public interface ProducerFactory {
    public CFProducer createProducer(ServiceType serviceType);
}
