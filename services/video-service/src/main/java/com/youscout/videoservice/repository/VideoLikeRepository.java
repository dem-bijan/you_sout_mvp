package com.youscout.videoservice.repository;

import com.youscout.videoservice.domain.VideoLike;
import com.youscout.videoservice.domain.VideoLikeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface VideoLikeRepository extends JpaRepository<VideoLike, VideoLikeId> {
    boolean existsByVideoIdAndUserId(UUID videoId, UUID userId);
}
