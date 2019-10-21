package org.lijma.demo.signandverify;

import org.lijma.demo.signandverify.apply.SignAndVerifyInterceptor;
import org.lijma.demo.signandverify.apply.SignFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurationSupport;

import javax.servlet.Filter;

@Configuration
@ConditionalOnProperty("sign.enabled")
public class SignConfig extends WebMvcConfigurationSupport {

    @Autowired
    private SignAndVerifyInterceptor signAndVerifyInterceptor;

    @Override
    protected void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(signAndVerifyInterceptor);
        super.addInterceptors(registry);
    }

    @Bean
    public FilterRegistrationBean<Filter> filterFilterRegistrationBean(){
        FilterRegistrationBean filterRegistrationBean = new FilterRegistrationBean();
        filterRegistrationBean.setFilter(signAndVerifyFilter());
        filterRegistrationBean.addUrlPatterns("/api/*");
        filterRegistrationBean.setName("SignAndVerifyFilter");
        filterRegistrationBean.setOrder(1);
        return filterRegistrationBean;
    }

    @Bean(name = "SignAndVerifyFilter")
    public Filter signAndVerifyFilter(){
        return new SignFilter();
    }
}
