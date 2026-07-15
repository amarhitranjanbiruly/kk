-- Auto Melee + Aimbot – Standalone (with Target Lock)
-- R key: Toggle or Hold (selectable in GUI)
-- L key: hide/show GUI
-- M key: toggle melee ON/OFF

local Players = game:GetService("Players")
local Run     = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local VIM     = game:GetService("VirtualInputManager")
local WS      = game:GetService("Workspace")
local SG      = game:GetService("StarterGui")
local lp      = Players.LocalPlayer

-- ── Settings ──────────────────────────────────────────────────────────────
local Settings = {
    meleeEnabled  = false,
    meleeRange    = 25,
    aimbotEnabled = false,
    aimbotFOV     = 150,
    smoothing     = 0.9,
    teamCheck     = false,
    aimbotMode    = "Hold",
}

-- ── Global locked target ─────────────────────────────────────────────────
local lockedTarget = nil   -- stores the enemy table {model, root}

-- ── Entity helpers ──────────────────────────────────────────────────────
local function getEntitiesFolder()
    return WS:FindFirstChild("Entities")
end

local function getMyChar()
    return lp.Character
end

local function getMyRoot()
    local c = getMyChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getOwnerPlayer(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then return plr end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return p end
    end
    return nil
end

local function isSameTeam(model)
    if not Settings.teamCheck then return false end
    local plr = getOwnerPlayer(model)
    if not plr then return false end
    if not plr.Team or not lp.Team then return false end
    return plr.Team == lp.Team
end

local function getEnemies()
    local myChar = getMyChar()
    local seen   = {}
    local t      = {}

    local function tryAdd(model)
        if not model or model == myChar or seen[model] then return end
        local hum  = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if hum and hum.Health > 0 and root then
            if isSameTeam(model) then return end
            seen[model] = true
            t[#t+1] = {model = model, root = root}
        end
    end

    local ef = getEntitiesFolder()
    if ef then
        for _, e in ipairs(ef:GetChildren()) do
            tryAdd(e)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            tryAdd(plr.Character)
        end
    end

    return t
end

-- ── Nearest enemy for aimbot (with FOV) ────────────────────────────────
local function getNearestEnemy()
    local cam = WS.CurrentCamera
    local center = cam.ViewportSize / 2
    local best, bestDist = nil, math.huge

    for _, e in ipairs(getEnemies()) do
        local head = e.model:FindFirstChild("Head") or e.root
        local pos, vis = cam:WorldToViewportPoint(head.Position)
        if vis then
            local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if d < bestDist and d <= Settings.aimbotFOV then
                bestDist = d
                best = e
            end
        end
    end
    return best
end

-- ── Check if locked target is still valid ──────────────────────────────
local function isValidTarget(target)
    if not target then return false end
    local model = target.model
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root then return false end
    local myRoot = getMyRoot()
    if myRoot and (root.Position - myRoot.Position).Magnitude > 300 then
        return false
    end
    if isSameTeam(model) then return false end
    return true
end

-- ── Nearest enemy for melee (no FOV, 360°) ─────────────────────────────
local function getNearestEnemyForMelee()
    local myRoot = getMyRoot()
    if not myRoot then return nil end
    local best, bestDist = nil, math.huge
    for _, e in ipairs(getEnemies()) do
        local dist = (e.root.Position - myRoot.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = e
        end
    end
    return best
end

-- ── Auto Melee Logic (now rotates character instead of camera) ──────────
local meleeCooldown = false

local function clickM1()
    pcall(function()
        local mp = UIS:GetMouseLocation()
        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0)
        task.wait(0.04)
        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
    end)
end

-- ── Aimbot Logic (with target lock) ──────────────────────────────────────
local aimbotStep = "GothamAimbotStep"

local function startAimbot()
    Run:BindToRenderStep(aimbotStep, Enum.RenderPriority.Last.Value, function()
        if not Settings.aimbotEnabled then return end
        local myRoot = getMyRoot()
        if not myRoot then return end

        if not isValidTarget(lockedTarget) then
            lockedTarget = getNearestEnemy()
        end

        if lockedTarget then
            local head = lockedTarget.model:FindFirstChild("Head") or lockedTarget.root
            local cam = WS.CurrentCamera
            local targetPos = head.Position + Vector3.new(0, 0.25, 0)

            if Settings.smoothing >= 0.999 then
                cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
            else
                local goalCFrame = CFrame.new(cam.CFrame.Position, targetPos)
                cam.CFrame = cam.CFrame:Lerp(goalCFrame, Settings.smoothing)
            end
        end
    end)
end

local function stopAimbot()
    lockedTarget = nil
    pcall(function() Run:UnbindFromRenderStep(aimbotStep) end)
end

-- ── Keybinds ──────────────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    
    -- REMOVE this line for L key (important fix)
    -- if gameProcessed then return end  

    if input.KeyCode == Enum.KeyCode.K then
        if win and win.Parent then
            win.Visible = not win.Visible
        end
    end

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R then
        if Settings.aimbotMode == "Toggle" then
            Settings.aimbotEnabled = not Settings.aimbotEnabled
            if Settings.aimbotEnabled then
                lockedTarget = nil
                startAimbot()
            else
                stopAimbot()
            end
        else
            Settings.aimbotEnabled = true
            lockedTarget = nil
            startAimbot()
        end
    end

    if input.KeyCode == Enum.KeyCode.M then
        Settings.meleeEnabled = not Settings.meleeEnabled
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R and Settings.aimbotMode == "Hold" then
        Settings.aimbotEnabled = false
        stopAimbot()
        if aimToggleBtn then
            aimToggleBtn.Text = "Aimbot OFF"
            aimToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
    end
end)

-- ── Heartbeat for Melee (rotates character, not camera) ────────────────
local meleeConn
meleeConn = Run.Heartbeat:Connect(function()
    if not Settings.meleeEnabled or meleeCooldown then return end
    local myRoot = getMyRoot()
    if not myRoot then return end

    local target = getNearestEnemyForMelee()
    if target and (target.root.Position - myRoot.Position).Magnitude <= Settings.meleeRange then
        -- Rotate character (HumanoidRootPart) to face the enemy, but keep upright
        local lookPos = Vector3.new(target.root.Position.X, myRoot.Position.Y, target.root.Position.Z)
        myRoot.CFrame = CFrame.new(myRoot.Position, lookPos)

        -- Click without moving the camera
        clickM1()
        meleeCooldown = true
        task.delay(0.15, function()
            meleeCooldown = false
        end)
    end
end)

-- ── GUI (unchanged) ──────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AutoCombatGUI"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 340, 0, 310)
win.Position = UDim2.new(0.5, -170, 0.5, -155)
win.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
Instance.new("UICorner").Parent = win

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "⚔ Auto Combat"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = win

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = win
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    meleeConn:Disconnect()
    stopAimbot()
end)

-- Melee toggle
local meleeToggleBtn = Instance.new("TextButton")
meleeToggleBtn.Size = UDim2.new(0, 120, 0, 34)
meleeToggleBtn.Position = UDim2.new(0.08, 0, 0, 40)
meleeToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
meleeToggleBtn.BorderSizePixel = 0
meleeToggleBtn.Text = "Melee OFF"
meleeToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
meleeToggleBtn.Font = Enum.Font.GothamBold
meleeToggleBtn.TextSize = 14
meleeToggleBtn.Parent = win
Instance.new("UICorner").Parent = meleeToggleBtn

meleeToggleBtn.MouseButton1Click:Connect(function()
    Settings.meleeEnabled = not Settings.meleeEnabled
    meleeToggleBtn.Text = Settings.meleeEnabled and "Melee ON" or "Melee OFF"
    meleeToggleBtn.BackgroundColor3 = Settings.meleeEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 70)
end)

-- Aimbot toggle
local aimToggleBtn = Instance.new("TextButton")
aimToggleBtn.Size = UDim2.new(0, 120, 0, 34)
aimToggleBtn.Position = UDim2.new(0.55, 0, 0, 40)
aimToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
aimToggleBtn.BorderSizePixel = 0
aimToggleBtn.Text = "Aimbot OFF"
aimToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
aimToggleBtn.Font = Enum.Font.GothamBold
aimToggleBtn.TextSize = 14
aimToggleBtn.Parent = win
Instance.new("UICorner").Parent = aimToggleBtn

aimToggleBtn.MouseButton1Click:Connect(function()
    Settings.aimbotEnabled = not Settings.aimbotEnabled
    if Settings.aimbotEnabled then
        lockedTarget = nil
        startAimbot()
    else
        stopAimbot()
    end
    aimToggleBtn.Text = Settings.aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
    aimToggleBtn.BackgroundColor3 = Settings.aimbotEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 70)
end)

-- Mode selection button
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0, 130, 0, 26)
modeBtn.Position = UDim2.new(0.5, -65, 0, 82)
modeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
modeBtn.BorderSizePixel = 0
modeBtn.Text = "Mode: Hold"
modeBtn.TextColor3 = Color3.fromRGB(255, 255, 200)
modeBtn.Font = Enum.Font.Gotham
modeBtn.TextSize = 12
modeBtn.Parent = win
Instance.new("UICorner").Parent = modeBtn

modeBtn.MouseButton1Click:Connect(function()
    if Settings.aimbotMode == "Toggle" then
        Settings.aimbotMode = "Hold"
        modeBtn.Text = "Mode: Hold"
    else
        Settings.aimbotMode = "Toggle"
        modeBtn.Text = "Mode: Toggle"
    end
    if Settings.aimbotEnabled and Settings.aimbotMode == "Hold" then
        Settings.aimbotEnabled = false
        stopAimbot()
        aimToggleBtn.Text = "Aimbot OFF"
        aimToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
end)

-- Sliders (Melee Range, FOV, Smoothing)
local meleeLabel = Instance.new("TextLabel")
meleeLabel.Size = UDim2.new(0.45, 0, 0, 20)
meleeLabel.Position = UDim2.new(0.05, 0, 0, 116)
meleeLabel.BackgroundTransparency = 1
meleeLabel.Text = "Melee Range: 12"
meleeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
meleeLabel.Font = Enum.Font.Gotham
meleeLabel.TextSize = 12
meleeLabel.TextXAlignment = Enum.TextXAlignment.Left
meleeLabel.Parent = win

local meleeSlider = Instance.new("Frame")
meleeSlider.Size = UDim2.new(0.4, 0, 0, 6)
meleeSlider.Position = UDim2.new(0.05, 0, 0, 140)
meleeSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
meleeSlider.BorderSizePixel = 0
meleeSlider.Parent = win
Instance.new("UICorner").Parent = meleeSlider

local meleeFill = Instance.new("Frame")
meleeFill.Size = UDim2.new(0.5, 0, 1, 0)
meleeFill.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
meleeFill.BorderSizePixel = 0
meleeFill.Parent = meleeSlider
Instance.new("UICorner").Parent = meleeFill

local meleeKnob = Instance.new("TextButton")
meleeKnob.Size = UDim2.new(0, 14, 0, 14)
meleeKnob.Position = UDim2.new(0.5, -7, 0.5, -7)
meleeKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
meleeKnob.BorderSizePixel = 0
meleeKnob.Text = ""
meleeKnob.Parent = meleeSlider
Instance.new("UICorner").Parent = meleeKnob

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0.45, 0, 0, 20)
fovLabel.Position = UDim2.new(0.55, 0, 0, 116)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV: 150"
fovLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextSize = 12
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = win

local fovSlider = Instance.new("Frame")
fovSlider.Size = UDim2.new(0.4, 0, 0, 6)
fovSlider.Position = UDim2.new(0.55, 0, 0, 140)
fovSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
fovSlider.BorderSizePixel = 0
fovSlider.Parent = win
Instance.new("UICorner").Parent = fovSlider

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0.5, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
fovFill.BorderSizePixel = 0
fovFill.Parent = fovSlider
Instance.new("UICorner").Parent = fovFill

local fovKnob = Instance.new("TextButton")
fovKnob.Size = UDim2.new(0, 14, 0, 14)
fovKnob.Position = UDim2.new(0.5, -7, 0.5, -7)
fovKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fovKnob.BorderSizePixel = 0
fovKnob.Text = ""
fovKnob.Parent = fovSlider
Instance.new("UICorner").Parent = fovKnob

local smoothLabel = Instance.new("TextLabel")
smoothLabel.Size = UDim2.new(1, -20, 0, 20)
smoothLabel.Position = UDim2.new(0, 10, 0, 166)
smoothLabel.BackgroundTransparency = 1
smoothLabel.Text = "Smoothing: 0.90"
smoothLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
smoothLabel.Font = Enum.Font.Gotham
smoothLabel.TextSize = 12
smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
smoothLabel.Parent = win

local smoothSlider = Instance.new("Frame")
smoothSlider.Size = UDim2.new(1, -20, 0, 6)
smoothSlider.Position = UDim2.new(0, 10, 0, 190)
smoothSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
smoothSlider.BorderSizePixel = 0
smoothSlider.Parent = win
Instance.new("UICorner").Parent = smoothSlider

local smoothFill = Instance.new("Frame")
smoothFill.Size = UDim2.new(0.9, 0, 1, 0)
smoothFill.BackgroundColor3 = Color3.fromRGB(200, 200, 80)
smoothFill.BorderSizePixel = 0
smoothFill.Parent = smoothSlider
Instance.new("UICorner").Parent = smoothFill

local smoothKnob = Instance.new("TextButton")
smoothKnob.Size = UDim2.new(0, 14, 0, 14)
smoothKnob.Position = UDim2.new(0.9, -7, 0.5, -7)
smoothKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
smoothKnob.BorderSizePixel = 0
smoothKnob.Text = ""
smoothKnob.Parent = smoothSlider
Instance.new("UICorner").Parent = smoothKnob

-- TeamCheck toggle
local teamBtn = Instance.new("TextButton")
teamBtn.Size = UDim2.new(0, 120, 0, 26)
teamBtn.Position = UDim2.new(0.08, 0, 0, 220)
teamBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
teamBtn.BorderSizePixel = 0
teamBtn.Text = "TeamCheck OFF"
teamBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
teamBtn.Font = Enum.Font.Gotham
teamBtn.TextSize = 12
teamBtn.Parent = win
Instance.new("UICorner").Parent = teamBtn

teamBtn.MouseButton1Click:Connect(function()
    Settings.teamCheck = not Settings.teamCheck
    teamBtn.Text = Settings.teamCheck and "TeamCheck ON" or "TeamCheck OFF"
    teamBtn.BackgroundColor3 = Settings.teamCheck and Color3.fromRGB(40, 80, 120) or Color3.fromRGB(50, 50, 60)
end)

-- Info text
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 255)
info.BackgroundTransparency = 1
info.Text = "R = aimbot • M = melee • L = hide/show GUI"
info.TextColor3 = Color3.fromRGB(180, 180, 180)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = win

-- Slider update functions
local function makeSlider(sliderFill, sliderKnob, label, minVal, maxVal, step, initial, callback)
    local current = initial
    local dragging = false
    sliderKnob.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    Run.Heartbeat:Connect(function()
        if not dragging then return end
        local absPos = sliderFill.Parent.AbsolutePosition
        local absSize = sliderFill.Parent.AbsoluteSize
        local mousePos = UIS:GetMouseLocation()
        local ratio = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
        local raw = minVal + ratio * (maxVal - minVal)
        local rounded = math.floor(raw / step + 0.5) * step
        rounded = math.clamp(rounded, minVal, maxVal)
        if rounded ~= current then
            current = rounded
            local r2 = (current - minVal) / (maxVal - minVal)
            sliderFill.Size = UDim2.new(r2, 0, 1, 0)
            sliderKnob.Position = UDim2.new(r2, -7, 0.5, -7)
            label.Text = label.Text:gsub("%d+[%.%d]*$", tostring(current))
            callback(current)
        end
    end)
    local r0 = (current - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(r0, 0, 1, 0)
    sliderKnob.Position = UDim2.new(r0, -7, 0.5, -7)
    label.Text = label.Text:gsub("%d+[%.%d]*$", tostring(current))
end

makeSlider(meleeFill, meleeKnob, meleeLabel, 2, 40, 1, 12, function(v)
    Settings.meleeRange = v
end)

makeSlider(fovFill, fovKnob, fovLabel, 30, 400, 5, 150, function(v)
    Settings.aimbotFOV = v
end)

makeSlider(smoothFill, smoothKnob, smoothLabel, 0.05, 1, 0.01, 0.9, function(v)
    Settings.smoothing = v
end)

-- Start aimbot if enabled
if Settings.aimbotEnabled then
    lockedTarget = nil
    startAimbot()
end

-- Notification
pcall(function()
    SG:SetCore("SendNotification", {
        Title = "Auto Combat",
        Text = "Loaded. R = aimbot (Hold by default), M = melee, L = toggle GUI.",
        Duration = 3,
    })
end)




--------------------- hitbox expander


-- ============================================================
-- CONFIGURATION
-- ============================================================
local ENTITIES_FOLDER = workspace:WaitForChild("Entities")   -- all NPCs/players go here
local MAX_SIZE = Vector3.new(2048, 2048, 2048)               -- size of the targeted hurtbox
local UPDATE_INTERVAL = 0                                -- how often to refresh (lower = more responsive)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then return end   -- LocalScript only

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local Camera = workspace.CurrentCamera
local originalSizes = {}   -- cache original sizes for every part

-- Returns the hurtbox part closest to the camera, and its distance.
-- Ignores the local player's own character.
local function getClosestHurtbox()
	local cameraPos = Camera.CFrame.Position
	local bestPart = nil
	local bestDist = math.huge

	-- Iterate over every entity in Entities folder
	for _, entity in ipairs(ENTITIES_FOLDER:GetChildren()) do
		-- Skip if it's the local player's character (so you don't target yourself)
		if entity == localPlayer.Character then
			continue
		end

		local hurtboxes = entity:FindFirstChild("Hurtboxes")
		if hurtboxes then
			-- Check every part inside Hurtboxes
			for _, part in ipairs(hurtboxes:GetChildren()) do
				if part:IsA("BasePart") then
					local dist = (part.Position - cameraPos).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart, bestDist
end

-- Reset all hurtboxes to original size, then enlarge the closest one
local function updateSizes()
	local targetPart = getClosestHurtbox()

	-- Reset EVERY hurtbox to its stored original size
	for _, entity in ipairs(ENTITIES_FOLDER:GetChildren()) do
		local hurtboxes = entity:FindFirstChild("Hurtboxes")
		if hurtboxes then
			for _, part in ipairs(hurtboxes:GetChildren()) do
				if part:IsA("BasePart") then
					if not originalSizes[part] then
						originalSizes[part] = part.Size
					end
					part.Size = originalSizes[part]
				end
			end
		end
	end

	-- If we found a target, set it to MAX_SIZE
	if targetPart then
		targetPart.Size = MAX_SIZE
	end
end

-- React to new entities being added (they'll be processed on next loop)
ENTITIES_FOLDER.ChildAdded:Connect(function() end)

-- Main update loop
task.spawn(function()
	while true do
		task.wait(UPDATE_INTERVAL)
		updateSizes()
	end
end)

