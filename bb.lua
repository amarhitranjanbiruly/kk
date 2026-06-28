--brutal

-- Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
local Tab = Window:CreateTab("Main", 4483362458)

-- ==================== LAG SERVER V2 (ABILITY SPAM) + ANTI-LAG ====================
local AbilitySpamEnabled = false
local AbilitySpamLoop
local MobRemote = ReplicatedStorage.Remotes.Character.ChangeCharacter
local IgnoreFriends = true
local AntiLagEnabled = true
local AutoMobEnabled = true

local function GetCurrentCharacter()
    return LocalPlayer.Data.Character.Value
end

local function FindNearestPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
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

local function EnsureMob()
    if not AutoMobEnabled then return end
    if GetCurrentCharacter() ~= "Mob" then
        MobRemote:FireServer("Mob")
        task.wait(0.1)
    end
end

local function UseAbility(abilityIndex)
    local charName = GetCurrentCharacter()
    local ability = ReplicatedStorage.Characters[charName].Abilities[abilityIndex]
    if not ability then return end

    local target = FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = targetChar and targetChar.HumanoidRootPart and targetChar.HumanoidRootPart.CFrame
    if not targetCF then return end

    pcall(function()
        RemoteCache.AbilitiesRemote:FireServer(ability, 9000000)

        local actions = {377,380,383,384,385,387,389}
        for i = 1, 7 do
            local args = {
                ability,
                charName .. ":Abilities:" .. abilityIndex,
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF, targetCF},
                    BestHitCharacter = targetChar,
                    HitCharacters = {targetChar},
                    Ignore = i > 2 and { ActionNumber1 = { targetChar } } or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {
                        IsFacing = not (i == 1 or i == 2),
                        IsInFront = i <= 2,
                        Blocked = i > 2 and false or nil
                    },
                    ServerTime = tick(),
                    Actions = i > 2 and { ActionNumber1 = {} } or {},
                    FromCFrame = targetCF
                },
                "Action" .. actions[i],
                i == 2 and 0.1 or nil
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

Tab:CreateToggle({
    Name = "Anti-Lag Protection",
    CurrentValue = true,
    Flag = "AntiLagToggle",
    Callback = function(Value)
        AntiLagEnabled = Value
    end
})

Tab:CreateToggle({
    Name = "Auto Switch to Mob (On by default)",
    CurrentValue = true,
    Flag = "AutoMobToggle",
    Callback = function(Value)
        AutoMobEnabled = Value
    end
})

Tab:CreateToggle({
    Name = "Lag Server V2 (Ability Spam)",
    CurrentValue = false,
    Flag = "LagServerV2Toggle",
    Callback = function(Value)
        AbilitySpamEnabled = Value
        if Value then
            EnsureMob()
            AbilitySpamLoop = task.spawn(function()
                local abilityIndices = { "1", "2", "3", "4" }
                while AbilitySpamEnabled do
                    for _, idx in ipairs(abilityIndices) do
                        if not AbilitySpamEnabled then break end
                        UseAbility(idx)
                        if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
                        if AbilitySpamEnabled then
                            local c = GetCurrentCharacter()
                            pcall(function()
                                local ability = ReplicatedStorage.Characters[c].Abilities[idx]
                                if ability then
                                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ability)
                                end
                            end)
                        end
                        if AntiLagEnabled then task.wait(0.05) end
                    end
                end
            end)
        else
            if AbilitySpamLoop then task.cancel(AbilitySpamLoop) end
        end
    end
})

-- ==================== ULTIMATE LAG MODE (SPAM ULTIMATES) ====================
local UltimateSpamEnabled = false
local UltimateSpamLoop

local function UseUltimate(ultimateIndex)
    local charName = GetCurrentCharacter()
    local ultimate = ReplicatedStorage.Characters[charName].Ultimates[ultimateIndex]
    if not ultimate then return end

    local target = FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = targetChar and targetChar.HumanoidRootPart and targetChar.HumanoidRootPart.CFrame
    if not targetCF then return end

    pcall(function()
        RemoteCache.AbilitiesRemote:FireServer(ultimate, 9000000)

        local actions = {377,380,383,384,385,387,389}
        for i = 1, 7 do
            local args = {
                ultimate,
                charName .. ":Ultimates:" .. ultimateIndex,
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF, targetCF},
                    BestHitCharacter = targetChar,
                    HitCharacters = {targetChar},
                    Ignore = i > 2 and { ActionNumber1 = { targetChar } } or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {
                        IsFacing = not (i == 1 or i == 2),
                        IsInFront = i <= 2,
                        Blocked = i > 2 and false or nil
                    },
                    ServerTime = tick(),
                    Actions = i > 2 and { ActionNumber1 = {} } or {},
                    FromCFrame = targetCF
                },
                "Action" .. actions[i],
                i == 2 and 0.1 or nil
            }
            RemoteCache.CombatRemote:FireServer(unpack(args))
        end
    end)
end

Tab:CreateToggle({
    Name = "Ultimate Lag Mode (Spam Ultimates)",
    CurrentValue = false,
    Flag = "UltimateLagToggle",
    Callback = function(Value)
        UltimateSpamEnabled = Value
        if Value then
            EnsureMob()
            UltimateSpamLoop = task.spawn(function()
                local ultimateIndices = { "1", "2", "3", "4" }
                while UltimateSpamEnabled do
                    for _, idx in ipairs(ultimateIndices) do
                        if not UltimateSpamEnabled then break end
                        UseUltimate(idx)
                        if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
                        if UltimateSpamEnabled then
                            local c = GetCurrentCharacter()
                            pcall(function()
                                local ultimate = ReplicatedStorage.Characters[c].Ultimates[idx]
                                if ultimate then
                                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ultimate)
                                end
                            end)
                        end
                        if AntiLagEnabled then task.wait(0.05) end
                    end
                end
            end)
        else
            if UltimateSpamLoop then task.cancel(UltimateSpamLoop) end
        end
    end
})

-- ==================== WALLCOMBO ====================
local WallComboConfig = {
    Enabled = false,
    Method = "Method 1",
    IgnoreFriends = false,
    RenderName = "WallComboV2",
    coreModule = nil
}

local function Setidentity()
    pcall(function()
        setthreadidentity(5)
        setthreadcontext(5)
    end)
end

task.spawn(function()
    Setidentity()
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Core"))
    end)
    if success and result then
        WallComboConfig.coreModule = result
    end
end)

Tab:CreateToggle({
    Name = "Ignore Friends (WallCombo)",
    CurrentValue = false,
    Flag = "WallComboIgnoreFriends",
    Callback = function(Value)
        WallComboConfig.IgnoreFriends = Value
    end
})

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
    if not char then return Vector3.new(0, 0, 0) end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0, 0, 0) end
    return hrp.Position + (hrp.CFrame.LookVector * 5)
end

local function getRootCFrame()
    local char = LocalPlayer.Character
    if not char then return CFrame.new() end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.CFrame or CFrame.new()
end

local function wallcomboMethod1()
    local currentChar = getCurrentCharacterName()
    if not characterHasWallCombo(currentChar) then return false end
    local targetPlayer = findNearestPlayerTarget()
    if not targetPlayer or not targetPlayer.Character then return false end
    local localChar = LocalPlayer.Character
    if not localChar then return false end

    pcall(function()
        local abilityObject = ReplicatedStorage.Characters[currentChar].WallCombo
        local actionId = math.random(1000, 9999) + math.random(1000, 5000)
        local serverTime = tick()
        local wallPos = getWallPosition()
        local fromCF = getRootCFrame()

        RemoteCache.AbilitiesRemote:FireServer(abilityObject, actionId, nil, targetPlayer.Character, wallPos)

        for i = 1, 4 do
            local args = {
                abilityObject,
                "Characters:" .. currentChar .. ":WallCombo",
                i,
                actionId,
                {
                    HitboxCFrames = i == 1 and {} or { CFrame.new(wallPos) },
                    BestHitCharacter = targetPlayer.Character,
                    HitCharacters = { targetPlayer.Character },
                    Ignore = (i >= 2 and i <= 3) and { ActionNumber1 = { targetPlayer.Character } } or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = { IsFacing = true, IsInFront = true, Blocked = false },
                    ServerTime = serverTime,
                    Actions = i == 4 and {
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
                "Action" .. math.random(1000, 9999),
                i == 4 and 0.1 or nil
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

Tab:CreateToggle({
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
    Range = { 1, 50 },
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        speed_amnt = Value
    end,
})

-- ==================== LAGSERVER TAB – 50 INDEPENDENT SPAMMERS (ABILITIES) ====================
local LagServerTab = Window:CreateTab("LagServer", 4483362458)

-- Slider for extra ability spammers (master controlled)
local abilitySpammerCount = 50
LagServerTab:CreateSlider({
    Name = "Number of Extra Ability Spammers",
    Range = {1, 10000},
    Increment = 1,
    CurrentValue = 50,
    Flag = "AbilitySpammerCount",
    Callback = function(Value)
        abilitySpammerCount = Value
    end
})

-- NEW: Slider for start delay (seconds)
local abilityStartDelay = 0.45
LagServerTab:CreateSlider({
    Name = "Start Delay (seconds)",
    Range = {0.01, 2},
    Increment = 0.01,
    CurrentValue = 0.45,
    Flag = "AbilityStartDelay",
    Callback = function(Value)
        abilityStartDelay = Value
    end
})

-- 50 manual toggles (unchanged)
local SpammerEnabled = {}
local SpammerThreads = {}

local function SpammerLoop(index)
    local abilityIndices = { "1", "2", "3", "4" }
    while SpammerEnabled[index] do
        for _, idx in ipairs(abilityIndices) do
            if not SpammerEnabled[index] then break end
            UseAbility(idx)
            if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
            if SpammerEnabled[index] then
                local c = GetCurrentCharacter()
                pcall(function()
                    local ability = ReplicatedStorage.Characters[c].Abilities[idx]
                    if ability then
                        ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ability)
                    end
                end)
            end
            if AntiLagEnabled then task.wait(0.05) end
        end
    end
end

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

for i = 1, 50 do
    LagServerTab:CreateToggle({
        Name = "Spammer #" .. i,
        CurrentValue = false,
        Flag = "SpammerToggle_" .. i,
        Callback = function(Value)
            SpammerEnabled[i] = Value
            StartSpammer(i)
        end
    })
end

-- Extra spammers (controlled by master, does NOT touch manual toggles)
local extraAbilitySpamming = false
local extraAbilityThreads = {}

local function ExtraAbilitySpammer()
    local abilityIndices = { "1", "2", "3", "4" }
    while extraAbilitySpamming do
        for _, idx in ipairs(abilityIndices) do
            if not extraAbilitySpamming then break end
            UseAbility(idx)
            if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
            if extraAbilitySpamming then
                local c = GetCurrentCharacter()
                pcall(function()
                    local ability = ReplicatedStorage.Characters[c].Abilities[idx]
                    if ability then
                        ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ability)
                    end
                end)
            end
            if AntiLagEnabled then task.wait(0.05) end
        end
    end
end

local masterToggleValue = false
local enableSequence = nil

LagServerTab:CreateToggle({
    Name = "Master Control (Extra Ability Spammers)",
    CurrentValue = false,
    Flag = "MasterSpammerToggle",
    Callback = function(Value)
        masterToggleValue = Value

        if enableSequence then
            task.cancel(enableSequence)
            enableSequence = nil
        end

        if Value then
            EnsureMob()
            extraAbilitySpamming = true
            enableSequence = task.spawn(function()
                for i = 1, abilitySpammerCount do
                    if not masterToggleValue then break end
                    local thread = task.spawn(ExtraAbilitySpammer)
                    table.insert(extraAbilityThreads, thread)
                    task.wait(abilityStartDelay)  -- use the slider value
                end
                enableSequence = nil
            end)
        else
            extraAbilitySpamming = false
            for _, thread in ipairs(extraAbilityThreads) do
                task.cancel(thread)
            end
            extraAbilityThreads = {}
        end
    end
})

-- ==================== ULTIMATE LAGSERVER TAB – 50 INDEPENDENT ULTIMATE SPAMMERS ====================
local UltimateLagServerTab = Window:CreateTab("UltimateLagServer", 4483362458)

-- Slider for extra ultimate spammers
local ultimateSpammerCount = 50
UltimateLagServerTab:CreateSlider({
    Name = "Number of Extra Ultimate Spammers",
    Range = {1, 10000},
    Increment = 1,
    CurrentValue = 50,
    Flag = "UltimateSpammerCount",
    Callback = function(Value)
        ultimateSpammerCount = Value
    end
})

-- NEW: Slider for start delay (seconds)
local ultimateStartDelay = 0.45
UltimateLagServerTab:CreateSlider({
    Name = "Start Delay (seconds)",
    Range = {0.01, 2},
    Increment = 0.01,
    CurrentValue = 0.45,
    Flag = "UltimateStartDelay",
    Callback = function(Value)
        ultimateStartDelay = Value
    end
})

local UltimateSpammerEnabled = {}
local UltimateSpammerThreads = {}

local function UltimateSpammerLoop(index)
    local ultimateIndices = { "1", "2", "3", "4" }
    while UltimateSpammerEnabled[index] do
        for _, idx in ipairs(ultimateIndices) do
            if not UltimateSpammerEnabled[index] then break end
            UseUltimate(idx)
            if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
            if UltimateSpammerEnabled[index] then
                local c = GetCurrentCharacter()
                pcall(function()
                    local ultimate = ReplicatedStorage.Characters[c].Ultimates[idx]
                    if ultimate then
                        ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ultimate)
                    end
                end)
            end
            if AntiLagEnabled then task.wait(0.05) end
        end
    end
end

local function StartUltimateSpammer(index)
    if UltimateSpammerThreads[index] then
        task.cancel(UltimateSpammerThreads[index])
        UltimateSpammerThreads[index] = nil
    end
    if UltimateSpammerEnabled[index] then
        EnsureMob()
        UltimateSpammerThreads[index] = task.spawn(UltimateSpammerLoop, index)
    end
end

for i = 1, 50 do
    UltimateLagServerTab:CreateToggle({
        Name = "Ultimate Spammer #" .. i,
        CurrentValue = false,
        Flag = "UltimateSpammerToggle_" .. i,
        Callback = function(Value)
            UltimateSpammerEnabled[i] = Value
            StartUltimateSpammer(i)
        end
    })
end

-- Extra ultimate spammers (master controlled)
local extraUltimateSpamming = false
local extraUltimateThreads = {}

local function ExtraUltimateSpammer()
    local ultimateIndices = { "1", "2", "3", "4" }
    while extraUltimateSpamming do
        for _, idx in ipairs(ultimateIndices) do
            if not extraUltimateSpamming then break end
            UseUltimate(idx)
            if AntiLagEnabled then task.wait(0.05) else task.wait(0) end
            if extraUltimateSpamming then
                local c = GetCurrentCharacter()
                pcall(function()
                    local ultimate = ReplicatedStorage.Characters[c].Ultimates[idx]
                    if ultimate then
                        ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(ultimate)
                    end
                end)
            end
            if AntiLagEnabled then task.wait(0.05) end
        end
    end
end

local ultimateMasterToggleValue = false
local ultimateEnableSequence = nil

UltimateLagServerTab:CreateToggle({
    Name = "Master Control (Extra Ultimate Spammers)",
    CurrentValue = false,
    Flag = "MasterUltimateSpammerToggle",
    Callback = function(Value)
        ultimateMasterToggleValue = Value

        if ultimateEnableSequence then
            task.cancel(ultimateEnableSequence)
            ultimateEnableSequence = nil
        end

        if Value then
            EnsureMob()
            extraUltimateSpamming = true
            ultimateEnableSequence = task.spawn(function()
                for i = 1, ultimateSpammerCount do
                    if not ultimateMasterToggleValue then break end
                    local thread = task.spawn(ExtraUltimateSpammer)
                    table.insert(extraUltimateThreads, thread)
                    task.wait(ultimateStartDelay)  -- use the slider value
                end
                ultimateEnableSequence = nil
            end)
        else
            extraUltimateSpamming = false
            for _, thread in ipairs(extraUltimateThreads) do
                task.cancel(thread)
            end
            extraUltimateThreads = {}
        end
    end
})

-- ==================== NEW: WALLCOMBO SPAMMER (EXTRA, MASTER CONTROLLED) ====================
local WallComboSpamTab = Window:CreateTab("WallComboSpam", 4483362458)

-- Slider for number of wall combo spammers
local wallComboSpammerCount = 50
WallComboSpamTab:CreateSlider({
    Name = "Number of WallCombo Spammers",
    Range = {1, 10000},
    Increment = 1,
    CurrentValue = 50,
    Flag = "WallComboSpammerCount",
    Callback = function(Value)
        wallComboSpammerCount = Value
    end
})

-- Slider for start delay (seconds)
local wallComboStartDelay = 0.45
WallComboSpamTab:CreateSlider({
    Name = "Start Delay (seconds)",
    Range = {0.01, 2},
    Increment = 0.01,
    CurrentValue = 0.45,
    Flag = "WallComboStartDelay",
    Callback = function(Value)
        wallComboStartDelay = Value
    end
})

-- Master toggle and threads
local wallComboSpamEnabled = false
local wallComboSpamThreads = {}
local wallComboEnableSequence = nil

-- The loop function for each thread
local function WallComboSpammerLoop()
    while wallComboSpamEnabled do
        wallcomboMethod1()
        -- Small wait to prevent overloading, you can adjust
        task.wait(0.05)
    end
end

WallComboSpamTab:CreateToggle({
    Name = "Master Control (Extra WallCombo Spammers)",
    CurrentValue = false,
    Flag = "MasterWallComboSpammerToggle",
    Callback = function(Value)
        wallComboSpamEnabled = Value

        if wallComboEnableSequence then
            task.cancel(wallComboEnableSequence)
            wallComboEnableSequence = nil
        end

        if Value then
            -- No need to switch to Mob, WallCombo works with any character that has it
            -- but you may optionally ensure mob? Not required.
            wallComboSpamEnabled = true
            wallComboEnableSequence = task.spawn(function()
                for i = 1, wallComboSpammerCount do
                    if not wallComboSpamEnabled then break end
                    local thread = task.spawn(WallComboSpammerLoop)
                    table.insert(wallComboSpamThreads, thread)
                    task.wait(wallComboStartDelay)
                end
                wallComboEnableSequence = nil
            end)
        else
            wallComboSpamEnabled = false
            for _, thread in ipairs(wallComboSpamThreads) do
                task.cancel(thread)
            end
            wallComboSpamThreads = {}
        end
    end
})

-- Optional: Add a keybind for the wall combo master toggle (e.g., W)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then
        local current = Rayfield:GetToggle("MasterWallComboSpammerToggle")
        if current ~= nil then
            Rayfield:SetToggle("MasterWallComboSpammerToggle", not current)
            Rayfield:Notify({
                Title = "Keybind",
                Content = "Toggled extra WallCombo spammers " .. (not current and "ON" or "OFF"),
                Duration = 2
            })
        end
    end
end)

-- ==================== KEYBINDS ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        local newValue = not masterToggleValue
        Rayfield:SetToggle("MasterSpammerToggle", newValue)
        Rayfield:Notify({
            Title = "Keybind",
            Content = "Toggled extra ability spammers " .. (newValue and "ON" or "OFF"),
            Duration = 2
        })
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        local newValue = not ultimateMasterToggleValue
        Rayfield:SetToggle("MasterUltimateSpammerToggle", newValue)
        Rayfield:Notify({
            Title = "Keybind",
            Content = "Toggled extra ultimate spammers " .. (newValue and "ON" or "OFF"),
            Duration = 2
        })
    end
end)

-- ==================== NOTIFICATION ====================
Rayfield:Notify({
    Title = "Script Ready",
    Content = "All features loaded. Press L for extra ability spammers, U for extra ultimate spammers, W for extra WallCombo spammers.",
    Duration = 5
})

-- Load configuration
Rayfield:LoadConfiguration()
