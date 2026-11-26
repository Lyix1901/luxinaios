#pragma once

#include <string>

namespace Luxina::Env {

    // Register all custom UNC / Executor globals into the target Luau state
    void RegisterEnvironment(void* state);

    // Compile and run Luau string
    bool ExecuteLuauChunk(void* state, const std::string& script);

    // Built-in Executor API Implementation
    int identifyexecutor(void* L);
    int getgenv(void* L);
    int getrenv(void* L);
    int getreg(void* L);
    int loadstring(void* L);
    int hookfunction(void* L);
    int hookmetamethod(void* L);
    int getrawmetatable(void* L);
    int setreadonly(void* L);
    int isreadonly(void* L);
    int setclipboard(void* L);
    int httpget(void* L);
    int rconsoleprint(void* L);

} // namespace Luxina::Env
