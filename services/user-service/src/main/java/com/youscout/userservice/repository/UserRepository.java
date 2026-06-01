package com.youscout.userservice.repository;

import com.youscout.userservice.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);

    @Modifying
    @Query("UPDATE User u SET u.followerCount = u.followerCount + :delta WHERE u.id = :userId")
    void updateFollowerCount(UUID userId, int delta);

    @Modifying
    @Query("UPDATE User u SET u.followingCount = u.followingCount + :delta WHERE u.id = :userId")
    void updateFollowingCount(UUID userId, int delta);

    @Modifying
    @Query("UPDATE User u SET u.videoCount = u.videoCount + :delta WHERE u.id = :userId")
    void updateVideoCount(UUID userId, int delta);
}
