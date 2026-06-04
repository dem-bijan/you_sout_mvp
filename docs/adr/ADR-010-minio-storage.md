# ADR-010: MinIO for Video Object Storage

**Status:** Accepted

## Context
Videos are binary large objects (BLOBs) that cannot be stored in a relational database. They range from a few MB to several GB. They must be served with high throughput to millions of concurrent users, support range requests (video seeking), and be geographically distributed close to users. The storage layer must be decoupled from the application — video files and their metadata (title, uploader, skills) are stored separately.

## Decision
**MinIO** is deployed as an S3-compatible object storage layer for all video content and generated thumbnails. MinIO's S3 API compatibility means the system can migrate to AWS S3 in production with zero application code changes (only configuration changes). Video upload flow:
1. Client uploads video to `video-service` via multipart HTTP
2. `video-service` streams the file directly to MinIO
3. MinIO returns a storage key
4. `video-service` stores the MinIO key + metadata in PostgreSQL
5. Video URLs served to clients point to the CDN (Cloudflare), which caches from MinIO

Thumbnail generation is performed asynchronously by a background worker triggered by a `video.uploaded` internal event.

## Consequences
- ✅ S3 API compatibility — zero-change migration to AWS S3 for production
- ✅ High-throughput streaming — MinIO serves video range requests natively
- ✅ Presigned URLs — clients can download directly from MinIO/CDN without proxying through video-service
- ✅ Bucket-level ACL — private buckets with presigned URL access for content control
- ❌ MinIO adds infrastructure complexity — mitigated by Docker Compose and Helm chart availability

## Governance
- Raw uploaded videos go to `youscout-raw` bucket; CDN-cached versions go to `youscout-cdn` bucket
- Presigned URLs expire in 1 hour; CDN cached versions have 24-hour TTL
- Buckets configured with versioning enabled for accidental deletion recovery
