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

Made by Garfield Cat Presents.

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
---lowk if you dont have any of these on ur executor its ggs

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
    local blob = table.concat(_logCache, "\n") .. "\n"
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
    label.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = ""
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = label

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
            TweenService:Create(label, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
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
        label.BackgroundTransparency = 0.15
        label.Text = text
    end
end


--- a list of apis
Fish.Options = {
    Decompile = true,
    MaxThreads = 3,
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
    StreamChunk = 1048576,
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
local SKIP_SVC = toSet({"CoreGui","CorePackages","CoreScripts","Chat","LogService"})
local SKIP_PROP = toSet({"Parent","RobloxLocked","HistoryId","ClassName","AttributesSerialize","Tags"})
local BINARY_PROPS = toSet({"SmoothGrid","ChildData","ChildData2","MeshData","MeshData2","PhysicsData","PhysicalConfigData","MaterialColors"})
local REAL_CONTENT_PROPS = toSet({"Texture","TextureId","TextureID","Image","MeshId","SoundId","AnimationId","ShirtTemplate","PantsTemplate","Graphic","AssetId"})
local CHARACTER_CLASSES = toSet({"Humanoid","Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso"})
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

local function buildApiClassProps(data)
    if type(data) ~= "table" or type(data.Classes) ~= "table" then return end
    local ownProps = {}
    local superclass = {}
    for _, class in ipairs(data.Classes) do
        local cn = class.Name
        if cn then
            superclass[cn] = class.Superclass
            local props = {}
            if type(class.Members) == "table" then
                for _, m in ipairs(class.Members) do
                    if m.MemberType == "Property" and m.Name then
                        props[m.Name] = true
                    end
                end
            end
            ownProps[cn] = props
        end
    end
    local count = 0
    for cn in pairs(ownProps) do
        local combined = {}
        local cur = cn
        local guard = 0
        while cur and guard < 50 do
            local p = ownProps[cur]
            if not p then break end
            for k in pairs(p) do combined[k] = true end
            cur = superclass[cur]
            guard = guard + 1
        end
        apiClassProps[cn] = combined
        count = count + 1
    end
    log("API dump: property cache built for " .. count .. " classes")
end

local function buildReflectionProps()
    if not Fish.Options.UseReflectionService then return end
    local ok, RS = pcall(function() return game:GetService("ReflectionService") end)
    if not ok or not RS then
        log("ReflectionService not available.")
        return
    end
    
    local okClasses, classes = pcall(function() return RS:GetClasses({}) end)
    if not okClasses or not classes then return end
    
    local count = 0
    for _, class in ipairs(classes) do
        local className = class.Name
        if className and not INSTANCE_SPECIFIC[className] then
            local props = {}
            local okProps, reflectedProps = pcall(function() return RS:GetPropertiesOfClass(className, {}) end)
            if okProps and reflectedProps then
                for _, prop in ipairs(reflectedProps) do
                    if prop.Name and not shouldSkipProp(prop.Name) then
                        table.insert(props, prop.Name)
                        if CRITICAL_PROPS_SET[prop.Name] then
                            apiClassProps[className] = apiClassProps[className] or {}
                            apiClassProps[className][prop.Name] = true
                        end
                    end
                end
            end
            if #props > 0 then
                INSTANCE_SPECIFIC[className] = props
                count = count + 1
            end
        end
    end
    log("ReflectionService: built property cache for " .. count .. " classes directly from engine.")
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

local function b64(s)
    if type(s) ~= "string" then return "" end
    local res = {}
    local n = 0
    local len = #s
    local byte = string.byte
    for i = 1, len - 2, 3 do
        local a, b, c = byte(s, i, i + 2)
        local v = a * 65536 + b * 256 + c
        n = n + 1
        res[n] = b64pairs[v // 262144] .. b64pairs[(v // 4096) % 64] .. b64pairs[(v // 64) % 64] .. b64pairs[v % 64]
    end
    local rem = len % 3
    if rem == 1 then
        local a = byte(s, len)
        n = n + 1
        res[n] = b64pairs[a // 4] .. b64pairs[(a % 4) * 16] .. "=="
    elseif rem == 2 then
        local a, b = byte(s, len - 1, len)
        local v = a * 256 + b
        n = n + 1
        res[n] = b64pairs[v // 1024] .. b64pairs[(v // 16) % 64] .. b64pairs[(v % 16) * 4] .. "="
    end
    return table.concat(res)
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
    local added = 0
    for _, class in ipairs(data.Classes) do
        local className = class.Name
        if className and not INSTANCE_SPECIFIC[className] then
            local props = {}
            if type(class.Members) == "table" then
                for _, member in ipairs(class.Members) do
                    if member.MemberType == "Property" and member.Name and not shouldSkipProp(member.Name) then
                        table.insert(props, member.Name)
                    end
                end
            end
            if class.Superclass and INSTANCE_SPECIFIC[class.Superclass] then
                for _, p in ipairs(INSTANCE_SPECIFIC[class.Superclass]) do table.insert(props, p) end
            end
            if #props > 0 then
                INSTANCE_SPECIFIC[className] = props
                added = added + 1
            end
        end
    end
    log("API dump: added " .. added .. " classes to INSTANCE_SPECIFIC")
    buildApiClassProps(data)
end

local _statusAccum = 0
local _lastYield = os.clock()
local _lastStatus = 0

local function breathe()
    if os.clock() - _lastYield >= 0.2 then
        task.wait()
        _lastYield = os.clock()
    end
end

local function bumpStatus(prefix, current, total)
    _statusAccum = _statusAccum + 1
    breathe()
    if os.clock() - _lastStatus < 0.25 then return end
    _lastStatus = os.clock()
    local pct = 0
    if total and total > 0 then
        pct = math.min(100, math.floor((current / total) * 100))
    end
    setStatusText(prefix .. " " .. current .. "/" .. tostring(total) .. " (" .. pct .. "%)")
end

local function u32(n) return string.pack("<I4", n) end
local function f32(n) return string.pack("<f", n) end
local function f64(n) return string.pack("<d", n) end
local function i32(n) return string.pack("<i4", n) end
local function wstr(s) return u32(#s) .. s end

local function clean(s)
    s = tostring(s)
    s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    s = s:gsub('"', "&quot;"):gsub("'", "&apos;")
    return s
end

local function nm(x)
    if type(x) ~= "number" then return "0" end
    if x ~= x then return "0" end
    if x == math.huge then return "1e308" end
    if x == -math.huge then return "-1e308" end
    if x == math.floor(x) and math.abs(x) < 1e15 then return string.format("%d", x) end
    return string.format("%.10g", x)
end

local function isRealContent(name) return REAL_CONTENT_PROPS[name] == true end

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
    local accessors = {"Source","Uri","Url","URL","Value","Text","String","AssetId","AssetID","Id","ID","Content","source","uri","url","value"}
    for _, key in ipairs(accessors) do
        local ok, s = pcall(function() return v[key] end)
        if ok and type(s) == "string" and s ~= "" then
            local inner = extractUri(s)
            if inner then return inner end
        end
        if ok and type(s) == "number" then return "rbxassetid://" .. tostring(s) end
    end
    local methods = {"ToString","GetSource","GetUri","GetUrl"}
    for _, m in ipairs(methods) do
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
local function serInt(name, v) return '<int name="' .. clean(name) .. '">' .. string.format("%d", v) .. '</int>' end
local function serInt64(name, v) return '<int64 name="' .. clean(name) .. '">' .. string.format("%d", v) .. '</int64>' end
local function serFloat(name, v) return '<float name="' .. clean(name) .. '">' .. nm(v) .. '</float>' end
local function serDouble(name, v) return '<double name="' .. clean(name) .. '">' .. nm(v) .. '</double>' end
local function serNumber(name, v)
    if v == math.floor(v) and v >= -2147483648 and v <= 2147483647 then return serInt(name, v) end
    if v == math.floor(v) and math.abs(v) < 9007199254740992 then return serInt64(name, v) end
    return serDouble(name, v)
end
local function serVector2(name, v) return '<Vector2 name="' .. clean(name) .. '"><X>' .. nm(v.X) .. '</X><Y>' .. nm(v.Y) .. '</Y></Vector2>' end
local function serVector3(name, v) return '<Vector3 name="' .. clean(name) .. '"><X>' .. nm(v.X) .. '</X><Y>' .. nm(v.Y) .. '</Y><Z>' .. nm(v.Z) .. '</Z></Vector3>' end
local function serCFrame(name, v)
    local ok, r = pcall(function() return {v:GetComponents()} end)
    if not ok or not r then return nil end
    local s = '<CoordinateFrame name="' .. clean(name) .. '"><X>' .. nm(r[1]) .. '</X><Y>' .. nm(r[2]) .. '</Y><Z>' .. nm(r[3]) .. '</Z>'
    for i = 0, 2 do for j = 0, 2 do s = s .. '<R' .. i .. j .. '>' .. nm(r[i * 3 + j + 4]) .. '</R' .. i .. j .. '>' end end
    return s .. '</CoordinateFrame>'
end
local function serColor3(name, v) return '<Color3 name="' .. clean(name) .. '"><R>' .. nm(v.R) .. '</R><G>' .. nm(v.G) .. '</G><B>' .. nm(v.B) .. '</B></Color3>' end
local function serBrickColor(name, v) return '<BrickColor name="' .. clean(name) .. '">' .. tostring(v.Number) .. '</BrickColor>' end
local function serUDim(name, v) return '<UDim name="' .. clean(name) .. '"><S>' .. nm(v.Scale) .. '</S><O>' .. tostring(v.Offset) .. '</O></UDim>' end
local function serUDim2(name, v) return '<UDim2 name="' .. clean(name) .. '"><XS>' .. nm(v.X.Scale) .. '</XS><XO>' .. tostring(v.X.Offset) .. '</XO><YS>' .. nm(v.Y.Scale) .. '</YS><YO>' .. tostring(v.Y.Offset) .. '</YO></UDim2>' end
local function serRect(name, v) return '<Rect name="' .. clean(name) .. '"><min><X>' .. nm(v.Min.X) .. '</X><Y>' .. nm(v.Min.Y) .. '</Y></min><max><X>' .. nm(v.Max.X) .. '</X><Y>' .. nm(v.Max.Y) .. '</Y></max></Rect>' end
local function serNumberRange(name, v) return '<NumberRange name="' .. clean(name) .. '"><Min>' .. nm(v.Min) .. '</Min><Max>' .. nm(v.Max) .. '</Max></NumberRange>' end
local function serNumberSequence(name, v)
    local s = '<NumberSequence name="' .. clean(name) .. '">'
    for _, k in ipairs(v.Keypoints) do s = s .. '<Keypoint><Time>' .. nm(k.Time) .. '</Time><Value>' .. nm(k.Value) .. '</Value><Envelope>' .. nm(k.Envelope) .. '</Envelope></Keypoint>' end
    return s .. '</NumberSequence>'
end
local function serColorSequence(name, v)
    local s = '<ColorSequence name="' .. clean(name) .. '">'
    for _, k in ipairs(v.Keypoints) do s = s .. '<Keypoint><Time>' .. nm(k.Time) .. '</Time><Color><R>' .. nm(k.Value.R) .. '</R><G>' .. nm(k.Value.G) .. '</G><B>' .. nm(k.Value.B) .. '</B></Color></Keypoint>' end
    return s .. '</ColorSequence>'
end
local function serEnumItem(name, v)
    local ok, val = pcall(function() return v.Value end)
    if ok and type(val) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(val) .. '</token>' end
    return nil
end
local function serTokenNumber(name, v)
    if type(v) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(v) .. '</token>' end
    local ok, val = pcall(function() return v.Value end)
    if ok and type(val) == "number" then return '<token name="' .. clean(name) .. '">' .. tostring(val) .. '</token>' end
    return nil
end
local function serFaces(name, v)
    local f, base = 0, 1
    for _, k in ipairs({"Top","Bottom","Left","Right","Front","Back"}) do if v[k] then f = f + base end base = base * 2 end
    return '<token name="' .. clean(name) .. '">' .. f .. '</token>'
end
local function serAxes(name, v)
    local f, base = 0, 1
    for _, k in ipairs({"X","Y","Z"}) do if v[k] then f = f + base end base = base * 2 end
    return '<token name="' .. clean(name) .. '">' .. f .. '</token>'
end

local Walker = { refs = {}, refCount = 0, totalInst = 0 }

local function serInstance(name, v)
    if Walker.refs[v] then return '<Ref name="' .. clean(name) .. '">' .. Walker.refs[v] .. '</Ref>' end
    return nil
end
local function serPhysicalProps(name, v)
    local ok, body = pcall(function()
        return '<Density>' .. nm(v.Density) .. '</Density><Friction>' .. nm(v.Friction) .. '</Friction><Elasticity>' .. nm(v.Elasticity) .. '</Elasticity><FrictionWeight>' .. nm(v.FrictionWeight) .. '</FrictionWeight><ElasticityWeight>' .. nm(v.ElasticityWeight) .. '</ElasticityWeight>'
    end)
    if not ok or not body then return nil end
    return '<PhysicalProperties name="' .. clean(name) .. '">' .. body .. '</PhysicalProperties>'
end
local function serBinaryString(name, v)
    if type(v) ~= "string" then return nil end
    return '<BinaryString name="' .. clean(name) .. '">' .. b64(v) .. '</BinaryString>'
end
local function serRay(name, v)
    local ok, o, d = pcall(function() return v.Origin, v.Direction end)
    if not ok then return nil end
    return '<Ray name="' .. clean(name) .. '"><Origin><X>' .. nm(o.X) .. '</X><Y>' .. nm(o.Y) .. '</Y><Z>' .. nm(o.Z) .. '</Z></Origin><Direction><X>' .. nm(d.X) .. '</X><Y>' .. nm(d.Y) .. '</Y><Z>' .. nm(d.Z) .. '</Z></Direction></Ray>'
end
local function serFont(name, v)
    local parts = {}
    pcall(function() table.insert(parts, '<Family>' .. clean(v.Family) .. '</Family>') end)
    pcall(function() table.insert(parts, '<Weight>' .. tostring(v.Weight.Value) .. '</Weight>') end)
    pcall(function() table.insert(parts, '<Style>' .. tostring(v.Style.Value) .. '</Style>') end)
    if #parts == 0 then return nil end
    return '<Font name="' .. clean(name) .. '">' .. table.concat(parts) .. '</Font>'
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

local function serializeProp(name, v)
    if v == nil then return nil end
    if shouldSkipProp(name) then return nil end
    if BINARY_PROPS[name] and type(v) == "string" then
        return '<BinaryString name="' .. clean(name) .. '">' .. b64(v) .. '</BinaryString>'
    end
    if type(v) == "boolean" then return serBool(name, v) end
    local special = specialPropHandlers[name]
    if special then local s = special(name, v) if s then return s end end
    local t = typeof(v)
    if t == "EnumItem" then return serEnumItem(name, v) end
    local fn = serByType[t]
    if not fn and type(v) == "boolean" then fn = serBool end
    if not fn then return nil end
    local ok, s = pcall(fn, name, v)
    if ok and s and s ~= "" then return s end
    return nil
end

local function propsViaGetProperties(inst)
    if not Fish.Options.UseGetProperties or not IO.getproperties then return nil end
    local ok, list = pcall(IO.getproperties, inst)
    if not ok or type(list) ~= "table" then return nil end
    local out = {}
    for _, k in ipairs(list) do
        if type(k) == "string" and not shouldSkipProp(k) and isPropValid(inst.ClassName, k) then
            table.insert(out, k)
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

local defaultValues = {}
local NOVALUE = {}
local function defaultValue(cls, defaultInst, k)
    local vals = defaultValues[cls]
    if not vals then vals = {} defaultValues[cls] = vals end
    local dv = vals[k]
    if dv == nil then
        local ok, got = pcall(indexProp, defaultInst, k)
        dv = (ok and got ~= nil) and got or NOVALUE
        vals[k] = dv
    end
    if dv == NOVALUE then return nil end
    return dv
end

local function valuesEqual(a, b)
    if a == b then return true end
    local ta, tb = typeof(a), typeof(b)
    if ta ~= tb then return false end
    if ta == "number" then return math.abs(a - b) < 1e-6 end
    if ta == "string" or ta == "boolean" then return a == b end
    local ok1, s1 = pcall(tostring, a)
    local ok2, s2 = pcall(tostring, b)
    if ok1 and ok2 then return s1 == s2 end
    return false
end

local function modelIsCharacter(m)
    if not m then return false end
    local ok, player = pcall(function() return Players:GetPlayerFromCharacter(m) end)
    if ok and player then return true end
    local ok2, hum = pcall(function() return m:FindFirstChildOfClass("Humanoid") end)
    if ok2 and hum then
        local ok3, hrp = pcall(function() return m:FindFirstChild("HumanoidRootPart") end)
        if ok3 and hrp then return true end
    end
    return false
end

local function isCharacter(inst, opts, charRefs)
    if not opts.StripCharacters then return false end
    if not inst then return false end
    if charRefs[inst] then return true end
    if not inst:IsA("Model") then
        if CHARACTER_CLASSES[inst.ClassName] then
            local okp2, parent = pcall(function() return inst.Parent end)
            if okp2 and parent and parent:IsA("Model") and modelIsCharacter(parent) then
                charRefs[inst] = true
                return true
            end
        end
        return false
    end
    if modelIsCharacter(inst) then
        charRefs[inst] = true
        local okd, desc = pcall(function() return inst:GetDescendants() end)
        if okd and desc then for _, d in ipairs(desc) do charRefs[d] = true end end
        return true
    end
    return false
end

local function nameIsCore(inst, opts, coreRefs)
    if not opts.StripCoreScripts then return false end
    local ok, n = pcall(function() return inst.Name end)
    if not ok or not n then return false end
    if CORE_SCRIPT_NAMES[n] then coreRefs[inst] = true return true end
    return false
end

local CORE_CONTAINERS = { PlayerScripts = true, PlayerGui = true, StarterPlayer = true }

local function keepInst(inst, opts, charRefs, coreRefs)
    if isCharacter(inst, opts, charRefs) then return false end
    if nameIsCore(inst, opts, coreRefs) then return false end
    if inst:IsA("Lighting") then return true end
    if opts.IgnoreNotArchivable then
        local ok, ar = pcall(function() return inst.Archivable end)
        if ok and ar == false then return false end
    end
    local parent = inst.Parent
    if parent and charRefs[parent] then return false end
    if parent and coreRefs[parent] then return false end
    if parent == game and SKIP_SVC[inst.ClassName] then return false end
    return true
end

local function canKeep(inst, opts, charRefs, coreRefs)
    local ok, keep = pcall(keepInst, inst, opts, charRefs, coreRefs)
    return ok and keep == true
end

local function walkRef(root, d, opts, refs, charRefs, coreRefs)
    if d > opts.Depth then return end
    if refs[root] then return end
    Walker.refCount = Walker.refCount + 1
    refs[root] = "RBX" .. Walker.refCount
    if Walker.refCount % 2000 == 0 then
        setStatusText("Saving game.. scanning " .. Walker.refCount)
    end
    breathe()
    if opts.StripCoreScripts and CORE_CONTAINERS[root.ClassName] then return end
    local ok, kids = pcall(root.GetChildren, root)
    if not ok or not kids then return end
    for _, c in ipairs(kids) do
        if canKeep(c, opts, charRefs, coreRefs) then walkRef(c, d + 1, opts, refs, charRefs, coreRefs) end
    end
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

local function emitContentProp(buf, inst, pad, propName)
    local raw = readProp(inst, propName)
    if raw == nil then return end
    local uri = extractUri(raw)
    if not uri then return end
    table.insert(buf, pad .. '    ' .. serContentTag(propName, uri))
end

local function emitSingleProp(buf, inst, pad, seen, k, opts, defaultInst)
    if seen[k] or shouldSkipProp(k) then return end
    if opts.APIProperties and not isPropValid(inst.ClassName, k) then return end
    if isRealContent(k) then
        seen[k] = true
        emitContentProp(buf, inst, pad, k)
    else
        local v = readProp(inst, k)
        if v ~= nil then
            seen[k] = true
            local skip = false
            if defaultInst then
                local dv = defaultValue(inst.ClassName, defaultInst, k)
                if dv ~= nil then
                    local ok1, eq = pcall(valuesEqual, v, dv)
                    if ok1 and eq then skip = true end
                end
            end
            if not skip then
                local s = serializeProp(k, v)
                if s then table.insert(buf, pad .. '    ' .. s) end
            end
        end
    end
end

local function emitPropsFromList(buf, inst, pad, seen, list, opts)
    local cls = inst.ClassName
    local defaultInst = opts.IgnoreDefaultProps and getDefault(cls) or nil
    for _, k in ipairs(list) do
        emitSingleProp(buf, inst, pad, seen, k, opts, defaultInst)
    end
end

local function encodeTags(inst)
    local tags = CollectionService:GetTags(inst)
    if type(tags) ~= "table" or #tags == 0 then return nil end
    return table.concat(tags, "\0")
end

local function emitAttributesAndTags(buf, inst, pad, opts)
    if opts.EmitAttributes then
        local ok, attrs = pcall(function() return inst:GetAttributes() end)
        if ok and type(attrs) == "table" and next(attrs) ~= nil then
            local success, encoded = pcall(function()
                return HttpService:JSONEncode(attrs)
            end)
            if success and encoded and #encoded > 0 then
                table.insert(buf, pad .. '    <BinaryString name="AttributesSerialize">' .. b64(encoded) .. '</BinaryString>')
            end
        end
    end
    if opts.EmitTags then
        local ok, encoded = pcall(encodeTags, inst)
        if ok and encoded then
            table.insert(buf, pad .. '    <BinaryString name="Tags">' .. b64(encoded) .. '</BinaryString>')
        end
    end
end

local function shouldEmitInMode(cls, mode)
    if mode == "full" then return true end
    if mode == "scripts" then return cls == "Script" or cls == "LocalScript" or cls == "ModuleScript" end
    if mode == "models" then return cls ~= "Script" and cls ~= "LocalScript" and cls ~= "ModuleScript" end
    return true
end

local emitInst

local GEOMETRY_PROPS = {
    UnionOperation = {"AssetId", "InitialSize", "ChildData", "ChildData2", "MeshData", "MeshData2", "PhysicsData", "PhysicalConfigData", "FormFactor", "UsePartColor", "RenderFidelity", "CollisionFidelity", "SmoothingAngle"},
    MeshPart = {"MeshId", "InitialSize", "PhysicsData", "PhysicalConfigData", "RenderFidelity", "CollisionFidelity", "HasJointOffset", "HasSkinnedMesh", "JointOffset"},
}

local emitInst

local propPlans = {}
local decompiledByBytecode = {}
local function propPlan(inst, cls, opts)
    local plan = propPlans[cls]
    if plan then return plan end
    plan = {}
    local added = {}
    local function add(list, useDefault)
        if not list then return end
        for _, k in ipairs(list) do
            if not added[k] and not shouldSkipProp(k) and (not opts.APIProperties or isPropValid(cls, k)) then
                added[k] = true
                plan[#plan + 1] = { k, useDefault, isRealContent(k) }
            end
        end
    end
    add(INSTANCE_SPECIFIC[cls], true)
    add(CRITICAL_PROPS, true)
    add(propsViaGetProperties(inst), false)
    propPlans[cls] = plan
    return plan
end

local function emitProps(own, inst, cls, pad, opts, decompileCache)
    local seen = {}
    local defaultInst = opts.IgnoreDefaultProps and getDefault(cls) or nil
    local plan = propPlan(inst, cls, opts)
    for i = 1, #plan do
        local entry = plan[i]
        local k = entry[1]
        if entry[3] then
            seen[k] = true
            emitContentProp(own, inst, pad, k)
        else
            local v = readProp(inst, k)
            if v ~= nil then
                seen[k] = true
                local same = false
                if entry[2] and defaultInst then
                    local dv = defaultValue(cls, defaultInst, k)
                    if dv ~= nil then
                        local ok1, eq = pcall(valuesEqual, v, dv)
                        same = ok1 and eq == true
                    end
                end
                if not same then
                    local str = serializeProp(k, v)
                    if str then own[#own + 1] = pad .. '    ' .. str end
                end
            end
        end
    end

    if not seen.Name then
        local name = readProp(inst, "Name")
        if name then
            if opts.Anonymous then
                local ok, p = pcall(function() return Players:GetPlayerFromCharacter(inst) end)
                if ok and p then name = "Player_" .. tostring(p.UserId) end
            end
            table.insert(own, pad .. '    <string name="Name">' .. clean(name) .. '</string>')
        end
    end

    emitAttributesAndTags(own, inst, pad, opts)

    if cls == "Script" then
        local src = tostring(DATA.server_script_placeholder or "")
        table.insert(own, pad .. '    <ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>')
    elseif cls == "LocalScript" or cls == "ModuleScript" then
        local src = readProp(inst, "Source")
        if decompileCache and decompileCache[inst] then src = decompileCache[inst] end
        if (not src or src == "") and opts.Decompile and opts._decompileFn then
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
        table.insert(own, pad .. '    <ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>')
    end

    if cls == "UnionOperation" or cls == "IntersectOperation" or cls == "NegateOperation" or cls == "PartOperation" or cls == "MeshPart" then
        for _, bp in ipairs(GEOMETRY_PROPS[cls] or GEOMETRY_PROPS.UnionOperation) do
            if not seen[bp] then
                local raw = readProp(inst, bp)
                if type(raw) == "string" and #raw > 0 then
                    if bp == "AssetId" then
                        local uri = extractUri(raw)
                        if uri then table.insert(own, pad .. '    ' .. serContentTag(bp, uri)) end
                    else
                        table.insert(own, pad .. '    <BinaryString name="' .. bp .. '">' .. b64(raw) .. '</BinaryString>')
                    end
                    seen[bp] = true
                elseif raw ~= nil then
                    local str = (bp == "AssetId") and extractUri(raw) and serContentTag(bp, extractUri(raw)) or serializeProp(bp, raw)
                    if str then
                        table.insert(own, pad .. '    ' .. str)
                        seen[bp] = true
                    end
                end
            end
        end
    end

    -- Terrain doesn't save if your executor has low UNC but atleast it tries
    if cls == "Terrain" and IO.gethiddenproperty then
        for _, bp in ipairs({"SmoothGrid", "MaterialColors"}) do
            if not seen[bp] then
                local ok, raw = pcall(IO.gethiddenproperty, inst, bp)
                if ok and type(raw) == "string" and #raw > 0 then
                    table.insert(own, pad .. '    <BinaryString name="' .. bp .. '">' .. b64(raw) .. '</BinaryString>')
                end
            end
        end
    end

end

emitInst = function(buf, inst, d, opts, decompileCache, refs, totalRefs)
    local ref = refs[inst]
    if not ref then return end
    local cls = inst.ClassName

    if not shouldEmitInMode(cls, opts.Mode) then
        local okc, kids = pcall(inst.GetChildren, inst)
        if okc and kids then for _, c in ipairs(kids) do if refs[c] then emitInst(buf, c, d, opts, decompileCache, refs, totalRefs) end end end
        return
    end

    Walker.totalInst = Walker.totalInst + 1
    bumpStatus("Saving", Walker.totalInst, totalRefs)

    local pad = string.rep("  ", d)
    local own = {}
    local ok, err = pcall(emitProps, own, inst, cls, pad, opts, decompileCache)
    if not ok then
        log("Skipped " .. tostring(ref) .. " (" .. tostring(cls) .. "): " .. tostring(err))
        return
    end

    buf[#buf + 1] = pad .. '<Item class="' .. clean(cls) .. '" referent="' .. ref .. '">'
    buf[#buf + 1] = pad .. '  <Properties>'
    for i = 1, #own do buf[#buf + 1] = own[i] end
    buf[#buf + 1] = pad .. '  </Properties>'

    local okc, kids = pcall(inst.GetChildren, inst)
    if okc and kids then for _, c in ipairs(kids) do if refs[c] then emitInst(buf, c, d + 1, opts, decompileCache, refs, totalRefs) end end end

    buf[#buf + 1] = pad .. '</Item>'

    local sink = opts._sink
    if sink and #buf >= 16384 then
        sink:write(table.concat(buf, "\n") .. "\n")
        table.clear(buf)
    end
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

local function buildReadmeXML(depth)
    local pad = string.rep("  ", depth)
    local src = buildReadmeSource()
    return table.concat({
        pad .. '<Item class="Script" referent="RBX_README">',
        pad .. '  <Properties>',
        pad .. '    <string name="Name">README</string>',
        pad .. '    <bool name="Disabled">false</bool>',
        pad .. '    <ProtectedString name="Source">' .. clean(src) .. '</ProtectedString>',
        pad .. '  </Properties>',
        pad .. '</Item>',
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
                    table.insert(_pendingRestore, {tool = tool, orig = origParent})
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
    s.chunk = chunk or 262144
    s.buf = {}
    s.size = 0
    s.total = 0
    s.failed = not pcall(IO.writefile, path, "")
    return s
end

function Sink:flush()
    if #self.buf == 0 or self.failed then return end
    local blob = table.concat(self.buf)
    table.clear(self.buf)
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
    table.clear(propPlans)
    table.clear(decompiledByBytecode)
    _lastYield = os.clock()
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
    Walker.refs = refs

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
        for _, r in ipairs(instance) do if typeof(r) == "Instance" then table.insert(roots, r) end end
    elseif typeof(instance) == "Instance" then
        table.insert(roots, instance)
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

    local okSave, result = pcall(function()
        for _, root in ipairs(roots) do
            if root == game then
                local ok0, kids0 = pcall(function() return game:GetChildren() end)
                if ok0 and kids0 then
                    for _, svc in ipairs(kids0) do
                        if canKeep(svc, opts, charRefs, coreRefs) then walkRef(svc, 1, opts, refs, charRefs, coreRefs) end
                    end
                end
            else
                if canKeep(root, opts, charRefs, coreRefs) then walkRef(root, 1, opts, refs, charRefs, coreRefs) end
            end
        end

        log("Walked " .. Walker.refCount .. " instances")
        local buf = {}
        local decompileCache = {}

        setStatusText("Saving game.. writing")

        table.insert(buf, '<?xml version="1.0" encoding="utf-8"?>')
        table.insert(buf, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
-- Another list of APIS i personally use alot for XML related stuff
        local finalName = name or placeName()
        local fname = finalName .. ".rbxlx"
        local outFolder = ensureOutFolder()
        local primaryPath = outFolder .. "/" .. fname

        local sink = nil
        if opts.StreamToFile and IO.appendfile and not opts.Callback and not opts.Clipboard then
            sink = Sink.new(primaryPath, opts.StreamChunk)
            opts._sink = sink
            sink:write(table.concat(buf, "\n") .. "\n")
            buf = {}
        end

        local readmeEmitted = false
        for _, root in ipairs(roots) do
            if root == game then
                local ok0, kids0 = pcall(function() return game:GetChildren() end)
                if ok0 and kids0 then
                    for _, svc in ipairs(kids0) do
                        if refs[svc] then
                            emitInst(buf, svc, 1, opts, decompileCache, refs, Walker.refCount)
                            if opts._readmeXMLFn and not readmeEmitted and svc:IsA("Lighting") then
                                local readmeXml = opts._readmeXMLFn(1)
                                if readmeXml then
                                    table.insert(buf, readmeXml)
                                    readmeEmitted = true
                                end
                            end
                            if sink and #buf > 0 then
                                sink:write(table.concat(buf, "\n") .. "\n")
                                buf = {}
                            end
                        end
                    end
                end
            else
                if refs[root] then emitInst(buf, root, 1, opts, decompileCache, refs, Walker.refCount) end
                if sink and #buf > 0 then
                    sink:write(table.concat(buf, "\n") .. "\n")
                    buf = {}
                end
            end
        end

        if opts._readmeXMLFn and not readmeEmitted then
            local readmeXml = opts._readmeXMLFn(1)
            if readmeXml then
                table.insert(buf, readmeXml)
                readmeEmitted = true
            end
        end

        table.insert(buf, '</roblox>')

        local xml
        if sink then
            sink:write(table.concat(buf, "\n"))
            buf = {}
            if not sink:finish() then
                setStatusText("Failed: could not write " .. primaryPath)
                Status.fade(8)
                return nil
            end
            xml = primaryPath
        else
            xml = table.concat(buf, "\n")
        end

        local elapsed = tick() - t0

        if sink and xml == primaryPath then
            log("XML streamed to " .. primaryPath .. " in " .. string.format("%.2fs", elapsed))
        else
            log("XML: " .. #xml .. " bytes, " .. Walker.totalInst .. " items emitted in " .. string.format("%.2fs", elapsed))
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
        if opts.FilePath then table.insert(paths, opts.FilePath) end
        table.insert(paths, primaryPath)
        table.insert(paths, fname)

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

        setStatusText("Saved to " .. primaryPath .. " in " .. string.format("%.1fs", elapsed))
        Status.fade(5)
        return xml
    end)

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

-- Thank you claude for adding useless underscores

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

return Fish
