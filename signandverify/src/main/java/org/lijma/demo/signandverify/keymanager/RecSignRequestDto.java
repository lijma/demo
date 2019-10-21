package org.lijma.demo.signandverify.keymanager;

public class RecSignRequestDto {

    private static final String ENCODING = "UTF-8";
    private static final String METHOD="01";
    private static final String VERSION = "0.0.1";
    private String bizContent;

    public RecSignRequestDto(String bizContent) {
        String compressed = bizContent.replaceAll("\\s*","");
        this.bizContent = compressed;
    }

    public String buildRequest(){
        return new StringBuilder()
                .append("biz_content=")
                .append(bizContent)
                .append("&encoding=")
                .append(ENCODING)
                .append("&signMethod=")
                .append(METHOD)
                .append("&version=")
                .append(VERSION)
                .toString();
    }


}
