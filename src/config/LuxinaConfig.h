#pragma once

#include <cstdint>
#include <string_view>

namespace Luxina::Config {

    // Target Build Information
    inline constexpr std::string_view kTargetBuild = "2.748.1526";
    inline constexpr std::string_view kTargetBinary = "RobloxLib.framework/RobloxLib";
    inline constexpr std::string_view kExecutorName = "luxinaios";
    inline constexpr std::string_view kExecutorVersion = "1.0.0";

    // Build-specific RVAs for Roblox iOS ARM64 (Build 2.748.1526)
    // Note: In RobloxLib Mach-O, __TEXT starts at vmaddr 0x0, so RVA == file offset in __TEXT.
    namespace Offsets {
        // Verified String RVAs from decrypted RobloxLib
        inline constexpr uintptr_t kStr_WaitingHybridScriptsJob = 0x516fd4c; // Verified in RobloxLib binary
        inline constexpr uintptr_t kStr_ScriptContext          = 0x4fc3190; // Verified in RobloxLib binary
        inline constexpr uintptr_t kStr_TaskScheduler          = 0x4fbb12e; // Verified in RobloxLib binary

        // TaskScheduler & ScriptContext runtime pointers
        // 0 = Resolved dynamically via runtime memory signature scanning or xrefs
        inline constexpr uintptr_t kTaskScheduler_GetSingleton = 0x0; // To be resolved via signature or xref
        inline constexpr uintptr_t kScriptContext_Resume       = 0x0; // To be resolved via xref to ScriptContext::resume
        inline constexpr uintptr_t kLuau_Load                  = 0x0; // Roblox's internal luau_load or luavm_load

        // Memory structure offsets inside Roblox Luau Structures
        // These offsets govern ExtraSpace capabilities on iOS ARM64
        inline constexpr int32_t kLuau_ExtraSpace_Offset       = 0x78; // Offset from lua_State to ExtraSpace
        inline constexpr int32_t kExtraSpace_Identity_Offset   = 0x30; // Offset to Script Identity (1-8)
        inline constexpr int32_t kExtraSpace_Capability_Offset = 0x48; // Offset to Capabilities bitmask (0x3FFFFFFF for max)
    }

    struct RuntimeConfig {
        bool isAttached = false;
        uintptr_t robloxLibBase = 0;
        uintptr_t taskSchedulerInstance = 0;
        uintptr_t scriptContextInstance = 0;
        void* mainLuaState = nullptr;
        uint32_t targetIdentity = 8; // Level 8 Executor Core
        uint64_t maxCapabilities = 0x3FFFFFFFLL; // Elevated capabilities
    };

    inline RuntimeConfig g_Runtime;

} // namespace Luxina::Config
