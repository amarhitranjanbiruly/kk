-- ESP: Green 2D box + Blue name + Green distance
-- Outline (chams/skeleton): Green = alive, Red = dead
-- Death check toggle (checkDeath): true = hide dead, false = show dead with red outline
-- Auto‑detects new players, respawns, health changes
-- FIXED: Full refresh every 5 minutes + error handling in update loop

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espEnabled = true       -- Master ESP on/off
local checkDeath = false      -- true = hide dead, false = show dead (with red outline)
local playerData = {}         -- Stores all drawing objects and state per player

-- Helper: get character model from custom path
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

-- Create skeleton lines (fallback) – color will be updated per frame
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
        line.Color = Color3.fromRGB(0, 255, 0)  -- temp, will be updated
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

-- Add a player to ESP (called for new players and initially)
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
        useSkeleton = false,
        lastHealth = nil,
        lastModel = nil
    }
    task.spawn(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if model and playerData[player] then
            if not attachHighlight(player, model, Color3.fromRGB(0, 255, 0)) then
                playerData[player].useSkeleton = true
                createSkeleton(player, model)
            end
            playerData[player].lastModel = model
        end
    end)
end

-- Remove player (cleanup)
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

-- Master toggle
local function setESPEnabled(enabled)
    espEnabled = enabled
    if not espEnabled then
        for player, data in pairs(playerData) do
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
end

-- Death check toggle
local function setDeathCheck(enabled)
    checkDeath = enabled
end

-- FULL REFRESH: destroys everything and recreates all ESP objects
local function fullRefresh()
    -- Store current enable state
    local wasEnabled = espEnabled
    espEnabled = false
    
    -- Remove all players from ESP
    for player, data in pairs(playerData) do
        if data.box then data.box:Remove() end
        if data.nameText then data.nameText:Remove() end
        if data.distText then data.distText:Remove() end
        if data.highlight then data.highlight:Destroy() end
        clearSkeleton(data)
    end
    playerData = {}
    
    -- Re‑add all current players
    for _, player in ipairs(Players:GetPlayers()) do
        addPlayer(player)
    end
    
    -- Restore enable state
    espEnabled = wasEnabled
end

-- Auto‑refresh timer (every 5 minutes = 300 seconds)
task.spawn(function()
    while true do
        task.wait(1)  -- 5 minutes
        if espEnabled then
            fullRefresh()
        end
    end
end)

-- Main update loop with error protection
local function updateESP()
    -- Protect the entire loop so errors don't break the connection
    local success, err = pcall(function()
        if not espEnabled then
            for player, data in pairs(playerData) do
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
            return
        end
        
        for player, data in pairs(playerData) do
            local model = getCharacter(player)
            local hrp = model and model:FindFirstChild("HumanoidRootPart")
            local humanoid = model and model:FindFirstChild("Humanoid")
            local currentHealth = humanoid and humanoid.Health or 0
            local isAlive = (hrp and humanoid and currentHealth > 0)
            
            -- Check if model changed (respawn) or health changed
            local modelChanged = (model ~= data.lastModel)
            local healthChanged = (currentHealth ~= data.lastHealth)
            if modelChanged or healthChanged then
                data.lastModel = model
                data.lastHealth = currentHealth
                if data.highlight then
                    data.highlight:Destroy()
                    data.highlight = nil
                end
                if data.skeletonLines then
                    clearSkeleton(data)
                    data.useSkeleton = false
                end
            end
            
            local shouldShow = false
            if checkDeath then
                shouldShow = isAlive
            else
                shouldShow = (hrp ~= nil)
            end
            
            if shouldShow and hrp then
                local outlineColor = isAlive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                
                if not data.highlight and not data.useSkeleton then
                    local success = attachHighlight(player, model, outlineColor)
                    if not success then
                        data.useSkeleton = true
                        createSkeleton(player, model)
                    end
                elseif data.highlight then
                    if data.highlight.OutlineColor ~= outlineColor then
                        attachHighlight(player, model, outlineColor)
                    end
                    if data.highlight.Parent ~= model then
                        attachHighlight(player, model, outlineColor)
                    end
                end
                
                if data.useSkeleton and data.skeletonLines then
                    updateSkeleton(player, model, data, isAlive)
                end
                
                -- 2D bounding box and text
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
    end)
    if not success then
        warn("ESP update error: ", err)
    end
end

-- ========== EVENT HOOKS ==========
for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

RunService.RenderStepped:Connect(updateESP)

-- Cleanup on script end (or when error occurs)
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

_G.setESP = setESPEnabled
_G.ESPEnabled = espEnabled
_G.setDeathCheck = setDeathCheck
_G.checkDeath = checkDeath
