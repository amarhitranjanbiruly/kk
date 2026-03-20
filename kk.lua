--[[
    Advanced Aimbot GUI + Configuration System
    Version: 2.2.0 (Mobile Trigger Icon + FOV Center)
    
    Features:
    - Toggle Menu: Press INSERT (Customizable)
    - Smooth Animations
    - Notification System
    - Wall Check / Team Check
    - Mouse Movement & Camera Support
    - LockPart Selector: (Head, Neck, Chest)
    - Mobile Trigger Icon (Draggable, Resizable, Lockable)
    - FOV Centering Option
]]

--// Cache
local select = select
local pcall, getgenv, next, Vector2, mathclamp, type = select(1, pcall, getgenv, next, Vector2.new, math.clamp, type)

--// Mouse Movement Compatibility Check
local mousemoverel = mousemoverel or (Input and Input.MouseMove) or (mouse_over_rel)

--// Preventing Multiple Processes
pcall(function()
    if getgenv().Aimbot and getgenv().Aimbot.Functions then
        getgenv().Aimbot.Functions:Exit()
    end
end)

--// Environment Setup
getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Variables
local Typing, Running, ServiceConnections = false, false, {}
local MenuVisible = true
local ScreenGui = nil

--// Script Settings
Environment.Settings = {
    Enabled                = true,
    TeamCheck              = false,
    AliveCheck             = true,
    WallCheck              = false,
    
    --// MOVEMENT SETTINGS
    UseMouseMovement       = true, 
    Sensitivity            = 1,    
    
    --// KEYS
    TriggerKey             = "MouseButton1", 
    MenuKey                = "Insert", -- ✅ CUSTOM MENU KEY
    Toggle                 = false,
    LockPart               = "Head",    -- ✅ TARGET OPTION

    --// MOBILE TRIGGER ICON SETTINGS
    ShowTriggerIcon        = true,      -- Show/hide the mobile trigger icon
    TriggerIconLocked      = false,     -- Lock icon position (disable dragging)
    TriggerIconSize        = 50,        -- Size of the trigger icon (width/height)
    TriggerIconPosition    = UDim2.new(1, -70, 1, -70), -- Default bottom-right
    TriggerIconColorActive = Color3.fromRGB(0, 200, 0), -- Green when active
    TriggerIconColorInactive = Color3.fromRGB(200, 0, 0), -- Red when inactive
}

Environment.FOVSettings = {
    Enabled = true,
    Visible = true,
    Amount = 80,
    Color = Color3.fromRGB(255, 255, 255),
    LockedColor = Color3.fromRGB(255, 70, 70),
    Transparency = 0.5,
    Sides = 60,
    Thickness = 1,
    Filled = false,
    Centered = false   -- NEW: when true, FOV circle stays at screen center
}

Environment.Visuals = {
    MenuColor = Color3.fromRGB(45, 45, 45),
    AccentColor = Color3.fromRGB(0, 150, 255),
    TextColor = Color3.fromRGB(255, 255, 255)
}

Environment.FOVCircle = Drawing.new("Circle")

--// Notification System
local function Notify(title, text, duration)
    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Size = UDim2.new(0, 250, 0, 60)
    NotificationFrame.Position = UDim2.new(1, 10, 0.8, 0)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = NotificationFrame

    local TTitle = Instance.new("TextLabel")
    TTitle.Size = UDim2.new(1, -10, 0, 25)
    TTitle.Position = UDim2.new(0, 10, 0, 5)
    TTitle.BackgroundTransparency = 1
    TTitle.Text = title
    TTitle.TextColor3 = Environment.Visuals.AccentColor
    TTitle.Font = Enum.Font.SourceSansBold
    TTitle.TextSize = 16
    TTitle.TextXAlignment = Enum.TextXAlignment.Left
    TTitle.Parent = NotificationFrame

    local TDesc = Instance.new("TextLabel")
    TDesc.Size = UDim2.new(1, -10, 0, 25)
    TDesc.Position = UDim2.new(0, 10, 0, 25)
    TDesc.BackgroundTransparency = 1
    TDesc.Text = text
    TDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
    TDesc.Font = Enum.Font.SourceSans
    TDesc.TextSize = 14
    TDesc.TextXAlignment = Enum.TextXAlignment.Left
    TDesc.Parent = NotificationFrame

    NotificationFrame:TweenPosition(UDim2.new(1, -260, 0.8, 0), "Out", "Quart", 0.5)
    task.wait(duration or 3)
    NotificationFrame:TweenPosition(UDim2.new(1, 10, 0.8, 0), "In", "Quart", 0.5)
    task.delay(0.5, function() NotificationFrame:Destroy() end)
end

--// Utility Functions
local function CancelLock()
    Environment.Locked = nil
    Environment.LockedPart = nil
    Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function IsVisible(part)
    if not part then return false end
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    
    if Environment.Settings.WallCheck then
        local origin = Camera.CFrame.Position
        local direction = part.Position - origin
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result and not result.Instance:IsDescendantOf(part.Parent) then
            return false
        end
    end
    return true
end

-- MODIFIED: GetClosestPlayer now uses mouse or screen center based on FOVCentered
local function GetClosestPlayer()
    local closestTarget = nil
    local closestPart = nil
    local closestDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)
    
    -- Determine the center point for distance calculation
    local centerPoint
    if Environment.FOVSettings.Centered then
        -- Use screen center when FOV is centered
        local viewport = Camera.ViewportSize
        centerPoint = Vector2.new(viewport.X / 2, viewport.Y / 2)
    else
        -- Use mouse position when following mouse
        centerPoint = UserInputService:GetMouseLocation()
    end
    
    -- Mapping "Neck" and "Chest" to actual R6/R15 Roblox part names
    local targetBone = Environment.Settings.LockPart
    if targetBone == "Neck" then targetBone = "UpperTorso" end
    if targetBone == "Chest" then targetBone = "LowerTorso" end

    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
            if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
            if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end

            local part = v.Character:FindFirstChild(targetBone) or v.Character:FindFirstChild("HumanoidRootPart")
            if part and IsVisible(part) then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                local distanceFromCenter = (centerPoint - Vector2(screenPoint.X, screenPoint.Y)).Magnitude
                
                if distanceFromCenter < closestDistance then
                    closestTarget = v
                    closestPart = part
                    closestDistance = distanceFromCenter
                end
            end
        end
    end

    Environment.Locked = closestTarget
    Environment.LockedPart = closestPart
end

--// Main Execution Logic
local function Load()
    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        -- FOV Circle drawing (supports centered or mouse-follow)
        if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
            Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
            Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
            Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
            Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
            Environment.FOVCircle.Color = Environment.FOVSettings.Color
            Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
            Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
            
            -- Position based on Centered setting
            if Environment.FOVSettings.Centered then
                local viewport = Camera.ViewportSize
                Environment.FOVCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
            else
                Environment.FOVCircle.Position = UserInputService:GetMouseLocation()
            end
        else
            Environment.FOVCircle.Visible = false
        end

        if Running and Environment.Settings.Enabled then
            GetClosestPlayer()

            if Environment.Locked and Environment.LockedPart then
                local screenPoint = Camera:WorldToViewportPoint(Environment.LockedPart.Position)
                local mouseLocation = UserInputService:GetMouseLocation()
                
                if Environment.Settings.UseMouseMovement then
                    local deltaX = (screenPoint.X - mouseLocation.X)
                    local deltaY = (screenPoint.Y - mouseLocation.Y)
                    local moveX = deltaX * (Environment.Settings.Sensitivity / 2)
                    local moveY = deltaY * (Environment.Settings.Sensitivity / 2)
                    
                    if mousemoverel then
                        mousemoverel(moveX, moveY)
                    end
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.LockedPart.Position)
                end

                Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor
            else
                CancelLock()
            end
        end
    end)

    ServiceConnections.TypingStarted = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
    ServiceConnections.TypingEnded = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)

    ServiceConnections.InputBegan = UserInputService.InputBegan:Connect(function(Input)
        if Typing then return end
        
        if Input.KeyCode.Name == Environment.Settings.MenuKey then
            MenuVisible = not MenuVisible
            ScreenGui.Enabled = MenuVisible
        end

        local triggerKey = Environment.Settings.TriggerKey
        local isTrigger = (Input.UserInputType.Name == triggerKey or Input.KeyCode.Name == triggerKey)

        if isTrigger then
            if Environment.Settings.Toggle then
                Running = not Running
                if not Running then CancelLock() end
            else
                Running = true
            end
        end
    end)

    ServiceConnections.InputEnded = UserInputService.InputEnded:Connect(function(Input)
        if Typing or Environment.Settings.Toggle then return end

        local triggerKey = Environment.Settings.TriggerKey
        local isTrigger = (Input.UserInputType.Name == triggerKey or Input.KeyCode.Name == triggerKey)

        if isTrigger then
            Running = false
            CancelLock()
        end
    end)
end

--// GUI Creation
local function CreateGUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = (syn and syn.protected_gui and syn.protected_gui()) or gethui and gethui() or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    _G.AimbotGUI = ScreenGui

    --// 1. ALWAYS VISIBLE FLOATING ICON (Menu Toggle)
    local IconFrame = Instance.new("TextButton")
    IconFrame.Name = "GeminiIcon"
    IconFrame.Size = UDim2.new(0, 50, 0, 50)
    IconFrame.Position = UDim2.new(0, 20, 0.5, 0)
    IconFrame.BackgroundColor3 = Environment.Visuals.AccentColor
    IconFrame.BorderSizePixel = 0
    IconFrame.Text = "G"
    IconFrame.TextColor3 = Color3.new(1, 1, 1)
    IconFrame.Font = Enum.Font.SourceSansBold
    IconFrame.TextSize = 26
    IconFrame.Visible = true 
    IconFrame.ZIndex = 10 
    IconFrame.Parent = ScreenGui

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(1, 0)
    IconCorner.Parent = IconFrame

    --// 2. MOBILE TRIGGER ICON (Toggles aimbot on/off)
    local TriggerIcon = Instance.new("TextButton")
    TriggerIcon.Name = "TriggerIcon"
    TriggerIcon.Size = UDim2.new(0, Environment.Settings.TriggerIconSize, 0, Environment.Settings.TriggerIconSize)
    TriggerIcon.Position = Environment.Settings.TriggerIconPosition
    TriggerIcon.BackgroundColor3 = Environment.Settings.TriggerIconColorInactive
    TriggerIcon.BorderSizePixel = 0
    TriggerIcon.Text = "A"  -- Simple text, can be changed
    TriggerIcon.TextColor3 = Color3.new(1, 1, 1)
    TriggerIcon.Font = Enum.Font.SourceSansBold
    TriggerIcon.TextSize = 26
    TriggerIcon.Visible = Environment.Settings.ShowTriggerIcon
    TriggerIcon.ZIndex = 10
    TriggerIcon.Parent = ScreenGui

    local TriggerCorner = Instance.new("UICorner")
    TriggerCorner.CornerRadius = UDim.new(1, 0)
    TriggerCorner.Parent = TriggerIcon

    -- Update icon color based on Running state
    local function UpdateTriggerIconColor()
        TriggerIcon.BackgroundColor3 = Running and Environment.Settings.TriggerIconColorActive or Environment.Settings.TriggerIconColorInactive
    end
    UpdateTriggerIconColor()

    -- Trigger icon click toggles aimbot on/off
    TriggerIcon.MouseButton1Click:Connect(function()
        Running = not Running
        UpdateTriggerIconColor()
        if not Running then CancelLock() end
        Notify("Aimbot", Running and "Activated" or "Deactivated", 1.5)
    end)

    -- Dragging logic for TriggerIcon (only if not locked)
    local draggingTrigger = false
    local dragTriggerInput, dragTriggerStart, dragTriggerStartPos

    TriggerIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not Environment.Settings.TriggerIconLocked then
            draggingTrigger = true
            dragTriggerStart = input.Position
            dragTriggerStartPos = TriggerIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then draggingTrigger = false end
            end)
        end
    end)

    TriggerIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragTriggerInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragTriggerInput and draggingTrigger then
            local delta = input.Position - dragTriggerStart
            local newPos = UDim2.new(dragTriggerStartPos.X.Scale, dragTriggerStartPos.X.Offset + delta.X,
                                      dragTriggerStartPos.Y.Scale, dragTriggerStartPos.Y.Offset + delta.Y)
            TriggerIcon.Position = newPos
            Environment.Settings.TriggerIconPosition = newPos  -- Save new position
        end
    end)

    -- Update size of trigger icon when setting changes
    local function UpdateTriggerIconSize()
        TriggerIcon.Size = UDim2.new(0, Environment.Settings.TriggerIconSize, 0, Environment.Settings.TriggerIconSize)
    end

    --// 3. MAIN MENU FRAME
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = MenuVisible
    MainFrame.Parent = ScreenGui

    local function ToggleMenu()
        MenuVisible = not MenuVisible
        MainFrame.Visible = MenuVisible
        IconFrame.BackgroundColor3 = MenuVisible and Color3.fromRGB(60, 60, 60) or Environment.Visuals.AccentColor
    end

    IconFrame.MouseButton1Click:Connect(ToggleMenu)

    --// 4. ICON DRAG LOGIC (GeminiIcon)
    local dragging, dragInput, dragStart, startPos
    IconFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = IconFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    IconFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            IconFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    --// Update Input Connection for MenuKey
    if ServiceConnections.InputBegan then ServiceConnections.InputBegan:Disconnect() end
    ServiceConnections.InputBegan = UserInputService.InputBegan:Connect(function(Input)
        if Typing then return end
        if Input.KeyCode.Name == Environment.Settings.MenuKey then
            ToggleMenu()
        end
        local triggerKey = Environment.Settings.TriggerKey
        local isTrigger = (Input.UserInputType.Name == triggerKey or Input.KeyCode.Name == triggerKey)
        if isTrigger then
            if Environment.Settings.Toggle then
                Running = not Running
                UpdateTriggerIconColor()
                if not Running then CancelLock() end
            else
                Running = true
                UpdateTriggerIconColor()
            end
        end
    end)

    --// 5. GUI STYLING
    local UICorner_Main = Instance.new("UICorner")
    UICorner_Main.CornerRadius = UDim.new(0, 8)
    UICorner_Main.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local UICorner_Title = Instance.new("UICorner")
    UICorner_Title.CornerRadius = UDim.new(0, 8)
    UICorner_Title.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "GEMINI AIMBOT v2"
    Title.TextColor3 = Environment.Visuals.AccentColor
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 35, 1, 0)
    MinBtn.Position = UDim2.new(1, -35, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.SourceSansBold
    MinBtn.TextSize = 20
    MinBtn.Parent = TitleBar
    MinBtn.MouseButton1Click:Connect(ToggleMenu)

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(1, 0, 1, -35)
    ScrollingFrame.Position = UDim2.new(0, 0, 0, 35)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = ScrollingFrame
    Layout.Padding = UDim.new(0, 6)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 10)
    Padding.Parent = ScrollingFrame

    --// Helper Functions for GUI Components
    local function CreateToggle(name, settingTable, settingKey)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 290, 0, 35)
        Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Frame.Parent = ScrollingFrame
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -50, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 45, 0, 22)
        Button.Position = UDim2.new(1, -55, 0.5, -11)
        Button.BackgroundColor3 = settingTable[settingKey] and Environment.Visuals.AccentColor or Color3.fromRGB(60, 60, 60)
        Button.Text = ""
        Button.Parent = Frame
        Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0)

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 16, 0, 16)
        Dot.Position = settingTable[settingKey] and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Dot.Parent = Button
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        Button.MouseButton1Click:Connect(function()
            settingTable[settingKey] = not settingTable[settingKey]
            local goal = settingTable[settingKey] and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = goal}):Play()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = settingTable[settingKey] and Environment.Visuals.AccentColor or Color3.fromRGB(60, 60, 60)}):Play()
        end)
    end

    local function CreateSlider(name, settingTable, settingKey, min, max, precise)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 290, 0, 45)
        Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Frame.Parent = ScrollingFrame
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 0, 20)
        Label.Position = UDim2.new(0, 10, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = name .. ": " .. tostring(settingTable[settingKey])
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame

        local SliderBack = Instance.new("Frame")
        SliderBack.Size = UDim2.new(1, -20, 0, 6)
        SliderBack.Position = UDim2.new(0, 10, 1, -12)
        SliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        SliderBack.Parent = Frame
        Instance.new("UICorner", SliderBack)

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((settingTable[settingKey] - min) / (max - min), 0, 1, 0)
        SliderFill.BackgroundColor3 = Environment.Visuals.AccentColor
        SliderFill.Parent = SliderBack
        Instance.new("UICorner", SliderFill)

        local function UpdateSlider()
            local mouse = UserInputService:GetMouseLocation()
            local relativeX = math.clamp(mouse.X - SliderBack.AbsolutePosition.X, 0, SliderBack.AbsoluteSize.X)
            local percent = relativeX / SliderBack.AbsoluteSize.X
            local val = min + (max - min) * percent
            if precise then val = math.floor(val * 10) / 10 else val = math.floor(val) end
            settingTable[settingKey] = val
            Label.Text = name .. ": " .. tostring(val)
            SliderFill.Size = UDim2.new(percent, 0, 1, 0)
            -- Special handling for TriggerIconSize
            if settingTable == Environment.Settings and settingKey == "TriggerIconSize" then
                UpdateTriggerIconSize()
            end
        end

        SliderBack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local connection
                connection = RunService.RenderStepped:Connect(function()
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        UpdateSlider()
                    else
                        connection:Disconnect()
                    end
                end)
            end
        end)
    end

    local function CreateKeybind(name, settingTable, settingKey)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 290, 0, 35)
        Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Frame.Parent = ScrollingFrame
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -100, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame

        local BindBtn = Instance.new("TextButton")
        BindBtn.Size = UDim2.new(0, 80, 0, 25)
        BindBtn.Position = UDim2.new(1, -90, 0.5, -12)
        BindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        BindBtn.Text = settingTable[settingKey]
        BindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        BindBtn.Font = Enum.Font.SourceSansBold
        BindBtn.TextSize = 14
        BindBtn.Parent = Frame
        Instance.new("UICorner", BindBtn)

        BindBtn.MouseButton1Click:Connect(function()
            BindBtn.Text = "..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                local key = nil
                if input.UserInputType == Enum.UserInputType.Keyboard then key = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then key = "MouseButton1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then key = "MouseButton2" end
                if key then
                    settingTable[settingKey] = key
                    BindBtn.Text = key
                    connection:Disconnect()
                end
            end)
        end)
    end

    local function CreateLockPartDropdown()
        local Options = {"Head", "Neck", "Chest"}
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 290, 0, 35)
        Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Frame.Parent = ScrollingFrame
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -110, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = "Lock Part"
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame

        local SelectionBtn = Instance.new("TextButton")
        SelectionBtn.Size = UDim2.new(0, 90, 0, 25)
        SelectionBtn.Position = UDim2.new(1, -100, 0.5, -12)
        SelectionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        SelectionBtn.Text = Environment.Settings.LockPart
        SelectionBtn.TextColor3 = Environment.Visuals.AccentColor
        SelectionBtn.Font = Enum.Font.SourceSansBold
        SelectionBtn.TextSize = 14
        SelectionBtn.Parent = Frame
        Instance.new("UICorner", SelectionBtn)

        SelectionBtn.MouseButton1Click:Connect(function()
            local currentIndex = 1
            for i, v in ipairs(Options) do if v == Environment.Settings.LockPart then currentIndex = i break end end
            local nextIndex = (currentIndex % #Options) + 1
            Environment.Settings.LockPart = Options[nextIndex]
            SelectionBtn.Text = Options[nextIndex]
            Notify("Target Changed", "Now aiming at: " .. Options[nextIndex], 1.5)
        end)
    end

    local function CreateSection(name)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 290, 0, 30)
        Label.BackgroundTransparency = 1
        Label.Text = name:upper()
        Label.TextColor3 = Environment.Visuals.AccentColor
        Label.Font = Enum.Font.SourceSansBold
        Label.TextSize = 14
        Label.Parent = ScrollingFrame
    end

    --// GUI COMPONENTS BUILD
    CreateSection("Main Toggles")
    CreateToggle("Master Enabled", Environment.Settings, "Enabled")
    CreateToggle("Team Check", Environment.Settings, "TeamCheck")
    CreateToggle("Wall Check", Environment.Settings, "WallCheck")
    CreateToggle("Alive Check", Environment.Settings, "AliveCheck")
    CreateSection("Aimbot Settings")
    CreateToggle("Use Mouse Movement", Environment.Settings, "UseMouseMovement")
    CreateToggle("Toggle Mode", Environment.Settings, "Toggle")
    CreateSlider("Sensitivity", Environment.Settings, "Sensitivity", 0, 10, true)
    CreateKeybind("Trigger Key", Environment.Settings, "TriggerKey")
    CreateLockPartDropdown() 
    CreateSection("Menu Config")
    CreateKeybind("Menu Open Key", Environment.Settings, "MenuKey")
    CreateSection("FOV Settings")
    CreateToggle("FOV Enabled", Environment.FOVSettings, "Enabled")
    CreateToggle("FOV Visible", Environment.FOVSettings, "Visible")
    CreateSlider("FOV Radius", Environment.FOVSettings, "Amount", 10, 800, false)
    CreateSlider("FOV Thickness", Environment.FOVSettings, "Thickness", 1, 10, false)
    CreateToggle("Filled FOV", Environment.FOVSettings, "Filled")
    CreateToggle("FOV Centered", Environment.FOVSettings, "Centered")  -- NEW toggle

    CreateSection("Mobile Controls")
    CreateToggle("Show Trigger Icon", Environment.Settings, "ShowTriggerIcon")
    CreateToggle("Lock Trigger Icon", Environment.Settings, "TriggerIconLocked")
    CreateSlider("Trigger Icon Size", Environment.Settings, "TriggerIconSize", 20, 100, false)

    -- Update icon visibility when ShowTriggerIcon changes
    local function updateTriggerIconVisibility()
        TriggerIcon.Visible = Environment.Settings.ShowTriggerIcon
    end
    -- Override the toggle for ShowTriggerIcon to also update visibility
    -- We need to hook into the toggle button for ShowTriggerIcon. Since we already created the toggle, we can add a connection after the fact.
    -- Find the toggle frame for ShowTriggerIcon and add a custom callback.
    -- Simpler: just update in the main loop or use a BindToClose? We'll add a connection in the render step or just use a manual check.
    -- But for immediate feedback, we'll connect to the setting change via a custom function.
    -- We'll add a separate connection that listens for changes to that setting (can't easily without a metatable). Instead, we can just check each frame? Not ideal.
    -- Let's modify the toggle creation to allow a callback. Since we already created all toggles, we'll search for the specific toggle after GUI creation.
    -- To keep it simple, we'll update the visibility whenever the setting is toggled from the GUI by adding a custom connection after the toggle is made.
    -- We'll locate the toggle button for "Show Trigger Icon" and add a click handler that also updates visibility.
    -- We'll do this after all UI is created, by iterating ScrollingFrame's children.

    -- After building the GUI, we'll find the toggle for ShowTriggerIcon and connect an extra function
    task.defer(function()
        for _, child in ipairs(ScrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                local label = child:FindFirstChild("TextLabel")
                if label and label.Text == "Show Trigger Icon" then
                    local button = child:FindFirstChild("TextButton")
                    if button then
                        button.MouseButton1Click:Connect(function()
                            -- The toggle already toggles the setting, we just need to apply visibility
                            TriggerIcon.Visible = Environment.Settings.ShowTriggerIcon
                        end)
                    end
                    break
                end
            end
        end
    end)

    -- Also, when lock setting changes, we don't need to do anything else; dragging is already conditional on that setting.
    -- For the lock toggle, we need to update the dragging condition, but it's already checked every time dragging starts, so it's fine.

    -- Initial visibility
    TriggerIcon.Visible = Environment.Settings.ShowTriggerIcon

    -- Adjust canvas size
    RunService.RenderStepped:Connect(function()
        local height = 0
        for _, v in ipairs(ScrollingFrame:GetChildren()) do
            if v:IsA("Frame") or v:IsA("TextLabel") then
                height = height + v.AbsoluteSize.Y + Layout.Padding.Offset
            end
        end
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, height + 20)
    end)
    
    Notify("GEMINI LOADED", "Press " .. Environment.Settings.MenuKey .. " to Open/Close", 4)
end

--// Cleanup
Environment.Functions = {}
function Environment.Functions:Exit()
    for _, v in next, ServiceConnections do v:Disconnect() end
    if Environment.FOVCircle then Environment.FOVCircle:Remove() end
    if ScreenGui then ScreenGui:Destroy() end
    getgenv().Aimbot = nil
end

--// Launch
Load()
CreateGUI()
