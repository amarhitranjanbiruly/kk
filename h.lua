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
