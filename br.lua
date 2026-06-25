-- Paste into Command Bar while sitting in your car
local player = game.Players.LocalPlayer
local character = player.Character
if not character then return warn("No character") end

local humanoid = character:FindFirstChild("Humanoid")
local seat = humanoid and humanoid.SeatPart
if not seat then return warn("You are not sitting in a car") end

-- Find car
local car = seat.Parent
while car and car ~= workspace do
    if car:IsA("Model") and car:FindFirstChildWhichIsA("VehicleSeat") then break end
    car = car.Parent
end
if not car or car == workspace then return warn("Could not find car model") end
print("Found car:", car.Name)

-- Ensure PrimaryPart
if not car.PrimaryPart then
    local part = car:FindFirstChildWhichIsA("BasePart")
    if part then 
        car.PrimaryPart = part 
    else 
        return error("Car has no BasePart") 
    end
end

-- Find checkpoint folder (try both solo and normal)
local checkpointsFolder = workspace:FindFirstChild("HighwayRace_solo_ServerCheckpoints")
                         or workspace:FindFirstChild("HighwayRace_ServerCheckpoints")
if not checkpointsFolder then
    return warn("No checkpoints folder found – race may not have started yet.\n" ..
                "Wait a few seconds and run again.")
end
print("Using:", checkpointsFolder.Name)

-- Build checkpoint list 1..27 + finish
local checkpoints = {}
for i = 1, 27 do
    local cp = checkpointsFolder:FindFirstChild(tostring(i))
    if cp then table.insert(checkpoints, cp) end
end
local finish = checkpointsFolder:FindFirstChild("ServerFinishLine")
if finish then table.insert(checkpoints, finish) end

if #checkpoints == 0 then
    return warn("No checkpoint parts found in folder – maybe race is over?")
end

-- Teleport function with error protection
local function teleport(target)
    local raise = 5   -- high enough to clear ground
    if target:IsA("BasePart") then
        local success, err = pcall(function()
            car:SetPrimaryPartCFrame(target.CFrame + Vector3.new(0, raise, 0))
        end)
        if success then
            print("Teleported to", target.Name)
        else
            warn("Failed to teleport to", target.Name, ":", err)
        end
    else
        warn("Invalid target:", target)
    end
end

-- Do the teleport loop
for _, cp in ipairs(checkpoints) do
    teleport(cp)
    task.wait(0.5)   -- give the game time to register each step
end

print("✅ All checkpoints visited!")
