-- ====================================================================
-- VOLLEYBALL LEGENDS - AGGRESSIVE SPORT EDITION (PREMIUM v2.2)
-- FIXED: сфера хитбокса привязана к мячу (единый цикл)
-- ADDED: Purge Character в Visuals + П.5 (дубликат цикла) + П.3 (утечки)
-- ====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

do
    pcall(function()
        if not hookfunction then return end
        local ContentProvider = game:GetService("ContentProvider")
        local CG = game:GetService("CoreGui")
        local oldPreloadAsync = ContentProvider.PreloadAsync
        if not oldPreloadAsync then return end
        hookfunction(oldPreloadAsync, function(self, instances, callback)
            if type(instances) ~= "table" then return oldPreloadAsync(self, instances, callback) end
            local filtered = {}
            for i = 1, #instances do
                local obj = instances[i]
                if obj ~= CG then
                    local skip = false
                    pcall(function()
                        local parent = obj
                        while parent do
                            if parent == CG then skip = true break end
                            parent = parent.Parent
                        end
                    end)
                    if not skip then table.insert(filtered, obj) end
                end
            end
            return oldPreloadAsync(self, filtered, callback)
        end)
    end)
end

pcall(function()
    if gethui then
        for _, gui in ipairs(gethui():GetChildren()) do
            if gui.Name == "VL_Menu" or gui.Name == "VL_Panel" or gui.Name == "VL_ESP" or gui.Name == "VL_Load" or gui.Name == "RobloxGui" then
                pcall(function() gui:Destroy() end)
            end
        end
    end
end)
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name == "VL_Menu" or gui.Name == "VL_Panel" or gui.Name == "VL_ESP" or gui.Name == "VL_Load" or gui.Name == "RobloxGui" then
        pcall(function() gui:Destroy() end)
    end
end

local THEME = {
    BG_DARK = Color3.fromRGB(8, 6, 14), BG_MID = Color3.fromRGB(14, 11, 22),
    BG_PANEL = Color3.fromRGB(11, 9, 18), BG_LEFT = Color3.fromRGB(18, 14, 28),
    ACCENT = Color3.fromRGB(180, 80, 255), ACCENT_DARK = Color3.fromRGB(80, 40, 150),
    ACCENT_GLOW = Color3.fromRGB(220, 150, 255), ACCENT_SOFT = Color3.fromRGB(130, 70, 200),
    ACCENT_HOT = Color3.fromRGB(255, 60, 180),
    TEXT_HI = Color3.fromRGB(245, 240, 255), TEXT_MID = Color3.fromRGB(170, 155, 200),
    TEXT_LOW = Color3.fromRGB(90, 75, 115), LINE = Color3.fromRGB(50, 35, 75),
}

local Config = {
    FlyingDotsEnabled = true, SoundEnabled = true, ScanLineEnabled = true,
    FpsCounterEnabled = false, MenuScale = 100, CornerRadius = 8, Dots = {},
    HitboxEnabled = false, HitboxSize = 30,
    BallESPEnabled = false, BallPredictorEnabled = false,
    FOV = 70,
}

local S = {
    Corner = {}, ColorSynced = {}, Sliders = {}, Toggles = {}, Br = {},
    Connections = {},  -- [NEW] П.3: сюда пишем все RunService коннекты для Unload
    BallESP = { model = nil, highlight = nil, particles = nil, light = nil, trail = nil, trailAtt0 = nil, trailAtt1 = nil },
    Pred = { ring = nil, lastPos = nil, lastTime = nil, smoothVel = nil, smoothLand = nil },
    HitboxVisual = { Sphere = nil, Radius = 0 },
    MegaHitbox = { Enabled = false, SizeMultiplier = 3, UpdateInterval = 0.05, ExpandedCount = 0 },
    RangeGuard = { Enabled = false, Radius = 8 },
    HitBlocker = { LastBlockTime = 0 },
    Tracers = { Enabled = false, Length = 25, OnlyEnemies = false, Folder = nil, Active = {} },
    ClothesWiper = { Enabled = false, Wiped = {} },
    Sky = { Current = nil, Connection = nil, Objects = {}, Presets = {}, Buttons = {} },
    -- [NEW] Purge Character
    Purge = {
        Enabled = false,
        Eyes = true,
        Sparkles = true,
        Gray = true,
        Leg = true,
        Head = true,
        Tracked = {},      -- [player] = { char, bc, conns, pulseConn, origColors }
        EyeColor = Color3.fromRGB(180, 80, 255),
        SparkleColor = Color3.fromRGB(255, 150, 255),
        GrayBase = Color3.fromRGB(185, 185, 192),
        BrightnessMin = 0.35,
        BrightnessMax = 1.0,
        PulseSpeed = 0.9,
    },
}

local logoPath = nil
local brandPath = nil
local bannerPath = nil

function RegisterCorner(uiCorner, baseRadius)
    table.insert(S.Corner, { Corner = uiCorner, BaseRadius = baseRadius or Config.CornerRadius })
end

function downloadImage(url, path)
    if isfile and isfile(path) then return true end
    local ok, content = pcall(function() return game:HttpGet(url, true) end)
    if ok and content then
        pcall(function() writefile(path, content) end)
        return true
    end
    return false
end

function getAssetPath(path)
    if getcustomasset then return getcustomasset(path)
    elseif getgenv and getgenv().getcustomasset then return getgenv().getcustomasset(path) end
    return nil
end

pcall(function()
    if isfile and writefile then
        if not isfile("vl_logo.png") then
            downloadImage("https://i.ibb.co/RkDbPKvG/IMG-20260912-124847.jpg", "vl_logo.png")
        end
        if not isfile("vl_brand.png") then
            downloadImage("https://i.ibb.co/WWWZY4jc/14289-removebg-preview.png", "vl_brand.png")
        end
        if not isfile("vl_banner.png") then
            downloadImage("https://i.ibb.co/tMsVBqwG/IMG-20260828-160933.png", "vl_banner.png")
        end
    end
    if isfile and isfile("vl_logo.png") then logoPath = getAssetPath("vl_logo.png") end
    if isfile and isfile("vl_brand.png") then brandPath = getAssetPath("vl_brand.png") end
    if isfile and isfile("vl_banner.png") then bannerPath = getAssetPath("vl_banner.png") end
end)

-- ====================================================================
-- ХУК HITBOX
-- ====================================================================
local HitboxModuleRef = nil
local HitboxOrigGet = nil

function GetHitboxModule()
    if HitboxModuleRef then return HitboxModuleRef end
    local Tools = ReplicatedStorage:FindFirstChild("Tools")
    if not Tools then return nil end
    local HM = Tools:FindFirstChild("Hitbox")
    if not HM then return nil end
    local ok, module = pcall(require, HM)
    if ok and type(module) == "table" then
        HitboxModuleRef = module
        return module
    end
    return nil
end

function UpdateHitboxHook()
    local Hitbox = GetHitboxModule()
    if not Hitbox then return false end
    local shouldHook = S.MegaHitbox.Enabled or S.RangeGuard.Enabled
    if shouldHook then
        if not Hitbox.__VL_Hooked then
            Hitbox.All = nil
            Hitbox.Hitboxes = {}
            HitboxOrigGet = Hitbox.get
            Hitbox.__VL_OrigGet = HitboxOrigGet
            Hitbox.get = function(move)
                local result = HitboxOrigGet(move)
                if result and result.Size then
                    local mult = 1
                    if S.MegaHitbox.Enabled then mult = S.MegaHitbox.SizeMultiplier end
                    if mult > 1 then
                        result.Size = Vector3.new(result.Size.X * mult, result.Size.Y * mult, result.Size.Z * mult)
                    end
                end
                return result
            end
            Hitbox.__VL_Hooked = true
            print("[VL] Hitbox.get захукан")
        end
    else
        if Hitbox.__VL_Hooked and Hitbox.__VL_OrigGet then
            Hitbox.get = Hitbox.__VL_OrigGet
            Hitbox.__VL_Hooked = nil
            Hitbox.__VL_OrigGet = nil
            Hitbox.All = nil
            Hitbox.Hitboxes = {}
        end
    end
    return true
end

-- ====================================================================
-- SCREEN GUI
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RobloxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 0
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local safeParent = CoreGui
pcall(function()
    if gethui then
        local hui = gethui()
        if hui then safeParent = hui end
    end
end)

local attachOK = pcall(function() ScreenGui.Parent = safeParent end)
if not attachOK or not ScreenGui.Parent then
    safeParent = CoreGui
    pcall(function() ScreenGui.Parent = CoreGui end)
end
if not ScreenGui.Parent then
    safeParent = LocalPlayer:WaitForChild("PlayerGui", 5)
    pcall(function() ScreenGui.Parent = safeParent end)
end

pcall(function()
    sethiddenproperty(ScreenGui, "RobloxLocked", true)
    sethiddenproperty(ScreenGui, "Archivable", false)
end)

local CG_REF = CoreGui
local PG_REF = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local HIDDEN_NAMES = { ["RobloxGui"]=true, ["VL_Menu"]=true, ["VL_Load"]=true }

pcall(function()
    if not hookmetamethod then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if self == CG_REF or self == PG_REF then
            local name = ...
            if type(name) == "string" and HIDDEN_NAMES[name] then return nil end
        end
        return oldNamecall(self, ...)
    end)
end)

local TabSound = Instance.new("Sound")
TabSound.SoundId = "rbxassetid://9035348386"
TabSound.Volume = 1
TabSound.Parent = SoundService

function PlayTab()
    if Config.SoundEnabled then pcall(function() TabSound:Play() end) end
end

-- ====================================================================
-- LOADING SCREEN
-- ====================================================================
local LoadGui = Instance.new("ScreenGui")
LoadGui.Name = "VL_Load"
LoadGui.ResetOnSpawn = false
LoadGui.IgnoreGuiInset = true
pcall(function() LoadGui.Parent = safeParent end)

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DarkOverlay.BackgroundTransparency = 1
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 1
DarkOverlay.Parent = LoadGui

TweenService:Create(DarkOverlay, TweenInfo.new(0.6), {BackgroundTransparency = 0.4}):Play()

local LoadingContainer = Instance.new("Frame")
LoadingContainer.Size = UDim2.new(0, 700, 0, 280)
LoadingContainer.Position = UDim2.new(0.5, -350, 0.5, -140)
LoadingContainer.BackgroundTransparency = 1
LoadingContainer.ZIndex = 10
LoadingContainer.Parent = LoadGui

local GlitchContainer = Instance.new("Frame")
GlitchContainer.Size = UDim2.new(1, 0, 0, 60)
GlitchContainer.BackgroundTransparency = 1
GlitchContainer.Parent = LoadingContainer

local GlitchGlow = Instance.new("TextLabel")
GlitchGlow.Size = UDim2.new(1, 0, 1, 0)
GlitchGlow.BackgroundTransparency = 1
GlitchGlow.Text = "VOLLEYBALL"
GlitchGlow.TextColor3 = THEME.ACCENT
GlitchGlow.TextSize = 46
GlitchGlow.Font = Enum.Font.GothamBold
GlitchGlow.TextTransparency = 0.75
GlitchGlow.ZIndex = 0
GlitchGlow.Parent = GlitchContainer

local GlitchRed = Instance.new("TextLabel")
GlitchRed.Size = UDim2.new(1, 0, 1, 0)
GlitchRed.BackgroundTransparency = 1
GlitchRed.Text = "VOLLEYBALL"
GlitchRed.TextColor3 = Color3.fromRGB(255, 50, 100)
GlitchRed.TextSize = 42
GlitchRed.Font = Enum.Font.Gotham
GlitchRed.ZIndex = 1
GlitchRed.Parent = GlitchContainer

local GlitchCyan = Instance.new("TextLabel")
GlitchCyan.Size = UDim2.new(1, 0, 1, 0)
GlitchCyan.BackgroundTransparency = 1
GlitchCyan.Text = "VOLLEYBALL"
GlitchCyan.TextColor3 = Color3.fromRGB(100, 220, 255)
GlitchCyan.TextSize = 42
GlitchCyan.Font = Enum.Font.Gotham
GlitchCyan.ZIndex = 2
GlitchCyan.Parent = GlitchContainer

local GlitchMain = Instance.new("TextLabel")
GlitchMain.Size = UDim2.new(1, 0, 1, 0)
GlitchMain.BackgroundTransparency = 1
GlitchMain.Text = "VOLLEYBALL"
GlitchMain.TextColor3 = Color3.fromRGB(255, 255, 255)
GlitchMain.TextSize = 42
GlitchMain.Font = Enum.Font.Gotham
GlitchMain.ZIndex = 3
GlitchMain.Parent = GlitchContainer

local GlitchGradient = Instance.new("UIGradient", GlitchMain)
GlitchGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_HOT),
})

task.spawn(function()
    while LoadGui.Parent do
        for i = -1, 1, 0.02 do GlitchGradient.Offset = Vector2.new(i, 0); task.wait(0.03) end
        for i = 1, -1, -0.02 do GlitchGradient.Offset = Vector2.new(i, 0); task.wait(0.03) end
    end
end)

task.spawn(function()
    while LoadGui.Parent do
        task.wait(math.random(10, 20) / 10)
        GlitchRed.Position = UDim2.new(0, math.random(3, 6), 0, math.random(-2, 2))
        GlitchCyan.Position = UDim2.new(0, math.random(-6, -3), 0, math.random(-2, 2))
        GlitchMain.Position = UDim2.new(0, math.random(-2, 2), 0, 0)
        GlitchGlow.Position = UDim2.new(0, math.random(-4, 4), 0, math.random(-2, 2))
        task.wait(0.05)
        GlitchRed.Position = UDim2.new(0, math.random(-8, -4), 0, 0)
        GlitchCyan.Position = UDim2.new(0, math.random(4, 8), 0, 0)
        task.wait(0.05)
        GlitchRed.Position = UDim2.new(0, 0, 0, 0)
        GlitchCyan.Position = UDim2.new(0, 0, 0, 0)
        GlitchMain.Position = UDim2.new(0, 0, 0, 0)
        GlitchGlow.Position = UDim2.new(0, 0, 0, 0)
    end
end)

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 60)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "// LOADING INTERFACE"
LoadingSubtitle.TextColor3 = THEME.ACCENT_HOT
LoadingSubtitle.TextSize = 13
LoadingSubtitle.Font = Enum.Font.Code
LoadingSubtitle.ZIndex = 5
LoadingSubtitle.Parent = LoadingContainer

local BarContainer = Instance.new("Frame")
BarContainer.Size = UDim2.new(0, 600, 0, 40)
BarContainer.Position = UDim2.new(0.5, -300, 0, 100)
BarContainer.BackgroundTransparency = 1
BarContainer.ZIndex = 5
BarContainer.Parent = LoadingContainer

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, 0, 0, 12)
BarBg.Position = UDim2.new(0, 0, 0, 14)
BarBg.BackgroundColor3 = Color3.fromRGB(8, 6, 14)
BarBg.BorderSizePixel = 0
BarBg.ZIndex = 6
BarBg.Parent = BarContainer
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

local BarBgStroke = Instance.new("UIStroke", BarBg)
BarBgStroke.Thickness = 1.5
BarBgStroke.Color = THEME.ACCENT_DARK
BarBgStroke.Transparency = 0.4

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = THEME.ACCENT_HOT
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 8
BarFill.Parent = BarBg
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local BarFillGradient = Instance.new("UIGradient", BarFill)
BarFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_GLOW),
})

task.spawn(function()
    while LoadGui.Parent do
        for i = -1, 1, 0.04 do BarFillGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
        for i = 1, -1, -0.04 do BarFillGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
    end
end)

local BarFillGlow = Instance.new("UIStroke", BarFill)
BarFillGlow.Thickness = 3
BarFillGlow.Color = THEME.ACCENT_GLOW
BarFillGlow.Transparency = 0.5

local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size = UDim2.new(1, 0, 0, 14)
PercentLabel.Position = UDim2.new(0, 0, 0, -2)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text = "0%"
PercentLabel.TextColor3 = THEME.TEXT_HI
PercentLabel.TextSize = 11
PercentLabel.Font = Enum.Font.Code
PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
PercentLabel.ZIndex = 9
PercentLabel.Parent = BarContainer

local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(1, 0, 0, 14)
ProgressLabel.Position = UDim2.new(0, 0, 0, -2)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "PROGRESS"
ProgressLabel.TextColor3 = THEME.TEXT_LOW
ProgressLabel.TextSize = 10
ProgressLabel.Font = Enum.Font.Code
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.ZIndex = 9
ProgressLabel.Parent = BarContainer

local StatusContainer = Instance.new("Frame")
StatusContainer.Size = UDim2.new(0, 600, 0, 30)
StatusContainer.Position = UDim2.new(0.5, -300, 0, 165)
StatusContainer.BackgroundTransparency = 1
StatusContainer.ZIndex = 5
StatusContainer.Parent = LoadingContainer

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "// INITIALIZATION"
StatusLabel.TextColor3 = THEME.ACCENT_HOT
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Code
StatusLabel.ZIndex = 6
StatusLabel.Parent = StatusContainer

local StatusGradient = Instance.new("UIGradient", StatusLabel)
StatusGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

local DotsContainer = Instance.new("Frame")
DotsContainer.Size = UDim2.new(0, 60, 0, 8)
DotsContainer.Position = UDim2.new(0.5, -30, 0, 200)
DotsContainer.BackgroundTransparency = 1
DotsContainer.ZIndex = 5
DotsContainer.Parent = LoadingContainer

local statusDots = {}
for i = 1, 3 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, (i-1) * 14, 0, 1)
    dot.BackgroundColor3 = THEME.ACCENT_HOT
    dot.BackgroundTransparency = 0.7
    dot.BorderSizePixel = 0
    dot.ZIndex = 6
    dot.Parent = DotsContainer
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    table.insert(statusDots, dot)
end

task.spawn(function()
    while LoadGui.Parent do
        for i, dot in ipairs(statusDots) do
            TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0.1, Size = UDim2.new(0, 8, 0, 8)}):Play()
            task.wait(0.25)
            TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 6, 0, 6)}):Play()
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    while LoadGui.Parent do
        for i = -1, 1, 0.03 do StatusGradient.Offset = Vector2.new(i, 0); task.wait(0.03) end
        for i = 1, -1, -0.03 do StatusGradient.Offset = Vector2.new(i, 0); task.wait(0.03) end
    end
end)

local Sound = Instance.new("Sound")
Sound.SoundId = "rbxassetid://136508094734046"
Sound.Volume = 1
Sound.Parent = SoundService

task.spawn(function()
    task.wait(0.3)
    local totalTime = 1.2
    local startTime = tick()
    while true do
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / totalTime, 0, 1)
        local eased = 1 - (1 - progress) ^ 2.5
        BarFill.Size = UDim2.new(eased, 0, 1, 0)
        PercentLabel.Text = string.format("%d%%", math.floor(eased * 100))
        if progress >= 1 then break end
        task.wait(0.016)
    end
    task.wait(0.3)
    for _, obj in ipairs(LoadGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            TweenService:Create(obj, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        elseif obj:IsA("Frame") then
            TweenService:Create(obj, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        elseif obj:IsA("UIStroke") then
            TweenService:Create(obj, TweenInfo.new(0.4), {Transparency = 1}):Play()
        end
    end
    task.wait(0.5)
    LoadGui:Destroy()
    pcall(function() Sound:Play() end)
end)

-- ====================================================================
-- MAIN PANEL
-- ====================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 490)
MainFrame.Position = UDim2.new(0.5, -340, -1, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = MainFrame

local OuterBorder = Instance.new("Frame")
OuterBorder.Size = UDim2.new(1, 0, 1, 0)
OuterBorder.BackgroundColor3 = THEME.BG_DARK
OuterBorder.BorderSizePixel = 0
OuterBorder.ZIndex = 1
OuterBorder.Parent = MainFrame
local OuterBorderCorner = Instance.new("UICorner", OuterBorder)
OuterBorderCorner.CornerRadius = UDim.new(0, Config.CornerRadius)
RegisterCorner(OuterBorderCorner, Config.CornerRadius)

local MainStroke = Instance.new("UIStroke", OuterBorder)
MainStroke.Thickness = 2
MainStroke.Color = THEME.ACCENT
MainStroke.Transparency = 0
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local MainStrokeGradient = Instance.new("UIGradient", MainStroke)
MainStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.25, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_GLOW),
    ColorSequenceKeypoint.new(0.75, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})
MainStrokeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 0.2),
})

task.spawn(function()
    while MainStrokeGradient.Parent do
        for i = -1, 1, 0.02 do
            if not MainStrokeGradient.Parent then break end
            MainStrokeGradient.Offset = Vector2.new(i, 0)
            task.wait(0.025)
        end
        for i = 1, -1, -0.02 do
            if not MainStrokeGradient.Parent then break end
            MainStrokeGradient.Offset = Vector2.new(i, 0)
            task.wait(0.025)
        end
    end
end)

local MainGlow = Instance.new("UIStroke", OuterBorder)
MainGlow.Thickness = 4
MainGlow.Color = THEME.ACCENT_GLOW
MainGlow.Transparency = 0.85
MainGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local PanelHolder = Instance.new("Frame")
PanelHolder.Size = UDim2.new(1, -4, 1, -4)
PanelHolder.Position = UDim2.new(0, 2, 0, 2)
PanelHolder.BackgroundColor3 = THEME.BG_MID
PanelHolder.BorderSizePixel = 0
PanelHolder.ClipsDescendants = true
PanelHolder.ZIndex = 2
PanelHolder.Parent = OuterBorder
local PanelHolderCorner = Instance.new("UICorner", PanelHolder)
PanelHolderCorner.CornerRadius = UDim.new(0, math.max(0, Config.CornerRadius - 2))
RegisterCorner(PanelHolderCorner, math.max(0, Config.CornerRadius - 2))

local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.3, 0, 1, 0)
LeftPanel.BackgroundColor3 = THEME.BG_LEFT
LeftPanel.BackgroundTransparency = 0.05
LeftPanel.BorderSizePixel = 0
LeftPanel.ClipsDescendants = true
LeftPanel.ZIndex = 2
LeftPanel.Parent = PanelHolder

local LeftGradient = Instance.new("UIGradient", LeftPanel)
LeftGradient.Rotation = 135
LeftGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 20, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 22)),
})

for i = 1, 6 do
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 200, 0, 1)
    stripe.Position = UDim2.new(0, -50, 0, 100 + i * 60)
    stripe.BackgroundColor3 = THEME.ACCENT
    stripe.BackgroundTransparency = 0.92
    stripe.BorderSizePixel = 0
    stripe.Rotation = -35
    stripe.ZIndex = 2
    stripe.Parent = LeftPanel
end

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.7, 0, 1, 0)
RightPanel.Position = UDim2.new(0.3, 0, 0, 0)
RightPanel.BackgroundColor3 = THEME.BG_PANEL
RightPanel.BackgroundTransparency = 0.05
RightPanel.BorderSizePixel = 0
RightPanel.ClipsDescendants = true
RightPanel.ZIndex = 2
RightPanel.Parent = PanelHolder

for i = 1, 12 do
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(1, 0, 0, 1)
    stripe.Position = UDim2.new(0, 0, 0, 40 * i + 30)
    stripe.BackgroundColor3 = THEME.ACCENT
    stripe.BackgroundTransparency = 0.94
    stripe.BorderSizePixel = 0
    stripe.ZIndex = 2
    stripe.Parent = RightPanel
end

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, 0)
Divider.Position = UDim2.new(0.3, -0.5, 0, 0)
Divider.BackgroundColor3 = THEME.ACCENT
Divider.BorderSizePixel = 0
Divider.ZIndex = 5
Divider.Parent = PanelHolder
Divider.BackgroundTransparency = 0

local DividerGradient = Instance.new("UIGradient", Divider)
DividerGradient.Rotation = 90
DividerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.25, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_GLOW),
    ColorSequenceKeypoint.new(0.75, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

task.spawn(function()
    while DividerGradient.Parent do
        for i = -1, 1, 0.02 do
            if not DividerGradient.Parent then break end
            DividerGradient.Offset = Vector2.new(0, i)
            task.wait(0.025)
        end
        for i = 1, -1, -0.02 do
            if not DividerGradient.Parent then break end
            DividerGradient.Offset = Vector2.new(0, i)
            task.wait(0.025)
        end
    end
end)

local LogoFrame = Instance.new("Frame")
LogoFrame.Size = UDim2.new(1, -20, 0, 70)
LogoFrame.Position = UDim2.new(0, 10, 0, 10)
LogoFrame.BackgroundTransparency = 1
LogoFrame.ZIndex = 5
LogoFrame.Parent = LeftPanel

local LogoBadge = Instance.new("Frame")
LogoBadge.Size = UDim2.new(0, 50, 0, 50)
LogoBadge.Position = UDim2.new(0, 5, 0, 10)
LogoBadge.BackgroundTransparency = 1
LogoBadge.ClipsDescendants = true
LogoBadge.ZIndex = 6
LogoBadge.Parent = LogoFrame
Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(1, 0)

local LogoBadgeGlow = Instance.new("UIStroke", LogoBadge)
LogoBadgeGlow.Thickness = 1
LogoBadgeGlow.Color = THEME.ACCENT_GLOW
LogoBadgeGlow.Transparency = 0.6

local LogoImage = Instance.new("ImageLabel")
LogoImage.Size = UDim2.new(1, 0, 1, 0)
LogoImage.BackgroundTransparency = 1
LogoImage.Image = logoPath or ""
LogoImage.ScaleType = Enum.ScaleType.Crop
LogoImage.ZIndex = 7
LogoImage.Parent = LogoBadge
Instance.new("UICorner", LogoImage).CornerRadius = UDim.new(1, 0)

local LogoTitle = Instance.new("TextLabel")
LogoTitle.Size = UDim2.new(1, -65, 0, 22)
LogoTitle.Position = UDim2.new(0, 65, 0, 10)
LogoTitle.BackgroundTransparency = 1
LogoTitle.Text = "VOLLEYBALL"
LogoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoTitle.TextSize = 17
LogoTitle.Font = Enum.Font.Gotham
LogoTitle.TextXAlignment = Enum.TextXAlignment.Left
LogoTitle.ZIndex = 6
LogoTitle.Parent = LogoFrame

local LogoTitleGradient = Instance.new("UIGradient", LogoTitle)
LogoTitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.TEXT_HI),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

local LogoSub = Instance.new("TextLabel")
LogoSub.Size = UDim2.new(1, -65, 0, 16)
LogoSub.Position = UDim2.new(0, 65, 0, 32)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "// LEGENDS"
LogoSub.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoSub.TextSize = 13
LogoSub.Font = Enum.Font.Code
LogoSub.TextXAlignment = Enum.TextXAlignment.Left
LogoSub.ZIndex = 6
LogoSub.Parent = LogoFrame

local LogoSubGradient = Instance.new("UIGradient", LogoSub)
LogoSubGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

local LogoVersion = Instance.new("TextLabel")
LogoVersion.Size = UDim2.new(1, -65, 0, 14)
LogoVersion.Position = UDim2.new(0, 65, 0, 48)
LogoVersion.BackgroundTransparency = 1
LogoVersion.Text = "// FREE 2.2.0"
LogoVersion.TextColor3 = THEME.TEXT_LOW
LogoVersion.TextSize = 10
LogoVersion.Font = Enum.Font.Code
LogoVersion.TextXAlignment = Enum.TextXAlignment.Left
LogoVersion.ZIndex = 6
LogoVersion.Parent = LogoFrame

task.spawn(function()
    while ScreenGui.Parent do
        for i = -1, 1, 0.02 do
            LogoTitleGradient.Offset = Vector2.new(i, 0)
            LogoSubGradient.Offset = Vector2.new(i, 0)
            task.wait(0.025)
        end
        for i = 1, -1, -0.02 do
            LogoTitleGradient.Offset = Vector2.new(i, 0)
            LogoSubGradient.Offset = Vector2.new(i, 0)
            task.wait(0.025)
        end
    end
end)

local PageHeader = Instance.new("Frame")
PageHeader.Size = UDim2.new(1, 0, 0, 55)
PageHeader.BackgroundTransparency = 1
PageHeader.ZIndex = 10
PageHeader.Parent = RightPanel
PageHeader.Visible = false

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 3, 0, 26)
AccentBar.Position = UDim2.new(0, 20, 0, 14)
AccentBar.BackgroundColor3 = THEME.ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 11
AccentBar.Parent = PageHeader
Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 1)

local AccentGradient = Instance.new("UIGradient", AccentBar)
AccentGradient.Rotation = 0
AccentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.25, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_GLOW),
    ColorSequenceKeypoint.new(0.75, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

task.spawn(function()
    while AccentGradient.Parent do
        for i = -1, 1, 0.04 do
            if not AccentGradient.Parent then break end
            AccentGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
        for i = 1, -1, -0.04 do
            if not AccentGradient.Parent then break end
            AccentGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
    end
end)

local PageIndex = Instance.new("TextLabel")
PageIndex.Size = UDim2.new(0, 40, 0, 22)
PageIndex.Position = UDim2.new(0, 30, 0, 16)
PageIndex.BackgroundTransparency = 1
PageIndex.Text = "01"
PageIndex.TextColor3 = THEME.TEXT_LOW
PageIndex.TextSize = 12
PageIndex.Font = Enum.Font.Code
PageIndex.TextXAlignment = Enum.TextXAlignment.Left
PageIndex.ZIndex = 11
PageIndex.Parent = PageHeader

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -180, 0, 22)
PageTitle.Position = UDim2.new(0, 70, 0, 16)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = ""
PageTitle.TextColor3 = THEME.TEXT_HI
PageTitle.TextSize = 17
PageTitle.Font = Enum.Font.Gotham
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.ZIndex = 11
PageTitle.Parent = PageHeader

local onlineFrame = Instance.new("Frame")
onlineFrame.Size = UDim2.new(0, 70, 0, 18)
onlineFrame.Position = UDim2.new(1, -85, 0, 20)
onlineFrame.BackgroundTransparency = 1
onlineFrame.ZIndex = 11
onlineFrame.Parent = PageHeader

local onlineDot = Instance.new("Frame")
onlineDot.Size = UDim2.new(0, 6, 0, 6)
onlineDot.Position = UDim2.new(0, 0, 0.5, -3)
onlineDot.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
onlineDot.BorderSizePixel = 0
onlineDot.ZIndex = 12
onlineDot.Parent = onlineFrame
Instance.new("UICorner", onlineDot).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    while onlineDot.Parent do
        TweenService:Create(onlineDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.6, Size = UDim2.new(0, 5, 0, 5)}):Play()
        task.wait(0.9)
        TweenService:Create(onlineDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {BackgroundTransparency = 0, Size = UDim2.new(0, 6, 0, 6)}):Play()
        task.wait(0.9)
    end
end)

local onlineLabel = Instance.new("TextLabel")
onlineLabel.Size = UDim2.new(0, 60, 1, 0)
onlineLabel.Position = UDim2.new(0, 12, 0, 0)
onlineLabel.BackgroundTransparency = 1
onlineLabel.Text = "ONLINE"
onlineLabel.TextColor3 = Color3.fromRGB(80, 255, 130)
onlineLabel.TextSize = 10
onlineLabel.Font = Enum.Font.Code
onlineLabel.TextXAlignment = Enum.TextXAlignment.Left
onlineLabel.ZIndex = 12
onlineLabel.Parent = onlineFrame

local HeaderBaseLine = Instance.new("Frame")
HeaderBaseLine.Size = UDim2.new(1, 0, 0, 2)
HeaderBaseLine.Position = UDim2.new(0, 0, 0, 45)
HeaderBaseLine.BackgroundColor3 = THEME.ACCENT_DARK
HeaderBaseLine.BackgroundTransparency = 0.7
HeaderBaseLine.BorderSizePixel = 0
HeaderBaseLine.ZIndex = 11
HeaderBaseLine.Parent = PageHeader

local HeaderRunner = Instance.new("Frame")
HeaderRunner.Size = UDim2.new(0.3, 0, 0, 2)
HeaderRunner.Position = UDim2.new(-0.3, 0, 0, 45)
HeaderRunner.BackgroundColor3 = THEME.ACCENT_HOT
HeaderRunner.BorderSizePixel = 0
HeaderRunner.ZIndex = 12
HeaderRunner.Parent = PageHeader

local RunnerGradient = Instance.new("UIGradient", HeaderRunner)
RunnerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})
RunnerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

local HeaderPulse = Instance.new("Frame")
HeaderPulse.Size = UDim2.new(1, 0, 0, 1)
HeaderPulse.Position = UDim2.new(0, 0, 0, 45.5)
HeaderPulse.BackgroundColor3 = THEME.ACCENT_GLOW
HeaderPulse.BackgroundTransparency = 0.6
HeaderPulse.BorderSizePixel = 0
HeaderPulse.ZIndex = 13
HeaderPulse.Parent = PageHeader

task.spawn(function()
    while ScreenGui.Parent do
        HeaderRunner.Position = UDim2.new(-0.3, 0, 0, 45)
        local t = TweenService:Create(HeaderRunner, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 0, 0, 45)})
        t:Play()
        t.Completed:Wait()
        task.wait(0.3)
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(HeaderPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.15}):Play()
        task.wait(0.6)
        TweenService:Create(HeaderPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.85}):Play()
        task.wait(0.6)
    end
end)

-- ====================================================================
-- BRACKETS
-- ====================================================================
function CreateBracket(pos, size, anchor, flipX, flipY)
    local bracket = Instance.new("Frame")
    bracket.Size = size
    bracket.Position = pos
    bracket.AnchorPoint = anchor
    bracket.BackgroundTransparency = 1
    bracket.ZIndex = 240
    bracket.Parent = MainFrame

    local hLine = Instance.new("Frame")
    hLine.Size = UDim2.new(1, 0, 0, 2)
    hLine.BackgroundColor3 = THEME.ACCENT_HOT
    hLine.BorderSizePixel = 0
    hLine.ZIndex = 241
    hLine.Parent = bracket
    if flipY then hLine.Position = UDim2.new(0, 0, 1, -2) end

    local hGrad = Instance.new("UIGradient", hLine)
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
    })

    task.spawn(function()
        while hGrad.Parent do
            for i = -1, 1, 0.03 do
                if not hGrad.Parent then break end
                hGrad.Offset = Vector2.new(i, 0)
                task.wait(0.04)
            end
            for i = 1, -1, -0.03 do
                if not hGrad.Parent then break end
                hGrad.Offset = Vector2.new(i, 0)
                task.wait(0.04)
            end
        end
    end)

    local vLine = Instance.new("Frame")
    vLine.Size = UDim2.new(0, 2, 1, 0)
    vLine.BackgroundColor3 = THEME.ACCENT_HOT
    vLine.BorderSizePixel = 0
    vLine.ZIndex = 241
    vLine.Parent = bracket
    if flipX then vLine.Position = UDim2.new(1, -2, 0, 0) end

    local vGrad = Instance.new("UIGradient", vLine)
    vGrad.Rotation = 90
    vGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
    })

    task.spawn(function()
        while vGrad.Parent do
            for i = -1, 1, 0.03 do
                if not vGrad.Parent then break end
                vGrad.Offset = Vector2.new(0, i)
                task.wait(0.04)
            end
            for i = 1, -1, -0.03 do
                if not vGrad.Parent then break end
                vGrad.Offset = Vector2.new(0, i)
                task.wait(0.04)
            end
        end
    end)

    return hLine, vLine, hGrad, vGrad
end

S.Br.TL_h, S.Br.TL_v, S.Br.TL_hg, S.Br.TL_vg = CreateBracket(UDim2.new(0, -6, 0, -6), UDim2.new(0, 22, 0, 22), Vector2.new(0, 0), false, false)
S.Br.TR_h, S.Br.TR_v, S.Br.TR_hg, S.Br.TR_vg = CreateBracket(UDim2.new(1, 6, 0, -6), UDim2.new(0, 22, 0, 22), Vector2.new(1, 0), true, false)
S.Br.BL_h, S.Br.BL_v, S.Br.BL_hg, S.Br.BL_vg = CreateBracket(UDim2.new(0, -6, 1, 6), UDim2.new(0, 22, 0, 22), Vector2.new(0, 1), false, true)
S.Br.BR_h, S.Br.BR_v, S.Br.BR_hg, S.Br.BR_vg = CreateBracket(UDim2.new(1, 6, 1, 6), UDim2.new(0, 22, 0, 22), Vector2.new(1, 1), true, true)

-- ====================================================================
-- TABS
-- ====================================================================
local TabNames = {"Main", "Visuals", "Combat", "Sky", "Settings"}
local TabIndexes = { "01", "02", "03", "04", "05" }
local Tabs = {}
local TabPages = {}
local ActiveTab = nil
local TabBaseY = 95
local TabHeight = 38
local TabSpacing = 44

function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -40, 1, -80)
    page.Position = UDim2.new(0, 20, 0, 65)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = THEME.ACCENT
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 5
    page.Parent = RightPanel
    TabPages[name] = page
    return page
end

for i, name in ipairs(TabNames) do
    local order = i
    local tab = Instance.new("TextButton")
    tab.Name = name .. "Tab"
    tab.Size = UDim2.new(1, -20, 0, TabHeight)
    tab.Position = UDim2.new(0, 10, 0, TabBaseY + (order - 1) * TabSpacing)
    tab.BackgroundColor3 = THEME.BG_MID
    tab.BackgroundTransparency = 0.5
    tab.BorderSizePixel = 0
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.ZIndex = 10
    tab.Parent = LeftPanel

    local tabCorner = Instance.new("UICorner", tab)
    tabCorner.CornerRadius = UDim.new(0, 4)
    RegisterCorner(tabCorner, 4)

    local stroke = Instance.new("UIStroke", tab)
    stroke.Thickness = 1
    stroke.Color = THEME.LINE
    stroke.Transparency = 0.3

    local tabAccent = Instance.new("Frame")
    tabAccent.Size = UDim2.new(0, 4, 0, 0)
    tabAccent.Position = UDim2.new(0, 2, 0.5, 0)
    tabAccent.AnchorPoint = Vector2.new(0, 0.5)
    tabAccent.BackgroundColor3 = THEME.ACCENT_HOT
    tabAccent.BorderSizePixel = 0
    tabAccent.ZIndex = 11
    tabAccent.Parent = tab
    Instance.new("UICorner", tabAccent).CornerRadius = UDim.new(1, 0)

    local tabAccentGradient = Instance.new("UIGradient", tabAccent)
    tabAccentGradient.Rotation = 90
    tabAccentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
    })

    task.spawn(function()
        while tabAccent.Parent do
            for j = -1, 1, 0.05 do tabAccentGradient.Offset = Vector2.new(0, j); task.wait(0.05) end
            for j = 1, -1, -0.05 do tabAccentGradient.Offset = Vector2.new(0, j); task.wait(0.05) end
        end
    end)

    local tabIndex = Instance.new("TextLabel")
    tabIndex.Size = UDim2.new(0, 25, 1, 0)
    tabIndex.Position = UDim2.new(0, 14, 0, 0)
    tabIndex.BackgroundTransparency = 1
    tabIndex.Text = TabIndexes[i]
    tabIndex.TextColor3 = THEME.TEXT_LOW
    tabIndex.TextSize = 11
    tabIndex.Font = Enum.Font.Code
    tabIndex.TextXAlignment = Enum.TextXAlignment.Left
    tabIndex.ZIndex = 11
    tabIndex.Parent = tab

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Position = UDim2.new(0, 42, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name:upper()
    textLabel.TextColor3 = THEME.TEXT_MID
    textLabel.TextSize = 13
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 11
    textLabel.Parent = tab

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "»"
    arrow.TextColor3 = THEME.ACCENT_HOT
    arrow.TextSize = 18
    arrow.Font = Enum.Font.Gotham
    arrow.TextTransparency = 1
    arrow.ZIndex = 11
    arrow.Parent = tab

    local originalSize = UDim2.new(1, -20, 0, TabHeight)
    local originalPos = UDim2.new(0, 10, 0, TabBaseY + (order - 1) * TabSpacing)
    local activeSize = UDim2.new(1, -6, 0, TabHeight + 2)
    local activePos = UDim2.new(0, 3, 0, TabBaseY - 1 + (order - 1) * TabSpacing)

    tab.MouseEnter:Connect(function()
        if not Tabs[name].IsActive then
            TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
            TweenService:Create(textLabel, TweenInfo.new(0.15), {TextColor3 = THEME.TEXT_HI}):Play()
        end
    end)
    tab.MouseLeave:Connect(function()
        if not Tabs[name].IsActive then
            TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(textLabel, TweenInfo.new(0.15), {TextColor3 = THEME.TEXT_MID}):Play()
        end
    end)

    tab.MouseButton1Click:Connect(function()
        PlayTab()
        for otherName, otherTab in pairs(Tabs) do
            if otherTab.IsActive then
                otherTab.IsActive = false
                local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
                TweenService:Create(otherTab.Button, ti, {Size = otherTab.OriginalSize, Position = otherTab.OriginalPos, BackgroundColor3 = THEME.BG_MID, BackgroundTransparency = 0.5}):Play()
                TweenService:Create(otherTab.Stroke, ti, {Color = THEME.LINE, Transparency = 0.3}):Play()
                TweenService:Create(otherTab.Text, ti, {TextColor3 = THEME.TEXT_MID}):Play()
                TweenService:Create(otherTab.Accent, ti, {Size = UDim2.new(0, 4, 0, 0)}):Play()
                TweenService:Create(otherTab.Arrow, ti, {TextTransparency = 1}):Play()
                TweenService:Create(otherTab.Index, ti, {TextColor3 = THEME.TEXT_LOW}):Play()
            end
        end
        for _, page in pairs(TabPages) do page.Visible = false end

        if ActiveTab == name then
            ActiveTab = nil
            TweenService:Create(PageTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            TweenService:Create(PageIndex, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            TweenService:Create(AccentBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(HeaderBaseLine, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(HeaderRunner, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(HeaderPulse, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            task.delay(0.2, function() PageHeader.Visible = false end)
            return
        end

        Tabs[name].IsActive = true
        ActiveTab = name
        PageHeader.Visible = true
        PageTitle.Text = name:upper()
        PageTitle.TextTransparency = 1
        PageIndex.Text = TabIndexes[i]
        PageIndex.TextTransparency = 1
        AccentBar.BackgroundTransparency = 1
        HeaderBaseLine.BackgroundTransparency = 0.7
        HeaderRunner.BackgroundTransparency = 0
        HeaderPulse.BackgroundTransparency = 0.6
        TweenService:Create(PageTitle, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TweenService:Create(PageIndex, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TweenService:Create(AccentBar, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        TweenService:Create(tab, TweenInfo.new(0.2), {Size = activeSize, Position = activePos, BackgroundColor3 = Color3.fromRGB(35, 22, 60), BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = THEME.ACCENT_HOT, Transparency = 0.3}):Play()
        TweenService:Create(textLabel, TweenInfo.new(0.2), {TextColor3 = THEME.TEXT_HI}):Play()
        TweenService:Create(tabAccent, TweenInfo.new(0.2), {Size = UDim2.new(0, 4, 0, TabHeight - 8)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        TweenService:Create(tabIndex, TweenInfo.new(0.2), {TextColor3 = THEME.ACCENT_HOT}):Play()
        if TabPages[name] then TabPages[name].Visible = true end
    end)

    Tabs[name] = {
        Button = tab, Text = textLabel, Stroke = stroke, Accent = tabAccent,
        Arrow = arrow, Index = tabIndex, IsActive = false,
        OriginalSize = originalSize, OriginalPos = originalPos,
    }
    CreatePage(name)
end

-- ====================================================================
-- DRAG HANDLE
-- ====================================================================
local DragHandle = Instance.new("Frame")
DragHandle.Size = UDim2.new(0, 50, 0, 50)
DragHandle.Position = UDim2.new(1, -55, 0, 5)
DragHandle.BackgroundTransparency = 1
DragHandle.ZIndex = 250
DragHandle.Parent = MainFrame

local CloseIcon = Instance.new("ImageLabel")
CloseIcon.Size = UDim2.new(0, 26, 0, 26)
CloseIcon.Position = UDim2.new(0.5, -13, 0.5, -13)
CloseIcon.BackgroundTransparency = 1
CloseIcon.Image = "rbxassetid://134892275535697"
CloseIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
CloseIcon.ImageTransparency = 0
CloseIcon.ZIndex = 252
CloseIcon.Parent = DragHandle

local DragButton = Instance.new("TextButton")
DragButton.Size = UDim2.new(1, 0, 1, 0)
DragButton.Position = UDim2.new(0, 0, 0, 0)
DragButton.BackgroundTransparency = 1
DragButton.Text = ""
DragButton.ZIndex = 253
DragButton.Parent = DragHandle

local isDraggingMenu = false
local dragStartMouse = Vector2.new(0, 0)
local dragStartFrame = UDim2.new(0, 0, 0, 0)

DragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMenu = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartFrame = MainFrame.Position
        TweenService:Create(CloseIcon, TweenInfo.new(0.15), {ImageColor3 = THEME.ACCENT_HOT}):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDraggingMenu then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local deltaX = input.Position.X - dragStartMouse.X
        local deltaY = input.Position.Y - dragStartMouse.Y
        MainFrame.Position = UDim2.new(
            dragStartFrame.X.Scale, dragStartFrame.X.Offset + deltaX,
            dragStartFrame.Y.Scale, dragStartFrame.Y.Offset + deltaY
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isDraggingMenu then
            TweenService:Create(CloseIcon, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end
        isDraggingMenu = false
    end
end)

-- ====================================================================
-- AVATAR / INFO
-- ====================================================================
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size = UDim2.new(0, 50, 0, 50)
AvatarFrame.Position = UDim2.new(0, 10, 1, -64)
AvatarFrame.BackgroundColor3 = THEME.BG_MID
AvatarFrame.BackgroundTransparency = 0.2
AvatarFrame.ZIndex = 10
AvatarFrame.Parent = LeftPanel
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(1, 0)

local AvatarStroke = Instance.new("UIStroke", AvatarFrame)
AvatarStroke.Thickness = 1
AvatarStroke.Color = THEME.ACCENT_HOT
AvatarStroke.Transparency = 0.6

local AvatarGlow = Instance.new("UIStroke", AvatarFrame)
AvatarGlow.Thickness = 2
AvatarGlow.Color = THEME.ACCENT_GLOW
AvatarGlow.Transparency = 0.92

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, -4, 1, -4)
AvatarImage.Position = UDim2.new(0, 2, 0, 2)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImage.ZIndex = 11
AvatarImage.Parent = AvatarFrame
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)

local PlayerName = Instance.new("TextLabel")
PlayerName.Size = UDim2.new(0, 85, 0, 18)
PlayerName.Position = UDim2.new(0, 68, 1, -60)
PlayerName.BackgroundTransparency = 1
PlayerName.Text = string.upper(LocalPlayer.DisplayName)
PlayerName.TextColor3 = THEME.TEXT_HI
PlayerName.TextSize = 12
PlayerName.Font = Enum.Font.Gotham
PlayerName.TextXAlignment = Enum.TextXAlignment.Left
PlayerName.TextTruncate = Enum.TextTruncate.AtEnd
PlayerName.ZIndex = 10
PlayerName.Parent = LeftPanel

local PlayerTag = Instance.new("TextLabel")
PlayerTag.Size = UDim2.new(0, 85, 0, 14)
PlayerTag.Position = UDim2.new(0, 68, 1, -42)
PlayerTag.BackgroundTransparency = 1
PlayerTag.Text = "// " .. LocalPlayer.Name
PlayerTag.TextColor3 = THEME.ACCENT_HOT
PlayerTag.TextSize = 10
PlayerTag.Font = Enum.Font.Code
PlayerTag.TextXAlignment = Enum.TextXAlignment.Left
PlayerTag.TextTruncate = Enum.TextTruncate.AtEnd
PlayerTag.ZIndex = 10
PlayerTag.Parent = LeftPanel

local BrandFrame = Instance.new("Frame")
BrandFrame.Size = UDim2.new(0, 42, 0, 42)
BrandFrame.Position = UDim2.new(1, -52, 1, -60)
BrandFrame.BackgroundTransparency = 1
BrandFrame.ZIndex = 10
BrandFrame.Parent = LeftPanel

local BrandImage = Instance.new("ImageLabel")
BrandImage.Size = UDim2.new(1, -4, 1, -4)
BrandImage.Position = UDim2.new(0, 2, 0, 2)
BrandImage.BackgroundTransparency = 1
BrandImage.Image = brandPath or ""
BrandImage.ScaleType = Enum.ScaleType.Fit
BrandImage.ZIndex = 11
BrandImage.Parent = BrandFrame
Instance.new("UICorner", BrandImage).CornerRadius = UDim.new(1, 0)

local FpsFrame = Instance.new("Frame")
FpsFrame.Size = UDim2.new(0, 70, 0, 18)
FpsFrame.Position = UDim2.new(1, -80, 1, -22)
FpsFrame.BackgroundTransparency = 1
FpsFrame.ZIndex = 20
FpsFrame.Visible = false
FpsFrame.Parent = LeftPanel

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Size = UDim2.new(1, 0, 1, 0)
FpsLabel.BackgroundTransparency = 1
FpsLabel.Text = "FPS 60"
FpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FpsLabel.TextSize = 13
FpsLabel.Font = Enum.Font.Gotham
FpsLabel.TextXAlignment = Enum.TextXAlignment.Right
FpsLabel.ZIndex = 21
FpsLabel.Parent = FpsFrame

local FpsGradient = Instance.new("UIGradient", FpsLabel)
FpsGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

task.spawn(function()
    while ScreenGui.Parent do
        for i = -1, 1, 0.02 do FpsGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
        for i = 1, -1, -0.02 do FpsGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
    end
end)

task.spawn(function()
    local frames = 0
    local lastTime = tick()
    local conn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastTime >= 1 then
            FpsLabel.Text = "FPS " .. tostring(math.floor(frames / (now - lastTime)))
            frames = 0
            lastTime = now
        end
    end)
    table.insert(S.Connections, conn)
end)

local DotContainer = Instance.new("Frame")
DotContainer.Size = UDim2.new(1, 0, 1, 0)
DotContainer.BackgroundTransparency = 1
DotContainer.ClipsDescendants = true
DotContainer.ZIndex = 1
DotContainer.Parent = LeftPanel

function RebuildDots()
    for _, dot in ipairs(Config.Dots) do
        if dot.Frame then dot.Frame:Destroy() end
    end
    Config.Dots = {}
    if not Config.FlyingDotsEnabled then return end
    local w = LeftPanel.AbsoluteSize.X
    local h = LeftPanel.AbsoluteSize.Y
    if w <= 0 then w = 200 end
    if h <= 0 then h = 490 end
    for i = 1, 22 do
        local star = Instance.new("Frame")
        local size = math.random(2, 3)
        star.Size = UDim2.new(0, size, 0, size)
        local startX = math.random(0, w)
        local startY = math.random(0, h)
        star.Position = UDim2.new(0, startX, 0, startY)
        star.BackgroundColor3 = THEME.ACCENT_HOT
        star.BackgroundTransparency = math.random(50, 75) / 100
        star.BorderSizePixel = 0
        star.ZIndex = 2
        star.Parent = DotContainer
        Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
        table.insert(Config.Dots, {
            Frame = star, SpeedX = math.random(3, 6) / 10, SpeedY = -math.random(4, 8) / 10,
            PosX = startX, PosY = startY,
            PulseSpeed = math.random(15, 30) / 10, PulsePhase = math.random() * math.pi * 2,
        })
    end
end

function UpdateDots()
    if not Config.FlyingDotsEnabled then return end
    local w = LeftPanel.AbsoluteSize.X
    local h = LeftPanel.AbsoluteSize.Y
    if w <= 0 or h <= 0 then return end
    local t = tick()
    for _, data in ipairs(Config.Dots) do
        if data.Frame and data.Frame.Parent then
            data.PosX = data.PosX + data.SpeedX
            data.PosY = data.PosY + data.SpeedY
            if data.PosX > w then data.PosX = 0 end
            if data.PosY < -5 then data.PosY = h + 5; data.PosX = math.random(0, w) end
            data.Frame.Position = UDim2.new(0, data.PosX, 0, data.PosY)
            local pulse = (math.sin(t * data.PulseSpeed + data.PulsePhase) + 1) / 2
            data.Frame.BackgroundTransparency = 0.5 + pulse * 0.4
        end
    end
end

task.spawn(function()
    RebuildDots()
    while ScreenGui.Parent do
        pcall(UpdateDots)
        task.wait(0.016)
    end
end)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 8, 0, 8)
StatusDot.BackgroundColor3 = THEME.ACCENT_HOT
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 200
StatusDot.Parent = MainFrame
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local DotGradient = Instance.new("UIGradient", StatusDot)
DotGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

task.spawn(function()
    while ScreenGui.Parent do
        for i = -1, 1, 0.01 do DotGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
        for i = 1, -1, -0.01 do DotGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
    end
end)

local ScanLine = Instance.new("Frame")
ScanLine.Size = UDim2.new(1, 0, 0, 3)
ScanLine.BackgroundColor3 = THEME.ACCENT_HOT
ScanLine.BorderSizePixel = 0
ScanLine.BackgroundTransparency = 0.5
ScanLine.ZIndex = 100
ScanLine.Parent = MainFrame

local ScanGradient = Instance.new("UIGradient", ScanLine)
ScanGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})

task.spawn(function()
    while ScreenGui.Parent do
        if Config.ScanLineEnabled then
            ScanLine.Visible = true
            ScanLine.Position = UDim2.new(0, 0, 0, 0)
            local t = TweenService:Create(ScanLine, TweenInfo.new(1.8, Enum.EasingStyle.Linear), {Position = UDim2.new(0, 0, 1, 0)})
            t:Play()
            t.Completed:Wait()
            task.wait(2)
        else
            ScanLine.Visible = false
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(LogoBadgeGlow, TweenInfo.new(0.8), {Transparency = 0.3}):Play()
        TweenService:Create(MainGlow, TweenInfo.new(0.8), {Transparency = 0.6}):Play()
        TweenService:Create(AvatarGlow, TweenInfo.new(0.8), {Transparency = 0.75}):Play()
        task.wait(0.8)
        TweenService:Create(LogoBadgeGlow, TweenInfo.new(0.8), {Transparency = 0.75}):Play()
        TweenService:Create(MainGlow, TweenInfo.new(0.8), {Transparency = 0.95}):Play()
        TweenService:Create(AvatarGlow, TweenInfo.new(0.8), {Transparency = 0.95}):Play()
        task.wait(0.8)
    end
end)

-- ====================================================================
-- HELPERS
-- ====================================================================
function CreateSection(parent, title, yPos, color)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 24)
    section.Position = UDim2.new(0, 0, 0, yPos)
    section.BackgroundTransparency = 1
    section.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 3, 0, 14)
    line.Position = UDim2.new(0, 0, 0.5, -7)
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    line.Parent = section
    Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -15, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = color
    label.TextSize = 12
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section

    return line, label
end

function CreateToggle(parent, name, descText, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.75, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = THEME.TEXT_HI
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0.75, 0, 0, 14)
    desc.Position = UDim2.new(0, 0, 0, 20)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = THEME.TEXT_LOW
    desc.TextSize = 10
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 42, 0, 22)
    toggleBg.Position = UDim2.new(1, -50, 0, 13)
    toggleBg.BackgroundColor3 = default and THEME.ACCENT or Color3.fromRGB(30, 25, 45)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local toggleStroke = Instance.new("UIStroke", toggleBg)
    toggleStroke.Thickness = 1
    toggleStroke.Color = default and THEME.ACCENT_HOT or THEME.LINE
    toggleStroke.Transparency = 0.5

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = default and UDim2.new(0, 23, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = toggleBg
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local state = default
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(0, 42, 0, 22)
    clickArea.Position = UDim2.new(1, -50, 0, 13)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 10
    clickArea.Parent = frame

    local function SetState(value, animate)
        state = value
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        local targetBg = value and THEME.ACCENT or Color3.fromRGB(30, 25, 45)
        local targetStroke = value and THEME.ACCENT_HOT or THEME.LINE
        local targetPos = value and UDim2.new(0, 23, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if animate then
            TweenService:Create(toggleBg, ti, {BackgroundColor3 = targetBg}):Play()
            TweenService:Create(toggleStroke, ti, {Color = targetStroke}):Play()
            TweenService:Create(handle, ti, {Position = targetPos}):Play()
        else
            toggleBg.BackgroundColor3 = targetBg
            toggleStroke.Color = targetStroke
            handle.Position = targetPos
        end
        if callback then callback(value) end
    end

    clickArea.MouseButton1Click:Connect(function()
        PlayTab()
        SetState(not state, true)
    end)

    table.insert(S.ColorSynced, {
        Kind = "Toggle", ToggleBg = toggleBg, ToggleStroke = toggleStroke,
        GetState = function() return state end,
    })

    S.Toggles[name] = SetState
end

function CreateSlider(parent, name, descText, yPos, minVal, maxVal, default, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = THEME.TEXT_HI
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0.7, 0, 0, 14)
    desc.Position = UDim2.new(0, 0, 0, 18)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = THEME.TEXT_LOW
    desc.TextSize = 10
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 18)
    valueLabel.Position = UDim2.new(1, -60, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default) .. (suffix or "")
    valueLabel.TextColor3 = THEME.ACCENT_HOT
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -50, 0, 5)
    barBg.Position = UDim2.new(0, 0, 0, 40)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local startPercent = (default - minVal) / (maxVal - minVal)
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(startPercent, 0, 1, 0)
    barFill.BackgroundColor3 = THEME.ACCENT_HOT
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local barFillGradient = Instance.new("UIGradient", barFill)
    barFillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_GLOW),
    })

    task.spawn(function()
        while barFill.Parent do
            for i = -1, 1, 0.03 do
                if not barFillGradient.Parent then break end
                barFillGradient.Offset = Vector2.new(i, 0)
                task.wait(0.04)
            end
            for i = 1, -1, -0.03 do
                if not barFillGradient.Parent then break end
                barFillGradient.Offset = Vector2.new(i, 0)
                task.wait(0.04)
            end
        end
    end)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new(startPercent, -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = barBg
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local handleGlow = Instance.new("UIStroke", handle)
    handleGlow.Thickness = 1
    handleGlow.Color = THEME.ACCENT_HOT
    handleGlow.Transparency = 0.4

    local dragArea = Instance.new("TextButton")
    dragArea.Size = UDim2.new(1, -50, 0, 20)
    dragArea.Position = UDim2.new(0, 0, 0, 33)
    dragArea.BackgroundTransparency = 1
    dragArea.Text = ""
    dragArea.ZIndex = 10
    dragArea.Parent = frame

    local isDragging = false

    local function SetValue(val, animate)
        val = math.clamp(val, minVal, maxVal)
        local p = (val - minVal) / (maxVal - minVal)
        if animate then
            TweenService:Create(barFill, TweenInfo.new(0.2), {Size = UDim2.new(p, 0, 1, 0)}):Play()
            TweenService:Create(handle, TweenInfo.new(0.2), {Position = UDim2.new(p, -7, 0.5, -7)}):Play()
        else
            barFill.Size = UDim2.new(p, 0, 1, 0)
            handle.Position = UDim2.new(p, -7, 0.5, -7)
        end
        valueLabel.Text = tostring(math.floor(val + 0.5)) .. (suffix or "")
        if callback then callback(math.floor(val + 0.5)) end
    end

    local function UpdateFromMouse(mouseX)
        local absPos = barBg.AbsolutePosition.X
        local width = barBg.AbsoluteSize.X
        if width <= 0 then return end
        local percent = math.clamp((mouseX - absPos) / width, 0, 1)
        SetValue(minVal + percent * (maxVal - minVal), false)
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateFromMouse(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromMouse(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    table.insert(S.ColorSynced, {
        Kind = "Slider", BarFill = barFill, BarFillGradient = barFillGradient,
        ValueLabel = valueLabel, HandleGlow = handleGlow,
    })

    S.Sliders[name] = SetValue
end

-- ====================================================================
-- MAIN PAGE
-- ====================================================================
local mainPage = TabPages["Main"]
mainPage.CanvasSize = UDim2.new(0, 0, 0, 380)

local bannerFrame = Instance.new("Frame")
bannerFrame.Size = UDim2.new(0.72, 0, 0, 90)
bannerFrame.Position = UDim2.new(0.5, 0, 0, 3)
bannerFrame.AnchorPoint = Vector2.new(0.5, 0)
bannerFrame.BackgroundColor3 = THEME.BG_DARK
bannerFrame.ClipsDescendants = true
bannerFrame.ZIndex = 6
bannerFrame.Parent = mainPage
Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, Config.CornerRadius)

local bannerStroke = Instance.new("UIStroke", bannerFrame)
bannerStroke.Thickness = 1.5
bannerStroke.Color = THEME.ACCENT
bannerStroke.Transparency = 0.3

local bannerGlow = Instance.new("UIStroke", bannerFrame)
bannerGlow.Thickness = 3
bannerGlow.Color = THEME.ACCENT_GLOW
bannerGlow.Transparency = 0.92

local bannerImage = Instance.new("ImageLabel")
bannerImage.Size = UDim2.new(1, 0, 1, 0)
bannerImage.BackgroundTransparency = 1
bannerImage.Image = bannerPath or ""
bannerImage.ScaleType = Enum.ScaleType.Crop
bannerImage.ZIndex = 7
bannerImage.Parent = bannerFrame
Instance.new("UICorner", bannerImage).CornerRadius = UDim.new(0, Config.CornerRadius)

local greetFrame = Instance.new("Frame")
greetFrame.Size = UDim2.new(1, 0, 0, 58)
greetFrame.Position = UDim2.new(0, 0, 0, 100)
greetFrame.BackgroundTransparency = 1
greetFrame.Parent = mainPage

local greetTitle = Instance.new("TextLabel")
greetTitle.Size = UDim2.new(1, 0, 0, 16)
greetTitle.BackgroundTransparency = 1
greetTitle.Text = "// HEY, I'M A BEGINNER CODER"
greetTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
greetTitle.TextSize = 11
greetTitle.Font = Enum.Font.Code
greetTitle.TextXAlignment = Enum.TextXAlignment.Left
greetTitle.Parent = greetFrame

local greetTitleGradient = Instance.new("UIGradient", greetTitle)
greetTitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_GLOW),
    ColorSequenceKeypoint.new(0.5, THEME.TEXT_HI),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_HOT),
})

local greetBody = Instance.new("TextLabel")
greetBody.Size = UDim2.new(1, 0, 0, 40)
greetBody.Position = UDim2.new(0, 0, 0, 18)
greetBody.BackgroundTransparency = 1
greetBody.Text = "still learning every day - building my own dream piece by piece.\ncode is the canvas, and the game is the art."
greetBody.TextColor3 = Color3.fromRGB(255, 255, 255)
greetBody.TextSize = 10
greetBody.Font = Enum.Font.Gotham
greetBody.TextWrapped = true
greetBody.TextXAlignment = Enum.TextXAlignment.Left
greetBody.LineHeight = 1.15
greetBody.Parent = greetFrame

local greetBodyGradient = Instance.new("UIGradient", greetBody)
greetBodyGradient.Rotation = 25
greetBodyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_GLOW),
    ColorSequenceKeypoint.new(0.4, THEME.TEXT_HI),
    ColorSequenceKeypoint.new(0.7, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

task.spawn(function()
    while greetTitleGradient.Parent do
        for i = -1, 1, 0.03 do greetTitleGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
        for i = 1, -1, -0.03 do greetTitleGradient.Offset = Vector2.new(i, 0); task.wait(0.04) end
    end
end)

task.spawn(function()
    while greetBodyGradient.Parent do
        for i = -1.2, 1.2, 0.02 do greetBodyGradient.Offset = Vector2.new(i, 0); task.wait(0.035) end
        for i = 1.2, -1.2, -0.02 do greetBodyGradient.Offset = Vector2.new(i, 0); task.wait(0.035) end
    end
end)

local splitLine = Instance.new("Frame")
splitLine.Size = UDim2.new(1, 0, 0, 1)
splitLine.Position = UDim2.new(0, 0, 0, 162)
splitLine.BackgroundColor3 = THEME.ACCENT
splitLine.BorderSizePixel = 0
splitLine.BackgroundTransparency = 0.7
splitLine.ZIndex = 6
splitLine.Parent = mainPage

local splitGrad = Instance.new("UIGradient", splitLine)
splitGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})
splitGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})

local statusSection = Instance.new("Frame")
statusSection.Size = UDim2.new(1, 0, 0, 18)
statusSection.Position = UDim2.new(0, 0, 0, 172)
statusSection.BackgroundTransparency = 1
statusSection.Parent = mainPage

local statusSectionLine = Instance.new("Frame")
statusSectionLine.Size = UDim2.new(0, 3, 0, 12)
statusSectionLine.Position = UDim2.new(0, 0, 0.5, -6)
statusSectionLine.BackgroundColor3 = THEME.ACCENT_HOT
statusSectionLine.BorderSizePixel = 0
statusSectionLine.Parent = statusSection
Instance.new("UICorner", statusSectionLine).CornerRadius = UDim.new(1, 0)

local statusSectionLabel = Instance.new("TextLabel")
statusSectionLabel.Size = UDim2.new(1, -15, 1, 0)
statusSectionLabel.Position = UDim2.new(0, 15, 0, 0)
statusSectionLabel.BackgroundTransparency = 1
statusSectionLabel.Text = "// LIVE STATUS"
statusSectionLabel.TextColor3 = THEME.ACCENT_HOT
statusSectionLabel.TextSize = 11
statusSectionLabel.Font = Enum.Font.Code
statusSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
statusSectionLabel.Parent = statusSection

local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(1, -10, 0, 116)
gridFrame.Position = UDim2.new(0, 5, 0, 194)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = mainPage

local gridLayout = Instance.new("UIGridLayout", gridFrame)
gridLayout.CellSize = UDim2.new(0.5, -4, 0, 55)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 5)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local statTiles = {}
local statConfigs = {
    {key = "FPS", label = "FPS", order = 1},
    {key = "PING", label = "PING", order = 2},
    {key = "MEMORY", label = "MEMORY", order = 3},
    {key = "SESSION", label = "SESSION", order = 4},
}

for _, cfg in ipairs(statConfigs) do
    local tile = Instance.new("Frame")
    tile.Size = UDim2.new(0.5, -4, 0, 55)
    tile.BackgroundColor3 = Color3.fromRGB(14, 11, 22)
    tile.BackgroundTransparency = 0.15
    tile.BorderSizePixel = 0
    tile.LayoutOrder = cfg.order
    tile.Parent = gridFrame
    Instance.new("UICorner", tile).CornerRadius = UDim.new(0, Config.CornerRadius)

    local tileStroke = Instance.new("UIStroke", tile)
    tileStroke.Thickness = 1
    tileStroke.Color = THEME.ACCENT
    tileStroke.Transparency = 0.5

    local tileInnerGlow = Instance.new("UIStroke", tile)
    tileInnerGlow.Thickness = 2
    tileInnerGlow.Color = THEME.ACCENT_GLOW
    tileInnerGlow.Transparency = 0.94

    local tileTopBar = Instance.new("Frame")
    tileTopBar.Size = UDim2.new(1, -20, 0, 2)
    tileTopBar.Position = UDim2.new(0, 10, 0, 6)
    tileTopBar.BackgroundColor3 = THEME.ACCENT_HOT
    tileTopBar.BorderSizePixel = 0
    tileTopBar.Parent = tile
    Instance.new("UICorner", tileTopBar).CornerRadius = UDim.new(1, 0)

    local tileTopGradient = Instance.new("UIGradient", tileTopBar)
    tileTopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
    })

    local tileDot = Instance.new("Frame")
    tileDot.Size = UDim2.new(0, 4, 0, 4)
    tileDot.Position = UDim2.new(1, -14, 0, 11)
    tileDot.BackgroundColor3 = THEME.ACCENT_HOT
    tileDot.BorderSizePixel = 0
    tileDot.Parent = tile
    Instance.new("UICorner", tileDot).CornerRadius = UDim.new(1, 0)

    local tileLabel = Instance.new("TextLabel")
    tileLabel.Size = UDim2.new(1, -20, 0, 12)
    tileLabel.Position = UDim2.new(0, 10, 0, 11)
    tileLabel.BackgroundTransparency = 1
    tileLabel.Text = cfg.label
    tileLabel.TextColor3 = THEME.TEXT_LOW
    tileLabel.TextSize = 9
    tileLabel.Font = Enum.Font.Code
    tileLabel.TextXAlignment = Enum.TextXAlignment.Left
    tileLabel.Parent = tile

    local tileValue = Instance.new("TextLabel")
    tileValue.Size = UDim2.new(1, -20, 0, 24)
    tileValue.Position = UDim2.new(0, 10, 0, 23)
    tileValue.BackgroundTransparency = 1
    tileValue.Text = "--"
    tileValue.TextColor3 = THEME.ACCENT_HOT
    tileValue.TextSize = 16
    tileValue.Font = Enum.Font.GothamBold
    tileValue.TextXAlignment = Enum.TextXAlignment.Left
    tileValue.Parent = tile

    local tileValueGradient = Instance.new("UIGradient", tileValue)
    tileValueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_GLOW),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_HOT),
    })

    statTiles[cfg.key] = { Value = tileValue }

    table.insert(S.ColorSynced, {
        Kind = "StatTile", Stroke = tileStroke, TopBar = tileTopBar,
        TopGradient = tileTopGradient, Value = tileValue,
        ValueGradient = tileValueGradient, InnerGlow = tileInnerGlow, Dot = tileDot,
    })
end

task.spawn(function()
    local sessionStart = tick()
    local frameCount = 0
    local lastFpsTime = tick()
    local conn = RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)
    table.insert(S.Connections, conn)
    while mainPage.Parent do
        local now = tick()
        if now - lastFpsTime >= 1 then
            if statTiles["FPS"] then statTiles["FPS"].Value.Text = tostring(math.floor(frameCount / (now - lastFpsTime))) end
            frameCount = 0
            lastFpsTime = now
        end
        if statTiles["PING"] then
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            statTiles["PING"].Value.Text = tostring(ping) .. "ms"
        end
        if statTiles["MEMORY"] then
            local mem = 0
            pcall(function() mem = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()) end)
            statTiles["MEMORY"].Value.Text = tostring(mem) .. "MB"
        end
        if statTiles["SESSION"] then
            local secs = math.floor(tick() - sessionStart)
            statTiles["SESSION"].Value.Text = string.format("%02d:%02d", math.floor(secs/60), secs % 60)
        end
        task.wait(1)
    end
end)

-- ====================================================================
-- COMBAT PAGE
-- ====================================================================
local combatPage = TabPages["Combat"]
combatPage.CanvasSize = UDim2.new(0, 0, 0, 500)

CreateSection(combatPage, "// HITBOX EXPANDER", 10, THEME.ACCENT_HOT)

CreateToggle(combatPage, "Hitbox Expander", "Expands impact area + shows sphere around ball", 40, S.MegaHitbox.Enabled, function(v)
    S.MegaHitbox.Enabled = v
    Config.HitboxEnabled = v
    if v then
        S.MegaHitbox.ExpandedCount = ExpandAllHitboxTemplates()
        UpdateHitboxHook()
        _CreateHitboxVisual()
        print("[VL] Hitbox ENABLED | x" .. S.MegaHitbox.SizeMultiplier)
    else
        UpdateHitboxHook()
        if not S.RangeGuard.Enabled then
            RestoreAllHitboxes()
            _DestroyHitboxVisual()
        end
        print("[VL] Hitbox DISABLED")
    end
end)

CreateSlider(combatPage, "Hitbox Size", "Impact area multiplier (x1 - x20)", 95, 10, 200, Config.HitboxSize, "x", function(v)
    Config.HitboxSize = v
    S.MegaHitbox.SizeMultiplier = v / 10
    if S.MegaHitbox.Enabled then
        ExpandAllHitboxTemplates()
        UpdateHitboxHook()
    end
end)

CreateToggle(combatPage, "Range Guard", "Blocks hit when ball is outside guard radius", 160, S.RangeGuard.Enabled, function(v)
    S.RangeGuard.Enabled = v
    if v then
        UpdateHitboxHook()
        if not S.HitboxVisual.Sphere then _CreateHitboxVisual() end
    else
        UpdateHitboxHook()
        if not S.MegaHitbox.Enabled then
            RestoreAllHitboxes()
            _DestroyHitboxVisual()
        end
    end
end)

CreateSlider(combatPage, "Guard Radius", "Distance limit in studs", 215, 3, 30, 8, " studs", function(v)
    S.RangeGuard.Radius = v
end)

-- ====================================================================
-- VISUALS PAGE
-- ====================================================================
local visualsPage = TabPages["Visuals"]
visualsPage.CanvasSize = UDim2.new(0, 0, 0, 900)  -- [CHANGED] больше места под Purge

CreateSection(visualsPage, "// BALL VISUALS", 10, Color3.fromRGB(120, 220, 255))

CreateToggle(visualsPage, "Ball ESP", "Highlights the ball with aura, sparks and light glow", 40, Config.BallESPEnabled, function(v)
    Config.BallESPEnabled = v
    if v then
        if S.BallESP.model then _CreateBallESP(S.BallESP.model) end
    else
        _DestroyBallESP()
    end
end)

CreateToggle(visualsPage, "Ball Predictor", "Shows landing point of the ball on the ground", 95, Config.BallPredictorEnabled, function(v)
    Config.BallPredictorEnabled = v
    if not v then
        S.Pred.smoothVel = nil
        S.Pred.smoothLand = nil
        if S.Pred.ring then S.Pred.ring.Transparency = 1 end
    end
end)

CreateSection(visualsPage, "// PLAYER TRACERS", 155, Color3.fromRGB(255, 100, 180))

CreateToggle(visualsPage, "Player Tracers", "3D beam from each player head showing look direction", 185, S.Tracers.Enabled, function(v)
    S.Tracers.Enabled = v
end)

CreateToggle(visualsPage, "Enemies Only", "Show tracers only for enemy team", 235, S.Tracers.OnlyEnemies, function(v)
    S.Tracers.OnlyEnemies = v
end)

CreateSlider(visualsPage, "Tracer Length", "Beam length in studs", 285, 5, 80, 25, " studs", function(v)
    S.Tracers.Length = v
end)

CreateSection(visualsPage, "// CAMERA", 350, Color3.fromRGB(120, 220, 255))

CreateSlider(visualsPage, "Field of View", "Camera zoom out angle (70 - 200)", 380, 70, 200, Config.FOV, "deg", function(v)
    Config.FOV = v
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = v
    end
end)

-- [NEW] ====== PURGE CHARACTER SECTION ======
CreateSection(visualsPage, "// PURGE CHARACTER", 450, Color3.fromRGB(180, 80, 255))

CreateToggle(visualsPage, "Purge Character", "Headless + Korblox + accessories + gray shift", 480, S.Purge.Enabled, function(v)
    S.Purge.Enabled = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then _ApplyPurge(p.Character, p) end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then _RestorePurge(p.Character, p) end
        end
    end
end)

CreateToggle(visualsPage, "Glow Eyes", "Neon eyes (work even when head is hidden)", 530, S.Purge.Eyes, function(v)
    S.Purge.Eyes = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then _TogglePurgeEyes(p.Character, v) end
    end
end)

CreateToggle(visualsPage, "Sparkles", "Sparkle particles around body", 580, S.Purge.Sparkles, function(v)
    S.Purge.Sparkles = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then _TogglePurgeSparkles(p.Character, v) end
    end
end)

CreateToggle(visualsPage, "Corpse Gray", "Pulsing gray body color", 630, S.Purge.Gray, function(v)
    S.Purge.Gray = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then _TogglePurgeGray(p.Character, v) end
    end
end)

CreateToggle(visualsPage, "Remove Leg", "Korblox - hide right leg", 680, S.Purge.Leg, function(v)
    S.Purge.Leg = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then _TogglePurgeLeg(p.Character, v) end
    end
end)

-- ====================================================================
-- PURGE FUNCTIONS
-- ====================================================================
local function _HidePart(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function()
        part.Transparency = 1
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
    end)
    for _, d in ipairs(part:GetChildren()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            pcall(function() d.Transparency = 1 end)
        end
    end
end

local function _RemoveAccessories(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then pcall(function() humanoid:RemoveAccessories() end) end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accoutrement") or child:IsA("Accessory") or child:IsA("Hat") then
            pcall(function() child:Destroy() end)
        end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Accoutrement") or d:IsA("Accessory") or d:IsA("Hat") then
            pcall(function() d:Destroy() end)
        end
    end
end

local function _HideHead(char)
    local head = char:FindFirstChild("Head")
    if head then _HidePart(head) end
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                pcall(function() child.Transparency = 1 end)
            elseif child:IsA("Accoutrement") or child:IsA("Accessory") or child:IsA("Hat") then
                pcall(function() child:Destroy() end)
            end
        end
    end
end

local function _HideOneLeg(char)
    local legName = "Right Leg"
    local leg = char:FindFirstChild(legName)
    if leg then _HidePart(leg) end
    for _, name in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
        _HidePart(char:FindFirstChild(name))
    end
end

local function _BuildPurgeEyes(char)
    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end
    local oldL = char:FindFirstChild("VLEyeL")
    local oldR = char:FindFirstChild("VLEyeR")
    if oldL then oldL:Destroy() end
    if oldR then oldR:Destroy() end
    local oldLight = head:FindFirstChild("VLEyeLight")
    if oldLight then oldLight:Destroy() end

    for _, side in ipairs({-1, 1}) do
        local eye = Instance.new("Part")
        eye.Name = side == -1 and "VLEyeL" or "VLEyeR"
        eye.Shape = Enum.PartType.Ball
        eye.Size = Vector3.new(0.4, 0.4, 0.4)
        eye.Anchored = false
        eye.CanCollide = false
        eye.CanQuery = false
        eye.CanTouch = false
        eye.CastShadow = false
        eye.Material = Enum.Material.Neon
        eye.Color = S.Purge.EyeColor
        eye.Transparency = 0
        eye.Parent = char
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = eye
        weld.C0 = CFrame.new(side * 0.35, 0.3, -0.6)
        weld.Parent = eye
    end

    local light = Instance.new("PointLight")
    light.Name = "VLEyeLight"
    light.Color = S.Purge.EyeColor
    light.Brightness = 4
    light.Range = 10
    light.Shadows = false
    light.Parent = head
end

local function _AddPurgeSparkles(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local old = hrp:FindFirstChild("VLSparkles")
    if old then old:Destroy() end
    local sp = Instance.new("Sparkles")
    sp.Name = "VLSparkles"
    sp.SparkleColor = S.Purge.SparkleColor
    sp.Enabled = true
    sp.Parent = hrp
end

local function _ApplyPurgeGray(bc)
    if not bc or not bc.Parent then return end
    local t = tick() * S.Purge.PulseSpeed
    local wave = (math.sin(t) + 1) / 2
    local b = S.Purge.BrightnessMin + (S.Purge.BrightnessMax - S.Purge.BrightnessMin) * wave
    local c = Color3.new(
        math.clamp(S.Purge.GrayBase.R * b, 0, 1),
        math.clamp(S.Purge.GrayBase.G * b, 0, 1),
        math.clamp(S.Purge.GrayBase.B * b, 0, 1)
    )
    pcall(function()
        bc.HeadColor3 = c
        bc.TorsoColor3 = c
        bc.LeftArmColor3 = c
        bc.RightArmColor3 = c
        bc.LeftLegColor3 = c
        bc.RightLegColor3 = c
    end)
end

function _TogglePurgeEyes(char, on)
    if on then _BuildPurgeEyes(char)
    else
        local e1 = char:FindFirstChild("VLEyeL") if e1 then e1:Destroy() end
        local e2 = char:FindFirstChild("VLEyeR") if e2 then e2:Destroy() end
        local head = char:FindFirstChild("Head")
        if head then
            local l = head:FindFirstChild("VLEyeLight") if l then l:Destroy() end
        end
    end
end

function _TogglePurgeSparkles(char, on)
    if on then _AddPurgeSparkles(char)
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local sp = hrp:FindFirstChild("VLSparkles")
            if sp then sp:Destroy() end
        end
    end
end

function _TogglePurgeGray(char, on)
    -- ничего дополнительного: цикл сам обновляет если S.Purge.Gray == true
end

function _TogglePurgeLeg(char, on)
    if on then _HideOneLeg(char)
    else
        for _, name in ipairs({"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                p.Transparency = 0
                p.CanCollide = true
                p.CanQuery = true
                p.CanTouch = true
            end
        end
    end
end

function _ApplyPurge(char, player)
    if not char or not char.Parent then return end
    player = player or Players:GetPlayerFromCharacter(char)

    local data = S.Purge.Tracked[player]
    if not data then
        data = { char = char, conns = {}, pulseConn = nil }
        S.Purge.Tracked[player] = data
    end
    data.char = char

    -- голова
    if S.Purge.Head then _HideHead(char) end

    -- аксессуары
    _RemoveAccessories(char)

    -- нога
    if S.Purge.Leg then _HideOneLeg(char) end

    -- глаза
    if S.Purge.Eyes then _BuildPurgeEyes(char) end

    -- блёстки
    if S.Purge.Sparkles then _AddPurgeSparkles(char) end

    -- реагируем на новые аксессуары
    local connAdd = char.ChildAdded:Connect(function(child)
        if not S.Purge.Enabled then return end
        if child:IsA("Accoutrement") or child:IsA("Accessory") or child:IsA("Hat") then
            pcall(function() child:Destroy() end)
        end
    end)
    table.insert(data.conns, connAdd)

    -- пульсация серых цветов
    if not data.pulseConn then
        data.pulseConn = RunService.Heartbeat:Connect(function()
            if not S.Purge.Enabled or not S.Purge.Gray then return end
            local bc = char:FindFirstChildOfClass("BodyColors")
            if bc then _ApplyPurgeGray(bc) end
        end)
        table.insert(S.Connections, data.pulseConn)
    end
end

function _RestorePurge(char, player)
    if not char then return end
    player = player or Players:GetPlayerFromCharacter(char)
    local data = S.Purge.Tracked[player]
    if data then
        if data.conns then
            for _, c in ipairs(data.conns) do pcall(function() c:Disconnect() end) end
        end
        if data.pulseConn then
            pcall(function() data.pulseConn:Disconnect() end)
        end
        S.Purge.Tracked[player] = nil
    end

    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        head.CanCollide = false
        head.CanQuery = true
        head.CanTouch = true
        head.CastShadow = true
    end

    for _, name in ipairs({"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            p.Transparency = 0
            p.CanCollide = true
            p.CanQuery = true
            p.CanTouch = true
        end
    end

    _TogglePurgeEyes(char, false)
    _TogglePurgeSparkles(char, false)
end

-- Подписка на игроков для Purge
local function _PurgeOnPlayer(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        if S.Purge.Enabled then _ApplyPurge(char, player) end
    end)
    if player.Character and S.Purge.Enabled then
        task.spawn(function()
            task.wait(0.4)
            if S.Purge.Enabled then _ApplyPurge(player.Character, player) end
        end)
    end
end
for _, p in ipairs(Players:GetPlayers()) do _PurgeOnPlayer(p) end
Players.PlayerAdded:Connect(_PurgeOnPlayer)

-- ====================================================================
-- BALL FUNCTIONS
-- ====================================================================
local WIPER_GRAY = Color3.fromRGB(163, 162, 165)

function _WipeCharacter(char)
    if not char then return end
    if S.ClothesWiper.Wiped[char] then return end
    S.ClothesWiper.Wiped[char] = true
    local shirt = char:FindFirstChildOfClass("Shirt")
    if shirt then pcall(function() shirt.ShirtTemplate = "" end) end
    local pants = char:FindFirstChildOfClass("Pants")
    if pants then pcall(function() pants.PantsTemplate = "" end) end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then
        pcall(function()
            bc.HeadColor3 = WIPER_GRAY
            bc.TorsoColor3 = WIPER_GRAY
            bc.LeftArmColor3 = WIPER_GRAY
            bc.RightArmColor3 = WIPER_GRAY
            bc.LeftLegColor3 = WIPER_GRAY
            bc.RightLegColor3 = WIPER_GRAY
        end)
    end
end

function _WiperUpdate()
    if not S.ClothesWiper.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local bc = char:FindFirstChildOfClass("BodyColors")
            if bc then
                pcall(function()
                    bc.HeadColor3 = WIPER_GRAY
                    bc.TorsoColor3 = WIPER_GRAY
                    bc.LeftArmColor3 = WIPER_GRAY
                    bc.RightArmColor3 = WIPER_GRAY
                    bc.LeftLegColor3 = WIPER_GRAY
                    bc.RightLegColor3 = WIPER_GRAY
                end)
            end
            if not S.ClothesWiper.Wiped[char] then
                _WipeCharacter(char)
            end
        end
    end
end

function _FindBall()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.PrimaryPart then
            if string.find(obj.Name, "^CLIENT_BALL_") then return obj end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and string.find(string.lower(obj.Name), "client_ball") then
            if obj.PrimaryPart then return obj end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.PrimaryPart then
            local lname = string.lower(obj.Name)
            if string.find(lname, "volleyball") and not string.find(lname, "shadow") then
                return obj
            end
        end
    end
    return nil
end

function _GetFloorY(pos)
    local ok, Physics = pcall(function() return require(ReplicatedStorage.Common.Physics) end)
    if ok and Physics and Physics.calculateFloorHeight then
        local ok2, y = pcall(function() return Physics.calculateFloorHeight(pos) end)
        if ok2 and y and type(y) == "number" then return y end
    end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {LocalPlayer.Character or Instance.new("Model")}
    local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 50, pos.Z), Vector3.new(0, -300, 0), rp)
    if hit then return hit.Position.Y end
    return nil
end

function _PredictLanding(origin, velocity)
    local g = 17
    local pos = origin
    local vel = velocity
    local dt = 0.05
    local floorY = _GetFloorY(origin) or -0.2
    for i = 1, 80 do
        vel = Vector3.new(vel.X, vel.Y - g * dt, vel.Z)
        pos = pos + vel * dt
        if pos.Y <= floorY + 1.2835 then
            return Vector3.new(pos.X, floorY, pos.Z)
        end
        if i % 10 == 0 then
            local nf = _GetFloorY(pos)
            if nf then floorY = nf end
        end
        if pos.Y < -500 then break end
    end
    return Vector3.new(pos.X, floorY, pos.Z)
end

function _DestroyBallTrail()
    if S.BallESP.trail then pcall(function() S.BallESP.trail:Destroy() end) S.BallESP.trail = nil end
    if S.BallESP.trailAtt0 then pcall(function() S.BallESP.trailAtt0:Destroy() end) S.BallESP.trailAtt0 = nil end
    if S.BallESP.trailAtt1 then pcall(function() S.BallESP.trailAtt1:Destroy() end) S.BallESP.trailAtt1 = nil end
end

function _CreateBallTrail(ball)
    _DestroyBallTrail()
    if not ball or not ball.PrimaryPart then return end
    local primary = ball.PrimaryPart
    local att0 = Instance.new("Attachment")
    att0.Position = Vector3.new(0, 0.3, 0)
    att0.Parent = primary
    S.BallESP.trailAtt0 = att0
    local att1 = Instance.new("Attachment")
    att1.Position = Vector3.new(0, -0.3, 0)
    att1.Parent = primary
    S.BallESP.trailAtt1 = att1
    local trail = Instance.new("Trail")
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Lifetime = 0.6
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_GLOW),
    })
    trail.Parent = primary
    S.BallESP.trail = trail
end

function _DestroyBallESP()
    if S.BallESP.highlight then pcall(function() S.BallESP.highlight:Destroy() end) S.BallESP.highlight = nil end
    if S.BallESP.particles then pcall(function() S.BallESP.particles:Destroy() end) S.BallESP.particles = nil end
    if S.BallESP.light then pcall(function() S.BallESP.light:Destroy() end) S.BallESP.light = nil end
    _DestroyBallTrail()
end

function _CreateBallESP(ball)
    _DestroyBallESP()
    if not ball or not ball.PrimaryPart then return end
    local primary = ball.PrimaryPart
    S.BallESP.highlight = Instance.new("Highlight")
    S.BallESP.highlight.Adornee = primary
    S.BallESP.highlight.FillColor = THEME.ACCENT
    S.BallESP.highlight.OutlineColor = THEME.ACCENT_HOT
    S.BallESP.highlight.FillTransparency = 0.55
    S.BallESP.highlight.OutlineTransparency = 0
    S.BallESP.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    S.BallESP.highlight.Parent = safeParent
    S.BallESP.light = Instance.new("PointLight")
    S.BallESP.light.Color = THEME.ACCENT
    S.BallESP.light.Brightness = 2
    S.BallESP.light.Range = 10
    S.BallESP.light.Parent = primary
    _CreateBallTrail(ball)
end

function _CreatePredictorVisuals()
    if S.Pred.ring then S.Pred.ring:Destroy() end
    S.Pred.ring = Instance.new("Part")
    S.Pred.ring.Shape = Enum.PartType.Cylinder
    S.Pred.ring.Size = Vector3.new(0.1, 4, 4)
    S.Pred.ring.Anchored = true
    S.Pred.ring.CanCollide = false
    S.Pred.ring.CanQuery = false
    S.Pred.ring.CanTouch = false
    S.Pred.ring.Material = Enum.Material.Neon
    S.Pred.ring.Color = THEME.ACCENT_HOT
    S.Pred.ring.Transparency = 1
    S.Pred.ring.Parent = workspace
end

_CreatePredictorVisuals()

-- ====================================================================
-- HITBOX VISUAL
-- ====================================================================
function _DestroyHitboxVisual()
    if S.HitboxVisual.Sphere then pcall(function() S.HitboxVisual.Sphere:Destroy() end) S.HitboxVisual.Sphere = nil end
end

function _CreateHitboxVisual()
    _DestroyHitboxVisual()
    local sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(6, 6, 6)
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.CanQuery = false
    sphere.CanTouch = false
    sphere.CastShadow = false
    sphere.Material = Enum.Material.ForceField
    sphere.Color = THEME.ACCENT
    sphere.Transparency = 0.75
    sphere.Parent = workspace
    S.HitboxVisual.Sphere = sphere
    S.HitboxVisual.Radius = S.MegaHitbox.SizeMultiplier * 1.2835
end

function _UpdateHitboxVisual(dt)
    if not (S.MegaHitbox.Enabled or S.RangeGuard.Enabled) then
        if S.HitboxVisual.Sphere then _DestroyHitboxVisual() end
        return
    end
    local ball = _FindBall()
    if not ball or not ball.PrimaryPart then
        if S.HitboxVisual.Sphere then S.HitboxVisual.Sphere.Transparency = 1 end
        return
    end
    if not S.HitboxVisual.Sphere or not S.HitboxVisual.Sphere.Parent then
        _CreateHitboxVisual()
    end
    local ballPos = ball.PrimaryPart.Position
    local sizeMult = S.MegaHitbox.Enabled and S.MegaHitbox.SizeMultiplier or 3
    local desiredRadius = sizeMult * 1.2835
    S.HitboxVisual.Radius = S.HitboxVisual.Radius + (desiredRadius - S.HitboxVisual.Radius) * math.min(dt * 8, 1)
    local r = S.HitboxVisual.Radius
    local sphere = S.HitboxVisual.Sphere
    sphere.Size = Vector3.new(r * 2, r * 2, r * 2)
    sphere.CFrame = CFrame.new(ballPos)
    if S.RangeGuard.Enabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = (ballPos - char.HumanoidRootPart.Position).Magnitude
            if dist <= S.RangeGuard.Radius then
                sphere.Color = Color3.fromRGB(80, 255, 130)
                sphere.Transparency = 0.6
            else
                sphere.Color = Color3.fromRGB(255, 80, 80)
                sphere.Transparency = 0.75
            end
        end
    else
        sphere.Color = THEME.ACCENT
        sphere.Transparency = 0.75
    end
end

function ExpandAllHitboxTemplates()
    local Assets = ReplicatedStorage:FindFirstChild("Assets")
    if not Assets then return 0 end
    local HitboxesNew = Assets:FindFirstChild("HitboxesNew")
    if not HitboxesNew then return 0 end
    local count = 0
    local function processAssemblies(assemblies)
        if not assemblies then return end
        for _, assembly in ipairs(assemblies:GetChildren()) do
            local part = assembly:FindFirstChild("Part")
            if part then
                local orig = part:GetAttribute("VL_OrigSize") or part.Size
                part:SetAttribute("VL_OrigSize", orig)
                part.Size = orig * S.MegaHitbox.SizeMultiplier
                count = count + 1
            end
        end
    end
    local defaultFolder = HitboxesNew:FindFirstChild("Default")
    if defaultFolder then processAssemblies(defaultFolder:FindFirstChild("Assemblies")) end
    local bySpecial = HitboxesNew:FindFirstChild("BySpecial")
    if bySpecial then
        for _, special in ipairs(bySpecial:GetChildren()) do
            processAssemblies(special:FindFirstChild("Assemblies"))
        end
    end
    return count
end

function RestoreAllHitboxes()
    local Assets = ReplicatedStorage:FindFirstChild("Assets")
    if not Assets then return end
    local HitboxesNew = Assets:FindFirstChild("HitboxesNew")
    if not HitboxesNew then return end
    for _, obj in ipairs(HitboxesNew:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Part" then
            local orig = obj:GetAttribute("VL_OrigSize")
            if orig then obj.Size = orig end
        end
    end
end

-- ====================================================================
-- TRACERS
-- ====================================================================
function _TracerGetHead(player)
    local char = player.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    return nil
end

function _TracerIsEnemy(player)
    if player == LocalPlayer then return false end
    if not LocalPlayer.Team then return true end
    if not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

function _TracerEnsureFolder()
    if S.Tracers.Folder and S.Tracers.Folder.Parent then return end
    S.Tracers.Folder = Instance.new("Folder")
    S.Tracers.Folder.Name = "VL_BeamTracers"
    S.Tracers.Folder.Parent = workspace
end

function _TracerDestroy(player)
    local t = S.Tracers.Active[player]
    if not t then return end
    if t.att0 then pcall(function() t.att0:Destroy() end) end
    if t.endPart then pcall(function() t.endPart:Destroy() end) end
    S.Tracers.Active[player] = nil
end

function _TracerCreate(player)
    local head = _TracerGetHead(player)
    if not head then return nil end
    _TracerEnsureFolder()
    local att0 = Instance.new("Attachment")
    att0.Parent = head
    local endPart = Instance.new("Part")
    endPart.Size = Vector3.new(0.6, 0.6, 0.6)
    endPart.Shape = Enum.PartType.Ball
    endPart.Anchored = true
    endPart.CanCollide = false
    endPart.CanQuery = false
    endPart.CanTouch = false
    endPart.Material = Enum.Material.Neon
    endPart.Color = THEME.ACCENT_HOT
    endPart.Transparency = 0.2
    endPart.Parent = S.Tracers.Folder
    local att1 = Instance.new("Attachment")
    att1.Parent = endPart
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 0.3
    beam.Width1 = 0.3
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Color = ColorSequence.new(THEME.ACCENT_HOT)
    beam.Parent = endPart
    return { att0 = att0, endPart = endPart, head = head }
end

function _TracerUpdate()
    if not S.Tracers.Enabled then
        for player, _ in pairs(S.Tracers.Active) do
            _TracerDestroy(player)
        end
        if S.Tracers.Folder then
            pcall(function() S.Tracers.Folder:Destroy() end)
            S.Tracers.Folder = nil
        end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local shouldShow = true
            if S.Tracers.OnlyEnemies and not _TracerIsEnemy(player) then shouldShow = false end
            if shouldShow then
                local head = _TracerGetHead(player)
                if head then
                    local t = S.Tracers.Active[player]
                    if not (t and t.att0 and t.att0.Parent and t.endPart and t.endPart.Parent) then
                        _TracerDestroy(player)
                        t = _TracerCreate(player)
                        if t then S.Tracers.Active[player] = t end
                    end
                    if t and t.endPart then
                        local endPos = head.Position + head.CFrame.LookVector * S.Tracers.Length
                        t.endPart.CFrame = CFrame.new(endPos)
                    end
                else
                    _TracerDestroy(player)
                end
            else
                _TracerDestroy(player)
            end
        end
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        pcall(_TracerUpdate)
        task.wait(0.03)
    end
end)

-- ====================================================================
-- HIT BLOCKER
-- ====================================================================
function _IsBallInGuardRange()
    if not S.RangeGuard.Enabled then return true end
    local ball = _FindBall()
    if not ball or not ball.PrimaryPart then return true end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return true end    local dist = (ball.PrimaryPart.Position - char.HumanoidRootPart.Position).Magnitude
    return dist <= S.RangeGuard.Radius
end

pcall(function()
    local CAS = game:GetService("ContextActionService")
    CAS:BindActionAtPriority("VL_HitBlock", function(_, state)
        if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
        if not S.RangeGuard.Enabled then return Enum.ContextActionResult.Pass end
        if not _IsBallInGuardRange() then
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, 9999, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
end)

-- ====================================================================
-- SKY PRESETS
-- ====================================================================
function _SkyCleanup()
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if string.sub(obj.Name, 1, 5) == "META_" or string.sub(obj.Name, 1, 3) == "VL_" then
            pcall(function() obj:Destroy() end)
        end
    end
    if S.Sky.Connection then
        pcall(function() S.Sky.Connection:Disconnect() end)
        S.Sky.Connection = nil
    end
    S.Sky.Objects = {}
    S.Sky.Current = nil
end

function _SkyPinkVibe()
    _SkyCleanup()
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
            pcall(function() obj:Destroy() end)
        end
    end
    local pinkSky = Instance.new("Sky")
    pinkSky.Name = "META_PinkSky"
    pinkSky.SkyboxBk = "rbxassetid://159454299"
    pinkSky.SkyboxDn = "rbxassetid://159454296"
    pinkSky.SkyboxFt = "rbxassetid://159454293"
    pinkSky.SkyboxLf = "rbxassetid://159454286"
    pinkSky.SkyboxRt = "rbxassetid://159454300"
    pinkSky.SkyboxUp = "rbxassetid://159454288"
    pinkSky.CelestialBodiesShown = true
    pinkSky.Parent = Lighting
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "META_PinkAtmosphere"
    atmosphere.Density = 0.4
    atmosphere.Color = Color3.fromRGB(255, 180, 220)
    atmosphere.Decay = Color3.fromRGB(180, 90, 150)
    atmosphere.Glare = 0.7
    atmosphere.Haze = 2.5
    atmosphere.Parent = Lighting
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "META_PinkFilter"
    cc.Brightness = 0.06
    cc.Contrast = 0.18
    cc.Saturation = 0.6
    cc.TintColor = Color3.fromRGB(255, 200, 230)
    cc.Parent = Lighting
    Lighting.Ambient = Color3.fromRGB(140, 100, 130)
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 150, 190)
    Lighting.Brightness = 1.8
    Lighting.ClockTime = 16.5
    S.Sky.Connection = RunService.Heartbeat:Connect(function()
        if not cc or not cc.Parent then
            if S.Sky.Connection then S.Sky.Connection:Disconnect() S.Sky.Connection = nil end
            return
        end
        local wave = (math.sin(tick() * 0.5) + 1) / 2
        cc.TintColor = Color3.fromRGB(240 + wave * 15, 190 + wave * 20, 220 + wave * 25)
    end)
    S.Sky.Current = "PinkVibe"
end

function _SkyAtmosh()
    _SkyCleanup()
    local Lighting = game:GetService("Lighting")
    local oldSky = Lighting:FindFirstChildOfClass("Sky")
    if oldSky then pcall(function() oldSky:Destroy() end) end
    local PINK_ID = "rbxassetid://1001627653"
    local sky = Instance.new("Sky")
    sky.Name = "META_AtmoshSky"
    sky.SkyboxBk = PINK_ID
    sky.SkyboxDn = PINK_ID
    sky.SkyboxFt = PINK_ID
    sky.SkyboxLf = PINK_ID
    sky.SkyboxRt = PINK_ID
    sky.SkyboxUp = PINK_ID
    sky.Parent = Lighting
    Lighting.ClockTime = 17.5
    Lighting.Brightness = 2.2
    S.Sky.Current = "Atmosh"
end

function _SkyTwilight()
    _SkyCleanup()
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            pcall(function() obj:Destroy() end)
        end
    end
    local sky = Instance.new("Sky")
    sky.Name = "META_TwilightSky"
    sky.SkyboxBk = "rbxassetid://159454299"
    sky.SkyboxDn = "rbxassetid://159454296"
    sky.SkyboxFt = "rbxassetid://159454293"
    sky.SkyboxLf = "rbxassetid://159454286"
    sky.SkyboxRt = "rbxassetid://159454300"
    sky.SkyboxUp = "rbxassetid://159454288"
    sky.Parent = Lighting
    Lighting.ClockTime = 17.8
    Lighting.Brightness = 2.5
    S.Sky.Current = "Twilight"
end

S.Sky.Presets = {
    { name = "Pink Vibe", func = _SkyPinkVibe },
    { name = "Atmosh Sky", func = _SkyAtmosh },
    { name = "Twilight Bloom", func = _SkyTwilight },
}

-- ====================================================================
-- SKY PAGE
-- ====================================================================
local skyPage = TabPages["Sky"]
skyPage.CanvasSize = UDim2.new(0, 0, 0, 700)

CreateSection(skyPage, "// SKY SELECTOR", 10, Color3.fromRGB(255, 150, 200))

local skyY = 50
local skyButtons = {}

function CreateSkyButton(preset, yPos, index)
    local frame = Instance.new("TextButton")
    frame.Size = UDim2.new(1, -16, 0, 40)
    frame.Position = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(22, 15, 34)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = skyPage
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Color = THEME.ACCENT_DARK
    stroke.Transparency = 0.55
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 2, 1, -12)
    accent.Position = UDim2.new(0, 0, 0, 6)
    accent.BackgroundColor3 = THEME.ACCENT_HOT
    accent.BorderSizePixel = 0
    accent.ZIndex = 6
    accent.Parent = frame
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local idxLabel = Instance.new("TextLabel")
    idxLabel.Size = UDim2.new(0, 22, 1, 0)
    idxLabel.Position = UDim2.new(0, 12, 0, 0)
    idxLabel.BackgroundTransparency = 1
    idxLabel.Text = string.format("%02d", index)
    idxLabel.TextColor3 = THEME.TEXT_LOW
    idxLabel.TextSize = 10
    idxLabel.Font = Enum.Font.Code
    idxLabel.TextXAlignment = Enum.TextXAlignment.Left
    idxLabel.ZIndex = 7
    idxLabel.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 38, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = preset.name
    nameLabel.TextColor3 = THEME.TEXT_HI
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 7
    nameLabel.Parent = frame

    local nameGradient = Instance.new("UIGradient", nameLabel)
    nameGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_GLOW),
        ColorSequenceKeypoint.new(0.5, THEME.TEXT_HI),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_HOT),
    })

    task.spawn(function()
        while nameGradient.Parent do
            for i = -1, 1, 0.03 do
                if not nameGradient.Parent then break end
                nameGradient.Offset = Vector2.new(i, 0)
                task.wait(0.05)
            end
            for i = 1, -1, -0.03 do
                if not nameGradient.Parent then break end
                nameGradient.Offset = Vector2.new(i, 0)
                task.wait(0.05)
            end
        end
    end)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 24)
    btn.Position = UDim2.new(1, -68, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(28, 18, 44)
    btn.BackgroundTransparency = 0.15
    btn.Text = "APPLY"
    btn.TextColor3 = THEME.ACCENT_HOT
    btn.TextSize = 10
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    btn.ZIndex = 7
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 1
    btnStroke.Color = THEME.ACCENT_DARK
    btnStroke.Transparency = 0.35

    local btnGradient = Instance.new("UIGradient", btn)
    btnGradient.Rotation = 45
    btnGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1, 0.85),
    })
    btnGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
        ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
    })

    task.spawn(function()
        while btnGradient.Parent do
            for i = -1, 1, 0.05 do
                if not btnGradient.Parent then break end
                btnGradient.Offset = Vector2.new(i, 0)
                task.wait(0.05)
            end
            for i = 1, -1, -0.05 do
                if not btnGradient.Parent then break end
                btnGradient.Offset = Vector2.new(i, 0)
                task.wait(0.05)
            end
        end
    end)

    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 19, 42)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 15, 34)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.55}):Play()
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.15}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.35}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        PlayTab()
        preset.func()
        for _, b in ipairs(skyButtons) do
            TweenService:Create(b.stroke, TweenInfo.new(0.2), {Color = THEME.ACCENT_DARK, Transparency = 0.55}):Play()
        end
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = THEME.ACCENT_HOT, Transparency = 0.2}):Play()
    end)

    table.insert(skyButtons, { frame = frame, stroke = stroke })
end

for i, preset in ipairs(S.Sky.Presets) do
    CreateSkyButton(preset, skyY + (i - 1) * 48, i)
end

skyY = skyY + #S.Sky.Presets * 48 + 20

local disableBtn = Instance.new("TextButton")
disableBtn.Size = UDim2.new(1, -16, 0, 30)
disableBtn.Position = UDim2.new(0, 8, 0, skyY)
disableBtn.BackgroundTransparency = 1
disableBtn.Text = "DISABLE SKY (Reset to default)"
disableBtn.TextColor3 = Color3.fromRGB(255, 100, 120)
disableBtn.TextSize = 12
disableBtn.Font = Enum.Font.Gotham
disableBtn.AutoButtonColor = false
disableBtn.Parent = skyPage

disableBtn.MouseButton1Click:Connect(function()
    PlayTab()
    _SkyCleanup()
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
            pcall(function() obj:Destroy() end)
        end
    end
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    for _, b in ipairs(skyButtons) do
        TweenService:Create(b.stroke, TweenInfo.new(0.2), {Color = THEME.ACCENT_DARK, Transparency = 0.55}):Play()
    end
end)

-- ====================================================================
-- SETTINGS PAGE
-- ====================================================================
local settingsPage = TabPages["Settings"]
settingsPage.CanvasSize = UDim2.new(0, 0, 0, 1180)

CreateSection(settingsPage, "// INTERFACE", 10, THEME.ACCENT)

CreateToggle(settingsPage, "Flying Dots", "Floating particles in left panel", 40, Config.FlyingDotsEnabled, function(v)
    Config.FlyingDotsEnabled = v
    RebuildDots()
end)

CreateToggle(settingsPage, "Sounds", "UI click and tab sounds", 95, Config.SoundEnabled, function(v)
    Config.SoundEnabled = v
end)

CreateToggle(settingsPage, "Scan Line", "Moving light animation", 150, Config.ScanLineEnabled, function(v)
    Config.ScanLineEnabled = v
    if ScanLine then ScanLine.Visible = v end
end)

CreateToggle(settingsPage, "Wipe Clothes", "Strips clothes of all players (client only)", 205, S.ClothesWiper.Enabled, function(v)
    S.ClothesWiper.Enabled = v
    if v then
        S.ClothesWiper.Wiped = {}
        _WiperUpdate()
    else
        S.ClothesWiper.Wiped = {}
    end
end)

CreateToggle(settingsPage, "FPS Counter", "Show FPS in left panel", 260, Config.FpsCounterEnabled, function(v)
    Config.FpsCounterEnabled = v
    FpsFrame.Visible = v
end)

CreateSection(settingsPage, "// LAYOUT", 330, THEME.ACCENT_HOT)

CreateSlider(settingsPage, "Menu Scale", "Resize the whole menu", 360, 70, 130, 100, "%", function(v)
    Config.MenuScale = v
    TweenService:Create(MainScale, TweenInfo.new(0.15), {Scale = v / 100}):Play()
end)

CreateSlider(settingsPage, "Corner Radius", "Round corners", 420, 0, 16, 8, "px", function(v)
    Config.CornerRadius = v
    for _, el in ipairs(S.Corner) do
        local parent = el.Corner.Parent
        local offset = (parent == PanelHolder) and -2 or 0
        TweenService:Create(el.Corner, TweenInfo.new(0.15), {CornerRadius = UDim.new(0, math.max(0, v + offset))}):Play()
    end
end)

-- ====================================================================
-- COLOR PICKER
-- ====================================================================
local colorSectionLine = CreateSection(settingsPage, "// COLOR", 500, Color3.fromRGB(120, 220, 255))

local paletteSize = 140
local paletteFrame = Instance.new("Frame")
paletteFrame.Size = UDim2.new(0, paletteSize, 0, paletteSize)
paletteFrame.Position = UDim2.new(0, 0, 0, 530)
paletteFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
paletteFrame.Parent = settingsPage
Instance.new("UICorner", paletteFrame).CornerRadius = UDim.new(1, 0)

local paletteStroke = Instance.new("UIStroke", paletteFrame)
paletteStroke.Thickness = 1
paletteStroke.Color = THEME.ACCENT_DARK
paletteStroke.Transparency = 0.4

local paletteImage = Instance.new("ImageLabel")
paletteImage.Size = UDim2.new(1, -4, 1, -4)
paletteImage.Position = UDim2.new(0, 2, 0, 2)
paletteImage.BackgroundTransparency = 1
paletteImage.Image = "rbxassetid://7393858625"
paletteImage.ScaleType = Enum.ScaleType.Stretch
paletteImage.Parent = paletteFrame
Instance.new("UICorner", paletteImage).CornerRadius = UDim.new(1, 0)

local pickerDot = Instance.new("Frame")
pickerDot.Size = UDim2.new(0, 12, 0, 12)
pickerDot.AnchorPoint = Vector2.new(0.5, 0.5)
pickerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
pickerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pickerDot.ZIndex = 5
pickerDot.Parent = paletteFrame
Instance.new("UICorner", pickerDot).CornerRadius = UDim.new(1, 0)

local previewBox = Instance.new("Frame")
previewBox.Size = UDim2.new(0, 60, 0, 60)
previewBox.Position = UDim2.new(0, paletteSize + 20, 0, 530 + (paletteSize - 60) / 2 - 30)
previewBox.BackgroundColor3 = THEME.ACCENT
previewBox.Parent = settingsPage
Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 6)

local resetColorBtn = Instance.new("TextButton")
resetColorBtn.Size = UDim2.new(1, -50, 0, 32)
resetColorBtn.Position = UDim2.new(0, 0, 0, 530 + paletteSize + 15)
resetColorBtn.BackgroundTransparency = 1
resetColorBtn.Text = "Reset Color"
resetColorBtn.TextColor3 = Color3.fromRGB(120, 220, 255)
resetColorBtn.TextSize = 13
resetColorBtn.Font = Enum.Font.Gotham
resetColorBtn.AutoButtonColor = false
resetColorBtn.Parent = settingsPage

local colorDragArea = Instance.new("TextButton")
colorDragArea.Size = UDim2.new(1, 0, 1, 0)
colorDragArea.BackgroundTransparency = 1
colorDragArea.Text = ""
colorDragArea.ZIndex = 10
colorDragArea.Parent = paletteFrame

function ApplyAccent_Core(newAccent, newHot, newDark, newGlow)
    THEME.ACCENT = newAccent
    THEME.ACCENT_HOT = newHot
    THEME.ACCENT_DARK = newDark
    THEME.ACCENT_GLOW = newGlow
    MainStroke.Color = newAccent
    if MainStrokeGradient then
        MainStrokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.25, newHot),
            ColorSequenceKeypoint.new(0.5, newGlow),
            ColorSequenceKeypoint.new(0.75, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
    end
    MainGlow.Color = newGlow
    LogoBadgeGlow.Color = newGlow
    AvatarStroke.Color = newHot
    AvatarGlow.Color = newGlow
    PlayerTag.TextColor3 = newHot
end

function ApplyAccent_Header(newAccent, newHot, newDark, newGlow)
    Divider.BackgroundColor3 = newAccent
    DividerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    AccentBar.BackgroundColor3 = newAccent
    AccentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.25, newHot),
        ColorSequenceKeypoint.new(0.5, newGlow),
        ColorSequenceKeypoint.new(0.75, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    HeaderBaseLine.BackgroundColor3 = newDark
    HeaderRunner.BackgroundColor3 = newHot
    HeaderPulse.BackgroundColor3 = newGlow
    ScanLine.BackgroundColor3 = newHot
    StatusDot.BackgroundColor3 = newHot
    LogoTitleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, THEME.TEXT_HI),
        ColorSequenceKeypoint.new(1, newDark),
    })
    LogoSubGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
end

function ApplyAccent_UI(newAccent, newHot, newDark, newGlow)
    paletteStroke.Color = newDark
    previewBox.BackgroundColor3 = newAccent
    if S.Br.TL_hg then
        local gradSeq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.5, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
        S.Br.TL_hg.Color = gradSeq
        S.Br.TR_hg.Color = gradSeq
        S.Br.BL_hg.Color = gradSeq
        S.Br.BR_hg.Color = gradSeq
        S.Br.TL_vg.Color = gradSeq
        S.Br.TR_vg.Color = gradSeq
        S.Br.BL_vg.Color = gradSeq
        S.Br.BR_vg.Color = gradSeq
    end
    S.Br.TL_h.BackgroundColor3 = newHot
    S.Br.TL_v.BackgroundColor3 = newHot
    S.Br.TR_h.BackgroundColor3 = newHot
    S.Br.TR_v.BackgroundColor3 = newHot
    S.Br.BL_h.BackgroundColor3 = newHot
    S.Br.BL_v.BackgroundColor3 = newHot
    S.Br.BR_h.BackgroundColor3 = newHot
    S.Br.BR_v.BackgroundColor3 = newHot
    for _, d in ipairs(Config.Dots) do
        if d.Frame then d.Frame.BackgroundColor3 = newHot end
    end
end

function ApplyAccent_Elements(newAccent, newHot, newDark, newGlow)
    for _, tData in pairs(Tabs) do
        tData.Accent.BackgroundColor3 = newHot
        if tData.Arrow then tData.Arrow.TextColor3 = newHot end
        if tData.IsActive then
            tData.Button.BackgroundColor3 = Color3.fromRGB(
                math.floor(newAccent.R * 60 + 10),
                math.floor(newAccent.G * 60 + 10),
                math.floor(newAccent.B * 60 + 10))
            tData.Stroke.Color = newHot
            tData.Index.TextColor3 = newHot
        else
            tData.Stroke.Color = THEME.LINE
            tData.Index.TextColor3 = THEME.TEXT_LOW
        end
    end
    if FpsGradient then
        FpsGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.5, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
    end
    if DotGradient then
        DotGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.5, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
    end
    if RunnerGradient then
        RunnerGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.5, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
    end
    if ScanGradient then
        ScanGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newHot),
            ColorSequenceKeypoint.new(0.5, newGlow),
            ColorSequenceKeypoint.new(1, newHot),
        })
    end
    greetTitleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newGlow),
        ColorSequenceKeypoint.new(0.5, THEME.TEXT_HI),
        ColorSequenceKeypoint.new(1, newHot),
    })
    greetBodyGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newGlow),
        ColorSequenceKeypoint.new(0.4, THEME.TEXT_HI),
        ColorSequenceKeypoint.new(0.7, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    splitLine.BackgroundColor3 = newAccent
    splitGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    statusSectionLine.BackgroundColor3 = newHot
    statusSectionLabel.TextColor3 = newHot
    bannerStroke.Color = newAccent
    bannerGlow.Color = newGlow
    if S.BallESP.highlight then
        S.BallESP.highlight.FillColor = newAccent
        S.BallESP.highlight.OutlineColor = newHot
    end
    if S.BallESP.light then S.BallESP.light.Color = newAccent end
    if S.BallESP.trail then
        S.BallESP.trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newHot),
            ColorSequenceKeypoint.new(0.5, newAccent),
            ColorSequenceKeypoint.new(1, newGlow),
        })
    end
    if S.Pred.ring then S.Pred.ring.Color = newHot end
    if S.HitboxVisual.Sphere and not S.RangeGuard.Enabled then S.HitboxVisual.Sphere.Color = newAccent end
    for _, t in pairs(S.Tracers.Active) do
        if t.beam then t.beam.Color = ColorSequence.new(newHot) end
        if t.endPart then t.endPart.Color = newHot end
    end
    for _, el in ipairs(S.ColorSynced) do
        if el.Kind == "Toggle" then
            local on = el.GetState and el.GetState() or false
            if on then
                el.ToggleBg.BackgroundColor3 = newAccent
                el.ToggleStroke.Color = newHot
            else
                el.ToggleBg.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
                el.ToggleStroke.Color = THEME.LINE
            end
        elseif el.Kind == "Slider" then
            el.BarFill.BackgroundColor3 = newHot
            el.BarFillGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, newDark),
                ColorSequenceKeypoint.new(0.5, newHot),
                ColorSequenceKeypoint.new(1, newGlow),
            })
            el.ValueLabel.TextColor3 = newHot
            el.HandleGlow.Color = newHot
        elseif el.Kind == "StatTile" then
            el.Stroke.Color = newAccent
            el.InnerGlow.Color = newGlow
            el.Dot.BackgroundColor3 = newHot
            el.TopBar.BackgroundColor3 = newHot
            el.TopGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, newDark),
                ColorSequenceKeypoint.new(0.5, newHot),
                ColorSequenceKeypoint.new(1, newDark),
            })
            el.Value.TextColor3 = newHot
            el.ValueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, newDark),
                ColorSequenceKeypoint.new(0.5, newGlow),
                ColorSequenceKeypoint.new(1, newDark),
            })
        end
    end
    if colorSectionLine then colorSectionLine.BackgroundColor3 = newHot end
end

function ApplyAccentColor(color)
    local h, s, v = Color3.toHSV(color)
    local newAccent = Color3.fromHSV(h, math.clamp(s * 1.4, 0, 1), 1)
    local newHot = Color3.fromHSV(h, 1, 1)
    local newDark = Color3.fromHSV(h, math.clamp(s * 0.9, 0, 1), 0.55)
    local newGlow = Color3.fromHSV(h, math.clamp(s * 0.5, 0, 1), 1)
    ApplyAccent_Core(newAccent, newHot, newDark, newGlow)
    ApplyAccent_Header(newAccent, newHot, newDark, newGlow)
    ApplyAccent_UI(newAccent, newHot, newDark, newGlow)
    ApplyAccent_Elements(newAccent, newHot, newDark, newGlow)
    S.Purge.EyeColor = newHot
    S.Purge.SparkleColor = newGlow
end

local isDraggingColor = false

function UpdateColorFromPosition(inputPos)
    local center = paletteFrame.AbsolutePosition + paletteFrame.AbsoluteSize / 2
    local rel = Vector2.new(inputPos.X - center.X, inputPos.Y - center.Y)
    local radius = paletteFrame.AbsoluteSize.X / 2
    local dist = math.sqrt(rel.X * rel.X + rel.Y * rel.Y)
    local hue = (math.atan2(rel.Y, rel.X) / (math.pi * 2)) % 1
    local saturation = math.clamp(dist / radius, 0, 1)
    local boostedSat = math.clamp(math.sqrt(saturation) * 1.3, 0, 1)
    local pickedColor = Color3.fromHSV(hue, boostedSat, 1)
    local clampedDist = math.min(dist, radius)
    local nx = math.cos(hue * math.pi * 2) * clampedDist
    local ny = math.sin(hue * math.pi * 2) * clampedDist
    pickerDot.Position = UDim2.new(0.5, nx, 0.5, ny)
    ApplyAccentColor(pickedColor)
end

colorDragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingColor = true
        settingsPage.ScrollingEnabled = false
        UpdateColorFromPosition(input.Position)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingColor and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateColorFromPosition(input.Position)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isDraggingColor then
            isDraggingColor = false
            settingsPage.ScrollingEnabled = true
        end
    end
end)

resetColorBtn.MouseButton1Click:Connect(function()
    PlayTab()
    ApplyAccentColor(Color3.fromRGB(180, 80, 255))
    pickerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
end)

-- ====================================================================
-- ACTIONS
-- ====================================================================
CreateSection(settingsPage, "// ACTIONS", 750, Color3.fromRGB(255, 100, 120))

function MakeActionButton(text, yPos, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -50, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = color
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    btn.Parent = settingsPage
    btn.MouseButton1Click:Connect(function()
        PlayTab()
        onClick()
    end)
    return btn
end

MakeActionButton("Reset Settings", 785, Color3.fromRGB(255, 180, 100), function()
    if S.Toggles["Flying Dots"] then S.Toggles["Flying Dots"](true, true) end
    if S.Toggles["Sounds"] then S.Toggles["Sounds"](true, true) end
    if S.Toggles["Scan Line"] then S.Toggles["Scan Line"](true, true) end
    if S.Toggles["FPS Counter"] then S.Toggles["FPS Counter"](false, true) end
    if S.Toggles["Hitbox Expander"] then S.Toggles["Hitbox Expander"](false, true) end
    if S.Toggles["Ball ESP"] then S.Toggles["Ball ESP"](false, true) end
    if S.Toggles["Ball Predictor"] then S.Toggles["Ball Predictor"](false, true) end
    if S.Toggles["Player Tracers"] then S.Toggles["Player Tracers"](false, true) end
    if S.Toggles["Enemies Only"] then S.Toggles["Enemies Only"](false, true) end
    if S.Toggles["Range Guard"] then S.Toggles["Range Guard"](false, true) end
    if S.Toggles["Wipe Clothes"] then S.Toggles["Wipe Clothes"](false, true) end
    if S.Toggles["Purge Character"] then S.Toggles["Purge Character"](false, true) end
    if S.Toggles["Glow Eyes"] then S.Toggles["Glow Eyes"](true, true) end
    if S.Toggles["Sparkles"] then S.Toggles["Sparkles"](true, true) end
    if S.Toggles["Corpse Gray"] then S.Toggles["Corpse Gray"](true, true) end
    if S.Toggles["Remove Leg"] then S.Toggles["Remove Leg"](true, true) end
    if S.Sliders["Menu Scale"] then S.Sliders["Menu Scale"](100, true) end
    if S.Sliders["Corner Radius"] then S.Sliders["Corner Radius"](8, true) end
    if S.Sliders["Hitbox Size"] then S.Sliders["Hitbox Size"](30, true) end
    if S.Sliders["Guard Radius"] then S.Sliders["Guard Radius"](8, true) end
    if S.Sliders["Tracer Length"] then S.Sliders["Tracer Length"](25, true) end
    if S.Sliders["Field of View"] then S.Sliders["Field of View"](70, true) end
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = 70
    end
    S.ClothesWiper.Enabled = false
    S.ClothesWiper.Wiped = {}
    RestoreAllHitboxes()
    _DestroyHitboxVisual()
    _DestroyBallESP()
    UpdateHitboxHook()
    for player, _ in pairs(S.Tracers.Active) do
        _TracerDestroy(player)
    end
    if S.Tracers.Folder then pcall(function() S.Tracers.Folder:Destroy() end) S.Tracers.Folder = nil end
    FpsFrame.Visible = false
    TweenService:Create(MainScale, TweenInfo.new(0.2), {Scale = 1}):Play()
    RebuildDots()
    if ScanLine then ScanLine.Visible = true end
    ApplyAccentColor(Color3.fromRGB(180, 80, 255))
    pickerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
end)

MakeActionButton("Unload Script", 830, Color3.fromRGB(255, 80, 100), function()
    -- [FIX] П.3: чистим все коннекты, партиклы, трекеры
    _DestroyBallESP()
    _DestroyHitboxVisual()
    if S.Pred.ring then S.Pred.ring:Destroy() end
    for player, _ in pairs(S.Tracers.Active) do
        _TracerDestroy(player)
    end
    if S.Tracers.Folder then pcall(function() S.Tracers.Folder:Destroy() end) end
    -- чистим Purge
    for player, data in pairs(S.Purge.Tracked) do
        if data.conns then
            for _, c in ipairs(data.conns) do pcall(function() c:Disconnect() end) end
        end
        if data.pulseConn then pcall(function() data.pulseConn:Disconnect() end) end
        S.Purge.Tracked[player] = nil
    end
    -- все RunService коннекты
    for _, c in ipairs(S.Connections) do
        pcall(function() c:Disconnect() end)
    end
    S.Connections = {}
    _SkyCleanup()
    S.ClothesWiper.Enabled = false
    S.ClothesWiper.Wiped = {}
    RestoreAllHitboxes()
    local Hitbox = GetHitboxModule()
    if Hitbox and Hitbox.__VL_Hooked and Hitbox.__VL_OrigGet then
        Hitbox.get = Hitbox.__VL_OrigGet
    end
    pcall(function() ScreenGui:Destroy() end)
    pcall(function() LoadGui:Destroy() end)
    pcall(function() TabSound:Destroy() end)
    pcall(function() Sound:Destroy() end)
end)

MakeActionButton("Rejoin Server", 875, THEME.ACCENT_HOT, function()
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

-- ====================================================================
-- [FIX] П.3: UTRACK ПО ВЫХОДУ ИГРОКА
-- ====================================================================
Players.PlayerRemoving:Connect(function(player)
    -- Tracers
    if S.Tracers.Active[player] then
        _TracerDestroy(player)
    end
    -- ClothesWiper
    if S.ClothesWiper.Wiped then
        if player.Character then
            S.ClothesWiper.Wiped[player.Character] = nil
        end
    end
    -- Purge
    if S.Purge.Tracked[player] then
        local data = S.Purge.Tracked[player]
        if data.conns then
            for _, c in ipairs(data.conns) do pcall(function() c:Disconnect() end) end
        end
        if data.pulseConn then pcall(function() data.pulseConn:Disconnect() end) end
        S.Purge.Tracked[player] = nil
    end
end)

-- Периодическая зачистка мёртвых ссылок (раз в 30 сек)
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(30)
        -- Tracers
        for player, _ in pairs(S.Tracers.Active) do
            if not player or not player.Parent then
                _TracerDestroy(player)
            end
        end
        -- ClothesWiper
        for char, _ in pairs(S.ClothesWiper.Wiped) do
            if not char or not char.Parent then
                S.ClothesWiper.Wiped[char] = nil
            end
        end
        -- Purge
        for player, data in pairs(S.Purge.Tracked) do
            if not player or not player.Parent then
                if data.conns then
                    for _, c in ipairs(data.conns) do pcall(function() c:Disconnect() end) end
                end
                if data.pulseConn then pcall(function() data.pulseConn:Disconnect() end) end
                S.Purge.Tracked[player] = nil
            end
        end
    end
end)

-- ====================================================================
-- MAIN UPDATE LOOP
-- ====================================================================
task.spawn(function()
    while true do
        if not ScreenGui.Parent then
            task.wait(0.2)
        else
        if not S.BallESP.model or not S.BallESP.model.Parent or not S.BallESP.model.PrimaryPart then
            S.BallESP.model = _FindBall()
            if S.BallESP.model and Config.BallESPEnabled then
                _CreateBallESP(S.BallESP.model)
            end
        end
        local ball = S.BallESP.model
        if ball and ball.PrimaryPart then
            local ballPos = ball.PrimaryPart.Position
            if Config.BallESPEnabled then
                if not S.BallESP.highlight or not S.BallESP.highlight.Parent then
                    _CreateBallESP(ball)
                else
                    S.BallESP.highlight.Adornee = ball.PrimaryPart
                end
            else
                if S.BallESP.highlight then _DestroyBallESP() end
            end
            if Config.BallPredictorEnabled then
                local now = tick()
                if S.Pred.lastPos and S.Pred.lastTime then
                    local dt = now - S.Pred.lastTime
                    if dt > 0.001 then
                        local rawVel = (ballPos - S.Pred.lastPos) / dt
                        if S.Pred.smoothVel then
                            S.Pred.smoothVel = S.Pred.smoothVel:Lerp(rawVel, 0.12)
                        else
                            S.Pred.smoothVel = rawVel
                        end
                    end
                end
                S.Pred.lastPos = ballPos
                S.Pred.lastTime = now
                if S.Pred.smoothVel and S.Pred.smoothVel.Magnitude >= 0.5 then
                    local landing = _PredictLanding(ballPos, S.Pred.smoothVel)
                    if S.Pred.smoothLand then
                        S.Pred.smoothLand = S.Pred.smoothLand:Lerp(landing, 0.15)
                    else
                        S.Pred.smoothLand = landing
                    end
                    local fp = S.Pred.smoothLand
                    S.Pred.ring.CFrame = CFrame.new(fp.X, fp.Y + 0.05, fp.Z) * CFrame.Angles(0, 0, math.rad(90))
                    S.Pred.ring.Transparency = 0.3
                else
                    S.Pred.ring.Transparency = 1
                end
            else
                if S.Pred.ring then S.Pred.ring.Transparency = 1 end
            end
        else
            if S.BallESP.highlight then _DestroyBallESP() end
            if S.Pred.ring then S.Pred.ring.Transparency = 1 end
        end
        -- [FIX] П.5: единственный вызов _UpdateHitboxVisual
        pcall(_UpdateHitboxVisual, 0.03)
        pcall(_WiperUpdate)
        task.wait(0.03)
        end
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        if S.MegaHitbox.Enabled then
            pcall(ExpandAllHitboxTemplates)
        end
        task.wait(1)
    end
end)

-- [FIX] П.5: удалён дубликат "⚡ ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ СФЕРЫ ХИТБОКСА"

-- ====================================================================
-- DROP-IN
-- ====================================================================
task.spawn(function()
    task.wait(1.6)
    local dropTween = TweenService:Create(MainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -340, 0.5, -245)})
    dropTween:Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

task.wait(1.8)
Tabs["Main"].IsActive = true
ActiveTab = "Main"
TabPages["Main"].Visible = true
Tabs["Main"].Button.BackgroundColor3 = Color3.fromRGB(35, 22, 60)
Tabs["Main"].Button.BackgroundTransparency = 0
Tabs["Main"].Text.TextColor3 = THEME.TEXT_HI
Tabs["Main"].Index.TextColor3 = THEME.ACCENT_HOT
Tabs["Main"].Arrow.TextTransparency = 0
Tabs["Main"].Button.Size = UDim2.new(1, -6, 0, TabHeight + 2)
Tabs["Main"].Button.Position = UDim2.new(0, 3, 0, TabBaseY - 1)
Tabs["Main"].Accent.Size = UDim2.new(0, 4, 0, TabHeight - 8)

PageHeader.Visible = true
PageTitle.Text = "MAIN"
PageTitle.TextTransparency = 0
PageIndex.Text = "01"
PageIndex.TextTransparency = 0
AccentBar.BackgroundTransparency = 0
HeaderBaseLine.BackgroundTransparency = 0.7
HeaderRunner.BackgroundTransparency = 0
HeaderPulse.BackgroundTransparency = 0.6

print("[VL] Loaded v2.2: Purge Character + П.5 + П.3 fixed")
