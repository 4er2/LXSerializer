# LX Serializer

A Roblox place serializer written in Lua.

LX Serializer saves Roblox instances and their properties to `.rbxlx` files that can be opened in Roblox Studio.

## Project status

This repository is branded as LX Serializer and no longer uses the legacy Fishilizer naming.

## Files

- `Fishilizer.lua` - compatibility entry point for older scripts
- `LXSerializer.lua` - primary loader for LX Serializer
- `logo.svg` - project mascot/logo asset

## Usage

```lua
loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/Civilation/LXSerializer/main/LXSerializer.lua"
))()
```

## Notes

- Legacy `Fishilizer` aliases remain only as compatibility shims.
- New projects should prefer `LXSerializer` and `LX_SERIALIZER_CONFIG` naming.
