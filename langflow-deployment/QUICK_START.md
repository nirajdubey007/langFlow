# 🚀 Quick Start - Build & Test Langflow Docker Image

## ✅ Your Dockerfile is Ready!

Your `build_and_push_fixed.Dockerfile` has been reviewed and is **properly configured** for Langflow.

## 📝 Three Simple Steps

### 1️⃣ Build & Test Locally (15-30 min)

```powershell
cd C:\Users\Niraj\lf\langflow\langflow-deployment
.\build-and-test.ps1
```

Wait for build to complete, then open **http://localhost:7860** in your browser.

### 2️⃣ Verify It Works

- ✓ Can you see the Langflow UI?
- ✓ Can you create a new flow?
- ✓ No errors in the logs?

If yes → proceed to step 3!

### 3️⃣ Push to Docker Hub

```powershell
.\push-to-hub.ps1
```

Enter your Docker Hub password when prompted.

**Done!** Your image is now at: `cera123/langflow:latest`

---

## 🔍 What Each Script Does

| Script | Purpose |
|--------|---------|
| `build-and-test.ps1` | Builds image and starts test container |
| `push-to-hub.ps1` | Tags and pushes to Docker Hub |
| `cleanup.ps1` | Removes test containers |

## 💡 Quick Tips

**View logs while container is running:**
```powershell
docker logs -f langflow-test
```

**Stop the test container:**
```powershell
docker stop langflow-test
```

**Check build status:**
```powershell
docker images cera123/langflow
```

## 🆘 If Something Goes Wrong

**"Docker is not running"**
→ Start Docker Desktop and wait for it to be ready

**"Build failed"**
→ Check your internet connection and try again

**"Port 7860 is already in use"**
→ Stop other Langflow instances or use different port:
```powershell
docker run -d --name langflow-test -p 8080:7860 cera123/langflow:test-local
```

**"Out of space"**
→ Run: `docker system prune -a` (frees up space)

---

## 📖 Need More Details?

See **TESTING_GUIDE.md** for:
- Detailed troubleshooting
- Manual commands
- Advanced configurations
- Production deployment

