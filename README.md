# luxinaios - Roblox Mobile iOS Script Executor
> High-performance, modern iOS Luau script executor for Roblox Mobile (Target Build: 2.748.1526).

---

## ✨ Features

- **Minimalist Floating UI:** Only a sleek, neon-bordered floating button appears on screen. Draggable with spring physics and auto edge-snapping.
- **Modern Glassmorphic Executor Window:** Tapping the button smoothly animates the **luxinaios** menu.
  - **Luau Code Editor:** Line numbers, code syntax area, `Execute`, `Clear`, and `Paste` actions.
  - **Script Hub:** Built-in 1-click support for Infinite Yield, Dex Explorer iOS, and SimpleSpy.
  - **Live Console:** Real-time print outputs and execution errors.
  - **Settings:** FPS Unlocker (120 FPS) and Identity status.
- **Core Luau Elevation:** Sets `ExtraSpace` Identity to Level 8 and Capabilities to `0x3FFFFFFF` (full CoreGui and API access).
- **UNC / UNS API Support:** Includes `identifyexecutor`, `getgenv`, `getrenv`, `getreg`, `loadstring`, `hookfunction`, `hookmetamethod`, `setclipboard`, `httpget`, and `rconsoleprint`.
- **Automated IPA Patcher:** Native Python script injecting `LC_LOAD_DYLIB` into the Mach-O binary.

---

## 🚀 How to Build with GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/build_ios.yml`) that automatically compiles `luxinaios.dylib` for ARM64 iOS using Apple Clang:

1. Push your changes to GitHub (`git push origin main` or via GitHub Desktop).
2. Go to the **Actions** tab on your GitHub repository.
3. Select the latest workflow run and download the compiled **`luxinaios-dylib`** artifact.

---

## 📲 How to Install with Sideloadly

### Option 1: Inject Dylib Directly
1. Download or locate your decrypted IPA (`com.roblox.robloxmobile-2.748.1526-Decrypted.ipa`).
2. Open **Sideloadly** and connect your iPhone/iPad.
3. Drag and drop the IPA into Sideloadly.
4. Click **Advanced Options**.
5. Under **Inject dylibs/frameworks**, select the compiled `luxinaios.dylib`.
6. Enter your Apple ID and click **Start**.

### Option 2: Use patch_ipa.py
1. Run the patcher script:
   ```bash
   python scripts/patch_ipa.py -i <path_to_decrypted_ipa> -d <path_to_luxinaios.dylib> -o luxinaios_Roblox.ipa
   ```
2. Drag `luxinaios_Roblox.ipa` directly into Sideloadly (or TrollStore) and install.

---

## 🛠 Project Structure

```
luxinaios/
├── .github/workflows/
│   └── build_ios.yml        # CI/CD macOS ARM64 Clang automated compiler
├── scripts/
│   └── patch_ipa.py         # Self-contained Mach-O LC_LOAD_DYLIB injector
├── src/
│   ├── config/
│   │   └── LuxinaConfig.h   # Target build RVAs and capabilities definition
│   ├── core/
│   │   ├── LuxinaCore.h     # TaskScheduler and ScriptContext bridge header
│   │   └── LuxinaCore.cpp   # Base resolver and Luau thread execution
│   ├── env/
│   │   ├── LuxinaEnv.h      # UNC globals header
│   │   └── LuxinaEnv.cpp    # identifyexecutor, getgenv, httpget, etc.
│   ├── ui/
│   │   ├── LuxinaUI.h       # UIKit floating button and executor header
│   │   └── LuxinaUI.mm      # Glassmorphic UI with luxinaios header
│   └── entry.mm             # Dynamic library constructor entry point
├── CMakeLists.txt           # CMake build configuration
├── Makefile                 # Theos tweak configuration
└── OFFSET_RECIPE.md         # IDA / Ghidra reverse engineering instructions
```
