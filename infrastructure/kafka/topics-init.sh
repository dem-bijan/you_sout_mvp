#!/bin/bash
# YouScout Kafka Topics Initialization
# Run this script after Kafka is healthy

set -e

BOOTSTRAP_SERVER=${BOOTSTRAP_SERVER:-kafka:9092}

echo "Creating YouScout Kafka topics..."

kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.video.published --partitions 3 --replication-factor 1 --if-not-exists
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.comment.created --partitions 3 --replication-factor 1 --if-not-exists
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.video.liked     --partitions 3 --replication-factor 1 --if-not-exists
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.user.followed   --partitions 3 --replication-factor 1 --if-not-exists
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.video.reported  --partitions 1 --replication-factor 1 --if-not-exists

# Dead Letter Topics
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.video.published.DLT --partitions 1 --replication-factor 1 --if-not-exists
kafka-topics.sh --create --bootstrap-server $BOOTSTRAP_SERVER --topic youscout.comment.created.DLT --partitions 1 --replication-factor 1 --if-not-exists

echo "All topics created successfully!"
kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list
