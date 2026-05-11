-- Paste into Command Bar while sitting in your car
local player = game.Players.LocalPlayer
local character = player.Character
if not character then return warn("No character") end

local humanoid = character:FindFirstChild("Humanoid")
local seat = humanoid and humanoid.SeatPart
if not seat then return warn("You are not sitting in a car") end

-- Find the car model
local car = seat.Parent
while car and car ~= workspace do
    if car:IsA("Model") and car:FindFirstChildWhichIsA("VehicleSeat") then break end
    car = car.Parent
end
if not car or car == workspace then return warn("Could not find car model") end

print("Found car:", car.Name)

-- Ensure car has a PrimaryPart
if not car.PrimaryPart then
    local part = car:FindFirstChildWhichIsA("BasePart")
    if part then 
        car.PrimaryPart = part 
    else 
        return error("Car has no BasePart")
    end
end

-- 🧠 Detect which game mode is active
local checkpointsFolder = workspace:FindFirstChild("HighwayRace_solo_ServerCheckpoints")
local mode = "solo"
if not checkpointsFolder then
    checkpointsFolder = workspace:FindFirstChild("HighwayRace_ServerCheckpoints")
    mode = "normal"
end
if not checkpointsFolder then
    return warn("No checkpoints folder found (HighwayRace_solo_ServerCheckpoints or HighwayRace_ServerCheckpoints)")
end

print("Detected mode:", mode, "→ using folder:", checkpointsFolder.Name)

-- Build checkpoint list from 1 to 27 + ServerFinishLine
local checkpoints = {}
for i = 1, 27 do
    local cp = checkpointsFolder:FindFirstChild(tostring(i))
    if cp then
        table.insert(checkpoints, cp)
    else
        warn("Checkpoint", i, "missing in", checkpointsFolder.Name)
    end
end
local finishLine = checkpointsFolder:FindFirstChild("ServerFinishLine")
if finishLine then
    table.insert(checkpoints, finishLine)
else
    warn("ServerFinishLine missing in", checkpointsFolder.Name)
end

if #checkpoints == 0 then
    return warn("No checkpoints found")
end

-- Teleport function (raises car by 2 studs)
local function teleport(target)
    local raise = 2
    if target:IsA("BasePart") then
        car:SetPrimaryPartCFrame(target.CFrame + Vector3.new(0, raise, 0))
        print("Teleported to", target.Name)
    elseif target:IsA("Model") and target.PrimaryPart then
        car:SetPrimaryPartCFrame(target.PrimaryPart.CFrame + Vector3.new(0, raise, 0))
        print("Teleported to model", target.Name)
    else
        warn("Invalid target:", target)
    end
end

-- Start teleporting
for _, cp in ipairs(checkpoints) do
    if cp then
        teleport(cp)
    end
    task.wait(0.5)
end

print("✅ All checkpoints visited in", mode, "mode!")
