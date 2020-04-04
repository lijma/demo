package com.nsn.oss.nbicf.engine;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.integration.config.EnableIntegration;
import org.springframework.integration.dsl.context.IntegrationFlowContext;

@Configuration
@EnableIntegration
public class ConfigIntegration {

    @Autowired
    private IntegrationFlowContext integrationFlowContext;

}
