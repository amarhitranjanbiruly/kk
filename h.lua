loadstring(game:HttpGet('https://raw.githubusercontent.com/amarhitranjanbiruly/kk/refs/heads/main/gh'))()

-- ESP for workspace.Ghost (Fixed with per-part outlines)
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local maxDistance = 100
local updateInterval = 50          -- milliseconds
local maxRAMLimitMB = 1000

-- Create reusable drawing objects (global box, line, health, name, dist)
local function createMainDrawings()
    local newBox = Drawing.new("Square")
    local newLine = Drawing.new("Line")
    local newHealth = Drawing.new("Line")
    local newName = Drawing.new("Text")
    local newDist = Drawing.new("Text")

    newBox.Thickness = 2
    newBox.Filled = false
    newBox.Transparency = 0
    newBox.Color = Color3.fromRGB(255, 0, 0)  -- red global box

    newLine.Thickness = 1
    newLine.Transparency = 0

    newHealth.Thickness = 3
    newHealth.Transparency = 0
    newHealth.Color = Color3.fromRGB(0, 255, 0)

    newName.Size = 13
    newName.Center = true
    newName.Outline = true
    newName.Transparency = 0
    newName.Color = Color3.fromRGB(255, 255, 255)

    newDist.Size = 13
    newDist.Center = true
    newDist.Outline = true
    newDist.Transparency = 0
    newDist.Color = Color3.fromRGB(0, 255, 0)

    return {box = newBox, line = newLine, health = newHealth, name = newName, dist = newDist}
end

-- Memory check
local function getMemoryUsageMB()
    return collectgarbage("count") / 1024
end

-- Visibility check (angle + raycast)
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
    return (not result) or result.Instance:IsDescendantOf(targetCharacter)
end

-- Helper: Get 2D screen bounding box of a BasePart (returns {minX, maxX, minY, maxY} or nil if off-screen)
local function getPartScreenBox(part)
    local cframe = part.CFrame
    local size = part.Size
    local half = size / 2

    local corners = {
        cframe * Vector3.new(-half.X, -half.Y, -half.Z),
        cframe * Vector3.new( half.X, -half.Y, -half.Z),
        cframe * Vector3.new(-half.X,  half.Y, -half.Z),
        cframe * Vector3.new( half.X,  half.Y, -half.Z),
        cframe * Vector3.new(-half.X, -half.Y,  half.Z),
        cframe * Vector3.new( half.X, -half.Y,  half.Z),
        cframe * Vector3.new(-half.X,  half.Y,  half.Z),
        cframe * Vector3.new( half.X,  half.Y,  half.Z)
    }

    local minX, maxX, minY, maxY
    local anyOnScreen = false

    for _, corner in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
        if onScreen then
            anyOnScreen = true
            if not minX then
                minX, maxX, minY, maxY = screenPos.X, screenPos.X, screenPos.Y, screenPos.Y
            else
                minX = math.min(minX, screenPos.X)
                maxX = math.max(maxX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxY = math.max(maxY, screenPos.Y)
            end
        end
    end

    if anyOnScreen then
        return {minX = minX, maxX = maxX, minY = minY, maxY = maxY}
    end
    return nil
end

-- Main ESP runner
local function runESP(ghostInstance)
    local mainDrawings = createMainDrawings()
    local outlineDrawings = {}  -- map: part -> drawing (Square)
    local active = true

    local function cleanup()
        active = false
        for _, d in pairs(mainDrawings) do
            pcall(function() d:Remove() end)
        end
        for _, d in pairs(outlineDrawings) do
            pcall(function() d:Remove() end)
        end
        table.clear(outlineDrawings)
    end

    task.spawn(function()
        while active and ghostInstance and ghostInstance.Parent do
            if getMemoryUsageMB() > maxRAMLimitMB then
                task.wait(1)
                continue
            end

            local humanoid = ghostInstance:FindFirstChildOfClass("Humanoid")
            local head = ghostInstance:FindFirstChild("Head")
            local hrp = ghostInstance:FindFirstChild("HumanoidRootPart")
            local visiblePartsFolder = ghostInstance:FindFirstChild("VisibleParts")

            if humanoid and head and hrp and humanoid.Health > 0 then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                if distance <= maxDistance then
                    -- Check visibility of head for the line color
                    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                    local visible = headOnScreen and isVisible(head, ghostInstance)
                    local lineColor = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

                    -- Line from top center to head (if head is on screen)
                    if headOnScreen then
                        local screenSize = Camera.ViewportSize
                        local topCenter = Vector2.new(screenSize.X / 2, 0)
                        mainDrawings.line.Visible = true
                        mainDrawings.line.From = topCenter
                        mainDrawings.line.To = Vector2.new(headPos.X, headPos.Y)
                        mainDrawings.line.Color = lineColor
                    else
                        mainDrawings.line.Visible = false
                    end

                    ---------------------------
                    -- Per-part outlines (green)
                    ---------------------------
                    -- First, mark all existing outline drawings as "still needed"
                    for part, drawing in pairs(outlineDrawings) do
                        outlineDrawings[part] = drawing  -- just keep reference, will check existence later
                    end

                    if visiblePartsFolder then
                        local partsToKeep = {}
                        for _, part in ipairs(visiblePartsFolder:GetChildren()) do
                            if part:IsA("BasePart") then
                                local box = getPartScreenBox(part)
                                if box then
                                    -- Get or create outline drawing for this part
                                    local drawing = outlineDrawings[part]
                                    if not drawing then
                                        drawing = Drawing.new("Square")
                                        drawing.Thickness = 2
                                        drawing.Filled = false
                                        drawing.Transparency = 0
                                        drawing.Color = Color3.fromRGB(0, 255, 0)  -- green
                                        outlineDrawings[part] = drawing
                                    end
                                    drawing.Visible = true
                                    drawing.Position = Vector2.new(box.minX, box.minY)
                                    drawing.Size = Vector2.new(box.maxX - box.minX, box.maxY - box.minY)
                                    partsToKeep[part] = true
                                else
                                    -- Part off-screen: hide its outline if it exists
                                    local drawing = outlineDrawings[part]
                                    if drawing then drawing.Visible = false end
                                    partsToKeep[part] = true
                                end
                            end
                        end
                        -- Remove outline drawings for parts that no longer exist
                        for part, drawing in pairs(outlineDrawings) do
                            if not partsToKeep[part] then
                                drawing:Remove()
                                outlineDrawings[part] = nil
                            end
                        end
                    else
                        -- No VisibleParts folder: hide all outlines
                        for _, drawing in pairs(outlineDrawings) do
                            drawing.Visible = false
                        end
                    end

                    ---------------------------
                    -- Global bounding box (from all visible parts)
                    ---------------------------
                    local overallBox = nil
                    if visiblePartsFolder then
                        for _, part in ipairs(visiblePartsFolder:GetChildren()) do
                            if part:IsA("BasePart") then
                                local partBox = getPartScreenBox(part)
                                if partBox then
                                    if not overallBox then
                                        overallBox = {minX = partBox.minX, maxX = partBox.maxX, minY = partBox.minY, maxY = partBox.maxY}
                                    else
                                        overallBox.minX = math.min(overallBox.minX, partBox.minX)
                                        overallBox.maxX = math.max(overallBox.maxX, partBox.maxX)
                                        overallBox.minY = math.min(overallBox.minY, partBox.minY)
                                        overallBox.maxY = math.max(overallBox.maxY, partBox.maxY)
                                    end
                                end
                            end
                        end
                    end

                    if overallBox then
                        mainDrawings.box.Visible = true
                        mainDrawings.box.Position = Vector2.new(overallBox.minX, overallBox.minY)
                        mainDrawings.box.Size = Vector2.new(overallBox.maxX - overallBox.minX, overallBox.maxY - overallBox.minY)

                        -- Health bar (left side of global box)
                        local hpRatio = humanoid.Health / humanoid.MaxHealth
                        local barX = overallBox.minX - 6
                        local barTop = overallBox.minY
                        local barBottom = overallBox.maxY
                        mainDrawings.health.Visible = true
                        mainDrawings.health.From = Vector2.new(barX, barBottom)
                        mainDrawings.health.To = Vector2.new(barX, barBottom - ((barBottom - barTop) * hpRatio))

                        -- Name text (below global box)
                        mainDrawings.name.Visible = true
                        mainDrawings.name.Text = "Ghost"
                        mainDrawings.name.Position = Vector2.new((overallBox.minX + overallBox.maxX) / 2, overallBox.maxY + 10)

                        -- Distance text (above global box)
                        mainDrawings.dist.Visible = true
                        mainDrawings.dist.Text = string.format("%dm", math.floor(distance))
                        mainDrawings.dist.Position = Vector2.new((overallBox.minX + overallBox.maxX) / 2, overallBox.minY - 15)
                    else
                        -- No part on screen: hide global elements
                        mainDrawings.box.Visible = false
                        mainDrawings.health.Visible = false
                        mainDrawings.name.Visible = false
                        mainDrawings.dist.Visible = false
                    end
                else
                    -- Out of distance: hide everything
                    mainDrawings.box.Visible = false
                    mainDrawings.line.Visible = false
                    mainDrawings.health.Visible = false
                    mainDrawings.name.Visible = false
                    mainDrawings.dist.Visible = false
                    for _, drawing in pairs(outlineDrawings) do
                        drawing.Visible = false
                    end
                end
            else
                -- Dead or missing parts: hide all
                mainDrawings.box.Visible = false
                mainDrawings.line.Visible = false
                mainDrawings.health.Visible = false
                mainDrawings.name.Visible = false
                mainDrawings.dist.Visible = false
                for _, drawing in pairs(outlineDrawings) do
                    drawing.Visible = false
                end
            end

            task.wait(updateInterval / 1000)
        end
        cleanup()
    end)

    return cleanup
end

-- Wait for Ghost instance and manage ESP lifecycle
local ghost = workspace:FindFirstChild("Ghost")
local currentCleanup = nil

local function startOnGhost(ghostObj)
    if currentCleanup then currentCleanup() end
    currentCleanup = runESP(ghostObj)
end

if ghost then
    startOnGhost(ghost)
else
    workspace.ChildAdded:Wait()  -- Wait for Ghost to appear
    startOnGhost(workspace.Ghost)
end

-- Handle re-add / removal
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Ghost" then
        startOnGhost(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Ghost" and currentCleanup then
        currentCleanup()
        currentCleanup = nil
    end
end)
