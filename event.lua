-- ESP: Green 2D box + (Red chams outline OR Skeleton) + Blue name + Green distance
-- Uses workspace.Game.Players[player.Name] for character access

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local playerData = {} -- { box, nameText, distText, highlight, skeletonLines, useSkeleton }

-- Helper: get character model from custom path
local function getCharacter(player)
    local gameFolder = workspace.Game
    if not gameFolder then return nil end
    local playersFolder = gameFolder.Players
    if not playersFolder then return nil end
    return playersFolder:FindFirstChild(player.Name)
end

-- Try to attach red chams outline (Highlight)
local function attachHighlight(player, model)
    if not model then return nil end
    local data = playerData[player]
    if not data then return nil end
    if data.highlight then
        data.highlight:Destroy()
        data.highlight = nil
    end
    local success, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Parent = model
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(255, 0, 0) -- red
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

-- Create skeleton lines (if Highlight fails)
local function createSkeleton(player, model)
    local data = playerData[player]
    if not data then return end
    -- Destroy old skeleton lines
    if data.skeletonLines then
        for _, line in ipairs(data.skeletonLines) do
            line:Remove()
        end
    end
    data.skeletonLines = {}
    -- We'll create lines on the fly in update loop, but pre-allocate line objects
    for i = 1, 12 do -- max joints pairs
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 0, 0) -- red skeleton
        line.Visible = false
        table.insert(data.skeletonLines, line)
    end
end

-- Update skeleton positions (draw 2D lines between joints)
local function updateSkeleton(player, model, data)
    if not model or not data.skeletonLines then return end
    -- Define joint names and connections (from, to)
    local joints = {
        { "Head", "UpperTorso" },
        { "UpperTorso", "HumanoidRootPart" },
        { "HumanoidRootPart", "LowerTorso" },
        { "LeftUpperArm", "LeftLowerArm" },
        { "LeftLowerArm", "LeftHand" },
        { "RightUpperArm", "RightLowerArm" },
        { "RightLowerArm", "RightHand" },
        { "LeftUpperLeg", "LeftLowerLeg" },
        { "LeftLowerLeg", "LeftFoot" },
        { "RightUpperLeg", "RightLowerLeg" },
        { "RightLowerLeg", "RightFoot" },
        { "UpperTorso", "LeftUpperArm" },
        { "UpperTorso", "RightUpperArm" },
        { "LowerTorso", "LeftUpperLeg" },
        { "LowerTorso", "RightUpperLeg" },
    }
    local lineIndex = 1
    for _, conn in ipairs(joints) do
        local partA = model:FindFirstChild(conn[1])
        local partB = model:FindFirstChild(conn[2])
        if partA and partB then
            local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
            local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)
            if onScreenA and onScreenB and lineIndex <= #data.skeletonLines then
                local line = data.skeletonLines[lineIndex]
                line.From = Vector2.new(posA.X, posA.Y)
                line.To = Vector2.new(posB.X, posB.Y)
                line.Visible = true
                lineIndex = lineIndex + 1
            end
        end
    end
    -- Hide unused lines
    for i = lineIndex, #data.skeletonLines do
        data.skeletonLines[i].Visible = false
    end
end

-- Clean skeleton lines
local function clearSkeleton(data)
    if data.skeletonLines then
        for _, line in ipairs(data.skeletonLines) do
            line:Remove()
        end
        data.skeletonLines = nil
    end
end

-- Create 2D drawing objects (green box, blue name, green distance)
local function createDrawings(player)
    if player == LocalPlayer then return nil end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(0, 255, 0) -- green box
    box.Transparency = 1
    box.Filled = false
    box.Visible = true
    box.ZIndex = 1

    local nameText = Drawing.new("Text")
    nameText.Color = Color3.fromRGB(0, 150, 255) -- blue name
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = true
    nameText.ZIndex = 1

    local distText = Drawing.new("Text")
    distText.Color = Color3.fromRGB(0, 255, 0) -- green distance
    distText.Size = 14
    distText.Center = false
    distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distText.Visible = true
    distText.ZIndex = 1

    return { box = box, nameText = nameText, distText = distText }
end

-- Add a player to ESP
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
    -- Delay to let character load
    task.spawn(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if not model then return end
        -- Try to attach Highlight, if fails then use skeleton
        local hlSuccess = attachHighlight(player, model)
        if not hlSuccess then
            -- Fallback to skeleton
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

-- Update ESP every frame
local function updateESP()
    for player, data in pairs(playerData) do
        local model = getCharacter(player)
        local hrp = model and model:FindFirstChild("HumanoidRootPart")
        local humanoid = model and model:FindFirstChild("Humanoid")
        
        if hrp and humanoid and humanoid.Health > 0 then
            -- Ensure highlight or skeleton is active
            if not data.highlight and not data.useSkeleton then
                -- Try Highlight again (maybe character respawned)
                local success = attachHighlight(player, model)
                if not success then
                    data.useSkeleton = true
                    createSkeleton(player, model)
                end
            elseif data.highlight and data.highlight.Parent ~= model then
                -- Re-attach highlight if model changed
                attachHighlight(player, model)
            end
            
            -- If using skeleton, update its lines
            if data.useSkeleton and data.skeletonLines then
                updateSkeleton(player, model, data)
            end
            
            -- 2D green bounding box and text
            local pos = hrp.Position
            -- Distance from local player
            local distance = nil
            local localChar = LocalPlayer.Character
            local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHrp then
                distance = (pos - localHrp.Position).Magnitude
            end
            
            -- Feet and head screen positions
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
                
                -- Blue name
                data.nameText.Text = player.Name
                data.nameText.Position = Vector2.new(headPos.X, top - 20)
                data.nameText.Visible = true
                
                -- Green distance (placed after name)
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
            -- Character dead or missing
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
-- Existing players
for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if model and playerData[player] then
            if not attachHighlight(player, model) then
                playerData[player].useSkeleton = true
                createSkeleton(player, model)
            end
        end
    end)
end

-- New players
Players.PlayerAdded:Connect(function(player)
    addPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        local model = getCharacter(player)
        if model and playerData[player] then
            if not attachHighlight(player, model) then
                playerData[player].useSkeleton = true
                createSkeleton(player, model)
            end
        end
    end)
end)

-- Player leaves
Players.PlayerRemoving:Connect(removePlayer)

-- Start render loop
RunService.RenderStepped:Connect(updateESP)

-- Cleanup on script end
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
