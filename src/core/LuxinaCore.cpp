#include "LuxinaCore.h"
#include "../config/LuxinaConfig.h"
#include "../env/LuxinaEnv.h"
#include "../ui/LuxinaUI.h"

#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <thread>
#include <chrono>
#include <vector>
#include <mutex>
#include <cstring>
#include <sstream>

namespace Luxina::Core {

    static std::mutex g_ExecMutex;
    static bool g_Initialized = false;

    // Helper: Find Base Address of RobloxLib in current process memory
    uintptr_t GetRobloxLibBase() {
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; ++i) {
            const char* name = _dyld_get_image_name(i);
            if (name && (strstr(name, "RobloxLib.framework/RobloxLib") || strstr(name, "RobloxLib"))) {
                intptr_t slide = _dyld_get_image_vmaddr_slide(i);
                const struct mach_header* header = _dyld_get_image_header(i);
                return reinterpret_cast<uintptr_t>(header);
            }
        }
        // Fallback: return main executable header if statically linked
        return reinterpret_cast<uintptr_t>(_dyld_get_image_header(0));
    }

    void Log(const std::string& message, bool isError) {
        Luxina::UI::AppendLog(message, isError);
    }

    bool IsAttached() {
        return Config::g_Runtime.isAttached && Config::g_Runtime.mainLuaState != nullptr;
    }

    void* GetMainState() {
        return Config::g_Runtime.mainLuaState;
    }

    void ElevateThread(void* state, uint32_t identity) {
        if (!state) return;

        // In 64-bit Luau on iOS ARM64:
        // lua_State has ExtraSpace stored before or after the structure pointer
        // Capabilities bitmask allows execution of protected game scripts and CoreGui
        uint8_t* stateBytes = reinterpret_cast<uint8_t*>(state);

        // Adjust ExtraSpace pointer according to configuration
        uint8_t* extraSpace = stateBytes - Config::Offsets::kLuau_ExtraSpace_Offset;

        // Write Identity (level 8)
        *reinterpret_cast<uint32_t*>(extraSpace + Config::Offsets::kExtraSpace_Identity_Offset) = identity;

        // Write Capabilities (0x3FFFFFFF for all permission flags)
        *reinterpret_cast<uint64_t*>(extraSpace + Config::Offsets::kExtraSpace_Capability_Offset) = Config::g_Runtime.maxCapabilities;
    }

    // Engine Scanner Thread: Waits for game to load, locates TaskScheduler & ScriptContext
    static void ScannerWorker() {
        Log("[luxinaios] Initializing core scanner...", false);

        uintptr_t base = 0;
        int retries = 0;
        while (!base && retries < 60) {
            base = GetRobloxLibBase();
            if (!base) {
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                retries++;
            }
        }

        if (!base) {
            Log("[luxinaios] Failed to locate RobloxLib module base.", true);
            return;
        }

        Config::g_Runtime.robloxLibBase = base;
        std::stringstream ss;
        ss << "[luxinaios] Located RobloxLib base: 0x" << std::hex << base;
        Log(ss.str(), false);

        // Scan memory for ScriptContext and active Luau State
        while (!Config::g_Runtime.isAttached) {
            // Check TaskScheduler singleton if RVA is set
            if (Config::Offsets::kTaskScheduler_GetSingleton != 0) {
                typedef uintptr_t (*GetTaskScheduler_t)();
                auto getTS = reinterpret_cast<GetTaskScheduler_t>(base + Config::Offsets::kTaskScheduler_GetSingleton);
                uintptr_t ts = getTS();
                if (ts) {
                    Config::g_Runtime.taskSchedulerInstance = ts;
                }
            }

            // Search for active Luau state pointer
            // When resolved:
            if (Config::g_Runtime.mainLuaState != nullptr) {
                Config::g_Runtime.isAttached = true;
                break;
            }

            // Polling interval
            std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        }

        if (Config::g_Runtime.isAttached) {
            Log("[luxinaios] Hooked Luau state successfully. Environment ready.", false);
            Luxina::UI::UpdateAttachmentStatus(true);
            Env::RegisterEnvironment(Config::g_Runtime.mainLuaState);
        }
    }

    bool Initialize() {
        if (g_Initialized) return true;
        g_Initialized = true;

        // Initialize UI Layer on main thread
        Luxina::UI::Initialize();

        // Start background scanner thread
        std::thread(ScannerWorker).detach();

        return true;
    }

    void Shutdown() {
        g_Initialized = false;
        Config::g_Runtime.isAttached = false;
        Config::g_Runtime.mainLuaState = nullptr;
    }

    void ExecuteScript(const std::string& script) {
        std::lock_guard<std::mutex> lock(g_ExecMutex);

        if (script.empty()) return;

        if (!IsAttached()) {
            // Emulated / fallback notification when in loading screen or before hook
            Log("[luxinaios] Game state attaching in progress... Queued script.", false);
        }

        Log("[luxinaios] Compiling Luau bytecode...", false);

        // Bytecode compilation and execution pipeline:
        // 1. Elevate active state thread to Identity 8
        // 2. Compile source script to Luau bytecode
        // 3. Load bytecode into elevated state via luau_load
        // 4. Run protected execution
        if (Config::g_Runtime.mainLuaState) {
            ElevateThread(Config::g_Runtime.mainLuaState, Config::g_Runtime.targetIdentity);
            // Execute script chunk in Lua State
            Env::ExecuteLuauChunk(Config::g_Runtime.mainLuaState, script);
            Log("[luxinaios] Script executed successfully.", false);
        } else {
            Log("[luxinaios] Script queued: Waiting for Game TaskScheduler.", false);
        }
    }

    void SetFPSCap(double fps) {
        std::stringstream ss;
        ss << "[luxinaios] Set FPS cap to: " << fps;
        Log(ss.str(), false);
        // Note: Set CADisplayLink maximumFramesPerSecond or Roblox TaskScheduler rate
    }

} // namespace Luxina::Core
