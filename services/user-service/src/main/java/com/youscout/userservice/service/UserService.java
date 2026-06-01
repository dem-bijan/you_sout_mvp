package com.youscout.userservice.service;

import com.youscout.userservice.domain.RefreshToken;
import com.youscout.userservice.domain.User;
import com.youscout.userservice.dto.*;
import com.youscout.userservice.exception.BadRequestException;
import com.youscout.userservice.exception.NotFoundException;
import com.youscout.userservice.repository.RefreshTokenRepository;
import com.youscout.userservice.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.time.ZonedDateTime;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository,
                       RefreshTokenRepository refreshTokenRepository,
                       JwtService jwtService,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BadRequestException("Email already in use");
        }
        if (userRepository.existsByUsername(request.username())) {
            throw new BadRequestException("Username already taken");
        }

        User user = new User();
        user.setUsername(request.username());
        user.setEmail(request.email());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.displayName());
        user = userRepository.save(user);

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new BadRequestException("Invalid email or password"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BadRequestException("Invalid email or password");
        }

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse refreshToken(String rawRefreshToken) {
        String tokenHash = hashToken(rawRefreshToken);
        RefreshToken storedToken = refreshTokenRepository.findByTokenHashAndUsedFalse(tokenHash)
                .orElseThrow(() -> new BadRequestException("Invalid refresh token"));

        if (storedToken.getExpiresAt().isBefore(ZonedDateTime.now())) {
            throw new BadRequestException("Refresh token expired");
        }

        storedToken.setUsed(true);
        refreshTokenRepository.save(storedToken);

        User user = userRepository.findById(storedToken.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));

        return generateAuthResponse(user);
    }

    @Transactional
    public void logout(UUID userId) {
        refreshTokenRepository.deleteByUserId(userId);
    }

    public UserDTO getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        return toUserDTO(user, false);
    }

    public UserDTO getUserById(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        return toUserDTO(user, false);
    }

    @Transactional
    public UserDTO updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));

        if (request.displayName() != null) user.setDisplayName(request.displayName());
        if (request.bio() != null) user.setBio(request.bio());
        if (request.avatarUrl() != null) user.setAvatarUrl(request.avatarUrl());

        user = userRepository.save(user);
        return toUserDTO(user, false);
    }

    @Transactional
    public void deleteAccount(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        user.setIsActive(false);
        userRepository.save(user);
        refreshTokenRepository.deleteByUserId(userId);
    }

    public boolean isUsernameAvailable(String username) {
        return !userRepository.existsByUsername(username);
    }

    @Transactional
    public void updateFollowerCount(UUID userId, int delta) {
        userRepository.updateFollowerCount(userId, delta);
    }

    @Transactional
    public void updateFollowingCount(UUID userId, int delta) {
        userRepository.updateFollowingCount(userId, delta);
    }

    private AuthResponse generateAuthResponse(User user) {
        String accessToken = jwtService.generateAccessToken(user.getId(), user.getEmail(), "USER");
        String rawRefreshToken = jwtService.generateRefreshToken();

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUserId(user.getId());
        refreshToken.setTokenHash(hashToken(rawRefreshToken));
        refreshToken.setExpiresAt(ZonedDateTime.now().plusSeconds(jwtService.getRefreshTokenExpiry() / 1000));
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
                accessToken,
                rawRefreshToken,
                jwtService.getAccessTokenExpiry() / 1000,
                toUserDTO(user, false)
        );
    }

    private UserDTO toUserDTO(User user, boolean isFollowedByCurrentUser) {
        return new UserDTO(
                user.getId().toString(),
                user.getUsername(),
                user.getDisplayName(),
                user.getBio(),
                user.getAvatarUrl(),
                user.getFollowerCount() != null ? user.getFollowerCount() : 0,
                user.getFollowingCount() != null ? user.getFollowingCount() : 0,
                user.getVideoCount() != null ? user.getVideoCount() : 0,
                isFollowedByCurrentUser
        );
    }

    private String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes());
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new RuntimeException("Failed to hash token", e);
        }
    }
}
