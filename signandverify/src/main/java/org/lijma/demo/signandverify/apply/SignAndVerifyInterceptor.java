package org.lijma.demo.signandverify.apply;

import org.apache.commons.io.IOUtils;
import org.lijma.demo.signandverify.keymanager.SignAndVerify;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import static org.apache.commons.io.Charsets.UTF_8;

@Component
public class SignAndVerifyInterceptor extends HandlerInterceptorAdapter {

    @Autowired
    private SignAndVerify signAndVerify;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response, Object handler) throws Exception {
        HandlerMethod handlerMethod = (HandlerMethod) handler;
        SignAndVerifyTag signAndVerifyTag = handlerMethod.getMethodAnnotation(SignAndVerifyTag.class);

        //数据验签
        if (signAndVerifyTag != null && signAndVerifyTag.verify()){
            String digest = request.getHeader("digest");
            String data = IOUtils.toString(request.getReader());
            signAndVerify.verify(data,digest,null);
        }

        return super.preHandle(request, response, handler);

    }

    @Override
    public void postHandle(HttpServletRequest request,
                           HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {

        HandlerMethod handlerMethod = (HandlerMethod) handler;
        SignAndVerifyTag signAndVerifyTag = handlerMethod.getMethodAnnotation(SignAndVerifyTag.class);

        //数据加签
        if (signAndVerifyTag != null && signAndVerifyTag.sign()){
            ContentCachingResponseWrapper contentWrapper = (ContentCachingResponseWrapper) response;
            String data = IOUtils.toString(contentWrapper.getContentInputStream(),UTF_8);
            String digest = signAndVerify.sign(data,null);
            response.setHeader("digest",digest);
        }

        super.postHandle(request, response, handler, modelAndView);
    }
}
