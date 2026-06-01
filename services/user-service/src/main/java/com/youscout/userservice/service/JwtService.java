package com.youscout.userservice.service;

import io.jsonwebtoken.Jwts;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    private static final long ACCESS_TOKEN_EXPIRY = 3600_000; // 1 hour
    private static final long REFRESH_TOKEN_EXPIRY = 604800_000; // 7 days

    @Value("${jwt.private-key:}")
    private String privateKeyStr;

    @Value("${jwt.public-key:}")
    private String publicKeyStr;

    private PrivateKey privateKey;
    private PublicKey publicKey;

    @PostConstruct
    public void init() throws Exception {
        if (privateKeyStr != null && !privateKeyStr.isEmpty()) {
            this.privateKey = loadPrivateKey(privateKeyStr);
        }
        if (publicKeyStr != null && !publicKeyStr.isEmpty()) {
            this.publicKey = loadPublicKey(publicKeyStr);
        }
    }

    public String generateAccessToken(UUID userId, String email, String role) {
        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + ACCESS_TOKEN_EXPIRY))
                .signWith(privateKey)
                .compact();
    }

    public String generateRefreshToken() {
        return UUID.randomUUID().toString();
    }

    public long getAccessTokenExpiry() {
        return ACCESS_TOKEN_EXPIRY;
    }

    public long getRefreshTokenExpiry() {
        return REFRESH_TOKEN_EXPIRY;
    }

    private PrivateKey loadPrivateKey(String base64Key) throws Exception {
        String keyContent = new String(Base64.getDecoder().decode(base64Key))
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replace("-----BEGIN RSA PRIVATE KEY-----", "")
                .replace("-----END RSA PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] keyBytes = Base64.getDecoder().decode(keyContent);
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(spec);
    }

    private PublicKey loadPublicKey(String base64Key) throws Exception {
        String keyContent = new String(Base64.getDecoder().decode(base64Key))
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");
        byte[] keyBytes = Base64.getDecoder().decode(keyContent);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(spec);
    }
}
