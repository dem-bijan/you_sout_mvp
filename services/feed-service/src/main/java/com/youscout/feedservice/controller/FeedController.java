package com.youscout.feedservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/feed")
public class FeedController {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    public FeedController(StringRedisTemplate redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getFeed(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        String feedKey = "feed:" + userId;
        long start = (long) page * size;
        long end = start + size - 1;

        Set<ZSetOperations.TypedTuple<String>> entries =
                redisTemplate.opsForZSet().reverseRangeWithScores(feedKey, start, end);

        List<Map<String, Object>> videos = buildVideoList(entries);

        Map<String, Object> response = Map.of(
                "success", true,
                "data", Map.of(
                        "content", videos,
                        "page", page,
                        "size", size,
                        "hasMore", videos.size() == size
                ),
                "message", "OK",
                "timestamp", ZonedDateTime.now().toString()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/explore")
    public ResponseEntity<Map<String, Object>> getExploreFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        String feedKey = "feed:explore";
        long start = (long) page * size;
        long end = start + size - 1;

        Set<ZSetOperations.TypedTuple<String>> entries =
                redisTemplate.opsForZSet().reverseRangeWithScores(feedKey, start, end);

        List<Map<String, Object>> videos = buildVideoList(entries);

        Map<String, Object> response = Map.of(
                "success", true,
                "data", Map.of(
                        "content", videos,
                        "page", page,
                        "size", size,
                        "hasMore", videos.size() == size
                ),
                "message", "OK",
                "timestamp", ZonedDateTime.now().toString()
        );
        return ResponseEntity.ok(response);
    }

    private List<Map<String, Object>> buildVideoList(Set<ZSetOperations.TypedTuple<String>> entries) {
        if (entries == null || entries.isEmpty()) return List.of();

        return entries.stream()
                .map(tuple -> {
                    String videoId = tuple.getValue();
                    String metaKey = "video:meta:" + videoId;
                    Map<Object, Object> meta = redisTemplate.opsForHash().entries(metaKey);

                    Map<String, Object> video = new HashMap<>();
                    video.put("videoId", videoId);
                    video.put("score", tuple.getScore());
                    if (!meta.isEmpty()) {
                        video.putAll(meta.entrySet().stream()
                                .collect(Collectors.toMap(
                                        e -> e.getKey().toString(),
                                        Map.Entry::getValue
                                )));
                    }
                    return video;
                })
                .toList();
    }
}
