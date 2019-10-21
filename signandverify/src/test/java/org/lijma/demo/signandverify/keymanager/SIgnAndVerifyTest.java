package org.lijma.demo.signandverify.keymanager;

import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;
import java.security.spec.InvalidKeySpecException;

import static org.junit.Assert.assertTrue;


public class SIgnAndVerifyTest {

    private static Logger logger = LoggerFactory.getLogger(SIgnAndVerifyTest.class);

    @Test
    public void shouldSignAndVerifySucceedGivenString()
            throws NoSuchAlgorithmException, IOException,
            InvalidKeySpecException, SignatureException, InvalidKeyException {

        String data = "test - abc";
        String content = new RecSignRequestDto(data).buildRequest();
        KeyManager keyManager = new KeyManager();

        String digest = SignAndVerify.sign(content,keyManager.getPrivateKey());
        logger.info("sign digest is \n {}",digest);

        boolean verified = SignAndVerify.verify(content,digest,keyManager.getPublicKey());
        assertTrue(verified);
    }

}
