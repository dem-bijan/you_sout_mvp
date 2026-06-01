package com.youscout.socialservice.repository;

import com.youscout.socialservice.domain.Follow;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Follow.FollowId> {
    boolean existsByFollowerIdAndFollowingId(UUID followerId, UUID followingId);
    Page<Follow> findByFollowingId(UUID followingId, Pageable pageable); // followers of user
    Page<Follow> findByFollowerId(UUID followerId, Pageable pageable);   // following by user

    @Query("SELECT f.followerId FROM Follow f WHERE f.followingId = :userId")
    List<UUID> findFollowerIdsByFollowingId(UUID userId);
}
