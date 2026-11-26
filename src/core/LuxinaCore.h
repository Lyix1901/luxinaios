#pragma once

#include <string>
#include <cstdint>
#include <functional>

namespace Luxina::Core {

    // Engine Lifecycle & Hooks
    bool Initialize();
    void Shutdown();

    // Luau Execution
    bool IsAttached();
    void* GetMainState();
    void ExecuteScript(const std::string& script);
    void ElevateThread(void* state, uint32_t identity);

    // Engine Controls
    void SetFPSCap(double fps);

    // Logging bridge
    void Log(const std::string& message, bool isError = false);

} // namespace Luxina::Core
