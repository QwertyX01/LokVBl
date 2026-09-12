-- ====================================================================
-- VOLLEYBALL LEGENDS - AGGRESSIVE SPORT EDITION (PREMIUM LOADING)
-- + COLOR PICKER + FULL ACCENT SYNC + CORNER RADIUS
-- ====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ЗАЩИТА
do
    local ok = pcall(function()
        local ContentProvider = game:GetService("ContentProvider")
        local CG = game:GetService("CoreGui")
        local oldPreloadAsync = ContentProvider.PreloadAsync

        hookfunction(ContentProvider.PreloadAsync, function(self, instances, callback)
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
        print("[VL] PreloadAsync hook installed")
    end)
end

for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name == "VL_Menu" or gui.Name == "VL_Panel" or gui.Name == "VL_ESP" or gui.Name == "VL_Load" or gui.Name == "RobloxGui" then
        pcall(function() gui:Destroy() end)
    end
end

local THEME = {
    BG_DARK       = Color3.fromRGB(8, 6, 14),
    BG_MID        = Color3.fromRGB(14, 11, 22),
    BG_PANEL      = Color3.fromRGB(11, 9, 18),
    BG_LEFT       = Color3.fromRGB(18, 14, 28),
    ACCENT        = Color3.fromRGB(180, 80, 255),
    ACCENT_DARK   = Color3.fromRGB(80, 40, 150),
    ACCENT_GLOW   = Color3.fromRGB(220, 150, 255),
    ACCENT_SOFT   = Color3.fromRGB(130, 70, 200),
    ACCENT_HOT    = Color3.fromRGB(255, 60, 180),
    TEXT_HI       = Color3.fromRGB(245, 240, 255),
    TEXT_MID      = Color3.fromRGB(170, 155, 200),
    TEXT_LOW      = Color3.fromRGB(90, 75, 115),
    LINE          = Color3.fromRGB(50, 35, 75),
}

local Config = {
    FlyingDotsEnabled = true,
    SoundEnabled = true,
    ScanLineEnabled = true,
    FpsCounterEnabled = false,
    MenuScale = 100,
    CornerRadius = 8,
    Dots = {},
}

-- Реестры для программного управления из Reset Settings
local CornerElements = {}
local ColorSyncedElements = {}
local SliderRegistry = {}   -- name -> SetValue(val)
local ToggleRegistry = {}   -- name -> SetState(val)

local function RegisterCorner(uiCorner, baseRadius)
    table.insert(CornerElements, {
        Corner = uiCorner,
        BaseRadius = baseRadius or Config.CornerRadius,
    })
end

local function fileExists(path)
    local ok, res = pcall(function() return loadfile(path) end)
    return ok and res ~= nil
end

local function downloadImage(url, path)
    if isfile and isfile(path) then
        pcall(function() delfile(path) end)
    end
    if not fileExists(path) then
        local ok, content = pcall(function() return game:HttpGet(url, true) end)
        if ok and content then pcall(function() writefile(path, content) end) end
    end
end

local function getAssetPath(path)
    if getcustomasset then return getcustomasset(path)
    elseif getgenv and getgenv().getcustomasset then return getgenv().getcustomasset(path) end
    return nil
end

downloadImage("https://i.ibb.co/RkDbPKvG/IMG-20260912-124847.jpg", "vl_logo.png")
local logoPath = getAssetPath("vl_logo.png")

downloadImage("https://i.ibb.co/WWDZY4jc/14289-removebg-preview.png", "vl_brand.png")
local brandPath = getAssetPath("vl_brand.png")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RobloxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 0
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local safeParent = CoreGui
pcall(function() if gethui then safeParent = gethui() end end)
pcall(function() ScreenGui.Parent = safeParent end)
pcall(function()
    sethiddenproperty(ScreenGui, "RobloxLocked", true)
    sethiddenproperty(ScreenGui, "Archivable", false)
end)

local CG_REF = CoreGui
local PG_REF = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local HIDDEN_NAMES = { ["RobloxGui"]=true, ["VL_Menu"]=true, ["VL_Load"]=true }

pcall(function()
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

local function PlayTab() if Config.SoundEnabled then pcall(function() TabSound:Play() end) end end

-- ====================================================================
-- PREMIUM LOADING SCREEN
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
GlitchContainer.Position = UDim2.new(0, 0, 0, 0)
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
        for i = -1, 1, 0.02 do
            GlitchGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
        for i = 1, -1, -0.02 do
            GlitchGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
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

local BarInnerGlow = Instance.new("Frame")
BarInnerGlow.Size = UDim2.new(1, -4, 1, -4)
BarInnerGlow.Position = UDim2.new(0, 2, 0, 2)
BarInnerGlow.BackgroundColor3 = THEME.ACCENT_DARK
BarInnerGlow.BackgroundTransparency = 0.9
BarInnerGlow.BorderSizePixel = 0
BarInnerGlow.ZIndex = 7
BarInnerGlow.Parent = BarBg
Instance.new("UICorner", BarInnerGlow).CornerRadius = UDim.new(1, 0)

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
BarFillGradient.Rotation = 0

task.spawn(function()
    while LoadGui.Parent do
        for i = -1, 1, 0.04 do
            BarFillGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
        for i = 1, -1, -0.04 do
            BarFillGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
    end
end)

local BarFillGlow = Instance.new("UIStroke", BarFill)
BarFillGlow.Thickness = 3
BarFillGlow.Color = THEME.ACCENT_GLOW
BarFillGlow.Transparency = 0.5

task.spawn(function()
    while LoadGui.BarFill and LoadGui.Parent do
        TweenService:Create(BarFillGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2}):Play()
        task.wait(0.8)
        TweenService:Create(BarFillGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6}):Play()
        task.wait(0.8)
    end
end)

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
StatusLabel.TextTransparency = 0
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
            TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0.1, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, (i-1) * 14 - 1, 0, 0)}):Play()
            task.wait(0.25)
            TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, (i-1) * 14, 0, 1)}):Play()
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    while LoadGui.Parent do
        for i = -1, 1, 0.03 do
            StatusGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
        for i = 1, -1, -0.03 do
            StatusGradient.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
    end
end)

local StatusPhrases = {
    {time = 0.0, text = "// INITIALIZATION"},
    {time = 0.5, text = "// LOADING MODULES"},
    {time = 1.2, text = "// WAIT"},
    {time = 1.8, text = "// JUST A LITTLE MORE"},
    {time = 2.4, text = "// FINALIZING"},
}

local Sound = Instance.new("Sound")
Sound.SoundId = "rbxassetid://136508094734046"
Sound.Volume = 1
Sound.Parent = SoundService

task.spawn(function()
    task.wait(0.2)
    for _, phrase in ipairs(StatusPhrases) do
        task.wait(phrase.time == 0 and 0 or (StatusPhrases[#StatusPhrases - 1] and 0.4 or 0.4))
        if not LoadGui.Parent then break end
        StatusLabel.Text = phrase.text
        StatusLabel.TextTransparency = 1
        TweenService:Create(StatusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end
end)

task.spawn(function()
    task.wait(0.3)
    local totalTime = 2.6
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
            TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        elseif obj:IsA("Frame") then
            TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        elseif obj:IsA("UIStroke") then
            TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
        end
    end

    task.wait(0.5)
    LoadGui:Destroy()
    pcall(function() Sound:Play() end)
end)

-- ====================================================================
-- ГЛАВНАЯ ПАНЕЛЬ
-- ====================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 490)
MainFrame.Position = UDim2.new(0.5, -340, -1, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = false
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
MainStroke.Transparency = 0.3
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

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

local RightGradient = Instance.new("UIGradient", RightPanel)
RightGradient.Rotation = 135
RightGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 12, 26)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 14)),
})

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
Divider.Size = UDim2.new(0, 2, 1, 0)
Divider.Position = UDim2.new(0.3, -1, 0, 0)
Divider.BackgroundColor3 = THEME.ACCENT
Divider.BorderSizePixel = 0
Divider.ZIndex = 5
Divider.Parent = PanelHolder
Divider.BackgroundTransparency = 0.4

local DividerGradient = Instance.new("UIGradient", Divider)
DividerGradient.Rotation = 90
DividerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_DARK),
    ColorSequenceKeypoint.new(0.5, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT_DARK),
})

-- ЛОГОТИП
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
LogoBadge.BorderSizePixel = 0
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
LogoVersion.Text = "// FREE 1.0.0"
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

-- HEADER
local PageHeader = Instance.new("Frame")
PageHeader.Size = UDim2.new(1, 0, 0, 55)
PageHeader.BackgroundTransparency = 1
PageHeader.ZIndex = 10
PageHeader.Parent = RightPanel
PageHeader.Visible = false

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 4, 0, 22)
AccentBar.Position = UDim2.new(0, 20, 0, 16)
AccentBar.BackgroundColor3 = THEME.ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 11
AccentBar.Parent = PageHeader
Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 1)

local AccentGradient = Instance.new("UIGradient", AccentBar)
AccentGradient.Rotation = 90
AccentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ACCENT_HOT),
    ColorSequenceKeypoint.new(1, THEME.ACCENT),
})

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
PageTitle.Size = UDim2.new(1, -100, 0, 22)
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
        local t = TweenService:Create(HeaderRunner, TweenInfo.new(1.6, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1, 0, 0, 45)
        })
        t:Play()
        t.Completed:Wait()
        task.wait(0.3)
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(HeaderPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.15}):Play()
        task.wait(0.6)
        TweenService:Create(HeaderPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.85}):Play()
        task.wait(0.6)
    end
end)

-- ====================================================================
-- ВКЛАДКИ
-- ====================================================================
local TabNames = {"Main", "Visuals", "Combat", "Settings"}
local TabIndexes = { "01", "02", "03", "04" }
local Tabs = {}
local TabPages = {}
local ActiveTab = nil
local TabBaseY = 100
local TabHeight = 42
local TabSpacing = 48

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -30, 1, -80)
    page.Position = UDim2.new(0, 15, 0, 65)
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
            for j = -1, 1, 0.05 do
                tabAccentGradient.Offset = Vector2.new(0, j)
                task.wait(0.05)
            end
            for j = 1, -1, -0.05 do
                tabAccentGradient.Offset = Vector2.new(0, j)
                task.wait(0.05)
            end
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

    local function AnimateTo(size, pos, bgColor, bgTrans, strokeColor, strokeTrans, textColor, accentSize, arrowTrans, indexColor)
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(tab, ti, {Size=size, Position=pos, BackgroundColor3=bgColor, BackgroundTransparency=bgTrans}):Play()
        TweenService:Create(stroke, ti, {Color=strokeColor, Transparency=strokeTrans}):Play()
        TweenService:Create(textLabel, ti, {TextColor3=textColor}):Play()
        TweenService:Create(tabAccent, ti, {Size = UDim2.new(0, 4, 0, accentSize)}):Play()
        TweenService:Create(arrow, ti, {TextTransparency = arrowTrans}):Play()
        TweenService:Create(tabIndex, ti, {TextColor3 = indexColor}):Play()
    end

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
        local sizeNow = tab.Size
        TweenService:Create(tab, TweenInfo.new(0.08), {Size = UDim2.new(sizeNow.X.Scale, sizeNow.X.Offset - 4, 0, sizeNow.Y.Offset)}):Play()
        task.delay(0.08, function()
            TweenService:Create(tab, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = sizeNow}):Play()
        end)

        for otherName, otherTab in pairs(Tabs) do
            if otherName ~= name and otherTab.IsActive then
                otherTab.IsActive = false
                local oT, oS, oX, oA, oAr, oI = otherTab.Button, otherTab.Stroke, otherTab.Text, otherTab.Accent, otherTab.Arrow, otherTab.Index
                local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                TweenService:Create(oT, ti, {Size = otherTab.OriginalSize, Position = otherTab.OriginalPos, BackgroundColor3 = THEME.BG_MID, BackgroundTransparency = 0.5}):Play()
                TweenService:Create(oS, ti, {Color = THEME.LINE, Transparency = 0.3}):Play()
                TweenService:Create(oX, ti, {TextColor3 = THEME.TEXT_MID}):Play()
                TweenService:Create(oA, ti, {Size = UDim2.new(0, 4, 0, 0)}):Play()
                TweenService:Create(oAr, ti, {TextTransparency = 1}):Play()
                TweenService:Create(oI, ti, {TextColor3 = THEME.TEXT_LOW}):Play()
            end
        end

        for _, page in pairs(TabPages) do page.Visible = false end

        if Tabs[name].IsActive then
            Tabs[name].IsActive = false
            AnimateTo(originalSize, originalPos, THEME.BG_MID, 0.5, THEME.LINE, 0.3, THEME.TEXT_MID, 0, 1, THEME.TEXT_LOW)
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

        AnimateTo(activeSize, activePos, Color3.fromRGB(35, 22, 60), 0, THEME.ACCENT_HOT, 0.3, THEME.TEXT_HI, TabHeight - 8, 0, THEME.ACCENT_HOT)
        if TabPages[name] then TabPages[name].Visible = true end
    end)

    Tabs[name] = {
        Button = tab, Text = textLabel, Stroke = stroke, Accent = tabAccent,
        Arrow = arrow, Index = tabIndex,
        AccentGradient = tabAccentGradient,
        IsActive = false,
        OriginalSize = originalSize, OriginalPos = originalPos,
        ActiveSize = activeSize, ActivePos = activePos,
    }
    CreatePage(name)
end

-- ====================================================================
-- DRAG HANDLE
-- ====================================================================
local DragHandle = Instance.new("Frame")
DragHandle.Size = UDim2.new(0, 60, 0, 60)
DragHandle.Position = UDim2.new(1, -60, 0, 0)
DragHandle.BackgroundTransparency = 1
DragHandle.BorderSizePixel = 0
DragHandle.ZIndex = 250
DragHandle.Parent = MainFrame

local DragCursor = Instance.new("ImageLabel")
DragCursor.Size = UDim2.new(0, 32, 0, 32)
DragCursor.Position = UDim2.new(0.5, -16, 0.5, -16)
DragCursor.BackgroundTransparency = 1
DragCursor.Image = "rbxassetid://92981589608159"
DragCursor.ImageColor3 = THEME.ACCENT_GLOW
DragCursor.ImageTransparency = 0.2
DragCursor.ZIndex = 251
DragCursor.Parent = DragHandle

task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(DragCursor, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.5}):Play()
        task.wait(1.2)
        TweenService:Create(DragCursor, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.2}):Play()
        task.wait(1.2)
    end
end)

local DragButton = Instance.new("TextButton")
DragButton.Size = UDim2.new(1, 20, 1, 20)
DragButton.Position = UDim2.new(0.5, -30, 0.5, -30)
DragButton.BackgroundTransparency = 1
DragButton.Text = ""
DragButton.ZIndex = 252
DragButton.Parent = DragHandle

DragButton.MouseEnter:Connect(function()
    TweenService:Create(DragCursor, TweenInfo.new(0.2), {ImageTransparency = 0, ImageColor3 = THEME.ACCENT_HOT}):Play()
end)
DragButton.MouseLeave:Connect(function()
    if not isDraggingMenu then
        TweenService:Create(DragCursor, TweenInfo.new(0.2), {ImageColor3 = THEME.ACCENT_GLOW}):Play()
    end
end)

local isDraggingMenu = false
local dragStartMouse = Vector2.new(0, 0)
local dragStartFrame = UDim2.new(0, 0, 0, 0)

DragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMenu = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartFrame = MainFrame.Position
        TweenService:Create(DragCursor, TweenInfo.new(0.15), {ImageTransparency = 0}):Play()
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
        isDraggingMenu = false
        TweenService:Create(DragCursor, TweenInfo.new(0.2), {ImageTransparency = 0.2}):Play()
    end
end)

-- ====================================================================
-- АВАТАР + БРЕНД
-- ====================================================================
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size = UDim2.new(0, 50, 0, 50)
AvatarFrame.Position = UDim2.new(0, 10, 1, -64)
AvatarFrame.BackgroundColor3 = THEME.BG_MID
AvatarFrame.BackgroundTransparency = 0.2
AvatarFrame.BorderSizePixel = 0
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
BrandFrame.BorderSizePixel = 0
BrandFrame.ZIndex = 10
BrandFrame.Parent = LeftPanel
Instance.new("UICorner", BrandFrame).CornerRadius = UDim.new(1, 0)

local BrandImage = Instance.new("ImageLabel")
BrandImage.Size = UDim2.new(1, -4, 1, -4)
BrandImage.Position = UDim2.new(0, 2, 0, 2)
BrandImage.BackgroundTransparency = 1
BrandImage.Image = brandPath or ""
BrandImage.ScaleType = Enum.ScaleType.Fit
BrandImage.ZIndex = 11
BrandImage.Parent = BrandFrame
Instance.new("UICorner", BrandImage).CornerRadius = UDim.new(1, 0)

-- ====================================================================
-- FPS COUNTER
-- ====================================================================
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
        for i = -1, 1, 0.02 do
            FpsGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
        for i = 1, -1, -0.02 do
            FpsGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
    end
end)

task.spawn(function()
    local frames = 0
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastTime >= 1 then
            FpsLabel.Text = "FPS " .. tostring(math.floor(frames / (now - lastTime)))
            frames = 0
            lastTime = now
        end
    end)
end)

-- ====================================================================
-- ИСКРЫ
-- ====================================================================
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
            MaxX = w, MaxY = h,
        })
    end
end

local function UpdateDots()
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

-- ====================================================================
-- СВЕТЯЩАЯСЯ ТОЧКА
-- ====================================================================
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
        for i = -1, 1, 0.01 do
            DotGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
        for i = 1, -1, -0.01 do
            DotGradient.Offset = Vector2.new(i, 0)
            task.wait(0.04)
        end
    end
end)

-- ====================================================================
-- SCAN LINE
-- ====================================================================
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
            ScanLine.BackgroundTransparency = 0.5
            local t = TweenService:Create(ScanLine, TweenInfo.new(1.8, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0, 0, 1, 0)
            })
            t:Play()
            t.Completed:Wait()
            task.wait(2)
        else
            ScanLine.Visible = false
            task.wait(0.5)
        end
    end
end)

-- ====================================================================
-- ПУЛЬСАЦИЯ ОБВОДОК
-- ====================================================================
task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(LogoBadgeGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.3}):Play()
        TweenService:Create(MainStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.15}):Play()
        TweenService:Create(AvatarGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.75}):Play()
        task.wait(0.8)
        TweenService:Create(LogoBadgeGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.75}):Play()
        TweenService:Create(MainStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.5}):Play()
        TweenService:Create(AvatarGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.95}):Play()
        task.wait(0.8)
    end
end)

-- ====================================================================
-- SETTINGS
-- ====================================================================
local settingsPage = TabPages["Settings"]
settingsPage.CanvasSize = UDim2.new(0, 0, 0, 1080)

local function CreateSection(parent, title, yPos, color)
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

local function CreateToggle(parent, name, descText, yPos, default, callback)
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
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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

    table.insert(ColorSyncedElements, {
        Kind = "Toggle",
        ToggleBg = toggleBg,
        ToggleStroke = toggleStroke,
        GetState = function() return state end,
    })

    ToggleRegistry[name] = SetState
end

local function CreateSlider(parent, name, descText, yPos, minVal, maxVal, default, suffix, callback)
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
        ColorSequenceKeypoint.new(1, THEME.ACCENT_HOT),
    })

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
        local p = (val - minVal) / (maxVal - minVal)
        if animate then
            TweenService:Create(barFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(p, 0, 1, 0)}):Play()
            TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(p, -7, 0.5, -7)}):Play()
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
        local val = minVal + percent * (maxVal - minVal)
        SetValue(val, false)
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

    table.insert(ColorSyncedElements, {
        Kind = "Slider",
        BarFill = barFill,
        BarFillGradient = barFillGradient,
        ValueLabel = valueLabel,
        HandleGlow = handleGlow,
    })

    SliderRegistry[name] = SetValue
end

-- ====================================================================
-- СЕКЦИЯ INTERFACE
-- ====================================================================
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

CreateToggle(settingsPage, "FPS Counter", "Show FPS in left panel", 205, Config.FpsCounterEnabled, function(v)
    Config.FpsCounterEnabled = v
    FpsFrame.Visible = v
end)

-- ====================================================================
-- СЕКЦИЯ LAYOUT
-- ====================================================================
CreateSection(settingsPage, "// LAYOUT", 275, THEME.ACCENT_HOT)

CreateSlider(settingsPage, "Menu Scale", "Resize the whole menu proportionally", 305, 70, 130, 100, "%", function(v)
    Config.MenuScale = v
    TweenService:Create(MainScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = v / 100}):Play()
end)

CreateSlider(settingsPage, "Corner Radius", "Round corners of all panels and buttons", 365, 0, 16, 8, "px", function(v)
    Config.CornerRadius = v
    for _, el in ipairs(CornerElements) do
        local base = el.BaseRadius or 8
        local offset = el.Corner.Parent == OuterBorder and 0
                    or el.Corner.Parent == PanelHolder and -2
                    or 0
        local target = math.max(0, v + offset)
        TweenService:Create(el.Corner, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CornerRadius = UDim.new(0, target)
        }):Play()
    end
end)

-- ====================================================================
-- СЕКЦИЯ COLOR
-- ====================================================================
local colorSectionLine = CreateSection(settingsPage, "// COLOR", 445, Color3.fromRGB(120, 220, 255))

local paletteSize = 140
local paletteFrame = Instance.new("Frame")
paletteFrame.Size = UDim2.new(0, paletteSize, 0, paletteSize)
paletteFrame.Position = UDim2.new(0, 0, 0, 475)
paletteFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
paletteFrame.BorderSizePixel = 0
paletteFrame.Parent = settingsPage
local paletteCorner = Instance.new("UICorner", paletteFrame)
paletteCorner.CornerRadius = UDim.new(1, 0)  -- круглая, не регистрируем

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
pickerDot.BorderSizePixel = 0
pickerDot.ZIndex = 5
pickerDot.Parent = paletteFrame
Instance.new("UICorner", pickerDot).CornerRadius = UDim.new(1, 0)

local pickerDotStroke = Instance.new("UIStroke", pickerDot)
pickerDotStroke.Thickness = 2
pickerDotStroke.Color = Color3.fromRGB(0, 0, 0)
pickerDotStroke.Transparency = 0

local previewBox = Instance.new("Frame")
previewBox.Size = UDim2.new(0, 60, 0, 60)
previewBox.Position = UDim2.new(0, paletteSize + 20, 0, 475 + (paletteSize - 60) / 2 - 30)
previewBox.BackgroundColor3 = THEME.ACCENT
previewBox.BorderSizePixel = 0
previewBox.Parent = settingsPage
local previewCorner = Instance.new("UICorner", previewBox)
previewCorner.CornerRadius = UDim.new(0, 6)
RegisterCorner(previewCorner, 6)

local previewStroke = Instance.new("UIStroke", previewBox)
previewStroke.Thickness = 1.5
previewStroke.Color = THEME.ACCENT_HOT
previewStroke.Transparency = 0.4

local hexLabel = Instance.new("TextLabel")
hexLabel.Size = UDim2.new(0, 80, 0, 18)
hexLabel.Position = UDim2.new(0, paletteSize + 20, 0, 475 + (paletteSize - 60) / 2 + 38)
hexLabel.BackgroundTransparency = 1
hexLabel.Text = "#B450FF"
hexLabel.TextColor3 = THEME.TEXT_HI
hexLabel.TextSize = 12
hexLabel.Font = Enum.Font.Code
hexLabel.TextXAlignment = Enum.TextXAlignment.Left
hexLabel.Parent = settingsPage

local resetColorBtn = Instance.new("TextButton")
resetColorBtn.Size = UDim2.new(1, -50, 0, 32)
resetColorBtn.Position = UDim2.new(0, 0, 0, 475 + paletteSize + 15)
resetColorBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
resetColorBtn.BackgroundTransparency = 1
resetColorBtn.BorderSizePixel = 0
resetColorBtn.Text = "Reset Color"
resetColorBtn.TextColor3 = Color3.fromRGB(120, 220, 255)
resetColorBtn.TextSize = 13
resetColorBtn.Font = Enum.Font.Gotham
resetColorBtn.AutoButtonColor = false
resetColorBtn.Parent = settingsPage
local resetColorCorner = Instance.new("UICorner", resetColorBtn)
resetColorCorner.CornerRadius = UDim.new(0, 6)
RegisterCorner(resetColorCorner, 6)

local resetStroke = Instance.new("UIStroke", resetColorBtn)
resetStroke.Thickness = 1
resetStroke.Color = Color3.fromRGB(120, 220, 255)
resetStroke.Transparency = 1

resetColorBtn.MouseEnter:Connect(function()
    TweenService:Create(resetColorBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
    TweenService:Create(resetStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
end)
resetColorBtn.MouseLeave:Connect(function()
    TweenService:Create(resetColorBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(resetStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
end)

local dragArea = Instance.new("TextButton")
dragArea.Size = UDim2.new(1, 0, 1, 0)
dragArea.Position = UDim2.new(0, 0, 0, 0)
dragArea.BackgroundTransparency = 1
dragArea.Text = ""
dragArea.ZIndex = 10
dragArea.Parent = paletteFrame

-- ====================================================================
-- APPLY ACCENT COLOR
-- ====================================================================
local function ColorToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

local function ApplyAccentColor(color)
    local h, s, v = Color3.toHSV(color)
    v = 1
    s = math.clamp(s * 1.4, 0, 1)

    local newAccent     = Color3.fromHSV(h, s, v)
    local newHot        = Color3.fromHSV(h, 1, 1)
    local newDark       = Color3.fromHSV(h, math.clamp(s * 0.9, 0, 1), 0.55)
    local newGlow       = Color3.fromHSV(h, math.clamp(s * 0.5, 0, 1), 1)

    THEME.ACCENT      = newAccent
    THEME.ACCENT_HOT  = newHot
    THEME.ACCENT_DARK = newDark
    THEME.ACCENT_GLOW = newGlow

    MainStroke.Color = newAccent
    LogoBadgeGlow.Color = newGlow
    AvatarStroke.Color = newHot
    AvatarGlow.Color = newGlow
    Divider.BackgroundColor3 = newAccent
    AccentBar.BackgroundColor3 = newAccent
    HeaderBaseLine.BackgroundColor3 = newDark
    HeaderRunner.BackgroundColor3 = newHot
    HeaderPulse.BackgroundColor3 = newGlow
    ScanLine.BackgroundColor3 = newHot
    StatusDot.BackgroundColor3 = newHot
    PlayerTag.TextColor3 = newHot
    DragCursor.ImageColor3 = newGlow
    paletteStroke.Color = newDark

    AccentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newHot),
        ColorSequenceKeypoint.new(1, newAccent),
    })
    DividerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    RunnerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
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
    FpsGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    DotGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newDark),
        ColorSequenceKeypoint.new(0.5, newHot),
        ColorSequenceKeypoint.new(1, newDark),
    })
    ScanGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, newHot),
        ColorSequenceKeypoint.new(0.5, newGlow),
        ColorSequenceKeypoint.new(1, newHot),
    })

    for _, d in ipairs(Config.Dots) do
        if d.Frame then d.Frame.BackgroundColor3 = newHot end
    end

    for tName, tData in pairs(Tabs) do
        tData.Accent.BackgroundColor3 = newHot
        tData.Arrow.TextColor3 = newHot
        tData.AccentGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newDark),
            ColorSequenceKeypoint.new(0.5, newHot),
            ColorSequenceKeypoint.new(1, newDark),
        })
        if tData.IsActive then
            tData.Button.BackgroundColor3 = Color3.fromRGB(
                math.floor(newAccent.R * 60 + 10),
                math.floor(newAccent.G * 60 + 10),
                math.floor(newAccent.B * 60 + 10)
            )
            tData.Stroke.Color = newHot
            tData.Index.TextColor3 = newHot
        else
            tData.Stroke.Color = THEME.LINE
            tData.Index.TextColor3 = THEME.TEXT_LOW
        end
    end

    previewBox.BackgroundColor3 = newAccent
    previewStroke.Color = newHot
    hexLabel.Text = ColorToHex(newAccent)

    for _, el in ipairs(ColorSyncedElements) do
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
                ColorSequenceKeypoint.new(1, newHot),
            })
            el.ValueLabel.TextColor3 = newHot
            el.HandleGlow.Color = newHot
        end
    end

    if colorSectionLine then
        colorSectionLine.BackgroundColor3 = newHot
    end
end

-- ====================================================================
-- UPDATE COLOR FROM POSITION
-- ====================================================================
local isDraggingColor = false

local function UpdateColorFromPosition(inputPos)
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

dragArea.InputBegan:Connect(function(input)
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
    hexLabel.Text = "#B450FF"
end)

-- ====================================================================
-- СЕКЦИЯ ACTIONS
-- ====================================================================
CreateSection(settingsPage, "// ACTIONS", 695, Color3.fromRGB(255, 100, 120))

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, -50, 0, 36)
resetBtn.Position = UDim2.new(0, 0, 0, 730)
resetBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
resetBtn.BackgroundTransparency = 1
resetBtn.BorderSizePixel = 0
resetBtn.Text = "Reset Settings"
resetBtn.TextColor3 = Color3.fromRGB(255, 180, 100)
resetBtn.TextSize = 13
resetBtn.Font = Enum.Font.Gotham
resetBtn.AutoButtonColor = false
resetBtn.Parent = settingsPage
local resetBtnCorner = Instance.new("UICorner", resetBtn)
resetBtnCorner.CornerRadius = UDim.new(0, 6)
RegisterCorner(resetBtnCorner, 6)

local resetBtnStroke = Instance.new("UIStroke", resetBtn)
resetBtnStroke.Thickness = 1
resetBtnStroke.Color = Color3.fromRGB(255, 180, 100)
resetBtnStroke.Transparency = 1

resetBtn.MouseEnter:Connect(function()
    TweenService:Create(resetBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
    TweenService:Create(resetBtnStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
end)
resetBtn.MouseLeave:Connect(function()
    TweenService:Create(resetBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(resetBtnStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
end)
resetBtn.MouseButton1Click:Connect(function()
    PlayTab()

    -- Настройки
    Config.FlyingDotsEnabled = true
    Config.SoundEnabled = true
    Config.ScanLineEnabled = true
    Config.FpsCounterEnabled = false
    Config.MenuScale = 100
    Config.CornerRadius = 8

    -- Программный возврат тумблеров
    if ToggleRegistry["Flying Dots"] then ToggleRegistry["Flying Dots"](true, true) end
    if ToggleRegistry["Sounds"] then ToggleRegistry["Sounds"](true, true) end
    if ToggleRegistry["Scan Line"] then ToggleRegistry["Scan Line"](true, true) end
    if ToggleRegistry["FPS Counter"] then ToggleRegistry["FPS Counter"](false, true) end

    -- Программный возврат слайдеров
    if SliderRegistry["Menu Scale"] then SliderRegistry["Menu Scale"](100, true) end
    if SliderRegistry["Corner Radius"] then SliderRegistry["Corner Radius"](8, true) end

    -- UI-состояние
    FpsFrame.Visible = false
    TweenService:Create(MainScale, TweenInfo.new(0.2), {Scale = 1}):Play()
    RebuildDots()
    if ScanLine then ScanLine.Visible = true end

    -- Сброс цвета + пикер-точка в центр
    ApplyAccentColor(Color3.fromRGB(180, 80, 255))
    pickerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    hexLabel.Text = "#B450FF"
end)

local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, -50, 0, 36)
unloadBtn.Position = UDim2.new(0, 0, 0, 775)
unloadBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
unloadBtn.BackgroundTransparency = 1
unloadBtn.BorderSizePixel = 0
unloadBtn.Text = "Unload Script"
unloadBtn.TextColor3 = Color3.fromRGB(255, 80, 100)
unloadBtn.TextSize = 13
unloadBtn.Font = Enum.Font.Gotham
unloadBtn.AutoButtonColor = false
unloadBtn.Parent = settingsPage
local unloadCorner = Instance.new("UICorner", unloadBtn)
unloadCorner.CornerRadius = UDim.new(0, 6)
RegisterCorner(unloadCorner, 6)

local unloadStroke = Instance.new("UIStroke", unloadBtn)
unloadStroke.Thickness = 1
unloadStroke.Color = Color3.fromRGB(255, 80, 100)
unloadStroke.Transparency = 1

unloadBtn.MouseEnter:Connect(function()
    TweenService:Create(unloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
    TweenService:Create(unloadStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
end)
unloadBtn.MouseLeave:Connect(function()
    TweenService:Create(unloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(unloadStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
end)
unloadBtn.MouseButton1Click:Connect(function()
    pcall(function() ScreenGui:Destroy() end)
    pcall(function() LoadGui:Destroy() end)
    pcall(function() TabSound:Destroy() end)
    pcall(function() Sound:Destroy() end)
end)

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, -50, 0, 36)
rejoinBtn.Position = UDim2.new(0, 0, 0, 820)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
rejoinBtn.BackgroundTransparency = 1
rejoinBtn.BorderSizePixel = 0
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.TextColor3 = THEME.ACCENT_HOT
rejoinBtn.TextSize = 13
rejoinBtn.Font = Enum.Font.Gotham
rejoinBtn.AutoButtonColor = false
rejoinBtn.Parent = settingsPage
local rejoinCorner = Instance.new("UICorner", rejoinBtn)
rejoinCorner.CornerRadius = UDim.new(0, 6)
RegisterCorner(rejoinCorner, 6)

local rejoinStroke = Instance.new("UIStroke", rejoinBtn)
rejoinStroke.Thickness = 1
rejoinStroke.Color = THEME.ACCENT_HOT
rejoinStroke.Transparency = 1

rejoinBtn.MouseEnter:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
    TweenService:Create(rejoinStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
end)
rejoinBtn.MouseLeave:Connect(function()
    TweenService:Create(rejoinBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(rejoinStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
end)
rejoinBtn.MouseButton1Click:Connect(function()
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

-- ====================================================================
-- DROP-IN
-- ====================================================================
task.spawn(function()
    task.wait(3.2)
    local dropTween = TweenService:Create(MainFrame,
        TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -340, 0.5, -245)})
    dropTween:Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

task.wait(3.5)
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

print("[VL] PREMIUM LOADING loaded with Color Picker + Corner Radius.")
