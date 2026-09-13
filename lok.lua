-- ====================================================================
-- VOLLEYBALL LEGENDS - AGGRESSIVE SPORT EDITION (PREMIUM v1.6)
-- FIX: Guard работает через тот же хук, что Hitbox
-- FIX: Логи грузятся до создания GUI (обход task.spawn)
-- FIX: Sky DISABLE кнопка прозрачная, только текст
-- ====================================================================

task.spawn(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- ХУК PRELOADASYNC
-- ====================================================================
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
                        if parent == CG then skip = true; break end
                        parent = parent.Parent
                    end
                end)
                if not skip then table.insert(filtered, obj) end
            end
        end
        return oldPreloadAsync(self, filtered, callback)
    end)
end)

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

-- ====================================================================
-- ТЕМА И КОНФИГ
-- ====================================================================
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

local Reg = {
    Corner = {}, ColorSynced = {}, Sliders = {}, Toggles = {},
    Br = {}, Assets = { logo = nil, brand = nil, banner = nil },
}

local S = {
    BallESP = { model = nil, highlight = nil, particles = nil, light = nil, trail = nil, trailAtt0 = nil, trailAtt1 = nil },
    Pred = { ring = nil, lastPos = nil, lastTime = nil, smoothVel = nil, smoothLand = nil },
    HitboxVisual = { Sphere = nil, Radius = 0 },
    MegaHitbox = { Enabled = false, SizeMultiplier = 3, UpdateInterval = 0.05, ExpandedCount = 0 },
    RangeGuard = { Enabled = false, Radius = 8 },
    HitBlocker = { LastBlockTime = 0 },
    Tracers = { Enabled = false, Length = 25, OnlyEnemies = false, Folder = nil, Active = {} },
    ClothesWiper = { Enabled = false, Wiped = {} },
    Sky = { Current = nil, Connection = nil, Connections = {}, Objects = {}, Presets = {}, Buttons = {} },
}

-- ====================================================================
-- ФУНКЦИИ
-- ====================================================================
function RegisterCorner(uiCorner, baseRadius)
    table.insert(Reg.Corner, { Corner = uiCorner, BaseRadius = baseRadius or Config.CornerRadius })
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

-- ФИКС ЛОГОТИПОВ: синхронная загрузка ДО создания GUI
function LoadAssetSync(url, filename)
    if not (isfile and writefile) then return nil end
    local ok = downloadImage(url, filename)
    if not ok then return nil end
    return getAssetPath(filename)
end

Reg.Assets.logo = LoadAssetSync("https://i.ibb.co/RkDbPKvG/IMG-20260912-124847.jpg", "vl_logo.png")
Reg.Assets.brand = LoadAssetSync("https://i.ibb.co/WWDZY4jc/14289-removebg-preview.png", "vl_brand.png")
Reg.Assets.banner = LoadAssetSync("https://i.ibb.co/tMsVBqwG/IMG-20260828-160933.png", "vl_banner.png")

print("[VL] Logo:", Reg.Assets.logo and "OK" or "NIL")
print("[VL] Brand:", Reg.Assets.brand and "OK" or "NIL")
print("[VL] Banner:", Reg.Assets.banner and "OK" or "NIL")

-- ====================================================================
-- HITBOX MODULE HOOK (работает И для Hitbox, И для Guard)
-- ====================================================================
local HitboxModuleRef = nil

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
    
    local active = S.MegaHitbox.Enabled or S.RangeGuard.Enabled
    local mult = S.MegaHitbox.Enabled and S.MegaHitbox.SizeMultiplier or 1
    
    if active then
        if not Hitbox.__VL_Hooked then
            Hitbox.All = nil
            Hitbox.Hitboxes = {}
            local origGet = Hitbox.get
            Hitbox.__VL_OrigGet = origGet
            Hitbox.get = function(move)
                local result = origGet(move)
                if result and result.Size then
                    local m = S.MegaHitbox.Enabled and S.MegaHitbox.SizeMultiplier or 1
                    if m > 1 then
                        result.Size = Vector3.new(
                            result.Size.X * m,
                            result.Size.Y * m,
                            result.Size.Z * m
                        )
                    end
                end
                return result
            end
            Hitbox.__VL_Hooked = true
            print("[VL] Hitbox.get захукан (x" .. mult .. ")")
        end
    else
        if Hitbox.__VL_Hooked and Hitbox.__VL_OrigGet then
            Hitbox.get = Hitbox.__VL_OrigGet
            Hitbox.__VL_Hooked = nil
            Hitbox.__VL_OrigGet = nil
            print("[VL] Hitbox.get возвращён в оригинал")
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
        if hui then safeParent = hui; return true end
    end
    return false
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

local StatusContainer = Instance.new("Frame")
StatusContainer.Size = UDim2.new(0, 600, 0, 30)
StatusContainer.Position = UDim2.new(0.5, -300, 0, 165)
StatusContainer.BackgroundTransparency = 1
StatusContainer.ZIndex = 5
StatusContainer.Parent = LoadingContainer

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "// INITIALIZING"
StatusLabel.TextColor3 = THEME.ACCENT_HOT
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Code
StatusLabel.ZIndex = 6
StatusLabel.Parent = StatusContainer

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

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.7, 0, 1, 0)
RightPanel.Position = UDim2.new(0.3, 0, 0, 0)
RightPanel.BackgroundColor3 = THEME.BG_PANEL
RightPanel.BackgroundTransparency = 0.05
RightPanel.BorderSizePixel = 0
RightPanel.ClipsDescendants = true
RightPanel.ZIndex = 2
RightPanel.Parent = PanelHolder

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, 0)
Divider.Position = UDim2.new(0.3, -0.5, 0, 0)
Divider.BackgroundColor3 = THEME.ACCENT
Divider.BorderSizePixel = 0
Divider.ZIndex = 5
Divider.Parent = PanelHolder

local DividerGradient = Instance.new("UIGradient", Divider)
DividerGradient.Rotation = 90
DividerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
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
LogoImage.Image = Reg.Assets.logo or ""
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
LogoVersion.Text = "// FREE 1.6.0"
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

local HeaderBaseLine = Instance.new("Frame")
HeaderBaseLine.Size = UDim2.new(1, 0, 0, 2)
HeaderBaseLine.Position = UDim2.new(0, 0, 0, 45)
HeaderBaseLine.BackgroundColor3 = THEME.ACCENT_DARK
HeaderBaseLine.BackgroundTransparency = 0.7
HeaderBaseLine.BorderSizePixel = 0
HeaderBaseLine.ZIndex = 11
HeaderBaseLine.Parent = PageHeader

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
            if otherName ~= name and otherTab.IsActive then
                otherTab.IsActive = false
                local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
                TweenService:Create(otherTab.Button, ti, {Size = otherTab.OriginalSize, Position = otherTab.OriginalPos, BackgroundColor3 = THEME.BG_MID, BackgroundTransparency = 0.5}):Play()
                TweenService:Create(otherTab.Stroke, ti, {Color = THEME.LINE, Transparency = 0.3}):Play()
                TweenService:Create(otherTab.Text, ti, {TextColor3 = THEME.TEXT_MID}):Play()
                TweenService:Create(otherTab.Accent, ti, {Size = UDim2.new(0, 4, 0, 0)}):Play()
                TweenService:Create(otherTab.Index, ti, {TextColor3 = THEME.TEXT_LOW}):Play()
            end
        end
        for _, page in pairs(TabPages) do page.Visible = false end

        if Tabs[name].IsActive then
            Tabs[name].IsActive = false
            ActiveTab = nil
            return
        end

        Tabs[name].IsActive = true
        ActiveTab = name
        PageHeader.Visible = true
        PageTitle.Text = name:upper()
        PageIndex.Text = TabIndexes[i]
        TweenService:Create(tab, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, TabHeight + 2), Position = UDim2.new(0, 3, 0, TabBaseY - 1 + (order - 1) * TabSpacing), BackgroundColor3 = Color3.fromRGB(35, 22, 60), BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = THEME.ACCENT_HOT, Transparency = 0.3}):Play()
        TweenService:Create(textLabel, TweenInfo.new(0.2), {TextColor3 = THEME.TEXT_HI}):Play()
        TweenService:Create(tabAccent, TweenInfo.new(0.2), {Size = UDim2.new(0, 4, 0, TabHeight - 8)}):Play()
        TweenService:Create(tabIndex, TweenInfo.new(0.2), {TextColor3 = THEME.ACCENT_HOT}):Play()
        if TabPages[name] then TabPages[name].Visible = true end
    end)

    Tabs[name] = {
        Button = tab, Text = textLabel, Stroke = stroke, Accent = tabAccent,
        Index = tabIndex, IsActive = false,
        OriginalSize = UDim2.new(1, -20, 0, TabHeight),
        OriginalPos = UDim2.new(0, 10, 0, TabBaseY + (order - 1) * TabSpacing),
    }
    CreatePage(name)
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

local bannerImage = Instance.new("ImageLabel")
bannerImage.Size = UDim2.new(1, 0, 1, 0)
bannerImage.BackgroundTransparency = 1
bannerImage.Image = Reg.Assets.banner or ""
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
greetBody.Parent = greetFrame

local splitLine = Instance.new("Frame")
splitLine.Size = UDim2.new(1, 0, 0, 1)
splitLine.Position = UDim2.new(0, 0, 0, 162)
splitLine.BackgroundColor3 = THEME.ACCENT
splitLine.BorderSizePixel = 0
splitLine.BackgroundTransparency = 0.7
splitLine.ZIndex = 6
splitLine.Parent = mainPage

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

    statTiles[cfg.key] = { Value = tileValue }
end

task.spawn(function()
    local sessionStart = tick()
    local frameCount = 0
    local lastFpsTime = tick()
    RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)
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
BrandImage.Image = Reg.Assets.brand or ""
BrandImage.ScaleType = Enum.ScaleType.Fit
BrandImage.ZIndex = 11
BrandImage.Parent = BrandFrame
Instance.new("UICorner", BrandImage).CornerRadius = UDim.new(1, 0)

-- ====================================================================
-- COMBAT PAGE
-- ====================================================================
local combatPage = TabPages["Combat"]
combatPage.CanvasSize = UDim2.new(0, 0, 0, 500)

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

    return line
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

    Reg.Toggles[name] = SetState
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

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new(startPercent, -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = barBg
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

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

    Reg.Sliders[name] = SetValue
end

-- ====================================================================
-- BALL / HITBOX FUNCTIONS
-- ====================================================================
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

function _DestroyHitboxVisual()
    if S.HitboxVisual.Sphere then pcall(function() S.HitboxVisual.Sphere:Destroy() end) S.HitboxVisual.Sphere = nil end
end

function _CreateHitboxVisual()
    _DestroyHitboxVisual()
    local sphere = Instance.new("Part")
    sphere.Name = "VL_HitboxSphere"
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
    -- Сфера активна если ЛИБО Hitbox, ЛИБО Guard включены
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
    
    -- Размер сферы: если Hitbox включен — его множитель. Если только Guard — фиксированный
    local sizeMult = S.MegaHitbox.Enabled and S.MegaHitbox.SizeMultiplier or 3
    local desiredRadius = sizeMult * 1.2835
    S.HitboxVisual.Radius = S.HitboxVisual.Radius + (desiredRadius - S.HitboxVisual.Radius) * math.min(dt * 8, 1)

    local r = S.HitboxVisual.Radius
    local sphere = S.HitboxVisual.Sphere
    sphere.Size = Vector3.new(r * 2, r * 2, r * 2)
    sphere.CFrame = CFrame.new(ballPos)

    -- Цвет: если Guard включен — показываем зелёный/красный
    if S.RangeGuard.Enabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = (ballPos - char.HumanoidRootPart.Position).Magnitude
            if dist <= S.RangeGuard.Radius then
                sphere.Color = Color3.fromRGB(80, 255, 130)  -- зелёный — можно бить
                sphere.Transparency = 0.6
            else
                sphere.Color = Color3.fromRGB(255, 80, 80)  -- красный — нельзя
                sphere.Transparency = 0.75
            end
        else
            sphere.Color = Color3.fromRGB(255, 80, 80)
            sphere.Transparency = 0.75
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
    local mult = S.MegaHitbox.SizeMultiplier
    
    local function processFolder(folder)
        local assemblies = folder:FindFirstChild("Assemblies")
        if not assemblies then return end
        for _, assembly in ipairs(assemblies:GetChildren()) do
            local part = assembly:FindFirstChild("Part")
            if part then
                local orig = part:GetAttribute("VL_OrigSize") or part.Size
                part:SetAttribute("VL_OrigSize", orig)
                part.Size = orig * mult
                count = count + 1
            end
        end
    end
    
    local defaultFolder = HitboxesNew:FindFirstChild("Default")
    if defaultFolder then processFolder(defaultFolder) end
    
    local bySpecial = HitboxesNew:FindFirstChild("BySpecial")
    if bySpecial then
        for _, special in ipairs(bySpecial:GetChildren()) do
            processFolder(special)
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
-- HIT BLOCKER (Guard)
-- ====================================================================
function _IsBallInGuardRange()
    if not S.RangeGuard.Enabled then return true end
    local ball = _FindBall()
    if not ball or not ball.PrimaryPart then return true end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return true end
    local dist = (ball.PrimaryPart.Position - char.HumanoidRootPart.Position).Magnitude
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
    end, false, 100, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
end)

-- ====================================================================
-- COMBAT PAGE UI
-- ====================================================================
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
        -- Включаем тот же хук что и Hitbox
        UpdateHitboxHook()
        if not S.HitboxVisual.Sphere then
            _CreateHitboxVisual()
        end
        print("[VL] Range Guard ENABLED | radius " .. S.RangeGuard.Radius)
    else
        UpdateHitboxHook()
        if not S.MegaHitbox.Enabled then
            _DestroyHitboxVisual()
            RestoreAllHitboxes()
        end
        print("[VL] Range Guard DISABLED")
    end
end)

CreateSlider(combatPage, "Guard Radius", "Distance limit in studs", 215, 3, 30, 8, " studs", function(v)
    S.RangeGuard.Radius = v
end)

-- ====================================================================
-- MAIN UPDATE LOOP (обновление сферы + Guard)
-- ====================================================================
task.spawn(function()
    while ScreenGui.Parent do
        pcall(_UpdateHitboxVisual, 0.03)
        task.wait(0.03)
    end
end)

-- ====================================================================
-- VISUALS PAGE
-- ====================================================================
local visualsPage = TabPages["Visuals"]
visualsPage.CanvasSize = UDim2.new(0, 0, 0, 300)

CreateSection(visualsPage, "// CAMERA", 10, Color3.fromRGB(120, 220, 255))

CreateSlider(visualsPage, "Field of View", "Camera zoom out angle (70 - 200)", 40, 70, 200, Config.FOV, "deg", function(v)
    Config.FOV = v
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = v
    end
end)

-- ====================================================================
-- SKY PAGE
-- ====================================================================
local skyPage = TabPages["Sky"]
skyPage.CanvasSize = UDim2.new(0, 0, 0, 480)

CreateSection(skyPage, "// SKY PRESETS", 8, THEME.ACCENT)

local skyListY = 44
local skyButtons = {}

function CreateSkyButton(preset, yPos, index)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, -8, 0, 42)
    card.Position = UDim2.new(0, 4, 0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(18, 13, 28)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.ZIndex = 5
    card.Parent = skyPage
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 1
    cardStroke.Color = THEME.ACCENT_DARK
    cardStroke.Transparency = 0.55

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 2, 1, -12)
    accent.Position = UDim2.new(0, 0, 0, 6)
    accent.BackgroundColor3 = THEME.ACCENT_DARK
    accent.BorderSizePixel = 0
    accent.ZIndex = 6
    accent.Parent = card
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local idxLabel = Instance.new("TextLabel")
    idxLabel.Size = UDim2.new(0, 24, 1, 0)
    idxLabel.Position = UDim2.new(0, 12, 0, 0)
    idxLabel.BackgroundTransparency = 1
    idxLabel.Text = string.format("%02d", index)
    idxLabel.TextColor3 = THEME.TEXT_LOW
    idxLabel.TextSize = 11
    idxLabel.Font = Enum.Font.Code
    idxLabel.TextXAlignment = Enum.TextXAlignment.Left
    idxLabel.ZIndex = 7
    idxLabel.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 40, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = preset.name:upper()
    nameLabel.TextColor3 = THEME.TEXT_HI
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 7
    nameLabel.Parent = card

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0.42, 0, 0.5, -2)
    dot.BackgroundColor3 = THEME.ACCENT_HOT
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.ZIndex = 8
    dot.Parent = card
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 64, 0, 24)
    applyBtn.Position = UDim2.new(1, -74, 0.5, -12)
    applyBtn.BackgroundColor3 = Color3.fromRGB(28, 18, 42)
    applyBtn.BackgroundTransparency = 0.1
    applyBtn.Text = "APPLY"
    applyBtn.TextColor3 = THEME.ACCENT_HOT
    applyBtn.TextSize = 10
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.AutoButtonColor = false
    applyBtn.ZIndex = 7
    applyBtn.Parent = card
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 5)

    local applyStroke = Instance.new("UIStroke", applyBtn)
    applyStroke.Thickness = 1
    applyStroke.Color = THEME.ACCENT
    applyStroke.Transparency = 0.4

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 17, 36)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.15), {Transparency = 0.25}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 13, 28)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.15), {Transparency = 0.55}):Play()
    end)

    applyBtn.MouseEnter:Connect(function()
        TweenService:Create(applyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    applyBtn.MouseLeave:Connect(function()
        TweenService:Create(applyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)

    applyBtn.MouseButton1Click:Connect(function()
        PlayTab()
        preset.func()
        for _, b in ipairs(skyButtons) do
            b.dot.BackgroundTransparency = 1
            TweenService:Create(b.accent, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ACCENT_DARK}):Play()
        end
        dot.BackgroundTransparency = 0
        TweenService:Create(accent, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ACCENT_HOT}):Play()
    end)

    table.insert(skyButtons, { card = card, dot = dot, accent = accent })
end

for i, preset in ipairs(S.Sky.Presets) do
    CreateSkyButton(preset, skyListY + (i - 1) * 48, i)
end

-- ⚡ DISABLE SKY: без фона, только текст
local disableY = skyListY + #S.Sky.Presets * 48 + 14

local disableBtn = Instance.new("TextButton")
disableBtn.Size = UDim2.new(1, -8, 0, 28)
disableBtn.Position = UDim2.new(0, 4, 0, disableY)
disableBtn.BackgroundTransparency = 1  -- ⚡ БЕЗ ФОНА
disableBtn.Text = "DISABLE SKY"
disableBtn.TextColor3 = Color3.fromRGB(255, 100, 120)
disableBtn.TextSize = 11
disableBtn.Font = Enum.Font.GothamBold
disableBtn.AutoButtonColor = false
disableBtn.Parent = skyPage

disableBtn.MouseEnter:Connect(function()
    TweenService:Create(disableBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 150, 150)}):Play()
end)
disableBtn.MouseLeave:Connect(function()
    TweenService:Create(disableBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 100, 120)}):Play()
end)

disableBtn.MouseButton1Click:Connect(function()
    PlayTab()
    for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
            pcall(function() obj:Destroy() end)
        end
    end
    game:GetService("Lighting").Ambient = Color3.fromRGB(70, 70, 70)
    game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    game:GetService("Lighting").Brightness = 2
    game:GetService("Lighting").ClockTime = 14
    for _, b in ipairs(skyButtons) do
        b.dot.BackgroundTransparency = 1
        TweenService:Create(b.accent, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ACCENT_DARK}):Play()
    end
end)

-- ====================================================================
-- DROP-IN
-- ====================================================================
task.spawn(function()
    task.wait(1.6)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -340, 0.5, -245)}):Play()
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

print("[VL] Loaded v1.7 FINAL")

end) -- конец task.spawn
