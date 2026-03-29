# Checkly Mobile — Dev Setup Guide

> A step-by-step guide to run the backend API and deploy the Flutter app to your Android phone **or Windows desktop** for testing.

## Prerequisites (One-Time Setup)

- ✅ Flutter SDK installed (`flutter --version`)
- ✅ .NET SDK installed (`dotnet --version`)
- ✅ PostgreSQL running on port 5432 (database: `checkly`)
- ✅ **For Android**: Phone with USB Debugging enabled + ADB in PATH
- ✅ **For Windows Desktop**: Visual Studio with "Desktop development with C++" workload

---

## Step 1: Connect Your Android Phone

1. Plug your phone into the PC via USB cable
2. If prompted on the phone, tap **"Allow USB debugging"** and check **"Always allow from this computer"**
3. Verify the connection:

```powershell
adb devices
```

You should see your device listed (e.g., `R9HT10C5NSM  device`).

---

## Step 2: Find Your PC's LAN IP

Your phone and PC must be on the **same WiFi network**.

```powershell
ipconfig | findstr "IPv4"
```

Note the IP address (e.g., `192.168.1.27`). This may change if your router assigns a new IP.

---

## Step 3: Start the Backend API Server

Open a terminal and run:

```powershell
cd c:\Users\HP\Documents\GitHub\Checkly\server
dotnet run --urls "http://0.0.0.0:5288"
```

> ⚠️ **Keep this terminal open!** Closing it kills the server.
>
> The `0.0.0.0` makes the server accessible from the LAN (not just localhost).

**Verify it's running** (in a separate terminal):

```powershell
netstat -ano | findstr ":5288"
```

You should see `LISTENING` on port 5288.

---

## Step 4: Build & Deploy the Flutter App

Open a **second terminal** and run:

```powershell
cd c:\Users\HP\Documents\GitHub\Checkly
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5288/api
```

**Replace the placeholders:**
- `<DEVICE_ID>` → Your device ID from `adb devices` (e.g., `R9HT10C5NSM`)
- `<YOUR_LAN_IP>` → Your IP from Step 2 (e.g., `192.168.1.27`)

**Full example:**

```powershell
flutter run -d R9HT10C5NSM --dart-define=API_BASE_URL=http://192.168.1.27:5288/api
```

> First build takes 2-4 minutes. Subsequent builds are faster.
>
> ⚠️ **Keep this terminal open too!** It enables hot-reload (press `r` to reload, `R` for full restart).

---

## Alternative: Run on Windows Desktop (No Phone Needed)

If you don't have an Android phone connected, you can run the app as a native Windows application.

### One-Time Setup

```powershell
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

> This generates the `windows/` folder. You only need to do this once.

### Run

```powershell
cd c:\Users\HP\Documents\GitHub\Checkly
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5288/api
```

> Since the app runs on the same machine as the backend, use `localhost` instead of your LAN IP.

### Limitations

| Feature | Works on Windows? |
|---------|:-:|
| UI / Navigation / Forms | ✅ |
| HTTP / API calls | ✅ |
| Local storage / SQLite | ✅ |
| Camera / GPS / Biometrics | ❌ |
| Push notifications | ❌ |

For camera/GPS-dependent flows, use the Android phone path (Steps 1-4 above).

---

## Quick Reference (Copy-Paste)

Once you've done the setup before, here's the cheat sheet:

```powershell
# Terminal 1 — Start backend
cd c:\Users\HP\Documents\GitHub\Checkly\server
dotnet run --urls "http://0.0.0.0:5288"

# Terminal 2 — Option A: Android phone
cd c:\Users\HP\Documents\GitHub\Checkly
flutter run -d R9HT10C5NSM --dart-define=API_BASE_URL=http://192.168.1.27:5288/api

# Terminal 2 — Option B: Windows desktop (no phone needed)
cd c:\Users\HP\Documents\GitHub\Checkly
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5288/api
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `adb devices` shows empty list | Re-enable USB Debugging, try a different USB cable, tap "Allow" on phone |
| `flutter devices` doesn't show phone | Run `adb kill-server` then `adb start-server`, reconnect USB |
| App shows "Connection refused" | Check backend is running (`netstat -ano \| findstr ":5288"`), verify LAN IP hasn't changed |
| Backend fails to start | Check PostgreSQL is running (`netstat -ano \| findstr ":5432"`) |
| Build fails with Gradle errors | Run `flutter clean` then try again |
| Phone not on same network | Connect phone to the same WiFi as PC |
| IP address changed | Re-run `ipconfig \| findstr "IPv4"` and update the `API_BASE_URL` |

---

## Stopping Everything

1. **Flutter app**: Press `q` in the Flutter terminal, or just close the terminal
2. **Backend server**: Press `Ctrl+C` in the server terminal, or just close it
3. **Unplug phone**: Safe to disconnect anytime
