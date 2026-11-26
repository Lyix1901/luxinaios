@echo off
echo ========================================================
echo  luxinaios - Automated IPA Patch Tool
echo ========================================================
echo.

set DEFAULT_IPA=%USERPROFILE%\Downloads\com.roblox.robloxmobile-2.748.1526-Decrypted.ipa
set OUTPUT_IPA=luxinaios_Roblox_2.748.1526_Patched.ipa

if exist "%DEFAULT_IPA%" (
    echo [+] Found decrypted IPA in Downloads:
    echo     %DEFAULT_IPA%
    echo.
    echo [*] Running patch_ipa.py...
    python scripts\patch_ipa.py -i "%DEFAULT_IPA%" -o "%OUTPUT_IPA%"
    echo.
    echo [+] Done! Ready to install with Sideloadly or TrollStore:
    echo     %OUTPUT_IPA%
) else (
    echo [-] Decrypted IPA not found at default Downloads location.
    echo     Please run: python scripts\patch_ipa.py -i ^<path_to_ipa^>
)

pause
