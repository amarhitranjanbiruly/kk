--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer

--// Theme Configuration
local Theme = {
    Main = Color3.fromRGB(15, 15, 15),
    Sidebar = Color3.fromRGB(20, 20, 20),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(180, 180, 180),
    Row = Color3.fromRGB(25, 25, 25),
    TopBar = Color3.fromRGB(25, 25, 25)
}

--// ReplicatedStorage Paths (adjust if needed)
local Settings = ReplicatedStorage:WaitForChild("Settings")
local Multipliers = Settings:WaitForChild("Multipliers")
local Cooldowns = Settings:WaitForChild("Cooldowns")
local Toggles = Settings:WaitForChild("Toggles")

--// GUI Parent (works in both executor and normal Roblox)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateSettingsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local parentSuccess, parentContainer = pcall(function()
    return (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parentSuccess or not parentContainer then
    parentContainer = LocalPlayer:WaitForChild("PlayerGui")
end
ScreenGui.Parent = parentContainer

--// Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 650, 0, 450)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
MainFrame.BackgroundColor3 = Theme.Main
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

--// Top Bar (drag area)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Theme.TopBar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Text = "Ultimate Settings Configuration"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -30, 0, 0)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Theme.SubText
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 18
MinimizeButton.ZIndex = 5
MinimizeButton.Parent = TopBar

--// Invisible drag button covering the TopBar (captures clicks on title area)
local DragButton = Instance.new("TextButton")
DragButton.Size = UDim2.new(1, -35, 1, 0)
DragButton.Position = UDim2.new(0, 0, 0, 0)
DragButton.BackgroundTransparency = 1
DragButton.Text = ""
DragButton.ZIndex = 10
DragButton.Parent = TopBar

--// Window Content (hidden when minimized)
local WindowContent = Instance.new("Frame")
WindowContent.Size = UDim2.new(1, 0, 1, -30)
WindowContent.Position = UDim2.new(0, 0, 0, 30)
WindowContent.BackgroundTransparency = 1
WindowContent.Parent = MainFrame

--// Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = WindowContent
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Parent = Sidebar
SideLayout.Padding = UDim.new(0, 2)

--// Content Container (right side)
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -165, 1, -10)
ContentContainer.Position = UDim2.new(0, 165, 0, 5)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = WindowContent

--// Pages storage
local Pages = {}

--// Helper: Update ScrollingFrame CanvasSize based on content
local function SetupScrollingFrame(page)
    local layout = page:FindFirstChildWhichIsA("UIListLayout")
    if not layout then return end

    -- Make scroll bar more visible
    page.ScrollBarThickness = 8

    local function updateCanvas()
        local contentHeight = layout.AbsoluteContentSize.Y
        page.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20) -- add small padding at bottom
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    -- Initial update (after all controls have been added, call this once more)
    updateCanvas()

    -- Also update when children are added/removed (redundant but safe)
    page.ChildAdded:Connect(updateCanvas)
    page.ChildRemoved:Connect(updateCanvas)
end

--// Helper: Create a new page (tab)
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 2
    Page.Visible = false
    Page.Parent = ContentContainer

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Page
    Layout.Padding = UDim.new(0, 5)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 40)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = "  " .. name
    TabButton.TextColor3 = Theme.SubText
    TabButton.Font = Enum.Font.SourceSansSemibold
    TabButton.TextSize = 16
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.Parent = Sidebar

    TabButton.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(Sidebar:GetChildren()) do
            if b:IsA("TextButton") then b.TextColor3 = Theme.SubText end
        end
        Page.Visible = true
        TabButton.TextColor3 = Theme.Accent
        -- Refresh canvas after switching (in case layout changed)
        SetupScrollingFrame(Page)
    end)

    Pages[name] = Page
    return Page
end

--// Helper: Create a toggle switch
local function CreateToggle(parent, name, valuePath)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(0, 460, 0, 40)
    Row.BackgroundColor3 = Theme.Row
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Text = name
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 15
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 36, 0, 18)
    Switch.Position = UDim2.new(1, -48, 0.5, -9)
    Switch.BackgroundColor3 = valuePath.Value and Theme.Accent or Color3.fromRGB(60, 60, 60)
    Switch.Text = ""
    Switch.Parent = Row
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = valuePath.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dot.Parent = Switch
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    Switch.MouseButton1Click:Connect(function()
        valuePath.Value = not valuePath.Value
        local goal = valuePath.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        TweenService:Create(Dot, TweenInfo.new(0.2), {Position = goal}):Play()
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = valuePath.Value and Theme.Accent or Color3.fromRGB(60, 60, 60)}):Play()
    end)
end

--// Helper: Create a slider
--// Helper: Create a slider (now with integer-only values)
local function CreateSlider(parent, name, valuePath, isMovement)
    local sliderMin = 0
    local currentVal = 0

    if isMovement then
        local walkSpeed = Multipliers:FindFirstChild("WalkSpeed")
        if walkSpeed then currentVal = math.round(walkSpeed.Value) end  -- round to integer
    elseif valuePath then
        currentVal = math.round(valuePath.Value)  -- round to integer
    end

    local sliderMax = math.max(1000, currentVal)
    local absoluteMax = 100000

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(0, 460, 0, 50)
    Row.BackgroundColor3 = Theme.Row
    Row.Active = true
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -100, 0, 25)
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.Text = name
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 14
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -120, 0, 4)
    SliderBg.Position = UDim2.new(0, 12, 1, -12)
    SliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SliderBg.BorderSizePixel = 0
    SliderBg.Active = true
    SliderBg.Parent = Row
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 2)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBg
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

    local Spinbox = Instance.new("TextBox")
    Spinbox.Size = UDim2.new(0, 60, 0, 24)
    Spinbox.Position = UDim2.new(1, -72, 0.5, -12)
    Spinbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Spinbox.Text = tostring(currentVal)
    Spinbox.TextColor3 = Theme.Accent
    Spinbox.Font = Enum.Font.Code
    Spinbox.TextSize = 13
    Spinbox.ClearTextOnFocus = false
    Spinbox.Parent = Row
    Instance.new("UICorner", Spinbox).CornerRadius = UDim.new(0, 3)

    -- Helper: round to nearest integer
    local function round(num)
        return math.floor(num + 0.5)
    end

    local function UpdateVisuals(value)
        local intValue = round(value)
        Spinbox.Text = tostring(intValue)
        local percent = (intValue - sliderMin) / (sliderMax - sliderMin)
        percent = math.clamp(percent, 0, 1)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
    end

    local function SetValue(rawValue)
        local num = tonumber(rawValue)
        if not num then return end
        num = round(math.clamp(num, 0, absoluteMax))   -- round to integer

        if isMovement then
            local walk = Multipliers:FindFirstChild("WalkSpeed")
            local run = Multipliers:FindFirstChild("RunSpeed")
            if walk then walk.Value = num end
            if run then run.Value = num end
        elseif valuePath then
            valuePath.Value = num
        end

        if num > sliderMax then
            sliderMax = num
        end
        UpdateVisuals(num)
    end

    local function UpdateFromMouse()
        if SliderBg.AbsoluteSize.X == 0 then return end
        local mousePos = UserInputService:GetMouseLocation()
        local relativeX = math.clamp(mousePos.X - SliderBg.AbsolutePosition.X, 0, SliderBg.AbsoluteSize.X)
        local percent = relativeX / SliderBg.AbsoluteSize.X
        local newVal = sliderMin + (sliderMax - sliderMin) * percent
        SetValue(newVal)
    end

    local dragging = false
    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateFromMouse()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateFromMouse()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    Spinbox.FocusLost:Connect(function()
        local val = tonumber(Spinbox.Text)
        if val then
            SetValue(val)
        else
            local current = isMovement and (Multipliers.WalkSpeed and Multipliers.WalkSpeed.Value) or (valuePath and valuePath.Value) or 0
            Spinbox.Text = tostring(round(current))
        end
    end)

    UpdateVisuals(currentVal)
end

--// ========== CREATE PAGES AND POPULATE THEM ==========

-- Multipliers page
local MultPage = CreatePage("Multipliers")
CreateSlider(MultPage, "Melee Damage", Multipliers.MeleeDamage)
CreateSlider(MultPage, "Ragdoll Power", Multipliers.RagdollPower)
CreateSlider(MultPage, "Melee Speed", Multipliers.MeleeSpeed)
CreateSlider(MultPage, "Dash Speed", Multipliers.DashSpeed)
CreateSlider(MultPage, "Ultimate Timer", Multipliers.UltimateTimer)
CreateSlider(MultPage, "Movement Speed (Walk & Run)", nil, true)
CreateSlider(MultPage, "Jump Height", Multipliers.JumpHeight)
SetupScrollingFrame(MultPage)

-- Multipliers Extra page
local ExtraMultPage = CreatePage("Multipliers Extra")
CreateSlider(ExtraMultPage, "Knockback Power", Multipliers.KnockbackPower)
CreateSlider(ExtraMultPage, "Ability Damage", Multipliers.AbilityDamage)
CreateSlider(ExtraMultPage, "Avatar Scale", Multipliers.AvatarScale)
CreateSlider(ExtraMultPage, "Charge Rate", Multipliers.ChargeRate)
CreateSlider(ExtraMultPage, "Health", Multipliers.Health)
CreateSlider(ExtraMultPage, "Ragdoll Timer", Multipliers.RagdollTimer)
CreateSlider(ExtraMultPage, "Regen Rate", Multipliers.RegenRate)
CreateSlider(ExtraMultPage, "Ultimate Damage", Multipliers.UltimateDamage)
SetupScrollingFrame(ExtraMultPage)

-- Cooldowns page
local CoolPage = CreatePage("Cooldowns")
CreateSlider(CoolPage, "Melee Cooldown", Cooldowns.Melee)
CreateSlider(CoolPage, "Dash Cooldown", Cooldowns.Dash)
CreateSlider(CoolPage, "Ability Cooldown", Cooldowns.Ability)
CreateSlider(CoolPage, "Evasive Cooldown", Cooldowns.Evasive)
CreateSlider(CoolPage, "Wall Combo Cooldown", Cooldowns.WallCombo)
SetupScrollingFrame(CoolPage)

-- Combat Toggles page
local CombatPage = CreatePage("Combat Toggles")
CreateToggle(CombatPage, "Endless", Toggles.Endless)
CreateToggle(CombatPage, "Multi Use Cutscenes", Toggles.MultiUseCutscenes)
CreateToggle(CombatPage, "No Stun On Miss", Toggles.NoStunOnMiss)
CreateToggle(CombatPage, "No Jump Fatigue", Toggles.NoJumpFatigue)
CreateToggle(CombatPage, "Disable Hit Stun", Toggles.DisableHitStun)
SetupScrollingFrame(CombatPage)

-- Extra Toggles page
local ExtraPage = CreatePage("Extra Toggles")
local ToggleList = {
    "AllowAllPackages", "DisableAbilities", "DisableBlocking", "DisableCombatTimer",
    "DisableDashing", "DisableEvasives", "DisableFinishers", "DisableIntros",
    "DisableMelee", "DisableRunning", "DisableSpawnShield", "DisableUltimates",
    "InstantTransformation", "FriendlyFire", "KickOnDeath", "NoJoining",
    "NoResetOnChange", "NoRespawning", "NoSlowdowns", "PreventChanges", "UsableWithoutCharge"
}
for _, name in pairs(ToggleList) do
    CreateToggle(ExtraPage, name, Toggles:WaitForChild(name))
end
SetupScrollingFrame(ExtraPage)

--// Minimize / Restore
local isMinimized = false
local regularSize = UDim2.new(0, 650, 0, 450)
local minimizedSize = UDim2.new(0, 650, 0, 30)

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MinimizeButton.Text = "+"
        WindowContent.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = minimizedSize}):Play()
    else
        MinimizeButton.Text = "−"
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = regularSize}):Play()
        task.wait(0.2)
        WindowContent.Visible = true
        -- Refresh canvas for visible page after restore
        for _, page in pairs(Pages) do
            if page.Visible then SetupScrollingFrame(page) end
        end
    end
end)

--// ========== DRAG: Uses invisible overlay button ==========
local isDragging = false
local dragStartMouse = nil
local dragStartFramePos = nil

DragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartMouse = UserInputService:GetMouseLocation()
        dragStartFramePos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UserInputService:GetMouseLocation() - dragStartMouse
        MainFrame.Position = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + delta.X,
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStartMouse = nil
        dragStartFramePos = nil
    end
end)

--// Open/Close with RightControl
Pages["Multipliers"].Visible = true
UserInputService.InputBegan:Connect(function(i, gameProcessed)
    if gameProcessed then return end
    if i.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
