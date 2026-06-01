package com.youscout.videoservice.service;

import io.minio.*;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class VideoStorageService {

    @Value("${minio.endpoint:http://localhost:9000}")
    private String endpoint;

    @Value("${minio.access-key:youscout_minio}")
    private String accessKey;

    @Value("${minio.secret-key:youscout_minio_secret}")
    private String secretKey;

    @Value("${minio.bucket:youscout-videos}")
    private String bucket;

    @Value("${minio.cdn-url:http://localhost:9000/youscout-videos}")
    private String cdnUrl;

    private MinioClient minioClient;

    @PostConstruct
    public void init() throws Exception {
        minioClient = MinioClient.builder()
                .endpoint(endpoint)
                .credentials(accessKey, secretKey)
                .build();

        // Create bucket if not exists
        boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
        if (!found) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
            // Set bucket policy to public read
            String policy = """
                    {
                        "Version": "2012-10-17",
                        "Statement": [{
                            "Effect": "Allow",
                            "Principal": {"AWS": ["*"]},
                            "Action": ["s3:GetObject"],
                            "Resource": ["arn:aws:s3:::%s/*"]
                        }]
                    }
                    """.formatted(bucket);
            minioClient.setBucketPolicy(SetBucketPolicyArgs.builder()
                    .bucket(bucket)
                    .config(policy)
                    .build());
        }
    }

    public String uploadVideo(MultipartFile file, String videoId) throws Exception {
        String extension = getExtension(file.getOriginalFilename());
        String key = "videos/" + videoId + "/original" + extension;

        minioClient.putObject(
                PutObjectArgs.builder()
                        .bucket(bucket)
                        .object(key)
                        .stream(file.getInputStream(), file.getSize(), -1)
                        .contentType(file.getContentType())
                        .build()
        );

        return cdnUrl + "/" + key;
    }

    public void deleteVideo(String minioKey) throws Exception {
        minioClient.removeObject(
                RemoveObjectArgs.builder()
                        .bucket(bucket)
                        .object(minioKey)
                        .build()
        );
    }

    private String getExtension(String filename) {
        if (filename == null) return ".mp4";
        int lastDot = filename.lastIndexOf('.');
        return lastDot >= 0 ? filename.substring(lastDot) : ".mp4";
    }
}
