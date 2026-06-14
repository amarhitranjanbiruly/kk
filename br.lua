-- Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Remote cache
local RemoteCache = {
    CharactersFolder = ReplicatedStorage:WaitForChild("Characters"),
    RemotesFolder = ReplicatedStorage:WaitForChild("Remotes"),
    AbilitiesRemote = ReplicatedStorage.Remotes.Abilities.Ability,
    CombatRemote = ReplicatedStorage.Remotes.Combat.Action,
    DashRemote = ReplicatedStorage.Remotes.Character.Dash
}

-- Window
local Window = Rayfield:CreateWindow({
    Name = "Ultimate Battlegrounds",
    LoadingTitle = "Loading Features...",
    LoadingSubtitle = "by elton",
    ConfigurationSaving = { Enabled = false }
})

-- Main Tab
local Tab = Window:CreateTab("Main", 4483362458) -- Use a generic icon

-- ==================== LAG SERVER V2 (ABILITY SPAM) + ANTI-LAG ====================
local AbilitySpamEnabled = false
local AbilitySpamLoop
local MobRemote = ReplicatedStorage.Remotes.Character.ChangeCharacter
local IgnoreFriends = true      -- Default: ignore friends
local AntiLagEnabled = true     -- ANTI-LAG ON BY DEFAULT

local function GetCurrentCharacter()
    return LocalPlayer.Data.Character.Value
end

-- Find nearest player, optionally ignoring friends
local function FindNearestPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        -- Check friend ignore condition
        if IgnoreFriends and p:IsFriendsWith(LocalPlayer.UserId) then
            continue
        end
        local tr = p.Character:FindFirstChild("HumanoidRootPart")
        local th = p.Character:FindFirstChild("Humanoid")
        if tr and th and (th:GetAttribute("Health") or th.Health) > 0 then
            local d = (hrp.Position - tr.Position).Magnitude
            if d < dist then
                dist = d
                nearest = p
            end
        end
    end
    return nearest
end

local function UseAbility(abilityIndex)
    local charName = GetCurrentCharacter()
    local ability = ReplicatedStorage.Characters[charName].Abilities[abilityIndex]  --ReplicatedStorage.Characters[charName].Ultimates[abilityIndex]
    if not ability then return end

    local target = FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = targetChar and targetChar.HumanoidRootPart and targetChar.HumanoidRootPart.CFrame
    if not targetCF then return end

    pcall(function()
        RemoteCache.AbilitiesRemote:FireServer(ability, 9000000)

        local actions = {377,380,383,384,385,387,389}
        for i=1,7 do
            local args = {
                ability,
                charName..":Abilities:"..abilityIndex,
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF, targetCF},
                    BestHitCharacter = targetChar,
                    HitCharacters = {targetChar},
                    Ignore = i>2 and {ActionNumber1={targetChar}} or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {
                        IsFacing = not (i==1 or i==2),
                        IsInFront = i<=2,
                        Blocked = i>2 and false or nil
                    },
                    ServerTime = tick(),
                    Actions = i>2 and {ActionNumber1={}} or {},
                    FromCFrame = targetCF
                },
                "Action"..actions[i],
                i==2 and 0.1 or nil
            }
            RemoteCache.CombatRemote:FireServer(unpack(args))
        end
    end)
end

-- UI Elements for Lag Server V2
Tab:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = true,
    Flag = "IgnoreFriendsToggle",
    Callback = function(Value)
        IgnoreFriends = Value
    end
})

-- SEPARATE ANTI-LAG TOGGLE (ON BY DEFAULT)
Tab:CreateToggle({
    Name = "Anti-Lag Protection",
    CurrentValue = true,
    Flag = "AntiLagToggle",
    Callback = function(Value)
        AntiLagEnabled = Value
    end
})

-- Main spam toggle
Tab:CreateToggle({
    Name = "Lag Server V2 (Ability Spam)",
    CurrentValue = false,
    Flag = "LagServerV2Toggle",
    Callback = function(Value)
        AbilitySpamEnabled = Value
        if Value then
            if GetCurrentCharacter() ~= "Mob" then
                MobRemote:FireServer("Mob")
            end
            AbilitySpamLoop = task.spawn(function()
                local abilityIndices = {"1", "2", "3", "4"}  -- Spam all four abilities
                while AbilitySpamEnabled do
                    for _, idx in ipairs(abilityIndices) do
                        if not AbilitySpamEnabled then break end
                        UseAbility(idx)
                        
                        -- ANTI-LAG: if enabled, add a short pause to reduce CPU usage
                        if AntiLagEnabled then
                            task.wait(0.05)   -- smooth, still effective
                        else
                            task.wait(0)      -- original speed (may cause lag)
                        end
                        
                        if AbilitySpamEnabled then
                            local c = GetCurrentCharacter()
                            pcall(function()
                                local ability = ReplicatedStorage.Characters[c].Abilities[idx]
                                if ability then
                                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ability)
                                end
                            end)
                        end
                        -- extra wait only if anti-lag is on
                        if AntiLagEnabled then
                            task.wait(0.05)
                        end
                    end
                end
            end)
        else
            if AbilitySpamLoop then task.cancel(AbilitySpamLoop) end
        end
    end
})

-- ==================== WALLCOMBO ====================
local WallComboSection = Tab:CreateSection("WallCombo")

local WallComboConfig = {
    Enabled = false,
    Method = "Method 1",
    IgnoreFriends = false,
    RenderName = "WallComboV2",
    coreModule = nil
}

-- Helper to set identity
local function Setidentity()
    pcall(function()
        setthreadidentity(5)
        setthreadcontext(5)
    end)
end

-- Load core module
task.spawn(function()
    Setidentity()
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Core"))
    end)
    if success and result then
        WallComboConfig.coreModule = result
    end
end)

-- Ignore friends toggle for WallCombo
Tab:CreateToggle({
    Name = "Ignore Friends (WallCombo)",
    CurrentValue = false,
    Flag = "WallComboIgnoreFriends",
    Callback = function(Value)
        WallComboConfig.IgnoreFriends = Value
    end
})

-- Helper functions for wall combo
local function getCurrentCharacterName()
    return LocalPlayer.Data.Character.Value
end

local function characterHasWallCombo(name)
    local folder = ReplicatedStorage.Characters:FindFirstChild(name)
    return folder and folder:FindFirstChild("WallCombo") ~= nil
end

local function findNearestPlayerTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if WallComboConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(p.UserId) then continue end
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and th and (th:GetAttribute("Health") or th.Health) > 0 then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < shortest and d < 900000 then
                    shortest = d
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function getWallPosition()
    local char = LocalPlayer.Character
    if not char then return Vector3.new(0,0,0) end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0,0,0) end
    return hrp.Position + (hrp.CFrame.LookVector * 5)
end

local function getRootCFrame()
    local char = LocalPlayer.Character
    if not char then return CFrame.new() end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.CFrame or CFrame.new()
end

-- Method 1 (remote-based)
local function wallcomboMethod1()
    local currentChar = getCurrentCharacterName()
    if not characterHasWallCombo(currentChar) then return false end
    local targetPlayer = findNearestPlayerTarget()
    if not targetPlayer or not targetPlayer.Character then return false end
    local localChar = LocalPlayer.Character
    if not localChar then return false end

    pcall(function()
        local abilityObject = ReplicatedStorage.Characters[currentChar].WallCombo
        local actionId = math.random(1000,9999) + math.random(1000,5000)
        local serverTime = tick()
        local wallPos = getWallPosition()
        local fromCF = getRootCFrame()

        RemoteCache.AbilitiesRemote:FireServer(abilityObject, actionId, nil, targetPlayer.Character, wallPos)

        for i=1,4 do
            local args = {
                abilityObject,
                "Characters:"..currentChar..":WallCombo",
                i,
                actionId,
                {
                    HitboxCFrames = i==1 and {} or {CFrame.new(wallPos)},
                    BestHitCharacter = targetPlayer.Character,
                    HitCharacters = {targetPlayer.Character},
                    Ignore = (i>=2 and i<=3) and {ActionNumber1={targetPlayer.Character}} or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {IsFacing = true, IsInFront = true, Blocked = false},
                    ServerTime = serverTime,
                    Actions = i==4 and {
                        ActionNumber1 = {
                            [targetPlayer.Name] = {
                                StartCFrameStr = tostring(CFrame.new(targetPlayer.Character.HumanoidRootPart.Position)),
                                ImpulseVelocity = Vector3.new(-67499, 150000, 307),
                                AbilityName = "WallCombo",
                                RotVelocityStr = "0,0,0",
                                VelocityStr = "0,0,0",
                                Gravity = 200000,
                                RotImpulseVelocity = Vector3.new(8977, -5293, 6185),
                                Seed = math.random(100000000, 999999999),
                                LookVectorStr = tostring(fromCF.LookVector),
                                Duration = 2
                            }
                        }
                    } or {},
                    FromCFrame = fromCF
                },
                "Action"..math.random(1000,9999),
                i==4 and 0.1 or nil
            }
            RemoteCache.CombatRemote:FireServer(unpack(args))
        end
    end)
    return true
end

local function executeWallCombo()
    if not WallComboConfig.Enabled then return end
    if WallComboConfig.Method == "Method 1" then
        wallcomboMethod1()
    end
end

local WallComboToggle = Tab:CreateToggle({
    Name = "Spam WallCombo",
    CurrentValue = false,
    Flag = "WallComboToggle",
    Callback = function(Value)
        WallComboConfig.Enabled = Value
        Setidentity()
        if Value then
            RunService:BindToRenderStep(WallComboConfig.RenderName, Enum.RenderPriority.Input.Value, executeWallCombo)
        else
            RunService:UnbindFromRenderStep(WallComboConfig.RenderName)
        end
    end
})

-- ==================== SPEED HACK ====================
local speed_amnt = 5
local speed_enabled = false

local function getChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
end

RunService:BindToRenderStep("speed_loop", 2000, function(dt)
    if speed_enabled then
        local hrp, hum = getChar()
        if hrp and hum then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * dt * 5 * speed_amnt)
        end
    end
end)

local SpeedTab = Window:CreateTab("Speed", 4483362458)
SpeedTab:CreateToggle({
    Name = "Enable Speed",
    CurrentValue = false,
    Callback = function(Value)
        speed_enabled = Value
    end,
})
SpeedTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        speed_amnt = Value
    end,
})

-- ==================== NEW: LAGSERVER TAB WITH 10 INDEPENDENT SPAMMERS ====================
local LagServerTab = Window:CreateTab("LagServer", 4483362458)

-- Array to store state and threads for each spammer
local SpammerEnabled = {}
local SpammerThreads = {}

-- Function to ensure character is Mob (used by each spammer when started)
local function EnsureMob()
    if GetCurrentCharacter() ~= "Mob" then
        MobRemote:FireServer("Mob")
        task.wait(0.1) -- small delay to allow switch
    end
end

-- Individual spammer loop
local function SpammerLoop(index)
    local abilityIndices = {"1", "2", "3", "4"}
    while SpammerEnabled[index] do
        for _, idx in ipairs(abilityIndices) do
            if not SpammerEnabled[index] then break end
            UseAbility(idx)

            if AntiLagEnabled then
                task.wait(0.05)
            else
                task.wait(0)
            end

            if SpammerEnabled[index] then
                local c = GetCurrentCharacter()
                pcall(function()
                    local ability = ReplicatedStorage.Characters[c].Abilities[idx]
                    if ability then
                        ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ability)
                    end
                end)
            end

            if AntiLagEnabled then
                task.wait(0.05)
            end
        end
    end
end

-- Start a specific spammer (creates thread if enabled)
local function StartSpammer(index)
    if SpammerThreads[index] then
        task.cancel(SpammerThreads[index])
        SpammerThreads[index] = nil
    end
    if SpammerEnabled[index] then
        EnsureMob()
        SpammerThreads[index] = task.spawn(SpammerLoop, index)
    end
end

-- Master toggle to enable/disable all 10 spammers
local masterToggleValue = false
LagServerTab:CreateToggle({
    Name = "Master Control (All 10 Spammers)",
    CurrentValue = false,
    Flag = "MasterSpammerToggle",
    Callback = function(Value)
        masterToggleValue = Value
        for i = 1, 10 do
            SpammerEnabled[i] = Value
            StartSpammer(i)
            -- Also update the UI toggle for each spammer (optional, but good for consistency)
            pcall(function()
                Rayfield:SetToggle("SpammerToggle_" .. i, Value)
            end)
        end
    end
})

-- Create 10 individual spammers
for i = 1, 10 do
    local toggleName = "Spammer #" .. i
    LagServerTab:CreateToggle({
        Name = toggleName,
        CurrentValue = false,
        Flag = "SpammerToggle_" .. i,
        Callback = function(Value)
            SpammerEnabled[i] = Value
            StartSpammer(i)
            -- If this spammer is turned off, and master toggle is on, we don't change master
            -- If all spammers become off, optionally we could auto-turn master off, but not required.
        end
    })
end

-- ==================== NOTIFICATION ====================
Rayfield:Notify({
    Title = "Script Ready",
    Content = "All features loaded. Anti-Lag is ON by default. New LagServer tab with 10 independent spammers added.",
    Duration = 5
})

-- Load configuration
Rayfield:LoadConfiguration()
