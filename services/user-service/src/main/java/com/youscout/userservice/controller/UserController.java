package com.youscout.userservice.controller;

import com.youscout.userservice.dto.*;
import com.youscout.userservice.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = userService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response, "Registration successful"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = userService.login(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Login successful"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");
        AuthResponse response = userService.refreshToken(refreshToken);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader("X-User-Id") String userId) {
        userService.logout(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(null, "Logged out"));
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserDTO>> getOwnProfile(@RequestHeader("X-User-Id") String userId) {
        UserDTO profile = userService.getProfile(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(profile));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDTO>> getUserById(@PathVariable UUID id) {
        UserDTO user = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.ok(user));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserDTO>> updateProfile(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody UpdateProfileRequest request) {
        UserDTO updated = userService.updateProfile(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Profile updated"));
    }

    @DeleteMapping("/account")
    public ResponseEntity<Void> deleteAccount(@RequestHeader("X-User-Id") String userId) {
        userService.deleteAccount(UUID.fromString(userId));
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/stats")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> getUserStats(@PathVariable UUID id) {
        UserDTO user = userService.getUserById(id);
        Map<String, Integer> stats = Map.of(
                "followerCount", user.followerCount(),
                "followingCount", user.followingCount(),
                "videoCount", user.videoCount()
        );
        return ResponseEntity.ok(ApiResponse.ok(stats));
    }

    @GetMapping("/check-username/{username}")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkUsername(@PathVariable String username) {
        boolean available = userService.isUsernameAvailable(username);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("available", available)));
    }

    // Internal endpoint for social-service to update follower counts
    @PutMapping("/{id}/follower-count")
    public ResponseEntity<Void> updateFollowerCount(@PathVariable UUID id, @RequestParam int delta) {
        userService.updateFollowerCount(id, delta);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/following-count")
    public ResponseEntity<Void> updateFollowingCount(@PathVariable UUID id, @RequestParam int delta) {
        userService.updateFollowingCount(id, delta);
        return ResponseEntity.ok().build();
    }
}
