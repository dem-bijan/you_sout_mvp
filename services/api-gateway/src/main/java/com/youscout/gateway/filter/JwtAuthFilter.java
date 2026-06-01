package com.youscout.gateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.List;

@Component
public class JwtAuthFilter implements GlobalFilter, Ordered {

    private static final List<String> PUBLIC_PATHS = List.of(
            "/api/users/register",
            "/api/users/login",
            "/api/feed/explore"
    );

    // Paths that are public when accessed with GET
    private static final List<String> PUBLIC_GET_PREFIXES = List.of(
            "/api/videos/"
    );

    @Value("${jwt.public-key:}")
    private String publicKeyStr;

    private PublicKey publicKey;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        String method = exchange.getRequest().getMethod().name();

        // Check public paths
        boolean isPublic = PUBLIC_PATHS.stream().anyMatch(path::startsWith);
        if (!isPublic && "GET".equalsIgnoreCase(method)) {
            isPublic = PUBLIC_GET_PREFIXES.stream().anyMatch(path::startsWith);
        }
        if (isPublic) {
            return chain.filter(exchange);
        }

        // Check actuator endpoints
        if (path.startsWith("/actuator")) {
            return chain.filter(exchange);
        }

        String authHeader = exchange.getRequest().getHeaders().getFirst("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        try {
            String token = authHeader.substring(7);
            PublicKey key = getPublicKey();
            Claims claims = Jwts.parser()
                    .verifyWith(java.security.interfaces.RSAPublicKey.class.cast(key))
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                    .header("X-User-Id", claims.getSubject())
                    .header("X-User-Email", claims.get("email", String.class))
                    .header("X-User-Role", claims.get("role", String.class))
                    .build();

            return chain.filter(exchange.mutate().request(mutatedRequest).build());
        } catch (Exception e) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }

    private PublicKey getPublicKey() throws Exception {
        if (publicKey == null) {
            String keyContent = new String(Base64.getDecoder().decode(publicKeyStr))
                    .replace("-----BEGIN PUBLIC KEY-----", "")
                    .replace("-----END PUBLIC KEY-----", "")
                    .replaceAll("\\s", "");
            byte[] keyBytes = Base64.getDecoder().decode(keyContent);
            X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
            KeyFactory kf = KeyFactory.getInstance("RSA");
            publicKey = kf.generatePublic(spec);
        }
        return publicKey;
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
