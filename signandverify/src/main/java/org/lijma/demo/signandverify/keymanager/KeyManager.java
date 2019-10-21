package org.lijma.demo.signandverify.keymanager;

import sun.misc.BASE64Decoder;

import java.io.IOException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

public class KeyManager {

    private static final String PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwHXDfcrYmPYKmMkc+iPy" +
            "aQD8lkFJ2hjMAqjxV6gFg1W0JCAQdExdACV+YpSbB4V4nLmqdO3yu3iWXHBi8aCm" +
            "GXzlN9Ems3m7qE2w/8eC5suTlMc5lHRp61a4nihVtEq45BdBRxUzsYLC5BaP+2lR" +
            "gO9vM4DarFLokofJGDbpnU3NhgHwQOyqZ716m0/7JgTtCUX5AgaDrmxDycBP9EOP" +
            "TGZDtC7kYwRkevfu42AbKn8ePWVP7IAnpNmpgKS/UXdQDDcjfqeV5WJcS/jis2Nq" +
            "57ZubtXux4Wqf+hoqjXEHZ9vb5y4eUcCtz7RJ1zlyqu/scYYLstuwQaAz61G7kjk" +
            "jwIDAQAB";

    private static final String PRIVATE_KEY = "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDAdcN9ytiY9gqY" +
            "yRz6I/JpAPyWQUnaGMwCqPFXqAWDVbQkIBB0TF0AJX5ilJsHhXicuap07fK7eJZc" +
            "cGLxoKYZfOU30SazebuoTbD/x4Lmy5OUxzmUdGnrVrieKFW0SrjkF0FHFTOxgsLk" +
            "Fo/7aVGA728zgNqsUuiSh8kYNumdTc2GAfBA7KpnvXqbT/smBO0JRfkCBoOubEPJ" +
            "wE/0Q49MZkO0LuRjBGR69+7jYBsqfx49ZU/sgCek2amApL9Rd1AMNyN+p5XlYlxL" +
            "+OKzY2rntm5u1e7Hhap/6GiqNcQdn29vnLh5RwK3PtEnXOXKq7+xxhguy27BBoDP" +
            "rUbuSOSPAgMBAAECggEAPO7L5u6q5rq3HipGN1fcLqx2S+f9xsQlCw6L4nG61Rr0" +
            "Pp+8NeXbZ+l2+yULdDUou434zq5rNDl4eWnHmbKAA//L3oEkXJxE8oMub7ytz/5S" +
            "Cj+NFlhJFI5PQxuIDt29bdGDBEtNI30/0NDn4vQ0LrsfnNHF6dsR8Rp2a2kvS3LC" +
            "efQKwaizLHbwrQf9+q8qISiolQo7UrXL49Zl2F1EVPCto09zYl+hWmlI9BXtLEUO" +
            "+L3dCwgrcTbDkCJjI/nNFPO6BgTjew0xYK63tZ6/EffEiaTUqN+0gDuO2MobOBeB" +
            "ASTi+6kd0hQEj0s9Qabxc81Izv1ho4bCFwqL7YLIOQKBgQDxjwG7F01lE6yWtIDy" +
            "Hw9x6zC/PO3wbmgYmBBjPeC7WLBy17J66l7Nlq0TiTHxGZKYcP4yVpaqZfgYiEQR" +
            "r4NCxL8z+X2CE6e4TWfO9sPTNKFpOMgGCwYQaQ8PdxpYWdTzwiSZAa7pTKUeoQJ9" +
            "Dlqci0cNZodiv5Ml/KcesnNB+wKBgQDL91CxEFxaFCqWpElg0M5PbMO8mu1c/Q6J" +
            "m8o7qndZhSAGrfVggPZhs88KhAHnqS8CRB6xyk8GUMGZ90FpF0NiVwqVsNRVurK6" +
            "CBDU6Ge3xPY39uEn2Tqg0G+GYHyVCGSxosLgf/hqaaCvYxsrnWIc72kcLOdxYBcP" +
            "MfgRTyJ3fQKBgQCuqhU6TxMrbxpwrnw+lq74VHOfFFOIcozam7ndyLRjQzHzGHx5" +
            "3FZImhbz9VQjXbZee/WSOIIhHDJUqtNtZlenQ9RtpI1YLRYtcesJ/+yBH6FHEEOx" +
            "+u6blxvItvpZwDr3Nv53lHwBPeZ3Sz0dZ++lGiB6VBS5FoU0Bohg7e/hWQKBgEag" +
            "M4OsO55BX2HcL0Bj7RxZeAmFx+0r/u2tUUCJzVvlGerWL6Ij5ax9G5LzlMlHruxk" +
            "9A/yEp0IN5F9qVufX4jcxOCCY3Pv+tUp19IxS0C55dwJE3u932wx4HwyStE8H8nW" +
            "pw4focAPJUG12oGmtIN6bvX/ooCCmll7nv83XKLtAoGAPHnKBPWMNpxkGmX19CXs" +
            "pJjkuqSV1Sbocln+AYF1VaRkLlLjGKnrrcnEreuMGxsAkQJnQIPJZ7laZAN8iiMS" +
            "q3HmJe+nBj3Ra7NoUZsLQBmp6K0WCG1S+qBlxGoDg20olsSkftuWbBf9DEVk9F62" +
            "CDNUpSVzxJT2mKbILROHUJY=";


    private RSAPrivateKey privateKey;
    private RSAPublicKey publicKey;

    public RSAPrivateKey getPrivateKey()
            throws NoSuchAlgorithmException, IOException, InvalidKeySpecException {
        if (privateKey == null){
            loadPrivateKey();
        }
        return privateKey;
    }

    public RSAPublicKey getPublicKey()
            throws NoSuchAlgorithmException, IOException, InvalidKeySpecException {
        if (publicKey == null){
            loadPubKey();
        }
        return publicKey;
    }

    private void loadPubKey() throws IOException,
            NoSuchAlgorithmException, InvalidKeySpecException {
        BASE64Decoder decoder = new BASE64Decoder();
        byte[] bytes = decoder.decodeBuffer(PUBLIC_KEY);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(bytes);
        publicKey = (RSAPublicKey)keyFactory.generatePublic(keySpec);
    }

    private void loadPrivateKey()
            throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {
        BASE64Decoder base64Decoder = new BASE64Decoder();
        byte[] buffer = base64Decoder.decodeBuffer(PRIVATE_KEY);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(buffer);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        this.privateKey = (RSAPrivateKey) keyFactory
                .generatePrivate(keySpec);
    }


}
