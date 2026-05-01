loadstring(game:HttpGet(""))()




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
