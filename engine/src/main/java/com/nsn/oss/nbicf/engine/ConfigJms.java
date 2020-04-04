package com.nsn.oss.nbicf.engine;

import org.apache.activemq.ActiveMQConnectionFactory;
import org.apache.activemq.pool.PooledConnectionFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.jms.ConnectionFactory;

@Configuration
public class ConfigJms {

    private static final String DEFAULT_BROKER_URL = "vm://embedded?broker.persistent=false&broker.useJmx=false";
    private static final Integer MAX_CONNECTIONS = 1000;
    private static final Boolean CREATE_ON_START = true;

    @Bean
    @Qualifier("jmsFactory")
    public ConnectionFactory connectionFactory(){
        ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory();
        connectionFactory.setTrustAllPackages(true);
        connectionFactory.setBrokerURL(DEFAULT_BROKER_URL);

        PooledConnectionFactory pooledConnectionFactory = new PooledConnectionFactory();
        pooledConnectionFactory.setConnectionFactory(connectionFactory);
        pooledConnectionFactory.setMaxConnections(MAX_CONNECTIONS);
        pooledConnectionFactory.setCreateConnectionOnStartup(CREATE_ON_START);

        return pooledConnectionFactory;
    }
}
