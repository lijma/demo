package com.nsn.oss.nbicf.engine;

import com.nsn.oss.nbicf.sdk.message.CFConsumer;
import com.nsn.oss.nbicf.sdk.message.ServiceType;

public interface ConsumerFactory {
    public CFConsumer createConsumer(ServiceType serviceType);
}
