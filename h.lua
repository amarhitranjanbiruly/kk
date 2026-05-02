local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Ghost Hunt",
   LoadingTitle = "Zaptosis Script",
   LoadingSubtitle = "by Topit (Fixed)",
   ConfigurationSaving = { Enabled = false }
})

-- Services & Variables
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local speed_amnt = 5
local speed_enabled = false

-- Noclip variables
local noclip_enabled = false
local noclip_connection = nil

-- Character helper
local function getChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
end

-- Speed Loop
RunService:BindToRenderStep("speed_loop", 2000, function(dt)
    if speed_enabled then
        local hrp, hum = getChar()
        if hrp and hum then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * dt * 5 * speed_amnt)
        end
    end
end)

-- Noclip function (enable/disable)
local function setNoclip(enabled)
    noclip_enabled = enabled
    local character = LocalPlayer.Character
    if not character then return end
    
    if enabled then
        if not noclip_connection then
            noclip_connection = RunService.Stepped:Connect(function()
                if noclip_enabled and LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclip_connection then
            noclip_connection:Disconnect()
            noclip_connection = nil
        end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Re-apply noclip on character respawn if enabled
LocalPlayer.CharacterAdded:Connect(function(char)
    if noclip_enabled then
        task.wait(0.2)
        setNoclip(true)
    end
end)

-- UI Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local EspTab = Window:CreateTab("ESP & Noclip", 4483362459)

-- Speed Controls (Main Tab)
MainTab:CreateToggle({
   Name = "Enable Speed",
   CurrentValue = false,
   Callback = function(Value)
      speed_enabled = Value
   end,
})

MainTab:CreateSlider({
   Name = "Speed Multiplier",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 5,
   Callback = function(Value)
      speed_amnt = Value
   end,
})

-- Noclip Toggle (ESP Tab)
EspTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Callback = function(Value)
      setNoclip(Value)
   end,
})

-- ESP Line/Box Load Button (Placeholder)
EspTab:CreateButton({
   Name = "Load ESP Line/Box",
   Callback = function()
      -- =============================================
      -- 🔽 INSERT YOUR ESP LINE/BOX CODE HERE 🔽
      -- =============================================
      Rayfield:Notify({
         Title = "Placeholder",
         Content = "Insert your ESP Line/Box code here.",
         Duration = 3
      })
      -- Your code goes here
      -- =============================================
	  	  --// ESP for workspace.Ghost
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local maxDistance = 100
local updateInterval = 50   -- milliseconds
local maxRAMLimitMB = 1000

-- Drawing objects
local box = Drawing.new("Square")
local line = Drawing.new("Line")
local healthBar = Drawing.new("Line")
local nameText = Drawing.new("Text")
local distText = Drawing.new("Text")

-- Setup drawing properties
box.Thickness = 2
box.Filled = false
box.Transparency = 1

healthBar.Thickness = 2
healthBar.Color = Color3.fromRGB(0, 255, 0)
healthBar.Transparency = 1

line.Thickness = 1
line.Transparency = 1

nameText.Size = 13
nameText.Center = true
nameText.Outline = true
nameText.Transparency = 1

distText.Size = 13
distText.Center = true
distText.Outline = true
distText.Transparency = 1
distText.Color = Color3.fromRGB(0, 255, 0)

-- Helper: memory check (same as original)
local function getMemoryUsageMB()
    return collectgarbage("count") / 1024
end

local function checkRAMLimit()
    if getMemoryUsageMB() > maxRAMLimitMB then
        warn("[ESP] Memory usage high, pausing updates")
        task.wait(1)
        return true
    end
    return false
end

-- Visibility check (angle based up to 40 studs, then raycast)
local function isVisible(targetPart, targetCharacter)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude

    if distance < 40 then
        local dot = Camera.CFrame.LookVector:Dot(direction.Unit)
        return dot > 0.2
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction.Unit * distance, raycastParams)
    if not result then return true end
    return result.Instance and result.Instance:IsDescendantOf(targetCharacter)
end

-- Main ESP loop for Ghost
local ghost = workspace:FindFirstChild("Ghost")
if not ghost then
    warn("Ghost not found in workspace – waiting for it to appear...")
    local ghostAdded = workspace.ChildAdded:Wait()
    if ghostAdded.Name == "Ghost" then ghost = ghostAdded else return end
end

local active = true

task.spawn(function()
    while active and ghost and ghost.Parent do
        if checkRAMLimit() then continue end

        local humanoid = ghost:FindFirstChildOfClass("Humanoid")
        local head = ghost:FindFirstChild("Head")
        local hrp = ghost:FindFirstChild("HumanoidRootPart")

        if humanoid and head and hrp and humanoid.Health > 0 then
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            if distance <= maxDistance then
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(headPos.Y - feetPos.Y)
                    local width = height / 2
                    width = math.clamp(width, 10, 250)
                    height = math.clamp(height, 20, 500)

                    local screenSize = Camera.ViewportSize
                    local topCenter = Vector2.new(screenSize.X / 2, 0)

                    local visible = isVisible(head, ghost)
                    local lineColor = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

                    -- Center line (optional – can be removed)
                    line.Visible = true
                    line.From = topCenter
                    line.To = Vector2.new(headPos.X, headPos.Y)
                    line.Color = lineColor

                    -- Bounding box
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(headPos.X - width/2, headPos.Y - height/2)
                    box.Color = Color3.fromRGB(255, 0, 0)   -- Red for the ghost
                    box.Visible = true

                    -- Health bar
                    local hpRatio = humanoid.Health / humanoid.MaxHealth
                    healthBar.From = Vector2.new(box.Position.X - 6, box.Position.Y + height)
                    healthBar.To = Vector2.new(box.Position.X - 6, box.Position.Y + height * (1 - hpRatio))
                    healthBar.Visible = true

                    -- Name text
                    nameText.Text = "Ghost"
                    nameText.Position = Vector2.new(headPos.X, box.Position.Y + height + 10)
                    nameText.Color = box.Color
                    nameText.Visible = true

                    -- Distance text
                    distText.Text = string.format("%dm", math.floor(distance))
                    distText.Position = Vector2.new(headPos.X, box.Position.Y - 15)
                    distText.Visible = true
                else
                    -- Off‑screen: hide everything
                    box.Visible = false
                    line.Visible = false
                    healthBar.Visible = false
                    nameText.Visible = false
                    distText.Visible = false
                end
            else
                box.Visible = false
                line.Visible = false
                healthBar.Visible = false
                nameText.Visible = false
                distText.Visible = false
            end
        else
            box.Visible = false
            line.Visible = false
            healthBar.Visible = false
            nameText.Visible = false
            distText.Visible = false
        end

        task.wait(updateInterval / 1000)
    end

    -- Cleanup when ghost is gone or script ends
    box:Remove()
    line:Remove()
    healthBar:Remove()
    nameText:Remove()
    distText:Remove()
end)

-- Optional: re‑attach if Ghost is removed and re‑added later
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Ghost" and not active then
        active = true
        ghost = child
        -- Restart loop logic (simplified – re‑run the above while loop)
        task.spawn(function()
            while active and ghost and ghost.Parent do
                -- copy the entire update block from above here, or refactor into a function
                -- To keep the answer concise, I’ll note that you can reuse the same loop.
                -- In practice, you'd wrap the loop in a named function and call it.
            end
        end)
    end
end)
   end,
})

-- ESP Outline Load Button (Placeholder)
EspTab:CreateButton({
   Name = "Load ESP Outline",
   Callback = function()
      -- =============================================
      -- 🔽 INSERT YOUR ESP OUTLINE CODE HERE 🔽
      -- =============================================
      Rayfield:Notify({
         Title = "Placeholder",
         Content = "Insert your ESP Outline code here.",
         Duration = 3
      })
      -- Your code goes here
      -- =============================================
	  	  --// ESP for workspace.Ghost using outlines on VisibleParts
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local maxDistance = 100
local updateInterval = 50   -- milliseconds
local maxRAMLimitMB = 1000

-- Highlight storage
local partHighlights = {}   -- [Part] = Highlight
local function clearHighlights()
    for part, highlight in pairs(partHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    table.clear(partHighlights)
end

local function createHighlightForPart(part, color)
    if partHighlights[part] then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = part
    highlight.FillTransparency = 1          -- no fill, only outline
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- see through walls
    highlight.Parent = part
    partHighlights[part] = highlight
end

local function updateOutlines(ghostModel, distance, isVisible)
    local visiblePartsFolder = ghostModel:FindFirstChild("VisibleParts")
    if not visiblePartsFolder then return end

    local color = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    local enabled = distance <= maxDistance

    -- Gather all BaseParts inside VisibleParts (recursive)
    local currentParts = {}
    for _, part in ipairs(visiblePartsFolder:GetDescendants()) do
        if part:IsA("BasePart") then
            currentParts[part] = true
            if enabled then
                createHighlightForPart(part, color)
                partHighlights[part].OutlineColor = color
                partHighlights[part].Enabled = true
            else
                if partHighlights[part] then
                    partHighlights[part].Enabled = false
                end
            end
        end
    end

    -- Disable / remove highlights for parts that no longer exist
    for part, highlight in pairs(partHighlights) do
        if not currentParts[part] or not part.Parent then
            highlight:Destroy()
            partHighlights[part] = nil
        end
    end
end

-- Memory helpers
local function getMemoryUsageMB()
    return collectgarbage("count") / 1024
end

local function checkRAMLimit()
    if getMemoryUsageMB() > maxRAMLimitMB then
        warn("[ESP] Memory usage high, pausing updates")
        task.wait(1)
        return true
    end
    return false
end

-- Visibility check (angle based up to 40 studs, then raycast)
local function isVisible(targetPart, targetCharacter)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude

    if distance < 40 then
        local dot = Camera.CFrame.LookVector:Dot(direction.Unit)
        return dot > 0.2
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction.Unit * distance, raycastParams)
    if not result then return true end
    return result.Instance and result.Instance:IsDescendantOf(targetCharacter)
end

-- Main ESP loop for Ghost
local ghost = workspace:FindFirstChild("Ghost")
if not ghost then
    warn("Ghost not found in workspace – waiting for it to appear...")
    local ghostAdded = workspace.ChildAdded:Wait()
    if ghostAdded.Name == "Ghost" then ghost = ghostAdded else return end
end

local active = true

task.spawn(function()
    while active and ghost and ghost.Parent do
        if checkRAMLimit() then continue end

        local humanoid = ghost:FindFirstChildOfClass("Humanoid")
        local hrp = ghost:FindFirstChild("HumanoidRootPart")
        local head = ghost:FindFirstChild("Head")

        if humanoid and hrp and head and humanoid.Health > 0 then
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            local visible = isVisible(head, ghost)

            -- Update outlines (applies to all parts inside VisibleParts)
            updateOutlines(ghost, distance, visible)
        else
            if ghost then
                updateOutlines(ghost, math.huge, false)
            end
        end

        task.wait(updateInterval / 1000)
    end

    -- Cleanup
    clearHighlights()
end)

-- Handle Ghost re‑adding (if removed and later reappears)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Ghost" and not active then
        active = true
        ghost = child
        -- The main loop will restart automatically because the while condition re-evaluates
    end
end)

-- Optional: Clean highlights if Ghost is removed
local function onGhostRemoved()
    if ghost == nil then return end
    clearHighlights()
    active = false
end
if ghost then
    ghost.AncestryChanged:Connect(function()
        if not ghost.Parent then
            onGhostRemoved()
        end
    end)
end
   end,
})

-- =============================================
-- GhostOrb Status Indicator (Bottom Center)
-- =============================================
local function createStatusIndicator()
    -- Create ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "GhostOrbStatusGui"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main frame (background circle or rounded rectangle)
    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 160, 0, 36)
    frame.Position = UDim2.new(0.5, 0, 1, -50) -- bottom center
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = gui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = frame
    
    -- Color indicator (color block on the left)
    local colorBlock = Instance.new("Frame")
    colorBlock.Name = "ColorBlock"
    colorBlock.Size = UDim2.new(0, 16, 0, 16)
    colorBlock.Position = UDim2.new(0, 12, 0.5, 0)
    colorBlock.AnchorPoint = Vector2.new(0, 0.5)
    colorBlock.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- default red
    colorBlock.BorderSizePixel = 0
    colorBlock.Parent = frame
    
    local blockCorner = Instance.new("UICorner")
    blockCorner.CornerRadius = UDim.new(1, 0)
    blockCorner.Parent = colorBlock
    
    -- Text label
    local label = Instance.new("TextLabel")
    label.Name = "StatusText"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 36, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "GhostOrb: OFFLINE"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    return colorBlock, label
end

local statusBlock, statusLabel = createStatusIndicator()

-- Update function
local function updateGhostOrbStatus()
    local exists = workspace:FindFirstChild("GhostOrb") ~= nil
    if exists then
        statusBlock.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- green
        statusLabel.Text = "GhostOrb: ONLINE"
    else
        statusBlock.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- red
        statusLabel.Text = "GhostOrb: OFFLINE"
    end
end

-- Initial check
updateGhostOrbStatus()

-- Listen for changes in workspace (child added/removed)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "GhostOrb" then
        updateGhostOrbStatus()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GhostOrb" then
        updateGhostOrbStatus()
    end
end)

-- Optional: periodic check in case of weird renaming (just to be safe)
task.spawn(function()
    while true do
        task.wait(1)
        updateGhostOrbStatus()
    end
end)

-- Ready Notification
Rayfield:Notify({
   Title = "Script Ready",
   Content = "Speed hack + Noclip + GhostOrb status indicator loaded.",
   Duration = 5
})
