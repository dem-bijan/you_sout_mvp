#!/bin/bash
# ─── YouScout Demo Seed Script ───────────────────────────────────
# Creates demo users, videos, comments, follows for a professor demo
set -e

BASE_URL="http://localhost:8080/api"

echo "════════════════════════════════════════════════════════"
echo "  YouScout Demo Seed Script"
echo "════════════════════════════════════════════════════════"

# ─── 1. Register Demo Users ─────────────────────────────────────
echo ""
echo "▶ Step 1: Creating demo users..."

# User 1: The main demo account (the one you'll log in as)
RESP1=$(curl -s "$BASE_URL/users/register" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"taha_scout","email":"taha@youscout.com","password":"demo123456","displayName":"Taha (Demo)"}')
echo "  ✓ User 1 (taha_scout): $(echo $RESP1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','FAILED'))" 2>/dev/null || echo "Already exists or created")"
USER1_ID=$(echo $RESP1 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null || echo "")
USER1_TOKEN=$(echo $RESP1 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

# User 2: A football player
RESP2=$(curl -s "$BASE_URL/users/register" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"kylian_mbp","email":"kylian@youscout.com","password":"demo123456","displayName":"Kylian M."}')
echo "  ✓ User 2 (kylian_mbp): $(echo $RESP2 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','FAILED'))" 2>/dev/null || echo "Already exists or created")"
USER2_ID=$(echo $RESP2 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null || echo "")
USER2_TOKEN=$(echo $RESP2 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

# User 3: A coach
RESP3=$(curl -s "$BASE_URL/users/register" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"coach_ahmed","email":"ahmed@youscout.com","password":"demo123456","displayName":"Coach Ahmed"}')
echo "  ✓ User 3 (coach_ahmed): $(echo $RESP3 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','FAILED'))" 2>/dev/null || echo "Already exists or created")"
USER3_ID=$(echo $RESP3 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null || echo "")
USER3_TOKEN=$(echo $RESP3 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

# User 4: Another player  
RESP4=$(curl -s "$BASE_URL/users/register" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"neymar_fan","email":"neymar@youscout.com","password":"demo123456","displayName":"Neymar Jr Fan"}')
echo "  ✓ User 4 (neymar_fan): $(echo $RESP4 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','FAILED'))" 2>/dev/null || echo "Already exists or created")"
USER4_ID=$(echo $RESP4 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null || echo "")
USER4_TOKEN=$(echo $RESP4 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

# User 5: A scout
RESP5=$(curl -s "$BASE_URL/users/register" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"scout_maria","email":"maria@youscout.com","password":"demo123456","displayName":"Maria Scout"}')
echo "  ✓ User 5 (scout_maria): $(echo $RESP5 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','FAILED'))" 2>/dev/null || echo "Already exists or created")"
USER5_ID=$(echo $RESP5 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null || echo "")
USER5_TOKEN=$(echo $RESP5 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

# Check we got IDs
if [ -z "$USER1_ID" ]; then
  echo "❌ Failed to get User 1 ID. Login to get tokens..."
  RESP1=$(curl -s "$BASE_URL/users/login" -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"taha@youscout.com","password":"demo123456"}')
  USER1_ID=$(echo $RESP1 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])" 2>/dev/null)
  USER1_TOKEN=$(echo $RESP1 | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null)
  echo "  → Logged in as taha_scout: $USER1_ID"
fi

echo ""
echo "  User IDs:"
echo "    taha_scout:   $USER1_ID"
echo "    kylian_mbp:   $USER2_ID"
echo "    coach_ahmed:  $USER3_ID"
echo "    neymar_fan:   $USER4_ID"
echo "    scout_maria:  $USER5_ID"

# ─── 2. Create Follow Relationships ─────────────────────────────
echo ""
echo "▶ Step 2: Creating follow relationships..."

# taha follows kylian, coach_ahmed, neymar
if [ -n "$USER1_TOKEN" ] && [ -n "$USER2_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER2_ID" -X POST \
    -H "Authorization: Bearer $USER1_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ taha_scout → follows → kylian_mbp"
fi
if [ -n "$USER1_TOKEN" ] && [ -n "$USER3_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER3_ID" -X POST \
    -H "Authorization: Bearer $USER1_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ taha_scout → follows → coach_ahmed"
fi
if [ -n "$USER1_TOKEN" ] && [ -n "$USER4_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER4_ID" -X POST \
    -H "Authorization: Bearer $USER1_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ taha_scout → follows → neymar_fan"
fi

# kylian follows taha, coach_ahmed
if [ -n "$USER2_TOKEN" ] && [ -n "$USER1_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER1_ID" -X POST \
    -H "Authorization: Bearer $USER2_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ kylian_mbp → follows → taha_scout"
fi
if [ -n "$USER2_TOKEN" ] && [ -n "$USER3_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER3_ID" -X POST \
    -H "Authorization: Bearer $USER2_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ kylian_mbp → follows → coach_ahmed"
fi

# coach follows taha, scout_maria
if [ -n "$USER3_TOKEN" ] && [ -n "$USER1_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER1_ID" -X POST \
    -H "Authorization: Bearer $USER3_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ coach_ahmed → follows → taha_scout"
fi
if [ -n "$USER3_TOKEN" ] && [ -n "$USER5_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER5_ID" -X POST \
    -H "Authorization: Bearer $USER3_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ coach_ahmed → follows → scout_maria"
fi

# scout_maria follows taha, kylian, neymar
if [ -n "$USER5_TOKEN" ] && [ -n "$USER1_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER1_ID" -X POST \
    -H "Authorization: Bearer $USER5_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ scout_maria → follows → taha_scout"
fi
if [ -n "$USER5_TOKEN" ] && [ -n "$USER2_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER2_ID" -X POST \
    -H "Authorization: Bearer $USER5_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ scout_maria → follows → kylian_mbp"
fi
if [ -n "$USER5_TOKEN" ] && [ -n "$USER4_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER4_ID" -X POST \
    -H "Authorization: Bearer $USER5_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ scout_maria → follows → neymar_fan"
fi

# neymar_fan follows taha
if [ -n "$USER4_TOKEN" ] && [ -n "$USER1_ID" ]; then
  curl -s "$BASE_URL/social/follow/$USER1_ID" -X POST \
    -H "Authorization: Bearer $USER4_TOKEN" -H "Content-Type: application/json" > /dev/null
  echo "  ✓ neymar_fan → follows → taha_scout"
fi

# ─── 3. Download sample videos & upload ──────────────────────────
echo ""
echo "▶ Step 3: Downloading sample football videos..."

TMPDIR=$(mktemp -d)

# Download small public domain football/sports clips
# Using Pixabay free stock video API (small clips)
curl -sL -o "$TMPDIR/video1.mp4" "https://cdn.pixabay.com/video/2019/06/21/24584-343947432_large.mp4" 2>/dev/null &
curl -sL -o "$TMPDIR/video2.mp4" "https://cdn.pixabay.com/video/2020/06/01/40454-425951057_large.mp4" 2>/dev/null &
curl -sL -o "$TMPDIR/video3.mp4" "https://cdn.pixabay.com/video/2016/01/25/2106-153172076_large.mp4" 2>/dev/null &
wait
echo "  ✓ Downloaded 3 sample video clips"

# Check if files have content; if not, create minimal test videos with ffmpeg
for f in "$TMPDIR/video1.mp4" "$TMPDIR/video2.mp4" "$TMPDIR/video3.mp4"; do
  if [ ! -s "$f" ]; then
    echo "  ⚠ Download failed for $f, creating placeholder..."
    if command -v ffmpeg &>/dev/null; then
      ffmpeg -y -f lavfi -i testsrc=duration=3:size=480x854:rate=30 \
        -f lavfi -i sine=frequency=440:duration=3 \
        -vcodec libx264 -pix_fmt yuv420p -preset ultrafast \
        "$f" 2>/dev/null
    fi
  fi
done

echo ""
echo "▶ Step 4: Uploading videos to the platform..."

# Upload video 1 (by kylian)
if [ -s "$TMPDIR/video1.mp4" ] && [ -n "$USER2_TOKEN" ]; then
  VID1_RESP=$(curl -s "$BASE_URL/videos" -X POST \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -F "file=@$TMPDIR/video1.mp4" \
    -F "description=Amazing dribbling skills 🔥 Watch this nutmeg combo! #football #skills" \
    -F "hashtags=football,skills,dribbling,nutmeg")
  VID1_ID=$(echo $VID1_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
  echo "  ✓ Video 1 uploaded by kylian_mbp: $VID1_ID"
fi

# Upload video 2 (by neymar_fan)
if [ -s "$TMPDIR/video2.mp4" ] && [ -n "$USER4_TOKEN" ]; then
  VID2_RESP=$(curl -s "$BASE_URL/videos" -X POST \
    -H "Authorization: Bearer $USER4_TOKEN" \
    -F "file=@$TMPDIR/video2.mp4" \
    -F "description=Training session highlights ⚽ Working on those free kicks! #training #freekick" \
    -F "hashtags=training,freekick,football,practice")
  VID2_ID=$(echo $VID2_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
  echo "  ✓ Video 2 uploaded by neymar_fan: $VID2_ID"
fi

# Upload video 3 (by coach_ahmed)
if [ -s "$TMPDIR/video3.mp4" ] && [ -n "$USER3_TOKEN" ]; then
  VID3_RESP=$(curl -s "$BASE_URL/videos" -X POST \
    -H "Authorization: Bearer $USER3_TOKEN" \
    -F "file=@$TMPDIR/video3.mp4" \
    -F "description=Tactical analysis: How to read the defense 🧠 #coaching #tactics" \
    -F "hashtags=coaching,tactics,analysis,football")
  VID3_ID=$(echo $VID3_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
  echo "  ✓ Video 3 uploaded by coach_ahmed: $VID3_ID"
fi

# ─── 4. Add Likes to Videos ──────────────────────────────────────
echo ""
echo "▶ Step 5: Adding likes to videos..."

if [ -n "$VID1_ID" ]; then
  # Multiple users like video 1
  curl -s "$BASE_URL/videos/$VID1_ID/like" -X POST -H "Authorization: Bearer $USER1_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/like" -X POST -H "Authorization: Bearer $USER3_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/like" -X POST -H "Authorization: Bearer $USER5_TOKEN" > /dev/null 2>&1
  echo "  ✓ Video 1: 3 likes (taha, coach_ahmed, scout_maria)"
  
  # Record views
  curl -s "$BASE_URL/videos/$VID1_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID1_ID/view" -X POST > /dev/null 2>&1
  echo "  ✓ Video 1: 5 views recorded"
fi

if [ -n "$VID2_ID" ]; then
  curl -s "$BASE_URL/videos/$VID2_ID/like" -X POST -H "Authorization: Bearer $USER1_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID2_ID/like" -X POST -H "Authorization: Bearer $USER2_TOKEN" > /dev/null 2>&1
  echo "  ✓ Video 2: 2 likes (taha, kylian)"
  
  curl -s "$BASE_URL/videos/$VID2_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID2_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID2_ID/view" -X POST > /dev/null 2>&1
  echo "  ✓ Video 2: 3 views recorded"
fi

if [ -n "$VID3_ID" ]; then
  curl -s "$BASE_URL/videos/$VID3_ID/like" -X POST -H "Authorization: Bearer $USER1_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/like" -X POST -H "Authorization: Bearer $USER4_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/like" -X POST -H "Authorization: Bearer $USER5_TOKEN" > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/like" -X POST -H "Authorization: Bearer $USER2_TOKEN" > /dev/null 2>&1
  echo "  ✓ Video 3: 4 likes (taha, neymar, scout, kylian)"
  
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  curl -s "$BASE_URL/videos/$VID3_ID/view" -X POST > /dev/null 2>&1
  echo "  ✓ Video 3: 7 views recorded"
fi

# ─── 5. Add Comments ─────────────────────────────────────────────
echo ""
echo "▶ Step 6: Adding comments to videos..."

if [ -n "$VID1_ID" ]; then
  # Comment 1 on video 1 (by coach_ahmed)
  C1_RESP=$(curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER3_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID1_ID\",\"content\":\"Incredible technique! This player has real potential 🌟\",\"username\":\"coach_ahmed\",\"displayName\":\"Coach Ahmed\",\"videoOwnerId\":\"$USER2_ID\"}")
  C1_ID=$(echo $C1_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
  echo "  ✓ Comment on Vid1 by coach_ahmed: 'Incredible technique!...'"

  # Reply to comment 1 (by kylian - the video owner)
  if [ -n "$C1_ID" ]; then
    curl -s "$BASE_URL/comments" -X POST \
      -H "Authorization: Bearer $USER2_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"videoId\":\"$VID1_ID\",\"content\":\"Thank you coach! I've been practicing every day 💪\",\"username\":\"kylian_mbp\",\"displayName\":\"Kylian M.\",\"parentId\":\"$C1_ID\",\"videoOwnerId\":\"$USER2_ID\"}" > /dev/null
    echo "  ✓ Reply by kylian_mbp: 'Thank you coach!...'"
  fi

  # Comment 2 (by scout_maria)
  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER5_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID1_ID\",\"content\":\"I'm scouting for FC Barcelona academy. Would love to see more! 👀\",\"username\":\"scout_maria\",\"displayName\":\"Maria Scout\",\"videoOwnerId\":\"$USER2_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid1 by scout_maria: 'I'm scouting for...'"

  # Comment 3 (by taha)
  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID1_ID\",\"content\":\"This is what YouScout is all about! 🔥⚽\",\"username\":\"taha_scout\",\"displayName\":\"Taha (Demo)\",\"videoOwnerId\":\"$USER2_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid1 by taha_scout"
fi

if [ -n "$VID2_ID" ]; then
  # Comments on video 2
  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID2_ID\",\"content\":\"Great form on those free kicks! Keep it up 👏\",\"username\":\"kylian_mbp\",\"displayName\":\"Kylian M.\",\"videoOwnerId\":\"$USER4_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid2 by kylian_mbp"

  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER3_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID2_ID\",\"content\":\"Your body position needs some adjustment. Try leaning back more on contact.\",\"username\":\"coach_ahmed\",\"displayName\":\"Coach Ahmed\",\"videoOwnerId\":\"$USER4_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid2 by coach_ahmed (coaching feedback)"
fi

if [ -n "$VID3_ID" ]; then
  # Comments on video 3
  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID3_ID\",\"content\":\"This tactical breakdown is so helpful for my team! 📋\",\"username\":\"taha_scout\",\"displayName\":\"Taha (Demo)\",\"videoOwnerId\":\"$USER3_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid3 by taha_scout"

  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER4_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID3_ID\",\"content\":\"Can you do one about attacking patterns next? 🙏\",\"username\":\"neymar_fan\",\"displayName\":\"Neymar Jr Fan\",\"videoOwnerId\":\"$USER3_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid3 by neymar_fan"

  # A reportable comment (spam/toxic for demo)
  curl -s "$BASE_URL/comments" -X POST \
    -H "Authorization: Bearer $USER5_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$VID3_ID\",\"content\":\"Check out my page for cheap football boots!! www.spam-link.com\",\"username\":\"scout_maria\",\"displayName\":\"Maria Scout\",\"videoOwnerId\":\"$USER3_ID\"}" > /dev/null
  echo "  ✓ Comment on Vid3 (spam comment for report demo)"
fi

# ─── 6. Seed Redis Feed ──────────────────────────────────────────
echo ""
echo "▶ Step 7: Populating Redis feed cache..."

# We need to push video metadata into Redis so the feed service can serve them
# The feed uses Redis sorted sets: feed:<userId> and feed:explore
DOCKER_REDIS="docker exec infrastructure-redis-1 redis-cli"

TIMESTAMP=$(date +%s)

if [ -n "$VID1_ID" ]; then
  # Add to explore feed
  $DOCKER_REDIS ZADD "feed:explore" $((TIMESTAMP - 100)) "$VID1_ID" > /dev/null
  # Store video metadata
  $DOCKER_REDIS HSET "video:meta:$VID1_ID" \
    "userId" "$USER2_ID" \
    "username" "kylian_mbp" \
    "displayName" "Kylian M." \
    "description" "Amazing dribbling skills 🔥 Watch this nutmeg combo! #football #skills" \
    "likesCount" "3" \
    "viewsCount" "5" \
    "commentsCount" "4" \
    "createdAt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/null
  echo "  ✓ Video 1 added to explore feed"
  
  # Add to taha's personal feed (he follows kylian)
  if [ -n "$USER1_ID" ]; then
    $DOCKER_REDIS ZADD "feed:$USER1_ID" $((TIMESTAMP - 100)) "$VID1_ID" > /dev/null
  fi
fi

if [ -n "$VID2_ID" ]; then
  $DOCKER_REDIS ZADD "feed:explore" $((TIMESTAMP - 50)) "$VID2_ID" > /dev/null
  $DOCKER_REDIS HSET "video:meta:$VID2_ID" \
    "userId" "$USER4_ID" \
    "username" "neymar_fan" \
    "displayName" "Neymar Jr Fan" \
    "description" "Training session highlights ⚽ Working on those free kicks! #training #freekick" \
    "likesCount" "2" \
    "viewsCount" "3" \
    "commentsCount" "2" \
    "createdAt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/null
  echo "  ✓ Video 2 added to explore feed"
  
  if [ -n "$USER1_ID" ]; then
    $DOCKER_REDIS ZADD "feed:$USER1_ID" $((TIMESTAMP - 50)) "$VID2_ID" > /dev/null
  fi
fi

if [ -n "$VID3_ID" ]; then
  $DOCKER_REDIS ZADD "feed:explore" $TIMESTAMP "$VID3_ID" > /dev/null
  $DOCKER_REDIS HSET "video:meta:$VID3_ID" \
    "userId" "$USER3_ID" \
    "username" "coach_ahmed" \
    "displayName" "Coach Ahmed" \
    "description" "Tactical analysis: How to read the defense 🧠 #coaching #tactics" \
    "likesCount" "4" \
    "viewsCount" "7" \
    "commentsCount" "3" \
    "createdAt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/null
  echo "  ✓ Video 3 added to explore feed"
  
  if [ -n "$USER1_ID" ]; then
    $DOCKER_REDIS ZADD "feed:$USER1_ID" $TIMESTAMP "$VID3_ID" > /dev/null
  fi
fi

# ─── Cleanup ─────────────────────────────────────────────────────
rm -rf "$TMPDIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Demo data seeded successfully!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  📱 LOGIN CREDENTIALS FOR THE DEMO:"
echo "  ───────────────────────────────────"
echo "  Email:    taha@youscout.com"
echo "  Password: demo123456"
echo ""
echo "  Other test accounts (same password: demo123456):"
echo "    • player1@youscout.com  (Lionel Messi Jr)"
echo "    • kylian@youscout.com   (Kylian M.)"
echo "    • ahmed@youscout.com    (Coach Ahmed)"
echo "    • neymar@youscout.com   (Neymar Jr Fan)"
echo "    • maria@youscout.com    (Maria Scout)"
echo ""
echo "  🎯 DEMO WALKTHROUGH:"
echo "  ───────────────────────────────────"
echo "  1. Login with taha@youscout.com"
echo "  2. Home Feed → Swipe through 3 videos"
echo "  3. Like a video (tap heart icon)"
echo "  4. Open comments → See existing comments"
echo "  5. Reply to a comment"
echo "  6. Report the spam comment"
echo "  7. Go to Discover → Browse trending"
echo "  8. Tap a user profile → Follow/Unfollow"
echo "  9. Go to Profile tab → See your stats"
echo " 10. Upload a new video (camera icon)"
echo ""
