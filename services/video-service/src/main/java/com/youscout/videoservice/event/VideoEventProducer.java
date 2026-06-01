package com.youscout.videoservice.event;

import com.youscout.videoservice.event.events.VideoLikedEvent;
import com.youscout.videoservice.event.events.VideoPublishedEvent;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
public class VideoEventProducer {

    private static final String VIDEO_PUBLISHED_TOPIC = "youscout.video.published";
    private static final String VIDEO_LIKED_TOPIC = "youscout.video.liked";

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public VideoEventProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publishVideoPublished(VideoPublishedEvent event) {
        kafkaTemplate.send(VIDEO_PUBLISHED_TOPIC, event.userId(), event);
    }

    public void publishVideoLiked(VideoLikedEvent event) {
        kafkaTemplate.send(VIDEO_LIKED_TOPIC, event.videoOwnerId(), event);
    }
}
