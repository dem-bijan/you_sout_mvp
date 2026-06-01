package com.youscout.videoservice.domain;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "hashtags")
public class Hashtag {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(unique = true, nullable = false, length = 100)
    private String name;

    @Column(name = "video_count")
    private Integer videoCount = 0;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Integer getVideoCount() { return videoCount; }
    public void setVideoCount(Integer videoCount) { this.videoCount = videoCount; }
}
