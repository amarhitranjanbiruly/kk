-- ESP: Green 2D box + Blue name + Green distance
-- Outline (chams/skeleton): Green = alive, Red = dead
-- Death check toggle: true = hide dead, false = show dead with red outline

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espEnabled = true       -- Master ESP on/off
local checkDeath = false       -- true = hide dead, false = show dead (with red outline)
local playerData = {}

-- Get character from custom path
local function getCharacter(player)
    local gameFolder = workspace.Game
    if not gameFolder then return nil end
    local playersFolder = gameFolder.Players
    if not playersFolder then return nil end
    return playersFolder:FindFirstChild(player.Name)
end

-- Attach or update Highlight (chams) with a specific color
local function attachHighlight(player, model, color)
    if not model then return false end
    local data = playerData[player]
    if not data then return false end
    if data.highlight then
        data.highlight:Destroy()
        data.highlight = nil
    end
    local success, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Parent = model
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = color
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        return h
    end)
    if success and hl then
        data.highlight = hl
        return true
    else
        return false
    end
end

-- Create skeleton lines (fallback)
local function createSkeleton(player, model)
    local data = playerData[player]
    if not data then return end
    if data.skeletonLines then
        for _, line in ipairs(data.skeletonLines) do
            line:Remove()
        end
    end
    data.skeletonLines = {}
    for i = 1, 15 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Color3.fromRGB(0, 255, 0)  -- default green, will update per frame
        line.Visible = false
        table.insert(data.skeletonLines, line)
    end
end

-- Update skeleton positions and colors
local function updateSkeleton(player, model, data, isAlive)
    if not model or not data.skeletonLines then return end
    local skeletonColor = isAlive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    
    local joints = {
        { "Head", "UpperTorso" }, { "UpperTorso", "HumanoidRootPart" },
        { "HumanoidRootPart", "LowerTorso" }, { "LeftUpperArm", "LeftLowerArm" },
        { "LeftLowerArm", "LeftHand" }, { "RightUpperArm", "RightLowerArm" },
        { "RightLowerArm", "RightHand" }, { "LeftUpperLeg", "LeftLowerLeg" },
        { "LeftLowerLeg", "LeftFoot" }, { "RightUpperLeg", "RightLowerLeg" },
        { "RightLowerLeg", "RightFoot" }, { "UpperTorso", "LeftUpperArm" },
        { "UpperTorso", "RightUpperArm" }, { "LowerTorso", "LeftUpperLeg" },
        { "LowerTorso", "RightUpperLeg" },
    }
    local lineIndex = 1
    for _, conn in ipairs(joints) do
        local partA = model:FindFirstChild(conn[1])
        local partB = model:FindFirstChild(conn[2])
        if partA and partB then
            local posA, onA = Camera:WorldToViewportPoint(partA.Position)
            local posB, onB = Camera:WorldToViewportPoint(partB.Position)
            if onA and onB and lineIndex <= #data.skeletonLines then
                local line = data.skeletonLines[lineIndex]
                line.From = Vector2.new(posA.X, posA.Y)
                line.To = Vector2.new(posB.X, posB.Y)
                line.Color = skeletonColor
                line.Visible = true
                lineIndex = lineIndex + 1
            end
        end
    end
    for i = lineIndex, #data.skeletonLines do
        data.skeletonLines[i].Visible = false
    end
end

-- Clear skeleton
local function clearSkeleton(data)
    if data.skeletonLines then
        for _, line in ipairs(data.skeletonLines) do
            line:Remove()
        end
        data.skeletonLines = nil
    end
end

-- Create 2D drawings (green box, blue name, green distance)
local function createDrawings(player)
    if player == LocalPlayer then return nil end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Transparency = 1
    box.Filled = false
    box.Visible = true
    box.ZIndex = 1

    local nameText = Drawing.new("Text")
    nameText.Color = Color3.fromRGB(0, 150, 255)
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = true
    nameText.ZIndex = 1

    local distText = Drawing.new("Text")
    distText.Color = Color3.fromRGB(0, 255, 0)
    distText.Size = 14
    distText.Center = false
    distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distText.Visible = true
    distText.ZIndex = 1

    return { box = box, nameText = nameText, distText = distText }
end

-- Add player to ESP
local function addPlayer(player)
    if player == LocalPlayer or playerData[player] then return end
    local drawings = createDrawings(player)
    if not drawings then return end
    playerData[player] = {
        box = drawings.box,
        nameText = drawings.nameText,
        distText = drawings.distText,
        highlight = nil,
        skeletonLines = nil,
        useSkeleton = false
    }
    task.spawn(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if not model then return end
        local success = attachHighlight(player, model, Color3.fromRGB(0, 255, 0)) -- initial green
        if not success then
            local data = playerData[player]
            if data then
                data.useSkeleton = true
                createSkeleton(player, model)
            end
        end
    end)
end

-- Remove player
local function removePlayer(player)
    local data = playerData[player]
    if data then
        if data.box then data.box:Remove() end
        if data.nameText then data.nameText:Remove() end
        if data.distText then data.distText:Remove() end
        if data.highlight then data.highlight:Destroy() end
        clearSkeleton(data)
        playerData[player] = nil
    end
end

-- Hide all ESP for a player
local function hidePlayerESP(player)
    local data = playerData[player]
    if data then
        if data.box then data.box.Visible = false end
        if data.nameText then data.nameText.Visible = false end
        if data.distText then data.distText.Visible = false end
        if data.highlight then data.highlight.Visible = false end
        if data.skeletonLines then
            for _, line in ipairs(data.skeletonLines) do
                line.Visible = false
            end
        end
    end
end

-- Show all ESP for a player
local function showPlayerESP(player)
    local data = playerData[player]
    if data then
        if data.box then data.box.Visible = true end
        if data.nameText then data.nameText.Visible = true end
        if data.distText then data.distText.Visible = true end
        if data.highlight then data.highlight.Visible = true end
    end
end

-- Master toggle
local function setESPEnabled(enabled)
    espEnabled = enabled
    if not espEnabled then
        for player, data in pairs(playerData) do
            hidePlayerESP(player)
        end
    else
        for player, data in pairs(playerData) do
            showPlayerESP(player)
        end
    end
end

-- Death check toggle
local function setDeathCheck(enabled)
    checkDeath = enabled
end

-- Update loop (handles color based on health)
local function updateESP()
    if not espEnabled then return end
    
    for player, data in pairs(playerData) do
        local model = getCharacter(player)
        local hrp = model and model:FindFirstChild("HumanoidRootPart")
        local humanoid = model and model:FindFirstChild("Humanoid")
        
        -- Determine alive status and visibility
        local isAlive = (hrp and humanoid and humanoid.Health > 0)
        local shouldShow = false
        
        if checkDeath then
            -- Only show if alive
            shouldShow = isAlive
        else
            -- Show if character exists (dead or alive)
            shouldShow = (hrp ~= nil)
        end
        
        if shouldShow and hrp then
            -- Choose outline color based on health (green alive, red dead)
            local outlineColor = isAlive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            
            -- Handle Highlight or skeleton
            if not data.highlight and not data.useSkeleton then
                local success = attachHighlight(player, model, outlineColor)
                if not success then
                    data.useSkeleton = true
                    createSkeleton(player, model)
                end
            elseif data.highlight then
                -- Update highlight color if needed
                if data.highlight.OutlineColor ~= outlineColor then
                    data.highlight:Destroy()
                    attachHighlight(player, model, outlineColor)
                end
                if data.highlight.Parent ~= model then
                    attachHighlight(player, model, outlineColor)
                end
            end
            
            if data.useSkeleton and data.skeletonLines then
                updateSkeleton(player, model, data, isAlive)
            end
            
            -- 2D bounding box and text (always green box, blue name, green distance)
            local pos = hrp.Position
            local distance = nil
            local localChar = LocalPlayer.Character
            local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHrp then
                distance = (pos - localHrp.Position).Magnitude
            end
            
            local footPos, footOn = Camera:WorldToViewportPoint(pos - Vector3.new(0, 3, 0))
            local headPos, headOn = Camera:WorldToViewportPoint(pos + Vector3.new(0, 2.5, 0))
            
            if footOn and headOn then
                local height = footPos.Y - headPos.Y
                local width = height * 0.8
                local left = headPos.X - width / 2
                local top = headPos.Y
                data.box.Size = Vector2.new(width, height)
                data.box.Position = Vector2.new(left, top)
                data.box.Visible = true
                
                data.nameText.Text = player.Name
                data.nameText.Position = Vector2.new(headPos.X, top - 20)
                data.nameText.Visible = true
                
                local distString = distance and string.format("  [%.1f]", distance) or "  [?]"
                data.distText.Text = distString
                data.distText.Position = Vector2.new(headPos.X + (data.nameText.TextBounds.X / 2), top - 20)
                data.distText.Visible = true
            else
                data.box.Visible = false
                data.nameText.Visible = false
                data.distText.Visible = false
            end
        else
            -- Hide everything
            data.box.Visible = false
            data.nameText.Visible = false
            data.distText.Visible = false
            if data.highlight then
                data.highlight:Destroy()
                data.highlight = nil
            end
            if data.skeletonLines then
                for _, line in ipairs(data.skeletonLines) do
                    line.Visible = false
                end
            end
        end
    end
end

-- ========== SETUP ==========
for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if model and playerData[player] then
            -- Try highlight with green first; skeleton will handle color later
            if not attachHighlight(player, model, Color3.fromRGB(0, 255, 0)) then
                playerData[player].useSkeleton = true
                createSkeleton(player, model)
            end
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    addPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if model and playerData[player] then
            if not attachHighlight(player, model, Color3.fromRGB(0, 255, 0)) then
                playerData[player].useSkeleton = true
                createSkeleton(player, model)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(removePlayer)

RunService.RenderStepped:Connect(updateESP)

-- Cleanup
local function fullClean()
    for player, data in pairs(playerData) do
        if data.box then data.box:Remove() end
        if data.nameText then data.nameText:Remove() end
        if data.distText then data.distText:Remove() end
        if data.highlight then data.highlight:Destroy() end
        clearSkeleton(data)
    end
    playerData = {}
end
game:GetService("ScriptContext").Error:Connect(fullClean)

-- Console toggles
_G.setESP = setESPEnabled
_G.ESPEnabled = espEnabled
_G.setDeathCheck = setDeathCheck
_G.checkDeath = checkDeath
