package org.lijma.demo.signandverify.apply;


import org.apache.commons.io.IOUtils;

import javax.servlet.ReadListener;
import javax.servlet.ServletInputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

public class ReadableServletRequestWrapper extends HttpServletRequestWrapper {

    private static final String ENCODING="UTF-8";
    private byte[] data;

    /**
     * Constructs a request object wrapping the given request.
     *
     * @param request The request to wrap
     * @throws IllegalArgumentException if the request is null
     */
    public ReadableServletRequestWrapper(HttpServletRequest request) throws IOException {
        super(request);
        data = IOUtils.toByteArray(request.getInputStream());
    }


    @Override
    public ServletInputStream getInputStream() throws IOException {
        return new MyServletInputStream(new ByteArrayInputStream(data));
    }


    @Override
    public BufferedReader getReader() throws IOException {
        InputStreamReader inputStreamReader = new InputStreamReader(getInputStream(), ENCODING);
        BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
        return bufferedReader;
    }

    static class MyServletInputStream extends ServletInputStream {

        private InputStream inputStream;

        public MyServletInputStream(InputStream inputStream) {
            this.inputStream = inputStream;
        }

        @Override
        public boolean isFinished() {
            return false;
        }

        @Override
        public boolean isReady() {
            return false;
        }

        @Override
        public void setReadListener(ReadListener listener) {
            throw new UnsupportedOperationException();
        }

        @Override
        public int read() throws IOException {
            return inputStream.read();
        }
    }

}
