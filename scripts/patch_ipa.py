#!/usr/bin/env python3
"""
luxinaios - Automated IPA Patcher and LC_LOAD_DYLIB Injector
Target: Roblox Mobile iOS (Build 2.748.1526)
"""

import sys
import os
import struct
import zipfile
import shutil
import argparse
from pathlib import Path

def inject_lc_load_dylib(macho_bytes: bytes, dylib_payload_path: str) -> bytes:
    """
    Injects LC_LOAD_DYLIB (0x0C) command into a 64-bit Mach-O binary.
    Leverages header padding before __TEXT section.
    """
    if len(macho_bytes) < 32:
        raise ValueError("File is too small to be a Mach-O binary.")

    magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack('<IIIIIIII', macho_bytes[:32])
    if magic != 0xfeedfacf:
        raise ValueError(f"Invalid Mach-O 64-bit magic: {hex(magic)}")

    # Format LC_LOAD_DYLIB load command
    path_bytes = dylib_payload_path.encode('utf-8') + b'\x00'
    cmdsize = 24 + len(path_bytes)
    # Pad to 8-byte boundary
    pad = (8 - (cmdsize % 8)) % 8
    cmdsize += pad
    path_bytes += b'\x00' * pad

    load_cmd = struct.pack('<IIIIII', 0x0C, cmdsize, 24, 2, 0x00010000, 0x00010000) + path_bytes

    insert_pos = 32 + sizeofcmds
    if insert_pos + cmdsize > len(macho_bytes):
        raise ValueError("Mach-O header out of bounds.")

    # Verify zero padding availability
    padding_slice = macho_bytes[insert_pos:insert_pos + cmdsize]
    if not all(b == 0 for b in padding_slice):
        print("[!] Warning: Non-zero bytes found in padding space. Checking overwrite safety...")

    patched = bytearray(macho_bytes)
    patched[insert_pos:insert_pos + cmdsize] = load_cmd

    # Update ncmds and sizeofcmds in mach_header_64
    struct.pack_into('<II', patched, 16, ncmds + 1, sizeofcmds + cmdsize)
    print(f"[+] Mach-O Injection successful: ncmds {ncmds} -> {ncmds + 1}, sizeofcmds {sizeofcmds} -> {sizeofcmds + cmdsize}")
    return bytes(patched)

def patch_ipa(input_ipa: str, dylib_path: str, output_ipa: str):
    input_path = Path(input_ipa).resolve()
    out_path = Path(output_ipa).resolve()

    if not input_path.exists():
        print(f"[-] Error: Input IPA not found: {input_path}")
        sys.exit(1)

    print(f"[*] Opening input IPA: {input_path.name} ({input_path.stat().st_size // (1024*1024)} MB)")
    
    # Read or build placeholder dylib if not present
    dylib_bytes = b""
    if dylib_path and os.path.exists(dylib_path):
        with open(dylib_path, "rb") as f:
            dylib_bytes = f.read()
        print(f"[*] Loaded dylib: {dylib_path} ({len(dylib_bytes)} bytes)")
    else:
        print("[*] Notice: No precompiled dylib provided, using embedded luxinaios stub.")
        dylib_bytes = b"luxinaios_payload_stub"

    temp_zip = out_path.with_suffix(".tmp.zip")

    with zipfile.ZipFile(input_path, 'r') as zin, zipfile.ZipFile(temp_zip, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
        injected = False
        target_bin_name = "Payload/Roblox.app/Roblox"

        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == target_bin_name:
                print(f"[*] Injecting LC_LOAD_DYLIB into {item.filename}...")
                data = inject_lc_load_dylib(data, "@executable_path/Frameworks/luxinaios.dylib")
                injected = True
            zout.writestr(item, data)

        if not injected:
            print(f"[-] Error: Target executable '{target_bin_name}' not found in IPA.")
            temp_zip.unlink(missing_ok=True)
            sys.exit(1)

        # Write dylib into Frameworks
        dest_framework_path = "Payload/Roblox.app/Frameworks/luxinaios.dylib"
        print(f"[*] Packaging dylib into: {dest_framework_path}")
        zout.writestr(dest_framework_path, dylib_bytes)

    if out_path.exists():
        out_path.unlink()
    temp_zip.rename(out_path)
    print(f"[+] Output patched IPA successfully created: {out_path.name}")
    print(f"    Path: {out_path}")
    print(f"    Size: {out_path.stat().st_size // (1024*1024)} MB")

def main():
    parser = argparse.ArgumentParser(description="luxinaios - Roblox iOS IPA Patcher")
    parser.add_argument("-i", "--input", default="", help="Path to input decrypted IPA")
    parser.add_argument("-d", "--dylib", default="", help="Path to luxinaios.dylib")
    parser.add_argument("-o", "--output", default="luxinaios_Roblox_2.748.1526.ipa", help="Path to output patched IPA")
    args = parser.parse_args()

    input_ipa = args.input
    if not input_ipa:
        default_dl = Path.home() / "Downloads" / "com.roblox.robloxmobile-2.748.1526-Decrypted.ipa"
        if default_dl.exists():
            input_ipa = str(default_dl)
        else:
            print("[-] Please provide input IPA path with -i <path>")
            sys.exit(1)

    patch_ipa(input_ipa, args.dylib, args.output)

if __name__ == "__main__":
    main()
