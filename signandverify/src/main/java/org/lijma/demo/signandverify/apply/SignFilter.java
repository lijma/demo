package org.lijma.demo.signandverify.apply;


import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class SignFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // initialize filter
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        //拦截数据请求
        HttpServletRequest httpServletRequest = (HttpServletRequest)request;

        //ContentCachingRequestWrapper有bug, 需要自己实现request读取多次的缓存
        ReadableServletRequestWrapper wrapper = new ReadableServletRequestWrapper(httpServletRequest);

        HttpServletResponse httpServletResponse = (HttpServletResponse)response;
        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(httpServletResponse);

        try {
            chain.doFilter(wrapper,responseWrapper);
        }finally {
            responseWrapper.copyBodyToResponse();
        }

    }

    @Override
    public void destroy() {
        // destroying the filter
    }

}
