# YouScout MVP

Micro‑services based social‑network prototype (User, Video, Interaction services) + Flutter front‑end.

* Docker‑Compose orchestration
* FastAPI back‑ends
* Premium dark‑theme Flutter UI

## Prerequisites
- **Docker Engine** & **Docker Compose** (install via `sudo apt install docker.io docker-compose-plugin`)
- **Flutter SDK** (stable 3.44.0) – see https://flutter.dev/docs/get-started/install
- **Android SDK / ADB** (`sudo apt install adb`) for running on a phone or emulator
- **Git** (`sudo apt install git`)

## Running the backend
```bash
# From the project root
cd /home/najib/Projects/Archi\ Logi
docker compose up --build -d
```

You should see all containers start:

```
yscout_gateway
yscout_user
yscout_video
yscout_interaction
yscout_postgres
yscout_mongo
yscout_minio
```

### Verify the services
```bash
# Health check the API gateway
curl http://localhost:8080/health      # → {"status":"ok"}

# List users (initially empty)
curl http://localhost:8001/users       # → []
```

## Running the Flutter front‑end
1. **Connect a physical Android device** (enable *Developer options → USB debugging*) **or start an Android emulator**.
2. Launch the app:
```bash
cd frontend/you_scout_app
flutter pub get
flutter run
```
The app will automatically talk to the gateway at `http://localhost:8080`.

## Cleaning up
```bash
# Stop and remove containers (keeps volumes)
docker compose down

# Remove Docker images (optional, frees space)
docker image prune -a

# Clean Flutter build artefacts
flutter clean
```

---
Enjoy exploring the YouScout MVP!

Micro‑services based social‑network prototype (User, Video, Interaction services) + Flutter front‑end.
* Docker‑Compose orchestration
* FastAPI back‑ends
* Premium dark‑theme Flutter UI
