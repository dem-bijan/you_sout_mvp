package com.youscout.videoservice.repository;

import com.youscout.videoservice.domain.Video;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface VideoRepository extends JpaRepository<Video, UUID> {
    Page<Video> findByUserIdAndIsActiveTrue(UUID userId, Pageable pageable);
    Page<Video> findByIsActiveTrueOrderByViewsCountDesc(Pageable pageable);
    Page<Video> findByIsActiveTrueOrderByCreatedAtDesc(Pageable pageable);

    @Modifying
    @Query("UPDATE Video v SET v.likesCount = v.likesCount + :delta WHERE v.id = :videoId")
    void updateLikesCount(UUID videoId, long delta);

    @Modifying
    @Query("UPDATE Video v SET v.commentsCount = v.commentsCount + :delta WHERE v.id = :videoId")
    void updateCommentsCount(UUID videoId, long delta);

    @Modifying
    @Query("UPDATE Video v SET v.viewsCount = v.viewsCount + 1 WHERE v.id = :videoId")
    void incrementViewsCount(UUID videoId);
}
