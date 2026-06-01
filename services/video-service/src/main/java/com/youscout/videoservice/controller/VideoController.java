package com.youscout.videoservice.controller;

import com.youscout.videoservice.dto.ApiResponse;
import com.youscout.videoservice.dto.SkillDTO;
import com.youscout.videoservice.dto.VideoDTO;
import com.youscout.videoservice.service.VideoService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/videos")
public class VideoController {

    private final VideoService videoService;

    public VideoController(VideoService videoService) {
        this.videoService = videoService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<VideoDTO>> uploadVideo(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "skillIds", required = false) String skillIdsJson,
            @RequestParam(value = "hashtags", required = false) String hashtagsCsv,
            @RequestHeader("X-User-Id") String userId,
            @RequestHeader(value = "X-User-Email", required = false) String email) throws Exception {

        List<String> skillIds = skillIdsJson != null ?
                Arrays.asList(skillIdsJson.replace("[", "").replace("]", "").replace("\"", "").split(",")) :
                List.of();
        List<String> hashtags = hashtagsCsv != null ?
                Arrays.asList(hashtagsCsv.split(",")) :
                List.of();

        // In production, fetch user details from user-service. For MVP, use headers.
        VideoDTO video = videoService.uploadVideo(file, description, skillIds, hashtags,
                userId, "user", "User", null);

        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(video, "Video uploaded"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<VideoDTO>> getVideo(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        UUID currentUserId = userId != null ? UUID.fromString(userId) : null;
        VideoDTO video = videoService.getVideoById(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok(video));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<Page<VideoDTO>>> getUserVideos(
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<VideoDTO> videos = videoService.getVideosByUser(userId, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.ok(videos));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteVideo(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") String userId) throws Exception {
        videoService.deleteVideo(id, UUID.fromString(userId));
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Map<String, Long>>> likeVideo(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") String userId) {
        long count = videoService.likeVideo(id, UUID.fromString(userId), "user");
        return ResponseEntity.ok(ApiResponse.ok(Map.of("likesCount", count)));
    }

    @DeleteMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Map<String, Long>>> unlikeVideo(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") String userId) {
        long count = videoService.unlikeVideo(id, UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(Map.of("likesCount", count)));
    }

    @PostMapping("/{id}/view")
    public ResponseEntity<Void> recordView(@PathVariable UUID id) {
        videoService.recordView(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/skills")
    public ResponseEntity<ApiResponse<List<SkillDTO>>> getSkills() {
        List<SkillDTO> skills = videoService.getAllSkills();
        return ResponseEntity.ok(ApiResponse.ok(skills));
    }

    @GetMapping("/trending")
    public ResponseEntity<ApiResponse<Page<VideoDTO>>> getTrending(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Page<VideoDTO> videos = videoService.getTrending(PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.ok(videos));
    }
}
