-- ESP: Full chams outline + name (blue) + distance (green)
-- Works for all players, including those who join later

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local playerData = {} -- { highlight, nameText, distText }

-- Apply Highlight (full outline) to a character
local function applyHighlight(character, player)
    local data = playerData[player]
    if data and data.highlight then
        data.highlight:Destroy()
    end
    
    local hl = Instance.new("Highlight")
    hl.Parent = character
    hl.FillTransparency = 1          -- no fill, only outline
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 100, 100) -- red outline (change as desired)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    if not playerData[player] then
        playerData[player] = {}
    end
    playerData[player].highlight = hl
end

-- Create text objects (blue name, green distance) for a player
local function addESP(player)
    if player == LocalPlayer then return end
    
    -- Don't create twice
    if playerData[player] then return end
    
    local nameText = Drawing.new("Text")
    nameText.Color = Color3.fromRGB(0, 150, 255)  -- blue
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = true
    nameText.ZIndex = 1
    
    local distText = Drawing.new("Text")
    distText.Color = Color3.fromRGB(0, 255, 0)    -- green
    distText.Size = 14
    distText.Center = false
    distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distText.Visible = true
    distText.ZIndex = 1
    
    playerData[player] = {
        nameText = nameText,
        distText = distText,
        highlight = nil
    }
    
    -- If character already exists, apply highlight immediately
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        applyHighlight(character, player)
    end
end

-- Clean up when a player leaves
local function removeESP(player)
    local data = playerData[player]
    if data then
        if data.nameText then data.nameText:Remove() end
        if data.distText then data.distText:Remove() end
        if data.highlight then data.highlight:Destroy() end
        playerData[player] = nil
    end
end

-- Called when a player's character appears (initial spawn or respawn)
local function onCharacterAdded(player, character)
    local data = playerData[player]
    if not data then return end  -- No ESP for this player (shouldn't happen)
    
    -- Small delay to ensure HumanoidRootPart exists
    task.wait(0.1)
    if character and character:FindFirstChild("HumanoidRootPart") then
        applyHighlight(character, player)
    end
end

-- Update text positions and distances every frame
local function updateESP()
    for player, data in pairs(playerData) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        if hrp and humanoid and humanoid.Health > 0 then
            -- Re-apply highlight if missing (e.g., after respawn)
            if not data.highlight or data.highlight.Parent ~= character then
                applyHighlight(character, player)
            end
            
            local head = character:FindFirstChild("Head")
            local headPos = (head or hrp).Position + Vector3.new(0, 2.5, 0)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                -- Distance from local player
                local distance = nil
                local localChar = LocalPlayer.Character
                if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                    local localPos = localChar.HumanoidRootPart.Position
                    distance = (hrp.Position - localPos).Magnitude
                end
                
                -- Name (blue)
                data.nameText.Text = player.Name
                data.nameText.Position = Vector2.new(screenPos.X - 35, screenPos.Y - 20)
                
                -- Distance (green)
                local distString = distance and string.format("%.1f", distance) or "?"
                data.distText.Text = " [" .. distString .. "]"
                data.distText.Position = Vector2.new(screenPos.X + (data.nameText.TextBounds.X / 2) - 10, screenPos.Y - 20)
                
                data.nameText.Visible = true
                data.distText.Visible = true
            else
                data.nameText.Visible = false
                data.distText.Visible = false
            end
        else
            data.nameText.Visible = false
            data.distText.Visible = false
            -- Remove highlight if character is dead or gone
            if data.highlight then
                data.highlight:Destroy()
                data.highlight = nil
            end
        end
    end
end

-- ========== SETUP FOR EXISTING AND NEW PLAYERS ==========
-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    addESP(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end

-- Handle future players (CRITICAL: call addESP first!)
Players.PlayerAdded:Connect(function(player)
    addESP(player)  -- <-- This was missing before
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(removeESP)

-- Start the render loop
RunService.RenderStepped:Connect(updateESP)

-- Optional: full cleanup if script is re-run (for exploit environments)
local function fullClean()
    for player, data in pairs(playerData) do
        if data.nameText then data.nameText:Remove() end
        if data.distText then data.distText:Remove() end
        if data.highlight then data.highlight:Destroy() end
    end
    playerData = {}
end
game:GetService("ScriptContext").Error:Connect(fullClean)
