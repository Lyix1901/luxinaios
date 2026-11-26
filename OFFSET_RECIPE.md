# luxinaios - Offset & Reverse Engineering Recipe
**Target:** Roblox Mobile iOS  
**Build:** 2.748.1526 (Decrypted)  
**Binary:** `Payload/Roblox.app/Frameworks/RobloxLib.framework/RobloxLib` (Mach-O ARM64)  
**Base Address:** `0x0` (__TEXT segment vmaddr == 0x0, file offset == RVA)

---

## 1. Measured & Verified Binary Offsets

| Symbol / String | Type | RVA / File Offset | Verified Status |
|-----------------|------|-------------------|-----------------|
| `"WaitingHybridScriptsJob"` | String | `0x516fd4c` | Measured in 2.748.1526 |
| `"ScriptContext"` | String | `0x4fc3190` | Measured in 2.748.1526 |
| `"TaskScheduler"` | String | `0x4fbb12e` | Measured in 2.748.1526 |

---

## 2. Reverse Engineering Recipe in IDA Pro / Ghidra / Hopper

### Step 1: Locating `TaskScheduler::get()` Singleton
1. Open `RobloxLib` in IDA Pro / Ghidra (load as ARM64 Mach-O).
2. Go to RVA `0x4fbb12e` (string `"TaskScheduler"`).
3. Check xrefs (press `X`) to find functions referencing this string.
4. You will land in the TaskScheduler initialization and constructor routines:
   - Look for an `ADRP` + `LDR` / `STR` pattern storing a pointer into a global BSS variable.
   - That global pointer is the `TaskScheduler` singleton instance.

### Step 2: Locating `WaitingHybridScriptsJob`
1. Go to RVA `0x516fd4c` (string `"WaitingHybridScriptsJob"`).
2. Check xrefs (`X`) to find the Job class descriptor / constructor.
3. In IDA, the virtual method table (vtable) assigns this name via `getName()` returning `const char*`.
4. In runtime:
   - Iterate jobs in `TaskScheduler` (`jobs_start` to `jobs_end`).
   - For each job, call `job->getName()` or read the job name string at `job + 0x88` (or ARM64 offset).
   - Match `"WaitingHybridScriptsJob"`.

### Step 3: Extracting `ScriptContext` and `lua_State*`
1. Inside `WaitingHybridScriptsJob`:
   - Inspect the job structure: there is a pointer pointing directly to `rbx::ScriptContext` (typically at offset `+0x138` or `+0x140`).
2. Inside `ScriptContext`:
   - Inspect the field where `lua_State*` is stored.
   - Verify by following xrefs to string `"ScriptContext"` where `lua_newthread` or `task_defer` is called.
   - The first parameter passed to Luau functions is the `lua_State*` pointer.

### Step 4: Luau ExtraSpace & Capability Escalation
Roblox Luau allocates an `ExtraSpace` structure associated with every `lua_State`:
- **Pointer Calculation:** `uint8_t* extraSpace = ((uint8_t*)L) - 0x78;`
- **Identity Level:** Offset `+0x30` from ExtraSpace:
  - Default LocalScript: `2`
  - CoreScript: `6` or `7`
  - Elevated Executor: `8`
- **Capabilities Bitmask:** Offset `+0x48` from ExtraSpace:
  - Set to `0x3FFFFFFF` (grants CoreGui, HttpService, and Plugin permission masks).

---

## 3. Repackaging & Sideloading
1. Run `python luxinaios/scripts/patch_ipa.py` to inject `LC_LOAD_DYLIB`.
2. Sideload the resulting IPA (`luxinaios_Roblox_2.748.1526.ipa`) using:
   - **TrollStore** (Recommended, no re-signing needed, JIT allowed).
   - **SideStore / AltStore** (Personal developer certificate).
   - **Scarlet / Feather / Esign**.
