local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/amarhitranjanbiruly/kk/refs/heads/main/rimod.lua'))()

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ===== SHARED CONFIG (from ultra‑fast script) =====
local Config = {
    IgnoreFriends = false,
    FastSpawn = false,
    CycleDelay = 0.1,          -- default: 10 cycles/sec
}

-- ===== REMOTE CACHE (from first script) =====
local RemoteCache = {
    CharactersFolder = ReplicatedStorage:WaitForChild("Characters"),
    RemotesFolder = ReplicatedStorage:WaitForChild("Remotes"),
    AbilitiesRemote = ReplicatedStorage.Remotes.Abilities.Ability,
    CombatRemote = ReplicatedStorage.Remotes.Combat.Action,
    DashRemote = ReplicatedStorage.Remotes.Character.Dash
}

-- ============================================================
--  SHARED HELPERS
-- ============================================================

-- Get current character name
local function getCurrentCharacterName()
    return LocalPlayer.Data.Character.Value
end

-- ============================================================
--  UPDATED: Get WallCombo ability + character name (dynamic)
--  Now scans ALL character folders for WallCombo, not just Gon.
-- ============================================================
local function getWallComboAbility()
    local charName = getCurrentCharacterName()
    if charName then
        local charFolder = ReplicatedStorage.Characters:FindFirstChild(charName)
        if charFolder then
            local wc = charFolder:FindFirstChild("WallCombo")
            if wc then return wc, charName end
        end
    end
    -- Fallback: scan all character folders for WallCombo
    for _, folder in ipairs(ReplicatedStorage.Characters:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            local wc = folder:FindFirstChild("WallCombo")
            if wc then return wc, folder.Name end
        end
    end
    return nil, nil
end

-- Force reset character (instant death)
local function resetCharacterForced()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        character:BreakJoints()
    end
end

-- Find nearest player (for ability spam) – from first script
local function findNearestPlayer(ignoreFriends)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        if ignoreFriends and p:IsFriendsWith(LocalPlayer.UserId) then continue end
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

-- ============================================================
--  FAST SPAWN LOGIC (from ultra‑fast script)
-- ============================================================

local function monitorHumanoid(humanoid)
    if not humanoid then return end
    humanoid:GetAttributeChangedSignal("Health"):Connect(function()
        if not Config.FastSpawn then return end
        local health = humanoid:GetAttribute("Health") or humanoid.Health
        if health and health <= 0 then
            resetCharacterForced()
        end
    end)
end

local function connectCharacter(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        monitorHumanoid(humanoid)
    end
end

if LocalPlayer.Character then
    connectCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(connectCharacter)

-- ============================================================
--  SECTION 1: MAIN TAB (from first script – Lag Server V2, Ultimate Lag, WallCombo)
-- ============================================================

-- Variables from first script
local AbilitySpamEnabled = false
local AbilitySpamLoop
local MobRemote = ReplicatedStorage.Remotes.Character.ChangeCharacter
local IgnoreFriends = true
local AntiLagEnabled = true
local AutoMobEnabled = true
local UltimateSpamEnabled = false
local UltimateSpamLoop

-- WallCombo config (from first script)
local WallComboConfig = {
    Enabled = false,
    Method = "Method 1",
    IgnoreFriends = false,
    RenderName = "WallComboV2",
    coreModule = nil
}

-- Set identity for core module (if needed)
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

local function getCurrentCharacter()
    return LocalPlayer.Data.Character.Value
end

local function EnsureMob()
    if not AutoMobEnabled then return end
    if getCurrentCharacter() ~= "Mob" then
        MobRemote:FireServer("Mob")
        task.wait(0.1)
    end
end

-- Use Ability (from first script)
local function UseAbility(abilityIndex)
    local charName = getCurrentCharacter()
    local ability = ReplicatedStorage.Characters[charName].Abilities[abilityIndex]
    if not ability then return end

    local target = findNearestPlayer(IgnoreFriends)
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

-- Use Ultimate (from first script)
local function UseUltimate(ultimateIndex)
    local charName = getCurrentCharacter()
    local ultimate = ReplicatedStorage.Characters[charName].Ultimates[ultimateIndex]
    if not ultimate then return end

    local target = findNearestPlayer(IgnoreFriends)
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

-- WallCombo Method 1 (from first script) – already dynamic
local function wallcomboMethod1()
    local currentChar = getCurrentCharacterName()
    local charFolder = ReplicatedStorage.Characters:FindFirstChild(currentChar)
    if not charFolder then return false end
    local abilityObject = charFolder:FindFirstChild("WallCombo")
    if not abilityObject then return false end

    local targetPlayer = findNearestPlayer(WallComboConfig.IgnoreFriends)
    if not targetPlayer or not targetPlayer.Character then return false end
    local localChar = LocalPlayer.Character
    if not localChar then return false end

    pcall(function()
        local actionId = math.random(1000, 9999) + math.random(1000, 5000)
        local serverTime = tick()
        local wallPos = localChar.HumanoidRootPart.Position + (localChar.HumanoidRootPart.CFrame.LookVector * 5)
        local fromCF = localChar.HumanoidRootPart.CFrame

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

-- ===== CREATE MAIN WINDOW =====
local Window = Rayfield:CreateWindow({
    Name = "Ultimate Battlegrounds + God Mode",
    LoadingTitle = "Loading Features...",
    LoadingSubtitle = "Combined by elton",
    ConfigurationSaving = { Enabled = false }
})

-- ===== MAIN TAB =====
local MainTab = Window:CreateTab("Main", 4483362458)

-- Ignore Friends (for ability spam)
MainTab:CreateToggle({
    Name = "Ignore Friends (Ability/Ultimate)",
    CurrentValue = true,
    Flag = "IgnoreFriendsToggle",
    Callback = function(Value)
        IgnoreFriends = Value
    end
})

-- Anti-Lag Protection
MainTab:CreateToggle({
    Name = "Anti-Lag Protection",
    CurrentValue = true,
    Flag = "AntiLagToggle",
    Callback = function(Value)
        AntiLagEnabled = Value
    end
})

-- Auto Switch to Mob
MainTab:CreateToggle({
    Name = "Auto Switch to Mob (On by default)",
    CurrentValue = true,
    Flag = "AutoMobToggle",
    Callback = function(Value)
        AutoMobEnabled = Value
    end
})

-- Lag Server V2 (Ability Spam)
MainTab:CreateToggle({
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
                            local c = getCurrentCharacter()
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

-- Ultimate Lag Mode (Spam Ultimates)
MainTab:CreateToggle({
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
                            local c = getCurrentCharacter()
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

-- WallCombo ignore friends
MainTab:CreateToggle({
    Name = "Ignore Friends (WallCombo)",
    CurrentValue = false,
    Flag = "WallComboIgnoreFriends",
    Callback = function(Value)
        WallComboConfig.IgnoreFriends = Value
    end
})

-- Spam WallCombo (RenderStep)
MainTab:CreateToggle({
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

-- ============================================================
--  SECTION 2: SPEED TAB (from first script)
-- ============================================================
local SpeedTab = Window:CreateTab("Speed", 4483362458)

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

-- ============================================================
--  SECTION 3: RAGE TAB – ULTRA FAST GOD MODE (UPDATED to support ALL characters)
-- ============================================================
local RageTab = Window:CreateTab("Rage", 4483362458)

-- =====================================================
--  FEATURE 1: GOD MODE v1 (ALL NPCs – ultra fast)
-- =====================================================
local GodModeActive = false
local GodModeThread = nil

-- Ensure default CycleDelay is set (if Config doesn't exist yet)
Config = Config or {}
Config.CycleDelay = 0.1

RageTab:CreateToggle({
    Name = "God Mode v1 (ALL NPCs) invis",
    CurrentValue = false,
    Flag = "GodModeNPC",
    Callback = function(Value)
        GodModeActive = Value
        if GodModeActive then
            if GodModeThread then task.cancel(GodModeThread) end
            GodModeThread = task.spawn(function()
                while GodModeActive do
                    local wallCombo = getWallComboAbility()
                    if not wallCombo then
                        task.wait(0.1)
                        continue
                    end

                    local npcFolder = workspace.Characters and workspace.Characters:FindFirstChild("NPCs")
                    if not npcFolder then
                        task.wait(0.1)
                        continue
                    end

                    for _, npc in ipairs(npcFolder:GetChildren()) do
                        if not npc:IsA("Model") then continue end
                        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                        local npcHumanoid = npc:FindFirstChild("Humanoid")
                        if not npcRoot or not npcHumanoid then continue end

                        local health = npcHumanoid:GetAttribute("Health") or npcHumanoid.Health
                        if not health or health <= 0 then continue end

                        local abilityArgs = {
                            wallCombo, 33036, {}, npcRoot.Position
                        }
                        local combatArgs = {
                            wallCombo, "Characters:Stark:WallCombo", 1, 33036,
                            {
                                HitboxCFrames = {},
                                BestHitCharacter = npc,
                                HitCharacters = {npc},
                                Ignore = {}, DeathInfo = {}, Actions = {},
                                HitInfo = { IsFacing = true, IsInFront = true },
                                BlockedCharacters = {},
                                FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                            },
                            "Action651", 0
                        }
                        pcall(function()
                            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end)
                    end

                    task.wait(Config.CycleDelay)
                end
            end)
        else
            if GodModeThread then task.cancel(GodModeThread); GodModeThread = nil end
        end
    end
})

-- =====================================================
--  FEATURE 2: GOD MODE v2 (ALL Players – ultra fast)
-- =====================================================
local GodModeV2Active = false
local GodModeV2Thread = nil

RageTab:CreateToggle({
    Name = "God Mode v2 (ALL Players) invis",
    CurrentValue = false,
    Flag = "GodModeV2",
    Callback = function(Value)
        GodModeV2Active = Value
        if GodModeV2Active then
            if GodModeV2Thread then task.cancel(GodModeV2Thread) end
            GodModeV2Thread = task.spawn(function()
                while GodModeV2Active do
                    local wallCombo = getWallComboAbility()
                    if not wallCombo then
                        task.wait(0.1)
                        continue
                    end

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player == LocalPlayer then continue end
                        if Config.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then
                            continue
                        end

                        local targetChar = player.Character
                        if not targetChar then continue end

                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                        if not targetRoot or not targetHumanoid then continue end

                        local health = targetHumanoid:GetAttribute("Health") or targetHumanoid.Health
                        if not health or health <= 0 then continue end

                        local abilityArgs = {
                            wallCombo, 33036, {}, targetRoot.Position
                        }
                        local combatArgs = {
                            wallCombo, "Characters:Stark:WallCombo", 1, 33036,
                            {
                                HitboxCFrames = {},
                                BestHitCharacter = targetChar,
                                HitCharacters = {targetChar},
                                Ignore = {}, DeathInfo = {}, Actions = {},
                                HitInfo = { IsFacing = true, IsInFront = true },
                                BlockedCharacters = {},
                                FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                            },
                            "Action651", 0
                        }
                        pcall(function()
                            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end)
                    end

                    task.wait(Config.CycleDelay)
                end
            end)
        else
            if GodModeV2Thread then task.cancel(GodModeV2Thread); GodModeV2Thread = nil end
        end
    end
})

-- =====================================================
--  SHARED TOGGLE: Ignore Friends (v2)
-- =====================================================
RageTab:CreateToggle({
    Name = "Ignore Friends (v2)",
    CurrentValue = false,
    Flag = "IgnoreFriendsAll",
    Callback = function(Value)
        Config.IgnoreFriends = Value
    end
})

-- ============================================================
--  FEATURE 1: GOD MODE v1 (ALL NPCs – ultra fast) – dynamic
-- ============================================================
local GodModeActive = false
local GodModeThread = nil

RageTab:CreateToggle({
    Name = "God Mode v1 (ALL NPCs) - Ultra Fast",
    CurrentValue = false,
    Flag = "GodModeNPC",
    Callback = function(Value)
        GodModeActive = Value
        if GodModeActive then
            if GodModeThread then task.cancel(GodModeThread) end
            GodModeThread = task.spawn(function()
                while GodModeActive do
                    local ability, charName = getWallComboAbility()
                    if not ability then
                        task.wait(0.1)
                        continue
                    end
                    local abilityPath = "Characters:" .. charName .. ":WallCombo"

                    local npcFolder = workspace.Characters and workspace.Characters:FindFirstChild("NPCs")
                    if not npcFolder then
                        task.wait(0.1)
                        continue
                    end

                    for _, npc in ipairs(npcFolder:GetChildren()) do
                        if not npc:IsA("Model") then continue end
                        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                        local npcHumanoid = npc:FindFirstChild("Humanoid")
                        if not npcRoot or not npcHumanoid then continue end

                        local health = npcHumanoid:GetAttribute("Health") or npcHumanoid.Health
                        if not health or health <= 0 then continue end

                        local abilityArgs = {
                            ability, 33036, {}, npcRoot.Position
                        }
                        local combatArgs = {
                            ability, abilityPath, 1, 33036,
                            {
                                HitboxCFrames = {},
                                BestHitCharacter = npc,
                                HitCharacters = {npc},
                                Ignore = {}, DeathInfo = {}, Actions = {},
                                HitInfo = { IsFacing = true, IsInFront = true },
                                BlockedCharacters = {},
                                FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                            },
                            "Action651", 0
                        }
                        pcall(function()
                            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end)
                    end

                    task.wait(Config.CycleDelay)
                end
            end)
        else
            if GodModeThread then task.cancel(GodModeThread); GodModeThread = nil end
        end
    end
})

-- ============================================================
--  FEATURE 2: GOD MODE v2 (ALL Players – ultra fast) – dynamic
-- ============================================================
local GodModeV2Active = false
local GodModeV2Thread = nil

RageTab:CreateToggle({
    Name = "God Mode v2 (ALL Players) - Ultra Fast",
    CurrentValue = false,
    Flag = "GodModeV2",
    Callback = function(Value)
        GodModeV2Active = Value
        if GodModeV2Active then
            if GodModeV2Thread then task.cancel(GodModeV2Thread) end
            GodModeV2Thread = task.spawn(function()
                while GodModeV2Active do
                    local ability, charName = getWallComboAbility()
                    if not ability then
                        task.wait(0.1)
                        continue
                    end
                    local abilityPath = "Characters:" .. charName .. ":WallCombo"

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player == LocalPlayer then continue end
                        if Config.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then
                            continue
                        end

                        local targetChar = player.Character
                        if not targetChar then continue end

                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                        if not targetRoot or not targetHumanoid then continue end

                        local health = targetHumanoid:GetAttribute("Health") or targetHumanoid.Health
                        if not health or health <= 0 then continue end

                        local abilityArgs = {
                            ability, 33036, {}, targetRoot.Position
                        }
                        local combatArgs = {
                            ability, abilityPath, 1, 33036,
                            {
                                HitboxCFrames = {},
                                BestHitCharacter = targetChar,
                                HitCharacters = {targetChar},
                                Ignore = {}, DeathInfo = {}, Actions = {},
                                HitInfo = { IsFacing = true, IsInFront = true },
                                BlockedCharacters = {},
                                FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                            },
                            "Action651", 0
                        }
                        pcall(function()
                            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end)
                    end

                    task.wait(Config.CycleDelay)
                end
            end)
        else
            if GodModeV2Thread then task.cancel(GodModeV2Thread); GodModeV2Thread = nil end
        end
    end
})

-- ============================================================
--  CYCLE DELAY SLIDER
-- ============================================================
RageTab:CreateSlider({
    Name = "Cycle Delay (seconds)",
    Range = {0.0002, 0.1},
    Increment = 0.0001,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "CycleDelay",
    Callback = function(Value)
        Config.CycleDelay = Value
    end
})

-- ============================================================
--  SHARED TOGGLE: Ignore Friends (v2)
-- ============================================================
RageTab:CreateToggle({
    Name = "Ignore Friends (v2)",
    CurrentValue = false,
    Flag = "IgnoreFriendsAll",
    Callback = function(Value)
        Config.IgnoreFriends = Value
    end
})

-- ============================================================
--  SECTION 4: MOVEMENT TAB (fixed version)
-- ============================================================
local MovementTab = Window:CreateTab("Movement", 4483362458)

-- ===== BUTTON: Reset Character =====
MovementTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        resetCharacterForced()
        Rayfield:Notify({
            Title = "Reset",
            Content = "Character killed!",
            Duration = 1,
            Image = 4483362458
        })
    end
})

-- ===== TOGGLE: Fast Spawn =====
MovementTab:CreateToggle({
    Name = "Fast Spawn (Auto-Respawn)",
    CurrentValue = false,
    Flag = "FastSpawnToggle",
    Callback = function(Value)
        Config.FastSpawn = Value
        if Value then
            Rayfield:Notify({
                Title = "Fast Spawn",
                Content = "Enabled – you'll respawn instantly on death.",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- ============================================================
--  SECTION 5: LAGSERVER TAB (50 ability spammers)
-- ============================================================
local LagServerTab = Window:CreateTab("LagServer", 4483362458)

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
                local c = getCurrentCharacter()
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

-- Extra ability spammers (master controlled)
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
                local c = getCurrentCharacter()
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
                    task.wait(abilityStartDelay)
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

-- ============================================================
--  SECTION 6: ULTIMATE LAGSERVER TAB (50 ultimate spammers)
-- ============================================================
local UltimateLagServerTab = Window:CreateTab("UltimateLagServer", 4483362458)

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
                local c = getCurrentCharacter()
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
                local c = getCurrentCharacter()
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
                    task.wait(ultimateStartDelay)
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

-- ============================================================
--  SECTION 7: TARGETED GOD MODE (UPDATED to support ALL characters)
-- ============================================================
local TargetedTab = Window:CreateTab("Targeted God Mode", 4483362458)

local TargetedConfig = {
    IgnoreFriends = false,
    SelectedTargets = {},
    GodModeActive = false,
    GodModeThread = nil,
}

-- Attack function for targeted god mode – now dynamic
local function attackTargeted(targetChar)
    local ability, charName = getWallComboAbility()
    if not ability then return end
    local abilityPath = "Characters:" .. charName .. ":WallCombo"

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local abilityArgs = {
        ability, 33036, {}, targetRoot.Position
    }
    local combatArgs = {
        ability, abilityPath, 1, 33036,
        {
            HitboxCFrames = {},
            BestHitCharacter = targetChar,
            HitCharacters = {targetChar},
            Ignore = {}, DeathInfo = {}, Actions = {},
            HitInfo = { IsFacing = true, IsInFront = true },
            BlockedCharacters = {},
            FromCFrame = CFrame.new(534.693, 5.532, 79.486)
        },
        "Action651", 0
    }
    pcall(function()
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
        ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
    end)
end

local function startTargetedGodMode()
    if TargetedConfig.GodModeThread then task.cancel(TargetedConfig.GodModeThread) end
    TargetedConfig.GodModeThread = task.spawn(function()
        while TargetedConfig.GodModeActive do
            for _, name in ipairs(TargetedConfig.SelectedTargets) do
                if not TargetedConfig.GodModeActive then break end
                local player = Players:FindFirstChild(name)
                if not player then
                    continue
                end
                if TargetedConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then
                    continue
                end
                local targetChar = player.Character
                if not targetChar then continue end
                local humanoid = targetChar:FindFirstChild("Humanoid")
                if not humanoid then continue end
                local health = humanoid:GetAttribute("Health") or humanoid.Health
                if health and health > 0 then
                    attackTargeted(targetChar)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Dropdown options builder
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    for _, name in ipairs(TargetedConfig.SelectedTargets) do
        if not Players:FindFirstChild(name) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    if #names == 0 then
        table.insert(names, "No players")
    end
    return names
end

TargetedTab:CreateSection("Target Selection")

local TargetDropdown = TargetedTab:CreateDropdown({
    Name = "Select Targets (multi)",
    Options = getPlayerNames(),
    CurrentOption = {},
    Multi = true,
    Callback = function(Options)
        TargetedConfig.SelectedTargets = Options
    end
})

TargetedTab:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Callback = function(Value)
        TargetedConfig.IgnoreFriends = Value
    end
})

TargetedTab:CreateToggle({
    Name = "God Mode v2 (Targeted)",
    CurrentValue = false,
    Callback = function(Value)
        TargetedConfig.GodModeActive = Value
        if Value then
            if #TargetedConfig.SelectedTargets == 0 then
                Rayfield:Notify({ Title = "Warning", Content = "No targets selected!", Duration = 2 })
            end
            startTargetedGodMode()
        else
            if TargetedConfig.GodModeThread then
                task.cancel(TargetedConfig.GodModeThread)
                TargetedConfig.GodModeThread = nil
            end
        end
    end
})

-- Auto-refresh dropdown
local function refreshDropdown()
    local options = getPlayerNames()
    TargetDropdown:SetOptions(options)
    TargetDropdown:SetCurrentOption(TargetedConfig.SelectedTargets)
end
refreshDropdown()
task.spawn(function()
    while true do
        task.wait(1)
        refreshDropdown()
    end
end)

-- ============================================================
--  KEYBINDS (from first script, extended)
-- ============================================================

-- L: toggle extra ability spammers
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

-- U: toggle extra ultimate spammers
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

-- ============================================================
--  FINAL NOTIFICATION
-- ============================================================
Rayfield:Notify({
    Title = "Combined Script Ready",
    Content = "All features loaded. Press L (abilities) and U (ultimates) for extra spammers.",
    Duration = 5
})

-- Load configuration (if any)
Rayfield:LoadConfiguration()
