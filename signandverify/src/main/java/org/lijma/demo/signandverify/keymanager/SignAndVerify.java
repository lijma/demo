package org.lijma.demo.signandverify.keymanager;

import org.springframework.stereotype.Component;

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.Signature;
import java.security.SignatureException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Base64;

@Component
public class SignAndVerify{

    public String sign(String data, RSAPrivateKey priKey)
            throws NoSuchAlgorithmException, InvalidKeyException,
                    UnsupportedEncodingException, SignatureException {
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(priKey);
        signature.update(data.getBytes("UTF-8"));
        byte[] bytes = signature.sign();
        return Base64.getEncoder().encodeToString(bytes);
    }

    public boolean verify (String content, String digest, RSAPublicKey publicKey)
            throws NoSuchAlgorithmException,
            InvalidKeyException, UnsupportedEncodingException, SignatureException {
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initVerify(publicKey);
        signature.update(content.getBytes("UTF-8"));
        byte[] bytes = Base64.getDecoder().decode(digest);
        return signature.verify(bytes);
    }

}
