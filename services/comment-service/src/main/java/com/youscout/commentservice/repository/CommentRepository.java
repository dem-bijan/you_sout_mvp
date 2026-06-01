package com.youscout.commentservice.repository;

import com.youscout.commentservice.domain.Comment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface CommentRepository extends JpaRepository<Comment, UUID> {
    Page<Comment> findByVideoIdAndIsActiveTrueOrderByCreatedAtDesc(UUID videoId, Pageable pageable);
    long countByVideoIdAndIsActiveTrue(UUID videoId);
}
