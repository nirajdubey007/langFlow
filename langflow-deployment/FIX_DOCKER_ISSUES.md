# Fix Docker Desktop Issues

Docker Desktop is not starting properly. This is usually a WSL (Windows Subsystem for Linux) issue.

## 🔧 Solution 1: Restart WSL (Quick Fix)

Open **PowerShell as Administrator** and run:

```powershell
# Stop WSL
wsl --shutdown

# Wait 10 seconds
Start-Sleep -Seconds 10

# Restart Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

Wait 1-2 minutes for Docker to start, then check:

```powershell
docker info
```

---

## 🔧 Solution 2: Restart Computer (Most Reliable)

Sometimes the simplest solution works best:

1. **Close Docker Desktop** completely
2. **Restart your computer**
3. **Start Docker Desktop** after reboot
4. Wait for "Engine running" status

---

## 🔧 Solution 3: Clear Docker Data (If above don't work)

⚠️ **Warning:** This will remove all your Docker containers, images, and volumes!

1. Close Docker Desktop
2. Open PowerShell and run:

```powershell
# Navigate to Docker data directory
cd "$env:APPDATA\Docker"

# Backup if needed
# Copy-Item -Path "$env:APPDATA\Docker" -Destination "$env:APPDATA\Docker.backup" -Recurse

# Clear Docker data
wsl --shutdown
Start-Sleep -Seconds 5
Remove-Item -Path "$env:LOCALAPPDATA\Docker\wsl" -Recurse -Force -ErrorAction SilentlyContinue
```

3. Start Docker Desktop
4. It will reinitialize (takes 2-3 minutes)

---

## 🔧 Solution 4: Update WSL

```powershell
# Open PowerShell as Administrator
wsl --update
wsl --set-default-version 2
```

Restart computer after update.

---

## 🔧 Solution 5: Check Docker Desktop Settings

If Docker starts but crashes:

1. Open Docker Desktop
2. Go to **Settings** → **General**
3. Ensure:
   - ✅ **Use WSL 2 based engine** is checked
   - ✅ **Start Docker Desktop when you sign in** is checked

4. Go to **Settings** → **Resources** → **WSL Integration**
5. Enable integration with your WSL distributions

6. Click **Apply & Restart**

---

## 🚨 Emergency Option: Reinstall Docker Desktop

If nothing works:

1. **Uninstall Docker Desktop**
   - Settings → Apps → Docker Desktop → Uninstall

2. **Clean up remaining files:**
```powershell
Remove-Item -Path "$env:APPDATA\Docker" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Docker" -Recurse -Force -ErrorAction SilentlyContinue
```

3. **Download and reinstall:**
   - https://www.docker.com/products/docker-desktop/

4. **Configure after install:**
   - Allocate 6-8 GB memory
   - Enable WSL 2 integration

---

## ✅ Verify Docker is Working

After trying any solution, verify:

```powershell
# Check Docker version
docker --version

# Check Docker is running
docker info

# Test with hello-world
docker run hello-world
```

If all commands work, Docker is ready!

---

## 🎯 Recommended Approach

**Try in this order:**

1. ✅ **Restart computer** (5 min) - Easiest and most reliable
2. ✅ **Restart WSL** (2 min) - Quick fix
3. ✅ **Update WSL** (5 min) - Ensures latest version
4. ✅ **Clear Docker data** (10 min) - If above don't work
5. ✅ **Reinstall Docker** (20 min) - Last resort

---

## 📞 After Docker is Working

Come back and run:

```powershell
cd C:\Users\Niraj\lf\langflow\langflow-deployment
.\check-prerequisites.ps1
.\build-and-test.ps1
```

---

## 💡 Tips

- **Always run Docker Desktop as Administrator** (right-click → Run as administrator)
- **Keep Windows and WSL updated**
- **Don't manually modify WSL distributions while Docker is running**
- **Ensure antivirus isn't blocking Docker**

