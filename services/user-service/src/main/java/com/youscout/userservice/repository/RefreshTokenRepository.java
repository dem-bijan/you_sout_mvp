package com.youscout.userservice.repository;

import com.youscout.userservice.domain.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {
    Optional<RefreshToken> findByTokenHashAndUsedFalse(String tokenHash);
    void deleteByUserId(UUID userId);
}
