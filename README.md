<div align="center">

<img src="logo.png" alt="LX Serializer Logo" width="150" />

# LX Serializer

**A Roblox place serializer written in Lua.**

LX Serializer saves Roblox instances and their properties to `.rbxlx` files that can be opened in Roblox Studio.

[![Repository](https://img.shields.io/badge/GitHub-Repository-181717?style=flat-square&logo=github)](https://github.com/4er2/LXSerializer)
[![Source](https://img.shields.io/badge/Source-Lua-blue?style=flat-square)](https://github.com/4er2/LXSerializer/blob/main/Serializer.lua)
[![Discord](https://img.shields.io/badge/Discord-Community-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/GZDXBMjndT)
[![Cash App](https://img.shields.io/badge/Cash%20App-Support-00C244?style=flat-square&logo=cashapp&logoColor=white)](https://cash.app/$aeroglass)

[GitHub Repository](https://github.com/4er2/LXSerializer) · [Source Code](https://github.com/4er2/LXSerializer/blob/main/Serializer.lua) · [Raw Lua Source](https://raw.githubusercontent.com/4er2/LXSerializer/main/Serializer.lua)

</div>

## Overview

LX Serializer reads the DataModel of a running Roblox game and saves the instances it can access. It supports property discovery, terrain data, CSG and union data, attributes, tags, and script extraction when the environment allows it.

You can save an entire place, export scripts separately, save models without scripts, or choose a specific instance to save.

The property lists LX Serializer needs are written into the script itself. The only thing it downloads is the Roblox API dump, which is just a list of class and property names — and if that download fails, the save still runs.

The goal is to save as much of the original place as possible. Some properties and data may not be accessible, so exported files might not be exact copies of the original.

## Features

- **Property discovery:** Uses `getproperties()` when available, combined with the built-in property maps.
- **Roblox API dump:** Reads class and property information to widen what can be saved.
- **Reflection support:** Uses engine reflection when available.
- **Terrain:** Saves terrain materials and occupancy data through voxel capture.
- **Unions and CSG:** Saves `UnionOperation`, `PartOperation`, `MeshPart` and friends through `AssetId`, `InitialSize`, `ChildData`, `PhysicsData` and the other binary properties, so Studio can rebuild the shape.
- **Attributes:** Can save instance attributes.
- **CollectionService tags:** Can save tags attached to instances.
- **Script extraction:** Recovers script source when the environment supports it.
- **Bytecode fallback:** Can save bytecode when enabled and available.
- **Export modes:** Supports full-place, script-only, and model-only exports.
- **Instance filtering:** Provides options for excluding player characters, core scripts, and other instances.
- **Tool preservation:** Can temporarily move eligible backpack tools into `StarterPack` while saving.
- **Streaming output:** Writes the file straight to disk in chunks, so very large places do not have to be held in memory all at once.
- **Progress display:** Shows a status line on your screen while saving.
- **Saved log:** Writes what happened to a log file you can read afterwards.

## Getting started

### Requirements

LX Serializer depends on the functions available in the environment where it runs.

- `writefile` — required. Without it there is nowhere to put the file, and the save stops straight away. The one exception is passing your own `Callback` function, which receives the finished XML instead.
- `gethiddenproperty` — needed for terrain, and for the binary union and mesh data. Without it, terrain is simply not saved.
- `decompile` — needed to recover script source.
- `getscriptbytecode` — optional, for the bytecode fallback.
- `setclipboard` — optional, for the clipboard output.
- HTTP access — optional, for the Roblox API dump.

Not every environment supports all of these. Features that depend on unavailable functions are skipped, and the script tells you which ones.

### Automatic execution

Load LX Serializer with the following code:

```lua
loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/4er2/LXSerializer/main/Serializer.lua"
))()
```

This loads LX Serializer and saves the whole place about a second later.

### Manual execution

To control what gets saved, turn off the automatic save before loading LX Serializer.

```lua
getgenv().LX_CONFIG = { AutoRun = false }

local Fish = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/4er2/LXSerializer/main/Serializer.lua"
))()

Fish.Init()

-- Save the entire place
Fish.SavePlace("MyPlace")

-- Save scripts
Fish.SaveScripts(game, "ScriptsOnly")

-- Save non-script instances
Fish.SaveModels(game, "ModelsOnly")

-- Save a specific instance
Fish.Save(workspace.MyModel, "SingleModel")
```

Saving to disk requires an environment with `writefile`.

## Export modes

LX Serializer has three main export modes.

| Mode | Description |
| --- | --- |
| `full` | Saves supported instances and properties, including scripts. |
| `scripts` | Saves script instances such as `Script`, `LocalScript`, and `ModuleScript`. |
| `models` | Saves non-script instances. |

The `SaveScripts()` and `SaveModels()` functions select their respective modes automatically.

### Save a specific model

```lua
Fish.Save(workspace.MyModel, "MyModel")
```

### Save scripts from a model

```lua
Fish.SaveScripts(workspace.MyModel, "MyScripts")
```

### Save non-script instances from a folder

```lua
Fish.SaveModels(workspace.MyFolder, "MyModels")
```

### Save the entire place

```lua
Fish.SavePlace("MyPlace")
```

The resulting file depends on the selected options and the functions available in the environment.

## API reference

The main functions available through the `Fish` table include:

| Function | Description |
| --- | --- |
| `Fish.Init()` | Loads supporting data and prepares LX Serializer for use. |
| `Fish.Save(instance, name?, opts?)` | Saves an instance or an array of instances. |
| `Fish.SavePlace(name?, opts?)` | Saves the current place. |
| `Fish.SaveInstance(instance, name?, opts?)` | Saves a specific instance. |
| `Fish.SaveScripts(instance, name?, opts?)` | Saves scripts. |
| `Fish.SaveModels(instance, name?, opts?)` | Saves non-script instances. |
| `Fish.FetchClasses(cacheFile?)` | Fetches or loads cached Roblox API information. |
| `Fish.ApplyAPIDump(data)` | Reads API dump information for property discovery. |

LX Serializer also registers convenience aliases in the execution environment:

| Alias | Description |
| --- | --- |
| `saveplace(name?, opts?)` | Saves the current place. |
| `dumpgame(name?, opts?)` | Saves the current place. |
| `fishsave(name?, opts?)` | Saves the current place. |
| `fetchplace(name?, opts?)` | Saves the current place. |
| `serialize(name?, opts?)` | Saves the current place. |
| `saveinstance(inst, name?, opts?)` | Saves a specific instance. |

The script itself is available as `getgenv().LXSerializer` and `getgenv().Fish`.

For additional information, see the [LX Serializer GitHub repository](https://github.com/4er2/LXSerializer).

## Configuration

Configuration can be set through `LX_CONFIG` before loading the script.

### Example

```lua
getgenv().LX_CONFIG = {
    Mode = "full",

    AutoRun = false,
    Decompile = false,
    SaveBytecode = false,

    RemovePlayerCharacters = true,
    StripCharacters = true,
    StripCoreScripts = true,

    IncludeBackpack = true,
    EmitTags = true,
    EmitAttributes = true,

    AvoidFileOverwrite = true,
    Notify = true,
    ShowStatus = true
}

loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/4er2/LXSerializer/main/Serializer.lua"
))()
```

This example turns off the automatic save and decompilation, enables attribute and tag saving, and excludes player characters.

### Per-save options

You can also pass options directly to a save function.

```lua
Fish.SavePlace("MyPlace", {
    Mode = "full",
    Decompile = false,
    EmitAttributes = true,
    EmitTags = true,
    RemovePlayerCharacters = true
})
```

This changes the settings for one export without changing the global configuration.

### Common options

| Option | Default | Description |
| --- | --- | --- |
| `Mode` | `"full"` | Selects the export mode. |
| `Decompile` | `true` | Attempts to recover script source when supported. |
| `SaveBytecode` | `false` | Enables bytecode fallback where available. |
| `UseGetProperties` | `true` | Uses `getproperties()` when available. |
| `APIProperties` | `true` | Uses API property information when saving. |
| `UseReflectionService` | `true` | Uses engine reflection when available. |
| `FetchDocs` | `true` | Enables API dump fetching. |
| `APIDumpURL` | MaximumADHD's API dump | Sets where the API dump is downloaded from. |
| `EmitTags` | `true` | Includes supported CollectionService tag data. |
| `EmitAttributes` | `false` | Includes instance attributes. |
| `IncludeBackpack` | `true` | Includes eligible backpack tools in the save process. |
| `RemovePlayerCharacters` | `true` | Excludes player characters. |
| `StripCharacters` | `true` | Filters character-related instances. |
| `StripCoreScripts` | `true` | Filters core script containers. |
| `IgnoreDefaultProps` | `true` | Skips properties matching their defaults. |
| `IgnoreNotArchivable` | `true` | Applies archivable-related filtering. |
| `Anonymous` | `false` | Replaces character names with the player's user id. |
| `Depth` | `100` | Sets the maximum traversal depth. |
| `OUT` | `"LXSerializer"` | Sets the output folder name. |
| `FilePath` | `false` | Sets an exact file to write to. |
| `AvoidFileOverwrite` | `true` | Keeps an existing file of the same name. |
| `StreamToFile` | `true` | Writes the file in chunks as it is built. |
| `StreamChunk` | `1048576` | Sets the chunk size used for streaming. |
| `LogToFile` | `true` | Writes the run log to `LXSerializer/LXSerializer.log`. |
| `ShowStatus` | `true` | Shows the progress line on your screen. |
| `Notify` | `true` | Sends a game notification when the save finishes. |
| `ReadMe` | `true` | Writes a README script into the saved place. |
| `Callback` | `false` | A function that receives the finished XML. |
| `Clipboard` | `false` | Copies the finished XML to the clipboard. |
| `AutoRun` | `true` | Saves the place shortly after the script loads. |

These are the main options and their documented defaults. Other options may be available in the current version.

See the [LX Serializer GitHub repository](https://github.com/4er2/LXSerializer) for project information and source code.

> [!WARNING]
> `KillAllScripts` is an available option that defaults to `false`. Enabling it disables accessible script instances during saving and affects the running game.

## How it works

LX Serializer goes through the selected instances and builds an XML file from the data it can access.

1. Loads configuration and the built-in property data.
2. Gets property information from the API dump, the built-in maps, and reflection when available.
3. Goes through the selected instances and applies the configured filters.
4. Collects supported properties, attributes, tags, and content data.
5. Captures terrain voxels and union, mesh, and CSG binary data when `gethiddenproperty` is available.
6. Recovers script source when decompilation is enabled and supported.
7. Builds the `.rbxlx` XML, writing it straight to disk in chunks.
8. Reports the result on your screen and in the log file.

Some properties need special handling because they contain binary data or values that cannot be written as ordinary XML.

## Limitations

LX Serializer cannot save every Roblox place perfectly. The result depends on which instances and properties the environment can access.

### Script source

Server `Script` instances receive placeholder source in the current implementation. Their original source should not be expected in the exported file.

`LocalScript` and `ModuleScript` source recovery depends on available source access and decompilation functions. Bytecode fallback does not guarantee that the original source can be recovered.

### Terrain

Terrain saving needs `gethiddenproperty`. Without it, terrain is left out of the file entirely.

### Unions and meshes

Union and mesh shapes are saved through `AssetId` and the binary geometry properties. The shape is rebuilt by Studio when the file is opened, so the asset still needs to be reachable from the machine opening it.

### Properties

Some properties may be inaccessible, unsupported, or filtered out. Roblox updates can introduce new classes and properties that the built-in maps do not cover.

### Runtime state

Not all runtime data can be restored from an exported file. Engine-managed values, unavailable assets, server-only data, and unsupported instance types can prevent an exact copy.

### File output

The file is written with `writefile`. Successfully building the XML does not always mean the file landed where you expected.

## Troubleshooting

### The save fails

- The status line on your screen says why. `Failed: executor has no writefile` means the environment cannot write files.
- Check `LXSerializer/LXSerializer.log` for the details.
- Try saving a smaller model to find out which instances might be causing the problem.

### Properties are missing

- Check whether `getproperties()` is available.
- Check the API property settings.
- Review which properties are filtered by your options.

### Terrain is missing

- Check whether `gethiddenproperty` is available. Without it terrain is skipped.

### Unions look wrong or are missing their shape

- Check whether `gethiddenproperty` is available, since the geometry data is read through it.
- Open the file on a machine that can reach the union asset.

### Scripts are missing source

- Check whether `Decompile` is enabled.
- Check whether the environment has a working `decompile` function.
- Remember that the current implementation does not recover the original source of server scripts.

### The exported file will not open

- Check the log for serialization errors.
- Make sure the file was written completely.
- Try exporting a smaller section.
- Open the file in Roblox Studio to see whether any data is invalid or unsupported.

## TODO

### Completed

- [x] Make the core XML serializer.
- [x] Add full-place, script-only, and model-only export modes.
- [x] Add support for saving individual instances.
- [x] Add property discovery and built-in property maps.
- [x] Add Roblox API dump support.
- [x] Add engine reflection support where available.
- [x] Add instance filtering options.
- [x] Add attribute and CollectionService tag saving.
- [x] Add terrain voxel capture.
- [x] Add support for accessible CSG and union binary properties.
- [x] Add optional script decompilation and bytecode fallback.
- [x] Write the file in chunks so large places fit.
- [x] Add the on-screen progress line, log file, and output methods.
- [x] Publish the source code on GitHub.

### Planned

- [ ] Improve terrain saving, especially for large regions.
- [ ] Add support for more engine-specific properties.
- [ ] Add tests to check whether generated `.rbxlx` files are valid.
- [ ] Test compatibility with Roblox updates.
- [ ] Show which instances and properties were skipped.
- [ ] Make serialization errors easier to understand.
- [ ] Add more examples to the documentation.
- [ ] Add tests for attributes, tags, terrain, and CSG data.

The unchecked items are things that could be worked on in the future. They are not finished features.

## Support LX Serializer

If you'd like to support LX Serializer and its development, you can send a donation through Cash App. It's completely optional, but any support is appreciated. <3

[![Cash App](https://img.shields.io/badge/Cash%20App-Support%20LX%20Serializer-00C244?style=flat-square&logo=cashapp&logoColor=white)](https://cash.app/$aeroglass)

Cash App: [$aeroglass](https://cash.app/$aeroglass)

## Links

- [GitHub Repository](https://github.com/4er2/LXSerializer)
- [Source Code](https://github.com/4er2/LXSerializer/blob/main/Serializer.lua)
- [Raw Lua Source](https://raw.githubusercontent.com/4er2/LXSerializer/main/Serializer.lua)
- [Discord](https://discord.gg/GZDXBMjndT)
- [Cash App](https://cash.app/$aeroglass)

## Disclaimer

LX Serializer is an independent project for Roblox serialization and game development research. It is not affiliated with or endorsed by Roblox Corporation.

Only save places and data you are allowed to access. Respect other creators' work and Roblox's rules.

Saving and decompilation depend on the environment. LX Serializer cannot guarantee that every instance, property, or script will be recovered. Keep backups of important files before using it.

<div align="center">

**Made with ❤️ by Garfield Cat Presents**

*Thanks for checking out LX Serializer!*

</div>
