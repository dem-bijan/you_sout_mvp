package com.youscout.videoservice.service;

import com.youscout.videoservice.domain.*;
import com.youscout.videoservice.dto.SkillDTO;
import com.youscout.videoservice.dto.VideoDTO;
import com.youscout.videoservice.event.VideoEventProducer;
import com.youscout.videoservice.event.events.VideoLikedEvent;
import com.youscout.videoservice.event.events.VideoPublishedEvent;
import com.youscout.videoservice.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    private final VideoRepository videoRepository;
    private final SkillRepository skillRepository;
    private final HashtagRepository hashtagRepository;
    private final VideoLikeRepository videoLikeRepository;
    private final VideoStorageService videoStorageService;
    private final VideoEventProducer eventProducer;

    public VideoService(VideoRepository videoRepository,
                        SkillRepository skillRepository,
                        HashtagRepository hashtagRepository,
                        VideoLikeRepository videoLikeRepository,
                        VideoStorageService videoStorageService,
                        VideoEventProducer eventProducer) {
        this.videoRepository = videoRepository;
        this.skillRepository = skillRepository;
        this.hashtagRepository = hashtagRepository;
        this.videoLikeRepository = videoLikeRepository;
        this.videoStorageService = videoStorageService;
        this.eventProducer = eventProducer;
    }

    @Transactional
    public VideoDTO uploadVideo(MultipartFile file, String description, List<String> skillIds,
                                 List<String> hashtags, String userId, String username,
                                 String displayName, String avatarUrl) throws Exception {
        UUID videoId = UUID.randomUUID();
        String videoUrl = videoStorageService.uploadVideo(file, videoId.toString());
        String extension = getExtension(file.getOriginalFilename());
        String minioKey = "videos/" + videoId + "/original" + extension;

        Video video = new Video();
        video.setId(videoId);
        video.setUserId(UUID.fromString(userId));
        video.setUserUsername(username);
        video.setUserDisplayName(displayName);
        video.setUserAvatarUrl(avatarUrl);
        video.setDescription(description);
        video.setMinioKey(minioKey);
        video.setVideoUrl(videoUrl);

        // Link skills
        if (skillIds != null && !skillIds.isEmpty()) {
            Set<Skill> skills = skillIds.stream()
                    .map(UUID::fromString)
                    .map(id -> skillRepository.findById(id).orElse(null))
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
            video.setSkills(skills);
        }

        // Link/create hashtags
        if (hashtags != null && !hashtags.isEmpty()) {
            Set<Hashtag> hashtagEntities = hashtags.stream()
                    .map(tag -> tag.startsWith("#") ? tag.substring(1) : tag)
                    .map(tag -> hashtagRepository.findByName(tag)
                            .orElseGet(() -> {
                                Hashtag h = new Hashtag();
                                h.setName(tag);
                                return hashtagRepository.save(h);
                            }))
                    .collect(Collectors.toSet());
            video.setHashtags(hashtagEntities);
        }

        video = videoRepository.save(video);

        // Publish Kafka event
        eventProducer.publishVideoPublished(new VideoPublishedEvent(
                video.getId().toString(),
                userId,
                username,
                displayName,
                avatarUrl,
                videoUrl,
                video.getThumbnailUrl(),
                description,
                System.currentTimeMillis()
        ));

        return toVideoDTO(video, false);
    }

    public VideoDTO getVideoById(UUID videoId, UUID currentUserId) {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new RuntimeException("Video not found"));
        boolean liked = currentUserId != null && videoLikeRepository.existsByVideoIdAndUserId(videoId, currentUserId);
        return toVideoDTO(video, liked);
    }

    public Page<VideoDTO> getVideosByUser(UUID userId, Pageable pageable) {
        return videoRepository.findByUserIdAndIsActiveTrue(userId, pageable)
                .map(v -> toVideoDTO(v, false));
    }

    public Page<VideoDTO> getTrending(Pageable pageable) {
        return videoRepository.findByIsActiveTrueOrderByViewsCountDesc(pageable)
                .map(v -> toVideoDTO(v, false));
    }

    public Page<VideoDTO> getRecent(Pageable pageable) {
        return videoRepository.findByIsActiveTrueOrderByCreatedAtDesc(pageable)
                .map(v -> toVideoDTO(v, false));
    }

    @Transactional
    public void deleteVideo(UUID videoId, UUID userId) throws Exception {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new RuntimeException("Video not found"));
        if (!video.getUserId().equals(userId)) {
            throw new RuntimeException("Not authorized to delete this video");
        }
        video.setIsActive(false);
        videoRepository.save(video);
        videoStorageService.deleteVideo(video.getMinioKey());
    }

    @Transactional
    public long likeVideo(UUID videoId, UUID userId, String username) {
        if (videoLikeRepository.existsByVideoIdAndUserId(videoId, userId)) {
            throw new RuntimeException("Already liked");
        }
        VideoLike like = new VideoLike();
        like.setVideoId(videoId);
        like.setUserId(userId);
        videoLikeRepository.save(like);
        videoRepository.updateLikesCount(videoId, 1);

        Video video = videoRepository.findById(videoId).orElseThrow();

        eventProducer.publishVideoLiked(new VideoLikedEvent(
                videoId.toString(),
                video.getUserId().toString(),
                video.getThumbnailUrl(),
                userId.toString(),
                username,
                System.currentTimeMillis()
        ));

        return video.getLikesCount() + 1;
    }

    @Transactional
    public long unlikeVideo(UUID videoId, UUID userId) {
        VideoLikeId likeId = new VideoLikeId(videoId, userId);
        if (!videoLikeRepository.existsById(likeId)) {
            throw new RuntimeException("Not liked");
        }
        videoLikeRepository.deleteById(likeId);
        videoRepository.updateLikesCount(videoId, -1);

        Video video = videoRepository.findById(videoId).orElseThrow();
        return Math.max(0, video.getLikesCount() - 1);
    }

    @Transactional
    public void recordView(UUID videoId) {
        videoRepository.incrementViewsCount(videoId);
    }

    public List<SkillDTO> getAllSkills() {
        return skillRepository.findByIsActiveTrue().stream()
                .map(s -> new SkillDTO(s.getId().toString(), s.getName(), s.getIconName()))
                .toList();
    }

    private VideoDTO toVideoDTO(Video video, boolean isLikedByCurrentUser) {
        List<SkillDTO> skills = video.getSkills().stream()
                .map(s -> new SkillDTO(s.getId().toString(), s.getName(), s.getIconName()))
                .toList();
        List<String> hashtags = video.getHashtags().stream()
                .map(Hashtag::getName)
                .toList();

        return new VideoDTO(
                video.getId().toString(),
                video.getUserId().toString(),
                video.getUserUsername(),
                video.getUserDisplayName(),
                video.getUserAvatarUrl(),
                video.getTitle(),
                video.getDescription(),
                video.getVideoUrl(),
                video.getThumbnailUrl(),
                video.getDurationSeconds(),
                video.getViewsCount() != null ? video.getViewsCount() : 0,
                video.getLikesCount() != null ? video.getLikesCount() : 0,
                video.getCommentsCount() != null ? video.getCommentsCount() : 0,
                skills,
                hashtags,
                isLikedByCurrentUser,
                video.getCreatedAt() != null ? video.getCreatedAt().toString() : null
        );
    }

    private String getExtension(String filename) {
        if (filename == null) return ".mp4";
        int lastDot = filename.lastIndexOf('.');
        return lastDot >= 0 ? filename.substring(lastDot) : ".mp4";
    }
}
