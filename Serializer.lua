--[[

LX Serializer is now open-sourced.

A gift from Garfield Cat Presents

The source is available for anyone who wants to contribute to its development

LX Serializer is still being worked on, and there is more to come.
There are features to improve, and things to fix

Eventually, once LX Serializer reaches its full power, it will no longer
be open-sourced. Until then, enjoy this special gift and make the most of it.

If you find bugs or have suggestions, feel free to share them with the
community. Feedback is always appreciated!!

Please give credit to the original project if you use or modify its code.

Thank you to everyone who has supported LX Serializer so far.

Enjoy this special gift <3

]]


local Fish = {}


local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local IO = {
    writefile = writefile,
    readfile = readfile,
    makefolder = makefolder,
    isfolder = isfolder,
    isfile = isfile,
    delfile = delfile,
    appendfile = appendfile,
    setclipboard = setclipboard,
    getproperties = getproperties,
    gethiddenproperty = gethiddenproperty,
    decompile = decompile,
    getscriptbytecode = getscriptbytecode,
    gethui = gethui,
    protectgui = protectgui,
}

local sbyte, schar, sfind, sgsub, fmt = string.byte, string.char, string.find, string.gsub, string.format
local floor, abs, huge = math.floor, math.abs, math.huge
local tconcat, tclear = table.concat, table.clear
local clock = os.clock

local _logCache = {}
local _logPath = nil

local function logFilePath()
    if _logPath then return _logPath end
    local out = tostring(Fish.Options.OUT or "LXSerializer")
    if IO.makefolder and IO.isfolder then
        local okF, exists = pcall(IO.isfolder, out)
        if not okF or not exists then pcall(IO.makefolder, out) end
    end
    _logPath = out .. "/LXSerializer.log"
    return _logPath
end

local function flushLog()
    if not Fish.Options.LogToFile or #_logCache == 0 then return end
    local path = logFilePath()
    local blob = tconcat(_logCache, "\n") .. "\n"
    _logCache = {}
    if IO.appendfile then
        pcall(IO.appendfile, path, blob)
    elseif IO.writefile then
        pcall(IO.writefile, path, blob)
    end
end

local function pushLog(text)
    if not Fish.Options.LogToFile then return end
    _logCache[#_logCache + 1] = "[" .. os.date("!%H:%M:%S") .. "] " .. tostring(text)
    if #_logCache >= 32 then flushLog() end
end

local function log(msg)
    pushLog(msg)
end

local Status = { token = 0 }

function Status.mount()
    if Status.label and Status.gui and Status.gui.Parent then return Status.label end

    local gui = Instance.new("ScreenGui")
    gui.Name = HttpService:GenerateGUID(false)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0, 14)
    label.Size = UDim2.new(0, 0, 0, 34)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.4
    label.Text = ""
    label.Parent = gui

    if IO.protectgui then pcall(IO.protectgui, gui) end
    gui.Parent = IO.gethui and IO.gethui() or CoreGui

    Status.gui = gui
    Status.label = label
    return label
end

function Status.fade(delay)
    local token = Status.token
    task.delay(delay or 4, function()
        if Status.token ~= token or not Status.label then return end
        local label, gui = Status.label, Status.gui
        local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        pcall(function()
            TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
        end)
        task.wait(0.7)
        if Status.token ~= token then return end
        pcall(function() gui:Destroy() end)
        Status.gui = nil
        Status.label = nil
    end)
end

local function setStatusText(text)
    text = tostring(text)
    Status.token = Status.token + 1
    pushLog(text)
    if not Fish.Options.ShowStatus then return end
    local ok, label = pcall(Status.mount)
    if ok and label then
        label.TextTransparency = 0
        label.TextStrokeTransparency = 0.4
        label.Text = text
    end
end


--- apis
Fish.Options = {
    Decompile = true,
    MaxThreads = 6,
    DecompileTimeout = 10,
    SaveBytecode = false,
    RemovePlayerCharacters = true,
    IncludeBackpack = true,
    IgnoreDefaultProps = true,
    IgnoreNotArchivable = true,
    UseGetProperties = true,
    FetchDocs = true,
    APIProperties = true,
    UseReflectionService = true,
    Mode = "full",
    FilePath = false,
    Callback = false,
    Clipboard = false,
    AvoidFileOverwrite = true,
    KillAllScripts = false,
    Anonymous = false,
    EmitTags = true,
    EmitAttributes = false,
    StripCharacters = true,
    StripCoreScripts = true,
    Depth = 100,
    Notify = true,
    ShowStatus = true,
    ReadMe = true,
    StreamToFile = true,
    StreamChunk = 4194304,
    LogToFile = true,
    AutoRun = true,
    OUT = "LXSerializer",
    APIDumpURL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json", -- why do i still use this
}

local DATA = {
    version = "0.0.0",
    instance_specific = {},
    critical_props = {},
    binary_props = {},
    real_content_props = {},
    content_prop_exact = {},
    core_script_names = {},
    character_classes = {},
    skip_svc = {},
    skip_prop = {},
    attr_type_ids = { string=0x02, boolean=0x03, number=0x04 },
    ser_types = {},
    server_script_placeholder = "-- Serverscripts are almost IMPOSSIBLE to save without additional requirements in every serverscript",
    readme_template = "",
    decompiler = nil,
}

local function toSet(arr)
    local s = {}
    if type(arr) == "table" then
        for _, v in ipairs(arr) do
            if type(v) == "string" then s[v] = true end
        end
    end
    return s
end

local CRITICAL_PROPS = {
    "Name","Archivable","Source","Disabled","RunContext","Texture","TextureId","TextureID",
    "Image","MeshId","SoundId","AnimationId","ShirtTemplate","PantsTemplate","Graphic",
    "Size","CFrame","Anchored","CanCollide","CanTouch","Transparency","Reflectance","Material",
    "Color","BrickColor","Value","Text","FontFace","BackgroundColor3","BackgroundTransparency",
    "Visible","ZIndex","Ambient","Brightness","ClockTime","Part0","Part1","C0","C1",
    "Attachment0","Attachment1","SmoothGrid","MaterialColors","ChildData","PhysicsData","PhysicalConfigData",
}
local CRITICAL_PROPS_SET = toSet(CRITICAL_PROPS)
local GAME_SVC = toSet({"Workspace","Lighting","ReplicatedFirst","ReplicatedStorage","StarterGui","StarterPack","StarterPlayer","Teams","SoundService","MaterialService","ServerStorage","ServerScriptService"})
local ROBLOX_JUNK = toSet({"PlayerModule","PlayerScriptsLoader","RbxCharacterSounds","ChatScript","BubbleChat","ChatServiceRunner","DefaultChatSystemChatEvents","ClientChatModules","ChatModules","CoreScripts"})
local JUNK_PARENTS = toSet({"StarterPlayerScripts","StarterCharacterScripts","ReplicatedStorage","ReplicatedFirst","StarterGui"})
local SKIP_PROP = toSet({"Parent","RobloxLocked","HistoryId","ClassName","AttributesSerialize","Tags"})
local PLAN_SKIP = toSet({"Source","Color3uint8","ScriptGuid","InitialSize"})
local BINARY_PROPS = toSet({"SmoothGrid","ChildData","ChildData2","MeshData","MeshData2","PhysicsData","PhysicalConfigData","MaterialColors"})
local REAL_CONTENT_PROPS = toSet({"Texture","TextureId","TextureID","Image","MeshId","SoundId","AnimationId","ShirtTemplate","PantsTemplate","Graphic","AssetId"})
local CHARACTER_CLASSES = toSet({"Humanoid","Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso"})
local NUMBER_TYPES = toSet({"float","double","int","int64"})
local EQ_RELIABLE = toSet({"Vector3","Vector2","CFrame","Color3","UDim","UDim2","BrickColor","EnumItem","Instance","NumberRange","Rect","Ray","Faces","Axes","boolean","string"})
local CONTENT_PROP_EXACT = {}
local CORE_SCRIPT_NAMES = {}
local INSTANCE_SPECIFIC = {}
local ATTR_TYPE_IDS = { string=0x02, boolean=0x03, number=0x04 }



local function shouldSkipProp(name)
    if SKIP_PROP[name] then return true end
    if CONTENT_PROP_EXACT[name] then return true end
    return false
end



local apiClassProps = {}
local apiHidden = {}
local apiTypes = {}

local reflSvc = nil
local reflDone = {}

local function buildReflectionProps()
    if not Fish.Options.UseReflectionService then return end
    local ok, RS = pcall(function() return game:GetService("ReflectionService") end)
    if not ok or not RS then
        log("ReflectionService not available.")
        return
    end
    reflSvc = RS
end

local function reflectClass(className)
    if not reflSvc or reflDone[className] then return end
    reflDone[className] = true
    if INSTANCE_SPECIFIC[className] then return end
    local okProps, reflectedProps = pcall(function() return reflSvc:GetPropertiesOfClass(className, {}) end)
    if not okProps or not reflectedProps then return end
    local props = {}
    for _, prop in ipairs(reflectedProps) do
        if prop.Name and not shouldSkipProp(prop.Name) then
            props[#props + 1] = prop.Name
            if CRITICAL_PROPS_SET[prop.Name] then
                apiClassProps[className] = apiClassProps[className] or {}
                apiClassProps[className][prop.Name] = true
            end
        end
    end
    if #props > 0 then INSTANCE_SPECIFIC[className] = props end
end

local function isPropValid(cls, propName)
    if CRITICAL_PROPS_SET[propName] then return true end
    local apiSet = apiClassProps[cls]
    if not apiSet then return true end
    return apiSet[propName] == true
end

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local b64pairs = {}
for i = 0, 63 do b64pairs[i] = b64chars:sub(i + 1, i + 1) end
local b64pairs12 = {}
for i = 0, 4095 do b64pairs12[i] = b64pairs[i // 64] .. b64pairs[i % 64] end

local function luaB64(s)
    local res = {}
    local n = 0
    local len = #s
    for i = 1, len - 2, 3 do
        local a, b, c = sbyte(s, i, i + 2)
        local v = a * 65536 + b * 256 + c
        n = n + 1
        res[n] = b64pairs12[v // 4096] .. b64pairs12[v % 4096]
    end
    local rem = len % 3
    if rem == 1 then
        local a = sbyte(s, len)
        n = n + 1
        res[n] = b64pairs[a // 4] .. b64pairs[(a % 4) * 16] .. "=="
    elseif rem == 2 then
        local a, b = sbyte(s, len - 1, len)
        local v = a * 256 + b
        n = n + 1
        res[n] = b64pairs[v // 1024] .. b64pairs[(v // 16) % 64] .. b64pairs[(v % 16) * 4] .. "="
    end
    return tconcat(res)
end

local nativeB64 = nil
do
    local candidates = {}
    if type(crypt) == "table" then
        candidates[#candidates + 1] = crypt.base64encode
        candidates[#candidates + 1] = crypt.base64_encode
        if type(crypt.base64) == "table" then candidates[#candidates + 1] = crypt.base64.encode end
    end
    if type(base64) == "table" then candidates[#candidates + 1] = base64.encode end
    candidates[#candidates + 1] = base64_encode
    local probe = {}
    for i = 0, 255 do probe[#probe + 1] = schar(i) end
    probe = tconcat(probe) .. "\0\0xy"
    local expected = luaB64(probe)
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            local ok, r = pcall(fn, probe)
            if ok and r == expected then nativeB64 = fn break end
        end
    end
end

local function b64(s)
    if type(s) ~= "string" then return "" end
    if s == "" then return "" end
    if nativeB64 then
        local ok, r = pcall(nativeB64, s)
        if ok and type(r) == "string" then return r end
    end
    return luaB64(s)
end

local function decompileScript(inst)
    if not IO.decompile then return nil end
    local ok, res = pcall(IO.decompile, inst)
    if ok and type(res) == "string" and res ~= "" then return res end
    return nil
end

function Fish.FetchClasses(cacheFile)
    cacheFile = cacheFile or "LXSerializerAPIDump.json"
    if IO.isfile and IO.readfile then
        local okI, exists = pcall(IO.isfile, cacheFile)
        if okI and exists then
            local okR, cached = pcall(IO.readfile, cacheFile)
            if okR and cached and #cached > 100 then
                local okD, data = pcall(HttpService.JSONDecode, HttpService, cached)
                if okD and data then
                    Fish.ApplyAPIDump(data)
                    log("Loaded cached API dump")
                    return data
                end
            end
        end
    end
    local okG, raw = pcall(function() return game:HttpGet(Fish.Options.APIDumpURL) end)
    if not okG or not raw then log("Failed to fetch API dump") return nil end
    if IO.writefile then pcall(IO.writefile, cacheFile, raw) end
    local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okD or not data then log("Failed to parse API dump") return nil end
    Fish.ApplyAPIDump(data)
    return data
end

function Fish.ApplyAPIDump(data)
    if type(data) ~= "table" or type(data.Classes) ~= "table" then return end
    local byName = {}
    for _, class in ipairs(data.Classes) do
        if type(class) == "table" and class.Name then byName[class.Name] = class end
    end
    local resolved = {}
    local function resolve(cn, guard)
        local r = resolved[cn]
        if r then return r end
        r = { list = {}, set = {}, all = {}, hidden = {}, types = {} }
        resolved[cn] = r
        local class = byName[cn]
        if not class then return r end
        if type(class.Members) == "table" then
            for _, m in ipairs(class.Members) do
                local pn = m.Name
                if m.MemberType == "Property" and type(pn) == "string" then
                    r.all[pn] = true
                    if type(m.Tags) == "table" then
                        for _, t in ipairs(m.Tags) do
                            if t == "NotScriptable" then r.hidden[pn] = true break end
                        end
                    end
                    if type(m.ValueType) == "table" and type(m.ValueType.Name) == "string" then
                        local cat = m.ValueType.Category
                        if cat == "Enum" then
                            r.types[pn] = "Enum"
                        elseif cat == "Class" then
                            r.types[pn] = "Instance"
                        else
                            r.types[pn] = m.ValueType.Name
                        end
                    end
                    local ser = m.Serialization
                    local canLoad = not (type(ser) == "table" and ser.CanLoad == false)
                    if canLoad and not r.set[pn] and not shouldSkipProp(pn) then
                        r.set[pn] = true
                        r.list[#r.list + 1] = pn
                    end
                end
            end
        end
        local sc = class.Superclass
        if sc and byName[sc] and guard < 64 then
            local sup = resolve(sc, guard + 1)
            for k in pairs(sup.all) do r.all[k] = true end
            for k in pairs(sup.hidden) do if r.hidden[k] == nil then r.hidden[k] = true end end
            for k, v in pairs(sup.types) do if r.types[k] == nil then r.types[k] = v end end
            for _, k in ipairs(sup.list) do
                if not r.set[k] then
                    r.set[k] = true
                    r.list[#r.list + 1] = k
                end
            end
        end
        return r
    end
    local added = 0
    for cn in pairs(byName) do
        local r = resolve(cn, 0)
        apiClassProps[cn] = r.all
        apiHidden[cn] = r.hidden
        apiTypes[cn] = r.types
        if not INSTANCE_SPECIFIC[cn] and #r.list > 0 then
            INSTANCE_SPECIFIC[cn] = r.list
            added = added + 1
        end
    end
    log("API dump: added " .. added .. " classes to INSTANCE_SPECIFIC")
end

local _statusAccum = 0
local _lastYield = clock()
local _lastStatus = 0

local function breathe()
    if clock() - _lastYield >= 0.5 then
        task.wait()
        _lastYield = clock()
    end
end

local function bumpStatus(prefix, current, total)
    _statusAccum = _statusAccum + 1
    breathe()
    if clock() - _lastStatus < 0.25 then return end
    _lastStatus = clock()
    local pct = 0
    if total and total > 0 then
        pct = math.min(100, floor((current / total) * 100))
    end
    setStatusText(prefix .. " " .. current .. "/" .. tostring(total) .. " (" .. pct .. "%)")
end

local function u32(n) return string.pack("<I4", n) end
local function f32(n) return string.pack("<f", n) end
local function f64(n) return string.pack("<d", n) end
local function i32(n) return string.pack("<i4", n) end
local function wstr(s) return u32(#s) .. s end

local CLEAN_PAT = "[\0-\8\11\12\14-\31&<>\"']"
local CLEAN_MAP = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&apos;" }
for i = 0, 31 do
    if i ~= 9 and i ~= 10 and i ~= 13 then CLEAN_MAP[schar(i)] = "" end
end

local function fixUtf8(s)
    if utf8.len(s) then return s end
    local out, n, i, len = {}, 0, 1, #s
    while i <= len do
        local _, bad = utf8.len(s, i)
        if not bad then
            n = n + 1
            out[n] = s:sub(i)
            break
        end
        if bad > i then
            n = n + 1
            out[n] = s:sub(i, bad - 1)
        end
        i = bad + 1
    end
    return tconcat(out)
end

local function clean(s)
    if type(s) ~= "string" then s = tostring(s) end
    s = fixUtf8(s)
    if not sfind(s, CLEAN_PAT) then return s end
    return (sgsub(s, CLEAN_PAT, CLEAN_MAP))
end

local function nm(x)
    if type(x) ~= "number" or x ~= x then return "0" end
    if x == huge then return "1e308" end
    if x == -huge then return "-1e308" end
    if x == floor(x) and abs(x) < 1e15 then return fmt("%d", x) end
    return fmt("%.10g", x)
end

local function isRealContent(name) return REAL_CONTENT_PROPS[name] == true end

local URI_ACCESSORS = {"Source","Uri","Url","URL","Value","Text","String","AssetId","AssetID","Id","ID","Content","source","uri","url","value"}
local URI_METHODS = {"ToString","GetSource","GetUri","GetUrl"}

local function extractUri(v)
    if v == nil then return nil end
    local tv = type(v)
    if tv == "string" then
        if v == "" then return nil end
        local id = v:match("rbxassetid://(%d+)")
        if id then return "rbxassetid://" .. id end
        local num = v:match("^(%d+)$")
        if num and #num >= 5 then return "rbxassetid://" .. num end
        if v:match("^rbxasset://") or v:match("^rbxgameasset://") or v:match("^rbxthumb://") or v:match("^https?://") or v:match("^rbxfile://") then return v end
        local tail = v:match("(%d+)%s*$")
        if tail and #tail >= 5 then return "rbxassetid://" .. tail end
        return nil
    end
    if tv == "number" then return "rbxassetid://" .. tostring(v) end
    for _, key in ipairs(URI_ACCESSORS) do
        local ok, s = pcall(function() return v[key] end)
        if ok and type(s) == "string" and s ~= "" then
            local inner = extractUri(s)
            if inner then return inner end
        end
        if ok and type(s) == "number" then return "rbxassetid://" .. tostring(s) end
    end
    for _, m in ipairs(URI_METHODS) do
        local ok, f = pcall(function() return v[m] end)
        if ok and type(f) == "function" then
            local ok2, s = pcall(f, v)
            if ok2 and type(s) == "string" and s ~= "" then
                local inner = extractUri(s)
                if inner then return inner end
            end
        end
    end
    if tv == "table" then
        for _, val in pairs(v) do
            if type(val) == "string" and val ~= "" then
                local inner = extractUri(val)
                if inner then return inner end
            end
        end
    end
    local ok, s = pcall(tostring, v)
    if ok and type(s) == "string" and s ~= "" then
        local id = s:match("rbxassetid://(%d+)")
        if id then return "rbxassetid://" .. id end
        local asset = s:match("rbxasset://([^%s%)%,]+)")
        if asset then return "rbxasset://" .. asset end
        local ga = s:match("rbxgameasset://(%d+)")
        if ga then return "rbxgameasset://" .. ga end
        local thumb = s:match("rbxthumb://[^%s%)]+")
        if thumb then return thumb end
        local http = s:match("(https?://[^%s%)%,]+)")
        if http then return http end
        local inner = s:match("Content%((.-)%)")
        if inner and inner ~= "" and inner ~= s then return extractUri(inner) end
    end
    return nil
end

local function notify(title, text, dur)
    if not Fish.Options.Notify then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 6,
        })
    end)
end

local function serContentTag(name, uri) return '<Content name="' .. clean(name) .. '"><url>' .. clean(uri) .. '</url></Content>' end
local function serString(name, v) if type(v) ~= "string" then return nil end return '<string name="' .. clean(name) .. '">' .. clean(v) .. '</string>' end
local function serProtectedString(name, v) if type(v) ~= "string" then v = "" end return '<ProtectedString name="' .. clean(name) .. '">' .. clean(v) .. '</ProtectedString>' end
local function serBool(name, v) if type(v) ~= "boolean" then v = v and true or false end return '<bool name="' .. clean(name) .. '">' .. (v and "true" or "false") .. '</bool>' end
local function serInt(name, v) return '<int name="' .. clean(name) .. '">' .. fmt("%d", v) .. '</int>' end
local function serInt64(name, v) return '<int64 name="' .. clean(name) .. '">' .. fmt("%d", v) .. '</int64>' end
local function serFloat(name, v) return '<float name="' .. clean(name) .. '">' .. nm(v) .. '</float>' end
local function serDouble(name, v) return '<double name="' .. clean(name) .. '">' .. nm(v) .. '</double>' end
local function serNumber(name, v)
    if v == floor(v) and v >= -2147483648 and v <= 2147483647 then return serInt(name, v) end
    if v == floor(v) and abs(v) < 9007199254740992 then return serInt64(name, v) end
    return serDouble(name, v)
end
local serNumberAs = { float = serFloat, double = serDouble, int = serInt, int64 = serInt64 }
local function serVector2(name, v) return '<Vector2 name="' .. clean(name) .. '"><X>' .. nm(v.X) .. '</X><Y>' .. nm(v.Y) .. '</Y></Vector2>' end
local function serVector3(name, v) return '<Vector3 name="' .. clean(name) .. '"><X>' .. nm(v.X) .. '</X><Y>' .. nm(v.Y) .. '</Y><Z>' .. nm(v.Z) .. '</Z></Vector3>' end
local function serCFrame(name, v)
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
    return '<CoordinateFrame name="' .. clean(name) .. '"><X>' .. nm(x) .. '</X><Y>' .. nm(y) .. '</Y><Z>' .. nm(z)
        .. '</Z><R00>' .. nm(r00) .. '</R00><R01>' .. nm(r01) .. '</R01><R02>' .. nm(r02)
        .. '</R02><R10>' .. nm(r10) .. '</R10><R11>' .. nm(r11) .. '</R11><R12>' .. nm(r12)
        .. '</R12><R20>' .. nm(r20) .. '</R20><R21>' .. nm(r21) .. '</R21><R22>' .. nm(r22)
        .. '</R22></CoordinateFrame>'
end
local function serColor3(name, v) return '<Color3 name="' .. clean(name) .. '"><R>' .. nm(v.R) .. '</R><G>' .. nm(v.G) .. '</G><B>' .. nm(v.B) .. '</B></Color3>' end
local function serBrickColor(name, v) return '<BrickColor name="' .. clean(name) .. '">' .. tostring(v.Number) .. '</BrickColor>' end
local function serUDim(name, v) return '<UDim name="' .. clean(name) .. '"><S>' .. nm(v.Scale) .. '</S><O>' .. tostring(v.Offset) .. '</O></UDim>' end
local function serUDim2(name, v) return '<UDim2 name="' .. clean(name) .. '"><XS>' .. nm(v.X.Scale) .. '</XS><XO>' .. tostring(v.X.Offset) .. '</XO><YS>' .. nm(v.Y.Scale) .. '</YS><YO>' .. tostring(v.Y.Offset) .. '</YO></UDim2>' end
local function serRect(name, v) return '<Rect name="' .. clean(name) .. '"><min><X>' .. nm(v.Min.X) .. '</X><Y>' .. nm(v.Min.Y) .. '</Y></min><max><X>' .. nm(v.Max.X) .. '</X><Y>' .. nm(v.Max.Y) .. '</Y></max></Rect>' end
local function serNumberRange(name, v) return '<NumberRange name="' .. clean(name) .. '"><Min>' .. nm(v.Min) .. '</Min><Max>' .. nm(v.Max) .. '</Max></NumberRange>' end
local function serNumberSequence(name, v)
    local parts = { '<NumberSequence name="' .. clean(name) .. '">' }
    for _, k in ipairs(v.Keypoints) do parts[#parts + 1] = '<Keypoint><Time>' .. nm(k.Time) .. '</Time><Value>' .. nm(k.Value) .. '</Value><Envelope>' .. nm(k.Envelope) .. '</Envelope></Keypoint>' end
    parts[#parts + 1] = '</NumberSequence>'
    return tconcat(parts)
end
local function serColorSequence(name, v)
    local parts = { '<ColorSequence name="' .. clean(name) .. '">' }
    for _, k in ipairs(v.Keypoints) do parts[#parts + 1] = '<Keypoint><Time>' .. nm(k.Time) .. '</Time><Color><R>' .. nm(k.Value.R) .. '</R><G>' .. nm(k.Value.G) .. '</G><B>' .. nm(k.Value.B) .. '</B></Color></Keypoint>' end
    parts[#parts + 1] = '</ColorSequence>'
    return tconcat(parts)
end
local function serEnumItem(name, v)
    local val = v.Value
    if type(val) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(val) .. '</token>' end
    return nil
end
local function serTokenNumber(name, v)
    if type(v) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(v) .. '</token>' end
    local ok, val = pcall(function() return v.Value end)
    if ok and type(val) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(val) .. '</token>' end
    return nil
end
local FACE_KEYS = {"Top","Bottom","Left","Right","Front","Back"}
local AXIS_KEYS = {"X","Y","Z"}
local function serFaces(name, v)
    local f, base = 0, 1
    for _, k in ipairs(FACE_KEYS) do if v[k] then f = f + base end base = base * 2 end
    return '<token name="' .. clean(name) .. '">' .. f .. '</token>'
end
local function serAxes(name, v)
    local f, base = 0, 1
    for _, k in ipairs(AXIS_KEYS) do if v[k] then f = f + base end base = base * 2 end
    return '<token name="' .. clean(name) .. '">' .. f .. '</token>'
end

local Walker = { refs = {}, refCount = 0, totalInst = 0 }

local function serInstance(name, v)
    local r = Walker.refs[v]
    if r then return '<Ref name="' .. clean(name) .. '">' .. r .. '</Ref>' end
    return nil
end
local function serPhysicalProps(name, v)
    return '<PhysicalProperties name="' .. clean(name) .. '"><Density>' .. nm(v.Density) .. '</Density><Friction>' .. nm(v.Friction) .. '</Friction><Elasticity>' .. nm(v.Elasticity) .. '</Elasticity><FrictionWeight>' .. nm(v.FrictionWeight) .. '</FrictionWeight><ElasticityWeight>' .. nm(v.ElasticityWeight) .. '</ElasticityWeight></PhysicalProperties>'
end
local function serBinaryString(name, v)
    if type(v) ~= "string" then return nil end
    return '<BinaryString name="' .. clean(name) .. '">' .. b64(v) .. '</BinaryString>'
end
local function serRay(name, v)
    local o, d = v.Origin, v.Direction
    return '<Ray name="' .. clean(name) .. '"><Origin><X>' .. nm(o.X) .. '</X><Y>' .. nm(o.Y) .. '</Y><Z>' .. nm(o.Z) .. '</Z></Origin><Direction><X>' .. nm(d.X) .. '</X><Y>' .. nm(d.Y) .. '</Y><Z>' .. nm(d.Z) .. '</Z></Direction></Ray>'
end
local function serFont(name, v)
    local parts = {}
    pcall(function() parts[#parts + 1] = '<Family>' .. clean(v.Family) .. '</Family>' end)
    pcall(function() parts[#parts + 1] = '<Weight>' .. tostring(v.Weight.Value) .. '</Weight>' end)
    pcall(function() parts[#parts + 1] = '<Style>' .. tostring(v.Style.Value) .. '</Style>' end)
    if #parts == 0 then return nil end
    return '<Font name="' .. clean(name) .. '">' .. tconcat(parts) .. '</Font>'
end

local serByType = {
    string = serString, ProtectedString = serProtectedString, SharedString = serString,
    boolean = serBool, bool = serBool, number = serNumber, int = serInt, int64 = serInt64,
    float = serFloat, double = serDouble, Vector2 = serVector2, Vector3 = serVector3,
    CFrame = serCFrame, Color3 = serColor3, BrickColor = serBrickColor, UDim = serUDim,
    UDim2 = serUDim2, Rect = serRect, NumberRange = serNumberRange,
    NumberSequence = serNumberSequence, ColorSequence = serColorSequence,
    EnumItem = serEnumItem, Faces = serFaces, Axes = serAxes, Instance = serInstance,
    PhysicalProperties = serPhysicalProps, BinaryString = serBinaryString,
    Ray = serRay, Font = serFont, FontFace = serFont,
}


--[[

String class incase anything fails, we use this as a backup

]]


local specialPropHandlers = { Shape = serTokenNumber, Face = serTokenNumber, Material = serTokenNumber }

local SHARED_PROPS = toSet({"PhysicalConfigData","ChildData2","MeshData2"})
local STRING_TYPES = toSet({"string","ProtectedString"})
local TYPE_ALIAS = { OptionalCoordinateFrame = "CFrame", Content = "Content", ContentId = "string" }

local sharedPool, sharedOrder = {}, {}

local function resetShared()
    sharedPool, sharedOrder = {}, {}
end

local function serShared(name, data)
    local k = sharedPool[data]
    if not k then
        k = b64(fmt("LXSS%012d", #sharedOrder + 1))
        sharedPool[data] = k
        sharedOrder[#sharedOrder + 1] = { k, data }
    end
    return '<SharedString name="' .. clean(name) .. '">' .. k .. '</SharedString>'
end

local function sharedBlock()
    if #sharedOrder == 0 then return nil end
    local parts = { '<SharedStrings>' }
    for _, pair in ipairs(sharedOrder) do
        parts[#parts + 1] = '<SharedString md5="' .. pair[1] .. '">' .. b64(pair[2]) .. '</SharedString>'
    end
    parts[#parts + 1] = '</SharedStrings>'
    return tconcat(parts, "\n")
end

local function typeOk(vt, v)
    local tv = typeof(v)
    if NUMBER_TYPES[vt] then return tv == "number" end
    if vt == "bool" then return tv == "boolean" end
    if STRING_TYPES[vt] then return tv == "string" end
    if vt == "Enum" then return tv == "EnumItem" or tv == "number" end
    if vt == "Instance" then return tv == "Instance" end
    local want = TYPE_ALIAS[vt] or vt
    if want == "Content" then return tv == "Content" or tv == "string" end
    return tv == want
end

local function serValue(name, v, numType, vt)
    if SHARED_PROPS[name] or vt == "SharedString" then
        if type(v) == "string" and #v > 0 then return serShared(name, v) end
        return nil
    end
    if BINARY_PROPS[name] or vt == "BinaryString" then
        if type(v) == "string" then return '<BinaryString name="' .. clean(name) .. '">' .. b64(v) .. '</BinaryString>' end
        return nil
    end
    if vt and not typeOk(vt, v) then return nil end
    if BINARY_PROPS[name] and type(v) == "string" then
        return '<BinaryString name="' .. clean(name) .. '">' .. b64(v) .. '</BinaryString>'
    end
    local tv = type(v)
    if tv == "boolean" then return serBool(name, v) end
    local special = specialPropHandlers[name]
    if special then local s = special(name, v) if s then return s end end
    local fn
    if tv == "number" and numType and (v == floor(v) or numType == "float" or numType == "double") then
        fn = serNumberAs[numType]
    else
        fn = serByType[typeof(v)]
    end
    if not fn then return nil, true end
    local ok, s = pcall(fn, name, v)
    if ok and s and s ~= "" then return s end
    return nil
end

local function serializeProp(name, v, vt)
    if v == nil then return nil end
    if shouldSkipProp(name) then return nil end
    return (serValue(name, v, nil, vt))
end

local function propsViaGetProperties(inst)
    if not Fish.Options.UseGetProperties or not IO.getproperties then return nil end
    local ok, list = pcall(IO.getproperties, inst)
    if not ok or type(list) ~= "table" then return nil end
    local out = {}
    local cls = inst.ClassName
    if type(list[1]) == "string" then
        for _, k in ipairs(list) do
            if type(k) == "string" and not shouldSkipProp(k) and isPropValid(cls, k) then
                out[#out + 1] = k
            end
        end
    else
        for k in pairs(list) do
            if type(k) == "string" and not shouldSkipProp(k) and isPropValid(cls, k) then
                out[#out + 1] = k
            end
        end
    end
    return out
end

local defaultCache = {}
local function getDefault(className)
    if defaultCache[className] ~= nil then return defaultCache[className] end
    local ok, inst = pcall(Instance.new, className)
    if not ok or not inst then defaultCache[className] = false return false end
    defaultCache[className] = inst
    return inst
end

local function indexProp(inst, name) return inst[name] end

local NOVALUE = {}

local function isSame(a, b)
    if a == b then return true end
    local ta = typeof(a)
    if ta ~= typeof(b) then return false end
    if ta == "number" then return abs(a - b) < 1e-6 end
    if EQ_RELIABLE[ta] then return false end
    local ok1, s1 = pcall(tostring, a)
    local ok2, s2 = pcall(tostring, b)
    if ok1 and ok2 then return s1 == s2 end
    return false
end

local function modelIsCharacter(m)
    if not m then return false end
    local ok, player = pcall(Players.GetPlayerFromCharacter, Players, m)
    if ok and player then return true end
    local ok2, hum = pcall(m.FindFirstChildOfClass, m, "Humanoid")
    if ok2 and hum then
        local ok3, hrp = pcall(m.FindFirstChild, m, "HumanoidRootPart")
        if ok3 and hrp then return true end
    end
    return false
end

local function isCharacter(inst, cls, opts, charRefs)
    if not opts.StripCharacters then return false end
    if charRefs[inst] then return true end
    if not inst:IsA("Model") then
        if CHARACTER_CLASSES[cls] then
            local parent = inst.Parent
            if parent and parent:IsA("Model") and modelIsCharacter(parent) then
                charRefs[inst] = true
                return true
            end
        end
        return false
    end
    if modelIsCharacter(inst) then
        charRefs[inst] = true
        local okd, desc = pcall(inst.GetDescendants, inst)
        if okd and desc then for _, d in ipairs(desc) do charRefs[d] = true end end
        return true
    end
    return false
end

local function nameIsCore(inst, opts, coreRefs)
    if not opts.StripCoreScripts or next(CORE_SCRIPT_NAMES) == nil then return false end
    local n = inst.Name
    if CORE_SCRIPT_NAMES[n] then coreRefs[inst] = true return true end
    return false
end

local CORE_CONTAINERS = { PlayerScripts = true, PlayerGui = true }

local function keepInst(inst, opts, charRefs, coreRefs)
    if charRefs[inst] then return false end
    local cls = inst.ClassName
    local parent = inst.Parent
    if parent and charRefs[parent] then return false end
    if parent and coreRefs[parent] then return false end
    if parent == game and not GAME_SVC[cls] then return false end
    if parent and ROBLOX_JUNK[inst.Name] and JUNK_PARENTS[parent.ClassName] then return false end
    if cls == "Player" and parent == Players then return false end
    if isCharacter(inst, cls, opts, charRefs) then return false end
    if nameIsCore(inst, opts, coreRefs) then return false end
    if cls == "Lighting" then return true end
    if opts.IgnoreNotArchivable then
        local ok, ar = pcall(indexProp, inst, "Archivable")
        if ok and ar == false then return false end
    end
    return true
end

local function canKeep(inst, opts, charRefs, coreRefs)
    local ok, keep = pcall(keepInst, inst, opts, charRefs, coreRefs)
    return ok and keep == true
end

local function walkRef(root, d, opts, refs, kidsOf, charRefs, coreRefs)
    if d > opts.Depth then return end
    if refs[root] then return end
    local n = Walker.refCount + 1
    Walker.refCount = n
    refs[root] = "RBX" .. n
    if n % 2000 == 0 then
        setStatusText("Saving game.. scanning " .. n)
    end
    breathe()
    if opts.StripCoreScripts and CORE_CONTAINERS[root.ClassName] then return end
    local ok, kids = pcall(root.GetChildren, root)
    if not ok or not kids or #kids == 0 then return end
    local kept = {}
    for _, c in ipairs(kids) do
        if canKeep(c, opts, charRefs, coreRefs) then
            walkRef(c, d + 1, opts, refs, kidsOf, charRefs, coreRefs)
            if refs[c] then kept[#kept + 1] = c end
        end
    end
    if #kept > 0 then kidsOf[root] = kept end
end

local readMode = {}

local function readProp(inst, name)
    local cls = inst.ClassName
    local modes = readMode[cls]
    if not modes then modes = {} readMode[cls] = modes end
    local mode = modes[name]
    if mode == 0 then return nil end
    if mode ~= 2 then
        local ok, v = pcall(indexProp, inst, name)
        if ok then
            modes[name] = 1
            return v
        end
    end
    if IO.gethiddenproperty then
        local okH, hv = pcall(IO.gethiddenproperty, inst, name)
        if okH then
            modes[name] = 2
            return hv
        end
    end
    modes[name] = 0
    return nil
end

local function encodeTags(inst)
    local tags = CollectionService:GetTags(inst)
    if type(tags) ~= "table" or #tags == 0 then return nil end
    return tconcat(tags, "\0")
end

local function emitAttributesAndTags(buf, inst, opts)
    if opts.EmitAttributes then
        local ok, attrs = pcall(inst.GetAttributes, inst)
        if ok and type(attrs) == "table" and next(attrs) ~= nil then
            local success, encoded = pcall(HttpService.JSONEncode, HttpService, attrs)
            if success and encoded and #encoded > 0 then
                buf[#buf + 1] = '<BinaryString name="AttributesSerialize">' .. b64(encoded) .. '</BinaryString>'
            end
        end
    end
    if opts.EmitTags then
        local ok, encoded = pcall(encodeTags, inst)
        if ok and encoded then
            buf[#buf + 1] = '<BinaryString name="Tags">' .. b64(encoded) .. '</BinaryString>'
        end
    end
end

local function shouldEmitInMode(cls, mode)
    if mode == "full" then return true end
    if mode == "scripts" then return cls == "Script" or cls == "LocalScript" or cls == "ModuleScript" end
    if mode == "models" then return cls ~= "Script" and cls ~= "LocalScript" and cls ~= "ModuleScript" end
    return true
end

local GEOMETRY_PROPS = {
    UnionOperation = {"AssetId", "ChildData", "ChildData2", "MeshData", "MeshData2", "PhysicsData", "PhysicalConfigData", "FormFactor", "UsePartColor", "RenderFidelity", "CollisionFidelity", "SmoothingAngle"},
    MeshPart = {"MeshId", "PhysicsData", "PhysicalConfigData", "RenderFidelity", "CollisionFidelity", "HasJointOffset", "HasSkinnedMesh", "JointOffset"},
}
local GEOMETRY_CLASSES = toSet({"UnionOperation","IntersectOperation","NegateOperation","PartOperation","MeshPart"})

local emitInst

local propPlans = {}
local decompiledByBytecode = {}

local function propPlan(inst, cls, opts)
    local plan = propPlans[cls]
    if plan then return plan end
    reflectClass(cls)
    plan = {}
    local added = {}
    local apiSet = apiClassProps[cls]
    local hiddenSet = apiHidden[cls]
    local typeSet = apiTypes[cls]
    local canHidden = IO.gethiddenproperty ~= nil
    local function add(list, useDefault, critical)
        if not list then return end
        for _, k in ipairs(list) do
            if not added[k] and not PLAN_SKIP[k] and not shouldSkipProp(k) then
                local valid
                if critical then
                    valid = apiSet == nil or apiSet[k] == true
                else
                    valid = not opts.APIProperties or isPropValid(cls, k)
                end
                local hidden = hiddenSet ~= nil and hiddenSet[k] == true
                if valid and (canHidden or not hidden) then
                    added[k] = true
                    local vt = typeSet and typeSet[k]
                    local base = #k > 7 and k:sub(-7) == "Content" and k:sub(1, -8) or nil
                    plan[#plan + 1] = {
                        name = k,
                        alias = base and { base, base .. "Id", base .. "ID" } or nil,
                        useDefault = useDefault,
                        content = isRealContent(k) or vt == "Content",
                        numType = vt and NUMBER_TYPES[vt] and vt or nil,
                        vt = vt,
                        mode = hidden and 2 or nil,
                        hidden = hidden,
                    }
                end
            end
        end
    end
    add(INSTANCE_SPECIFIC[cls], true)
    add(CRITICAL_PROPS, true, true)
    add(propsViaGetProperties(inst), false)
    local visibleLower = {}
    for _, e in ipairs(plan) do
        if not e.hidden then visibleLower[e.name:lower()] = true end
    end
    local final = {}
    for _, e in ipairs(plan) do
        if not (e.hidden and visibleLower[e.name:lower()] and not BINARY_PROPS[e.name]) then
            final[#final + 1] = e
        end
    end
    propPlans[cls] = final
    return final
end

local function readEntry(inst, e, gh)
    local k = e.name
    local mode = e.mode
    if mode == 2 then
        local ok, hv = pcall(gh, inst, k)
        if ok and hv ~= nil then
            e.probed = true
            return hv
        end
        if not e.probed then e.dead = true end
        return nil
    end
    local ok, v = pcall(indexProp, inst, k)
    if ok then
        e.mode = 1
        return v
    end
    if mode == 1 then return nil end
    if gh then
        local okH, hv = pcall(gh, inst, k)
        if okH and hv ~= nil then
            e.mode = 2
            return hv
        end
    end
    e.dead = true
    return nil
end

local function readDefault(defaultInst, e, gh)
    local ok, got
    if e.mode == 2 then
        ok, got = pcall(gh, defaultInst, e.name)
    else
        ok, got = pcall(indexProp, defaultInst, e.name)
    end
    if ok and got ~= nil then return got end
    return NOVALUE
end

local function emitProps(buf, inst, cls, opts, decompileCache)
    local seen = {}
    local defaultInst = opts.IgnoreDefaultProps and getDefault(cls) or nil
    local plan = propPlan(inst, cls, opts)
    local gh = IO.gethiddenproperty
    local aliasUris
    for i = 1, #plan do
        local e = plan[i]
        if not e.dead then
            local v = readEntry(inst, e, gh)
            if v ~= nil then
                local k = e.name
                seen[k] = true
                if e.alias then
                    local uri = extractUri(v)
                    if uri then
                        aliasUris = aliasUris or {}
                        aliasUris[#aliasUris + 1] = { e.alias, uri }
                    end
                elseif e.content then
                    local uri = extractUri(v)
                    if uri then buf[#buf + 1] = serContentTag(k, uri) end
                else
                    local same = false
                    if e.useDefault and defaultInst then
                        local dv = e.def
                        if dv == nil then
                            dv = readDefault(defaultInst, e, gh)
                            e.def = dv
                        end
                        if dv ~= NOVALUE then same = isSame(v, dv) end
                    end
                    if not same then
                        local str, unsupported = serValue(k, v, e.numType, e.vt)
                        if str then
                            buf[#buf + 1] = str
                        elseif unsupported then
                            e.dead = true
                        end
                    end
                end
            end
        end
    end

    if aliasUris then
        for _, pair in ipairs(aliasUris) do
            local cands = pair[1]
            local done = false
            for _, c in ipairs(cands) do
                if seen[c] then done = true break end
            end
            if not done then
                for _, c in ipairs(cands) do
                    local ok = pcall(indexProp, inst, c)
                    if ok then
                        buf[#buf + 1] = serContentTag(c, pair[2])
                        seen[c] = true
                        break
                    end
                end
            end
        end
    end

    if not seen.Name then
        local name = readProp(inst, "Name")
        if name then
            if opts.Anonymous then
                local ok, p = pcall(Players.GetPlayerFromCharacter, Players, inst)
                if ok and p then name = "Player_" .. tostring(p.UserId) end
            end
            buf[#buf + 1] = '<string name="Name">' .. clean(name) .. '</string>'
        end
    end

    emitAttributesAndTags(buf, inst, opts)

    if cls == "Script" then
        local src = tostring(DATA.server_script_placeholder or "")
        buf[#buf + 1] = '<ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>'
    elseif cls == "LocalScript" or cls == "ModuleScript" then
        local src = decompileCache and decompileCache[inst]
        if not src then src = readProp(inst, "Source") end
        local tried = opts._decompileTried and opts._decompileTried[inst]
        if (not src or src == "") and opts.Decompile and opts._decompileFn and not tried then
            local key
            if opts._bytecodeFn then
                local okb, bc = pcall(opts._bytecodeFn, inst)
                if okb and type(bc) == "string" and bc ~= "" then key = bc end
            end
            local cached = key and decompiledByBytecode[key]
            if cached then
                src = cached
            else
                local okd, decoded = pcall(opts._decompileFn, inst)
                if okd and type(decoded) == "string" and decoded ~= "" then
                    src = decoded
                    if key then decompiledByBytecode[key] = decoded end
                end
            end
        end
        if (not src or src == "") and opts.SaveBytecode and opts._bytecodeFn then
            local okb, bc = pcall(opts._bytecodeFn, inst)
            if okb and type(bc) == "string" and bc ~= "" then src = b64(bc) end
        end
        if not src or src == "" then
            src = "-- [LX Serializer] No source recovered for " .. tostring(cls) .. " \"" .. tostring(readProp(inst, "Name")) .. "\""
        end
        buf[#buf + 1] = '<ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>'
    end

    if GEOMETRY_CLASSES[cls] then
        local gTypes = apiTypes[cls]
        for _, bp in ipairs(GEOMETRY_PROPS[cls] or GEOMETRY_PROPS.UnionOperation) do
            if not seen[bp] then
                local raw = readProp(inst, bp)
                local isContent = bp == "AssetId" or REAL_CONTENT_PROPS[bp]
                if isContent then
                    local uri = raw ~= nil and extractUri(raw) or nil
                    if uri then
                        buf[#buf + 1] = serContentTag(bp, uri)
                        seen[bp] = true
                    end
                elseif raw ~= nil then
                    local str = serializeProp(bp, raw, gTypes and gTypes[bp])
                    if str then
                        buf[#buf + 1] = str
                        seen[bp] = true
                    end
                end
            end
        end
    end

    if GEOMETRY_CLASSES[cls] then
        local function okSize(v)
            return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
                and v.X > 0 and v.Y > 0 and v.Z > 0
                and v.X < math.huge and v.Y < math.huge and v.Z < math.huge
        end
        local init
        if IO.gethiddenproperty then
            local ok, hv = pcall(IO.gethiddenproperty, inst, "InitialSize")
            if ok and okSize(hv) then init = hv end
        end
        if not init then
            local ok, v = pcall(indexProp, inst, "InitialSize")
            if ok and okSize(v) then init = v end
        end
        if not init and cls == "MeshPart" then
            local ok, v = pcall(indexProp, inst, "MeshSize")
            if ok and okSize(v) then init = v end
        end
        if not init then
            local ok, v = pcall(indexProp, inst, "Size")
            if ok and okSize(v) then init = v end
        end
        if init then
            buf[#buf + 1] = serVector3("InitialSize", init)
        end
    end

    -- Terrain doesn't save if your executor has low UNC but atleast it tries
    if cls == "Terrain" and IO.gethiddenproperty then
        for _, bp in ipairs({"SmoothGrid", "MaterialColors"}) do
            if not seen[bp] then
                local ok, raw = pcall(IO.gethiddenproperty, inst, bp)
                if ok and type(raw) == "string" and #raw > 0 then
                    buf[#buf + 1] = '<BinaryString name="' .. bp .. '">' .. b64(raw) .. '</BinaryString>'
                end
            end
        end
    end

end

local openItems = 0

local function safeEmit(buf, inst, opts, decompileCache, refs, kidsOf, totalRefs)
    local before = openItems
    local ok, err = pcall(emitInst, buf, inst, opts, decompileCache, refs, kidsOf, totalRefs)
    if not ok then
        log("Skipped " .. tostring(refs[inst]) .. ": " .. tostring(err))
    end
    while openItems > before do
        buf[#buf + 1] = '</Item>'
        openItems = openItems - 1
    end
end

emitInst = function(buf, inst, opts, decompileCache, refs, kidsOf, totalRefs)
    local ref = refs[inst]
    if not ref then return end
    local cls = inst.ClassName
    local kids = kidsOf[inst]

    if not shouldEmitInMode(cls, opts.Mode) then
        if kids then for i = 1, #kids do safeEmit(buf, kids[i], opts, decompileCache, refs, kidsOf, totalRefs) end end
        return
    end

    Walker.totalInst = Walker.totalInst + 1
    bumpStatus("Saving", Walker.totalInst, totalRefs)

    local start = #buf
    buf[start + 1] = '<Item class="' .. cls .. '" referent="' .. ref .. '">'
    buf[start + 2] = '<Properties>'
    local ok, err = pcall(emitProps, buf, inst, cls, opts, decompileCache)
    if not ok then
        for i = #buf, start + 1, -1 do buf[i] = nil end
        log("Skipped " .. tostring(ref) .. " (" .. tostring(cls) .. "): " .. tostring(err))
        return
    end
    buf[#buf + 1] = '</Properties>'
    openItems = openItems + 1

    if kids then for i = 1, #kids do safeEmit(buf, kids[i], opts, decompileCache, refs, kidsOf, totalRefs) end end

    buf[#buf + 1] = '</Item>'
    openItems = openItems - 1

    local sink = opts._sink
    if sink and #buf >= 32768 then
        sink:write(tconcat(buf, "\n") .. "\n")
        tclear(buf)
    end
end

local function timedCall(fn, arg, limit)
    local finished, okr, res = false, false, nil
    task.spawn(function()
        okr, res = pcall(fn, arg)
        finished = true
    end)
    local t = clock()
    while not finished and clock() - t < limit do task.wait() end
    if not finished then return nil end
    if okr and type(res) == "string" and res ~= "" then return true, res end
    return false
end

local function prefetchScripts(refs, opts, cache)
    if not opts.Decompile or not opts._decompileFn or opts.Mode == "models" then return end
    local bcFn = opts._bytecodeFn
    local groups, order = {}, {}
    local tried = opts._decompileTried
    for inst in pairs(refs) do
        local cls = inst.ClassName
        if cls == "LocalScript" or cls == "ModuleScript" then
            local src = readProp(inst, "Source")
            if type(src) ~= "string" or src == "" then
                local key
                if bcFn then
                    local okb, bc = pcall(bcFn, inst)
                    if okb and type(bc) == "string" and bc ~= "" then key = bc end
                end
                local hit = key and decompiledByBytecode[key]
                if hit then
                    cache[inst] = hit
                else
                    local gk = key or inst
                    local g = groups[gk]
                    if not g then
                        g = {}
                        groups[gk] = g
                        order[#order + 1] = gk
                    end
                    g[#g + 1] = inst
                end
            end
        end
        breathe()
    end
    local total = #order
    if total == 0 then return end
    local decomp = opts._decompileFn
    local limit = tonumber(opts.DecompileTimeout) or 10
    local threads = math.clamp(floor(tonumber(opts.MaxThreads) or 1), 1, 32)
    if threads > total then threads = total end
    local nextIdx, done, finished = 0, 0, 0
    local function worker()
        while true do
            nextIdx = nextIdx + 1
            local idx = nextIdx
            if idx > total then break end
            local gk = order[idx]
            local g = groups[gk]
            local okd, out = timedCall(decomp, g[1], limit)
            if okd == false then
                okd, out = timedCall(decomp, g[1], limit)
            end
            if okd and type(out) == "string" and out ~= "" then
                if type(gk) == "string" then decompiledByBytecode[gk] = out end
                for _, s in ipairs(g) do cache[s] = out end
            end
            for _, s in ipairs(g) do tried[s] = true end
            done = done + 1
            bumpStatus("Decompiling", done, total)
        end
    end
    setStatusText("Decompiling 0/" .. total)
    for _ = 1, threads do
        task.spawn(function()
            pcall(worker)
            finished = finished + 1
        end)
    end
    while finished < threads do task.wait() end
    _lastYield = clock()
    log("Decompiled " .. total .. " unique scripts using " .. threads .. " threads")
end

local function placeName()
    local pid = game.PlaceId
    local name
    local ok, n = pcall(function() return game.Name end)
    if ok and n and n ~= "" and n ~= "Game" and n:lower() ~= "ugc" then name = n end
    if not name then
        local okp, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(pid) end)
        if okp and info and info.Name and info.Name ~= "" then name = info.Name end
    end
    if not name or name == "" then name = "Place_" .. tostring(pid) end
    name = name:gsub("[^%w_%-%s]", ""):gsub("%s+", "_"):gsub("_+", "_")
    if #name > 80 then name = name:sub(1, 80) end
    if name == "" then name = "Place_" .. tostring(pid) end
    return name
end

local function buildReadmeSource()
    local tpl = DATA.readme_template
    if type(tpl) ~= "string" or tpl == "" then
        tpl = "-- LX Serializer\nGame saved with LX Serializer\n"
    end
    local subs = {
        PLACE_NAME = placeName(),
        PLACE_ID = tostring(game.PlaceId),
        JOB_ID = tostring(game.JobId or "N/A"),
        MODE = tostring(Fish.Options.Mode),
        DECOMPILE = tostring(Fish.Options.Decompile),
        DEPTH = tostring(Fish.Options.Depth),
        TIMESTAMP = os.date("!%Y-%m-%d %H:%M:%S"),
    }
    local out = tpl:gsub("{{(%w+)}}", function(k) return subs[k] or "" end)
    return out
end

local function buildReadmeXML()
    local src = buildReadmeSource()
    return tconcat({
        '<Item class="Script" referent="RBX_README">',
        '<Properties>',
        '<string name="Name">README</string>',
        '<bool name="Disabled">false</bool>',
        '<ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>',
        '</Properties>',
        '</Item>',
    }, "\n")
end

local function mergeOptions(userOpts)
    local merged = {}
    for k, v in pairs(Fish.Options) do merged[k] = v end
    if userOpts then for k, v in pairs(userOpts) do merged[k] = v end end
    merged._decompileFn = Fish._decompileFn
    merged._bytecodeFn = Fish._bytecodeFn
    if merged.ReadMe then
        merged._readmeXMLFn = buildReadmeXML
    else
        merged._readmeXMLFn = nil
    end
    return merged
end

local _pendingRestore = {}

local function moveBackpackToStarter()
    _pendingRestore = {}
    local lp = Players.LocalPlayer
    if not lp then return end
    local bp = lp:FindFirstChildOfClass("Backpack")
    if not bp then return end
    local sp = game:GetService("StarterPack")
    if not sp then return end
    local okL, tools = pcall(function() return bp:GetChildren() end)
    if not okL or not tools then return end
    for _, tool in ipairs(tools) do
        if tool:IsA("Tool") then
            if not sp:FindFirstChild(tool.Name) then
                local origParent = tool.Parent
                local okMove = pcall(function() tool.Parent = sp end)
                if okMove then
                    _pendingRestore[#_pendingRestore + 1] = {tool = tool, orig = origParent}
                end
            end
        end
    end
end

local function restoreBackpack()
    for i = #_pendingRestore, 1, -1 do
        local entry = _pendingRestore[i]
        pcall(function()
            if entry.tool and entry.tool.Parent == game:GetService("StarterPack") then
                entry.tool.Parent = entry.orig
            end
        end)
    end
    _pendingRestore = {}
end

local function ensureOutFolder()
    local out = tostring(Fish.Options.OUT or "LXSerializer")
    if IO.makefolder and IO.isfolder then
        local okF, exists = pcall(IO.isfolder, out)
        if not okF or not exists then pcall(IO.makefolder, out) end
    end
    return out
end

local Sink = {}
Sink.__index = Sink

function Sink.new(path, chunk)
    local s = setmetatable({}, Sink)
    s.path = path
    s.chunk = chunk or 4194304
    s.buf = {}
    s.size = 0
    s.total = 0
    s.failed = not pcall(IO.writefile, path, "")
    return s
end

function Sink:flush()
    if #self.buf == 0 or self.failed then return end
    local blob = tconcat(self.buf)
    tclear(self.buf)
    self.size = 0
    if not pcall(IO.appendfile, self.path, blob) then
        self.failed = true
        log("Append failed on " .. self.path)
    end
end

function Sink:write(str)
    if type(str) ~= "string" or #str == 0 then return end
    self.buf[#self.buf + 1] = str
    self.size = self.size + #str
    self.total = self.total + #str
    if self.size >= self.chunk then self:flush() end
end

function Sink:finish()
    self.closed = true
    self:flush()
    if self.failed then return false end
    log("Streamed to file: " .. self.path .. " (" .. self.total .. " bytes)")
    return true
end

function Fish.Init()
    Fish._decompileFn = IO.decompile and decompileScript or nil
    Fish._bytecodeFn = IO.getscriptbytecode
    if Fish.Options.FetchDocs or Fish.Options.APIProperties then
        local ok, data = pcall(Fish.FetchClasses)
        if not ok then log("API dump fetch failed: " .. tostring(data)) end
    end
    if Fish.Options.UseReflectionService then
        buildReflectionProps()
    end
    Fish._ready = true
    return Fish
end

function Fish.Save(instance, name, userOpts)
    local opts = mergeOptions(userOpts)

    if not opts.Callback and not IO.writefile then
        log("writefile unavailable")
        setStatusText("Failed: executor has no writefile")
        Status.fade(8)
        notify("LX Serializer: FAILED", "Executor missing writefile", 10)
        return nil
    end

    _statusAccum = 0
    _lastStatus = 0
    tclear(propPlans)
    tclear(decompiledByBytecode)
    openItems = 0
    resetShared()
    _lastYield = clock()
    ensureOutFolder()
    log("Starting save (" .. tostring(opts.Mode) .. ")")
    setStatusText("Saving game..")
    if not IO.gethiddenproperty then log("gethiddenproperty unavailable, terrain will not be saved") end
    if opts.Decompile and not Fish._decompileFn then log("decompile unavailable, scripts will be saved without source") end


    if opts.KillAllScripts then
        pcall(function()
            for _, s in ipairs(game:GetDescendants()) do
                if s:IsA("Script") or s:IsA("LocalScript") or s:IsA("ModuleScript") then
                    pcall(function() s.Disabled = true end)
                end
            end
        end)
    end

    log("Serializing...")
    task.wait()

    local t0 = tick()
    Walker.refs = {}
    Walker.refCount = 0
    Walker.totalInst = 0

    local charRefs = {}
    local coreRefs = {}
    local refs = {}
    local kidsOf = {}
    Walker.refs = refs
    opts._decompileTried = {}

    if opts.RemovePlayerCharacters then
        local okp, plist = pcall(function() return Players:GetPlayers() end)
        if okp and plist then
            for _, p in ipairs(plist) do
                local okc, char = pcall(function() return p.Character end)
                if okc and char then
                    charRefs[char] = true
                    local okd, desc = pcall(function() return char:GetDescendants() end)
                    if okd and desc then for _, d in ipairs(desc) do charRefs[d] = true end end
                end
            end
        end
    end

    local roots = {}
    if type(instance) == "table" then
        for _, r in ipairs(instance) do if typeof(r) == "Instance" then roots[#roots + 1] = r end end
    elseif typeof(instance) == "Instance" then
        roots[#roots + 1] = instance
    end

    if #roots == 0 then
        setStatusText("Failed: no valid root instance")
        Status.fade(8)
        notify("LX Serializer: FAILED", "No valid root instance", 10)
        return nil
    end

    local didMoveBackpack = false
    if opts.IncludeBackpack then
        local okM = pcall(moveBackpackToStarter)
        didMoveBackpack = okM
    end

    local pendingBuf = {}
    local okSave, result = pcall(function()
        local services = nil
        for _, root in ipairs(roots) do
            if root == game then
                local ok0, kids0 = pcall(function() return game:GetChildren() end)
                if ok0 and kids0 then
                    services = kids0
                    for _, svc in ipairs(kids0) do
                        if canKeep(svc, opts, charRefs, coreRefs) then walkRef(svc, 1, opts, refs, kidsOf, charRefs, coreRefs) end
                    end
                end
            else
                if canKeep(root, opts, charRefs, coreRefs) then walkRef(root, 1, opts, refs, kidsOf, charRefs, coreRefs) end
            end
        end

        log("Walked " .. Walker.refCount .. " instances")
        local buf = pendingBuf
        local decompileCache = {}

        prefetchScripts(refs, opts, decompileCache)

        setStatusText("Saving game.. writing")

        buf[#buf + 1] = '<?xml version="1.0" encoding="utf-8"?>'
        buf[#buf + 1] = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
-- Another list of APIS i personally use alot for XML related stuff
        local finalName = name or placeName()
        local fname = finalName .. ".rbxlx"
        local outFolder = ensureOutFolder()
        local primaryPath = outFolder .. "/" .. fname

        local sink = nil
        if opts.StreamToFile and IO.appendfile and not opts.Callback and not opts.Clipboard then
            sink = Sink.new(primaryPath, opts.StreamChunk)
            opts._sink = sink
            sink:write(tconcat(buf, "\n") .. "\n")
            tclear(buf)
        end

        local total = Walker.refCount
        local readmeEmitted = false
        for _, root in ipairs(roots) do
            if root == game then
                if services then
                    for _, svc in ipairs(services) do
                        if refs[svc] then
                            safeEmit(buf, svc, opts, decompileCache, refs, kidsOf, total)
                            if opts._readmeXMLFn and not readmeEmitted and svc.ClassName == "Lighting" then
                                local readmeXml = opts._readmeXMLFn()
                                if readmeXml then
                                    buf[#buf + 1] = readmeXml
                                    readmeEmitted = true
                                end
                            end
                        end
                    end
                end
            else
                if refs[root] then safeEmit(buf, root, opts, decompileCache, refs, kidsOf, total) end
            end
            if sink and #buf > 0 then
                sink:write(tconcat(buf, "\n") .. "\n")
                tclear(buf)
            end
        end

        if opts._readmeXMLFn and not readmeEmitted then
            local readmeXml = opts._readmeXMLFn()
            if readmeXml then
                buf[#buf + 1] = readmeXml
                readmeEmitted = true
            end
        end

        local ssb = sharedBlock()
        if ssb then buf[#buf + 1] = ssb end
        buf[#buf + 1] = '</roblox>'

        local xml
        if sink then
            sink:write(tconcat(buf, "\n"))
            tclear(buf)
            if not sink:finish() then
                setStatusText("Failed: could not write " .. primaryPath)
                Status.fade(8)
                return nil
            end
            xml = primaryPath
        else
            xml = tconcat(buf, "\n")
        end

        local elapsed = tick() - t0

        if sink and xml == primaryPath then
            log("XML streamed to " .. primaryPath .. " in " .. fmt("%.2fs", elapsed))
        else
            log("XML: " .. #xml .. " bytes, " .. Walker.totalInst .. " items emitted in " .. fmt("%.2fs", elapsed))
        end

        if opts.Callback and type(opts.Callback) == "function" then
            pcall(opts.Callback, xml)
            setStatusText("Saved! (" .. Walker.totalInst .. " instances)")
            return xml
        end

        if opts.Clipboard and IO.setclipboard then
            pcall(IO.setclipboard, xml)
            setStatusText("Saved to clipboard!")
            return xml
        end

        local paths = {}
        if opts.FilePath then paths[#paths + 1] = opts.FilePath end
        paths[#paths + 1] = primaryPath
        paths[#paths + 1] = fname

        local wrote = (sink ~= nil and xml == primaryPath)
        if not wrote then
            for _, path in ipairs(paths) do
                if IO.isfile and IO.delfile then
                    local okI, exists = pcall(IO.isfile, path)
                    if okI and exists and not opts.AvoidFileOverwrite then pcall(IO.delfile, path) end
                end
                local ok, err = pcall(IO.writefile, path, xml)
                if ok then
                    log("Wrote: " .. path .. " (" .. #xml .. " bytes)")
                    wrote = true
                    break
                else
                    log("Write fail " .. path .. ": " .. tostring(err))
                end
            end
        end

        if not wrote then
            setStatusText("Failed: writefile rejected every path")
            Status.fade(8)
            return xml
        end

        setStatusText("Saved to " .. primaryPath .. " in " .. fmt("%.1fs", elapsed))
        Status.fade(5)
        return xml
    end)

    local leftSink = opts._sink
    opts._sink = nil
    if not okSave and leftSink and not leftSink.closed then
        pcall(function()
            if #pendingBuf > 0 then leftSink:write(tconcat(pendingBuf, "\n") .. "\n") end
            local tail = {}
            for _ = 1, openItems do tail[#tail + 1] = '</Item>' end
            local ssb = sharedBlock()
            if ssb then tail[#tail + 1] = ssb end
            tail[#tail + 1] = '</roblox>'
            openItems = 0
            leftSink:write(tconcat(tail, "\n"))
            leftSink:finish()
        end)
    end

    if didMoveBackpack then
        restoreBackpack()
    end

    flushLog()

    if not okSave then
        log("Save error: " .. tostring(result))
        setStatusText("Failed: " .. tostring(result):sub(1, 80))
        Status.fade(8)
        return nil
    end

    return result
end


function Fish.SavePlace(name, userOpts)
    return Fish.Save(game, name, userOpts)
end

function Fish.SaveInstance(instance, name, userOpts)
    local merged = userOpts or {}
    merged.Mode = merged.Mode or "full"
    return Fish.Save(instance, name, merged)
end

function Fish.SaveScripts(instance, name, userOpts)
    local merged = userOpts or {}
    merged.Mode = "scripts"
    merged.Decompile = true
    return Fish.Save(instance, name, merged)
end

function Fish.SaveModels(instance, name, userOpts)
    local merged = userOpts or {}
    merged.Mode = "models"
    merged.Decompile = false
    return Fish.Save(instance, name, merged)
end

Fish.Data = DATA
Fish.ValidPropsForClass = apiClassProps
Fish.EncodeBase64 = b64
Fish.ExtractUri = extractUri
Fish.SerializeProp = serializeProp
Fish.EncodeTags = encodeTags --tags
Fish.DecompileScript = decompileScript --scripts
Fish.SetStatus = setStatusText
Fish.DeepClone = function(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do n[k] = Fish.DeepClone(v) end
    return n
end


-- Let's you use SavePlace() (of course Konstant Uses that 🤬)

local genv = (getgenv and getgenv()) or _G

local function run(kind, a, b, c)
    if not Fish._ready then Fish.Init() end
    if kind == "instance" then return Fish.SaveInstance(a, b, c) end
    return Fish.SavePlace(a, b)
end

genv.saveplace = function(name, opts)
    return run("place", name, opts)
end

genv.dumpgame = function(name, opts)
    return run("place", name, opts)
end

genv.fishsave = function(name, opts)
    return run("place", name, opts)
end

genv.fetchplace = function(name, opts)
    return run("place", name, opts)
end

genv.serialize = function(name, opts)
    return run("place", name, opts)
end

genv.saveinstance = function(inst, name, opts)
    return run("instance", inst, name, opts)
end

genv.Fish = Fish
genv.LXSerializer = Fish


if type(genv.LX_CONFIG) == "table" then
    for k, v in pairs(genv.LX_CONFIG) do
        Fish.Options[k] = v
    end
end

if Fish.Options.AutoRun then
    task.spawn(function()
        task.wait(1)
        run("place")
    end)
end
