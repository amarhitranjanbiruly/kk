-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local heartbeat = RunService.Heartbeat

-- Folders
local Toggles = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Toggles")
local Multipliers = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers")
local Cooldowns = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Cooldowns")

-- Remote cache
local Remotes = {
    Ability = nil,
    Combat = nil,
    Dash = nil
}

pcall(function()
    Remotes.Ability = ReplicatedStorage.Remotes.Abilities.Ability
    Remotes.Combat = ReplicatedStorage.Remotes.Combat.Action
    Remotes.Dash = ReplicatedStorage.Remotes.Character.Dash
end)

-- Configuration table
local Config = {
    -- Kill Aura
    KillAura = false,
    KillAuraRange = false,
    KillAuraDistance = 100,
    KillAuraDamage = 9000000000,
    IgnoreFriends = false,
    KillAuraOnHit = false,
    KillAuraHitMultiplier = 1,

    -- Hitbox
    Hitbox = false,
    HitboxSize = 15,

    -- God Mode
    GodMode = false,
    GodModeV2 = false,
    LagServer = false,

    -- Wall Combo
    WallCombo = false,
    WallComboMethod = "Method 1",
    WallComboIgnoreFriends = false,

    -- Movement
    DashCooldown = 100,
    DashSpeed = 100,
    JumpHeight = 100,
    RunSpeed = 100,
    WalkSpeed = 100,
    RagdollPower = 100,
    MeleeSpeed = 100,
    MeleeCooldown = 100,
    TPWalk = false,
    TPWalkSpeed = 0,

    -- Auto Reset
    AutoReset = false,
    RespawnAtDeath = false,

    -- Farm
    SelectedFarmPlayer = nil,
    FarmLoop = false,
    AutoFarm = false,

    -- Cosmetics (simplified)
    KillEmote = "None",
    KillEmoteSlot = 1,
    Accessory = "None",
    Aura = "None",
    Cape = "None",

    -- Misc
    Invisible = false,
}

-- Loops storage
local Loops = {
    KillAura = nil,
    GodMode = nil,
    GodModeV2 = nil,
    LagServer = nil,
    WallCombo = nil,
    Farm = nil,
    AutoFarm = nil,
    TPWalk = nil,
}

-- ===== UTILITY FUNCTIONS =====
local function getCurrentCharacter()
    local ok, res = pcall(function() return LocalPlayer.Data.Character.Value end)
    return ok and res or nil
end

local function hasWallCombo(charName)
    if not charName then return false end
    local chars = ReplicatedStorage:FindFirstChild("Characters")
    if not chars then return false end
    local charFolder = chars:FindFirstChild(charName)
    if not charFolder then return false end
    return charFolder:FindFirstChild("WallCombo") ~= nil
end

local function getNearestPlayer(ignoreFriends, maxDist)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if ignoreFriends and LocalPlayer:IsFriendsWith(p.UserId) then continue end
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and th and (th:GetAttribute("Health") or th.Health) > 0 then
                local dist = (hrp.Position - tr.Position).Magnitude
                if dist < nearestDist and (not maxDist or dist <= maxDist) then
                    nearestDist = dist
                    nearest = p.Character
                end
            end
        end
    end
    return nearest
end

-- ===== KILL AURA =====
local function executeKillAura()
    if not Config.KillAura then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local charName = getCurrentCharacter()
    if not charName or not hasWallCombo(charName) then return end
    local wallCombo = ReplicatedStorage.Characters[charName].WallCombo
    if not wallCombo then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then continue end

        local targetChar = player.Character
        if not targetChar then continue end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
        if not targetHrp or not targetHum then continue end

        local health = targetHum:GetAttribute("Health") or targetHum.Health
        if health <= 0 then continue end

        local dist = (hrp.Position - targetHrp.Position).Magnitude
        if dist > Config.KillAuraDistance then continue end

        pcall(function()
            Remotes.Ability:FireServer(wallCombo, Config.KillAuraDamage, {}, targetHrp.Position)
            local startCF = tostring(hrp.CFrame)
            Remotes.Combat:FireServer(
                wallCombo,
                "Characters:" .. charName .. ":WallCombo",
                2,
                Config.KillAuraDamage,
                {
                    HitboxCFrames = { targetHrp.CFrame, targetHrp.CFrame },
                    BestHitCharacter = targetChar,
                    HitCharacters = { targetChar },
                    Ignore = {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = { IsFacing = false, IsInFront = true },
                    ServerTime = tick(),
                    Actions = {
                        ActionNumber1 = {
                            [player.Name] = {
                                StartCFrameStr = startCF,
                                Local = true,
                                Collision = false,
                                Animation = "Punch1Hit",
                                Preset = "Punch",
                                Velocity = Vector3.zero,
                                FromPosition = targetHrp.Position,
                                Seed = math.random(1, 1e6)
                            }
                        }
                    },
                    FromCFrame = targetHrp.CFrame
                },
                "Action150",
                0
            )
        end)
    end
end

local function startKillAura()
    if Loops.KillAura then return end
    Loops.KillAura = heartbeat:Connect(executeKillAura)
end

local function stopKillAura()
    if Loops.KillAura then
        Loops.KillAura:Disconnect()
        Loops.KillAura = nil
    end
end

-- ===== HITBOX EXTENDER =====
local oldBox = nil
local function enableHitbox()
    if oldBox then return end
    local success, core = pcall(require, ReplicatedStorage:FindFirstChild("Core"))
    if not success or not core then return end
    local success2, hitLib = pcall(core.Get, core, "Combat", "Hit")
    if not success2 or not hitLib then return end
    oldBox = hitLib.Box
    hitLib.Box = function(_, ...)
        local args = { ... }
        if Config.Hitbox then
            local opts = args[2] or {}
            opts.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
            args[2] = opts
        end
        return oldBox(_, unpack(args))
    end
end

-- ===== GOD MODE =====
local function godModeLoop()
    while Config.GodMode do
        local npcs = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
        if npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                if npc:IsA("Model") and (npc.Name == "Attacking Bum" or npc.Name == "The Ultimate Bum") then
                    pcall(function()
                        Remotes.Ability:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, 33036, npc, Vector3.new(527,4.5,80))
                        Remotes.Combat:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                            BestHitCharacter = npc,
                            HitCharacters = {npc},
                            HitInfo = { IsFacing = true, IsInFront = true }
                        }, "Action651", 0)
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end

-- ===== GOD MODE V2 (closest player) =====
local function godModeV2Loop()
    while Config.GodModeV2 do
        local target = getNearestPlayer(Config.IgnoreFriends, nil)
        if target then
            pcall(function()
                Remotes.Ability:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, 33036, target, target.HumanoidRootPart.Position)
                Remotes.Combat:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                    BestHitCharacter = target,
                    HitCharacters = {target},
                    HitInfo = { IsFacing = true, IsInFront = true }
                }, "Action651", 0)
            end)
        end
        task.wait(0.1)
    end
end

-- ===== LAG SERVER =====
local function lagServerLoop()
    while Config.LagServer do
        local npcs = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
        if npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                if npc:IsA("Model") and (npc.Name == "Attacking Bum" or npc.Name == "The Ultimate Bum") then
                    pcall(function()
                        Remotes.Ability:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, 33036, npc, Vector3.new(527,4.5,80))
                        Remotes.Combat:FireServer(ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                            BestHitCharacter = npc,
                            HitCharacters = {npc},
                            HitInfo = { IsFacing = true, IsInFront = true }
                        }, "Action651", 0)
                    end)
                end
            end
        end
        task.wait()
    end
end

-- ===== WALL COMBO SPAM =====
local function wallComboMethod1()
    local charName = getCurrentCharacter()
    if not charName or not hasWallCombo(charName) then return end
    local wallCombo = ReplicatedStorage.Characters[charName].WallCombo
    if not wallCombo then return end

    local target = getNearestPlayer(Config.WallComboIgnoreFriends, 50)
    if not target then return end
    local targetHrp = target.HumanoidRootPart

    pcall(function()
        Remotes.Ability:FireServer(wallCombo, math.random(1000,9999), target, targetHrp.Position)
        Remotes.Combat:FireServer(wallCombo, "Characters:"..charName..":WallCombo", 1, math.random(1000,9999), {
            BestHitCharacter = target,
            HitCharacters = {target},
            HitInfo = { IsFacing = true, IsInFront = true }
        }, "Action"..math.random(1000,9999), 0)
    end)
end

local function wallComboLoop()
    while Config.WallCombo do
        if Config.WallComboMethod == "Method 1" then
            wallComboMethod1()
        end
        task.wait(0.1)
    end
end

-- ===== TP WALK =====
local function tpWalkLoop()
    while Config.TPWalk do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 and Config.TPWalkSpeed > 0 then
            char:TranslateBy(hum.MoveDirection * Config.TPWalkSpeed * heartbeat:Wait())
        else
            heartbeat:Wait()
        end
    end
end

-- ===== AUTO RESET ON DEATH =====
local function onCharacterAdded(char)
    if Config.RespawnAtDeath and Config.DeathPosition then
        task.wait(0.2)
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = Config.DeathPosition
    end

    local hum = char:WaitForChild("Humanoid")
    hum:GetAttributeChangedSignal("Health"):Connect(function()
        if Config.AutoReset then
            local health = hum:GetAttribute("Health") or hum.Health
            if health <= 0 then
                hum:ChangeState(Enum.HumanoidStateType.Dead)
            end
        end
        if Config.RespawnAtDeath then
            local health = hum:GetAttribute("Health") or hum.Health
            if health <= 0 then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then Config.DeathPosition = hrp.CFrame end
            end
        end
    end)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ===== CREATE RAYFIELD WINDOW =====
local Window = Rayfield:CreateWindow({
    Name = "Ultimate Battlegrounds",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by elton",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EltonsHub_UB",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Enter Key",
        Note = "",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = "Hello"
    }
})

-- ===== MAIN TAB =====
local MainTab = Window:CreateTab("Main", "home")
MainTab:CreateSection("Hitbox Settings")

MainTab:CreateToggle({
    Name = "Hitbox Extender",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        Config.Hitbox = Value
        enableHitbox()
    end
})

MainTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 15,
    Flag = "HitboxSize",
    Callback = function(Value)
        Config.HitboxSize = Value
    end
})

MainTab:CreateSection("Other Settings")

local function createMultiplierToggle(name, folder, flag, default)
    MainTab:CreateToggle({
        Name = name,
        CurrentValue = default,
        Flag = flag,
        Callback = function(Value)
            pcall(function() folder.Value = Value end)
        end
    })
end

createMultiplierToggle("Disable Combat Timer", Toggles:WaitForChild("DisableCombatTimer"), "DisableCombatTimer", false)
createMultiplierToggle("Disable Finishers", Toggles:WaitForChild("DisableFinishers"), "DisableFinishers", false)
createMultiplierToggle("Disable Hit Stun", Toggles:WaitForChild("DisableHitStun"), "DisableHitStun", false)
createMultiplierToggle("Longer Ultimate", Toggles:WaitForChild("Endless"), "LongerUltimate", false)
createMultiplierToggle("Instant Ultimate", Toggles:WaitForChild("InstantTransformation"), "InstantUltimate", false)
createMultiplierToggle("Multi Cutscene", Toggles:WaitForChild("MultiUseCutscenes"), "MultiCutscene", false)
createMultiplierToggle("No Jump Fatigue", Toggles:WaitForChild("NoJumpFatigue"), "NoJumpFatigue", false)
createMultiplierToggle("No Slowdowns", Toggles:WaitForChild("NoSlowdowns"), "NoSlowdowns", false)
createMultiplierToggle("No Stun On Miss", Toggles:WaitForChild("NoStunOnMiss"), "NoStunOnMiss", false)

-- ===== RAGE TAB =====
local RageTab = Window:CreateTab("Rage", "skull")
RageTab:CreateSection("Kill Aura")

RageTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        Config.KillAura = Value
        if Value then startKillAura() else stopKillAura() end
    end
})

RageTab:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Flag = "KillAuraIgnoreFriends",
    Callback = function(Value)
        Config.IgnoreFriends = Value
    end
})

RageTab:CreateSlider({
    Name = "Kill Aura Distance",
    Range = {10, 500},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 100,
    Flag = "KillAuraDistance",
    Callback = function(Value)
        Config.KillAuraDistance = Value
    end
})

RageTab:CreateSection("Damage Multiplier")

RageTab:CreateToggle({
    Name = "Damage Multiplier",
    CurrentValue = false,
    Flag = "KillAuraOnHit",
    Callback = function(Value)
        Config.KillAuraOnHit = Value
    end
})

RageTab:CreateSlider({
    Name = "Multiplier",
    Range = {1, 50},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "KillAuraMultiplier",
    Callback = function(Value)
        Config.KillAuraHitMultiplier = Value
    end
})

RageTab:CreateSection("God Mode")

RageTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(Value)
        Config.GodMode = Value
        if Value then
            Loops.GodMode = task.spawn(godModeLoop)
        else
            if Loops.GodMode then task.cancel(Loops.GodMode) end
        end
    end
})

RageTab:CreateToggle({
    Name = "God Mode V2 (Ranked)",
    CurrentValue = false,
    Flag = "GodModeV2",
    Callback = function(Value)
        Config.GodModeV2 = Value
        if Value then
            Loops.GodModeV2 = task.spawn(godModeV2Loop)
        else
            if Loops.GodModeV2 then task.cancel(Loops.GodModeV2) end
        end
    end
})

RageTab:CreateSection("Lag Server")

RageTab:CreateToggle({
    Name = "Lag Server",
    CurrentValue = false,
    Flag = "LagServer",
    Callback = function(Value)
        Config.LagServer = Value
        if Value then
            Loops.LagServer = task.spawn(lagServerLoop)
        else
            if Loops.LagServer then task.cancel(Loops.LagServer) end
        end
    end
})

RageTab:CreateSection("Wall Combo")

RageTab:CreateDropdown({
    Name = "Wall Combo Method",
    Options = {"Method 1", "Method 2"},
    CurrentOption = "Method 1",
    Flag = "WallComboMethod",
    Callback = function(Value)
        Config.WallComboMethod = Value
    end
})

RageTab:CreateToggle({
    Name = "Spam Wall Combo",
    CurrentValue = false,
    Flag = "WallCombo",
    Callback = function(Value)
        Config.WallCombo = Value
        if Value then
            Loops.WallCombo = task.spawn(wallComboLoop)
        else
            if Loops.WallCombo then task.cancel(Loops.WallCombo) end
        end
    end
})

RageTab:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Flag = "WallComboIgnoreFriends",
    Callback = function(Value)
        Config.WallComboIgnoreFriends = Value
    end
})

-- ===== MOVEMENT TAB =====
local MovementTab = Window:CreateTab("Movement", "activity")
MovementTab:CreateSection("Multipliers / Cooldowns")

local function createMultiplierInput(name, folder, flag, default)
    MovementTab:CreateSlider({
        Name = name,
        Range = {0, 500},
        Increment = 1,
        Suffix = "%",
        CurrentValue = default,
        Flag = flag,
        Callback = function(Value)
            pcall(function() folder.Value = Value end)
        end
    })
end

createMultiplierInput("Dash Cooldown", Cooldowns:WaitForChild("Dash"), "DashCooldown", 100)
createMultiplierInput("Dash Speed", Multipliers:WaitForChild("DashSpeed"), "DashSpeed", 100)
createMultiplierInput("Jump Height", Multipliers:WaitForChild("JumpHeight"), "JumpHeight", 100)
createMultiplierInput("Run Speed", Multipliers:WaitForChild("RunSpeed"), "RunSpeed", 100)
createMultiplierInput("Walk Speed", Multipliers:WaitForChild("WalkSpeed"), "WalkSpeed", 100)
createMultiplierInput("Ragdoll Power", Multipliers:WaitForChild("RagdollPower"), "RagdollPower", 100)
createMultiplierInput("Melee Speed", Multipliers:WaitForChild("MeleeSpeed"), "MeleeSpeed", 100)
createMultiplierInput("Melee Cooldown", Cooldowns:WaitForChild("Melee"), "MeleeCooldown", 100)

MovementTab:CreateSection("TP Walk")

MovementTab:CreateToggle({
    Name = "TP Walk",
    CurrentValue = false,
    Flag = "TPWalk",
    Callback = function(Value)
        Config.TPWalk = Value
        if Value then
            Loops.TPWalk = task.spawn(tpWalkLoop)
        else
            if Loops.TPWalk then task.cancel(Loops.TPWalk) end
        end
    end
})

MovementTab:CreateSlider({
    Name = "TP Walk Speed",
    Range = {0, 200},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 50,
    Flag = "TPWalkSpeed",
    Callback = function(Value)
        Config.TPWalkSpeed = Value
    end
})

MovementTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        end
    end
})

-- ===== FARM TAB =====
local FarmTab = Window:CreateTab("Farm", "list")
FarmTab:CreateSection("Player Teleport")

-- Dropdown for player selection
local playerOptions = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerOptions, p.Name) end
end
if #playerOptions == 0 then playerOptions = {"No players"} end

local playerDropdown = FarmTab:CreateDropdown({
    Name = "Select Player",
    Options = playerOptions,
    CurrentOption = playerOptions[1],
    Flag = "FarmPlayer",
    Callback = function(Value)
        Config.SelectedFarmPlayer = Players:FindFirstChild(Value)
    end
})

-- Refresh button
FarmTab:CreateButton({
    Name = "Refresh List",
    Callback = function()
        local newOpts = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(newOpts, p.Name) end
        end
        if #newOpts == 0 then newOpts = {"No players"} end
        playerDropdown:SetOptions(newOpts)
    end
})

FarmTab:CreateButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        if Config.SelectedFarmPlayer and Config.SelectedFarmPlayer.Character then
            local targetHrp = Config.SelectedFarmPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp and myHrp then
                myHrp.CFrame = targetHrp.CFrame
            end
        end
    end
})

FarmTab:CreateToggle({
    Name = "Loop Teleport",
    CurrentValue = false,
    Flag = "FarmLoop",
    Callback = function(Value)
        Config.FarmLoop = Value
        if Value then
            Loops.Farm = heartbeat:Connect(function()
                if Config.FarmLoop and Config.SelectedFarmPlayer and Config.SelectedFarmPlayer.Character then
                    local targetHrp = Config.SelectedFarmPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp and myHrp then
                        myHrp.CFrame = targetHrp.CFrame
                    end
                end
            end)
        else
            if Loops.Farm then Loops.Farm:Disconnect() end
        end
    end
})

FarmTab:CreateSection("Auto Farm")

FarmTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        Config.AutoFarm = Value
        if Value then
            Config.KillAura = true
            startKillAura()
            Loops.AutoFarm = task.spawn(function()
                while Config.AutoFarm do
                    local target = getNearestPlayer(false, nil)
                    if target then
                        local cam = workspace.CurrentCamera
                        cam.CameraSubject = target:FindFirstChildOfClass("Humanoid")
                        -- teleport below
                        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local targetHrp = target:FindFirstChild("HumanoidRootPart")
                        if myHrp and targetHrp then
                            myHrp.CFrame = CFrame.new(targetHrp.Position.X, targetHrp.Position.Y - 10, targetHrp.Position.Z)
                        end
                    end
                    task.wait(0.25)
                end
            end)
        else
            if Loops.AutoFarm then task.cancel(Loops.AutoFarm) end
            Config.KillAura = false
            stopKillAura()
            -- reset camera
            local myChar = LocalPlayer.Character
            if myChar then
                local hum = myChar:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end
        end
    end
})

-- ===== COSMETICS TAB =====
local CosmeticsTab = Window:CreateTab("Cosmetics/Emotes", "smile")
CosmeticsTab:CreateSection("Kill Emotes")

-- Fetch kill emotes
local killEmoteOptions = {"None"}
local killEmoteFolder = ReplicatedStorage:FindFirstChild("Cosmetics") and ReplicatedStorage.Cosmetics:FindFirstChild("KillEmote")
if killEmoteFolder then
    for _, v in pairs(killEmoteFolder:GetChildren()) do
        table.insert(killEmoteOptions, v.Name)
    end
end

CosmeticsTab:CreateDropdown({
    Name = "Select Kill Emote",
    Options = killEmoteOptions,
    CurrentOption = "None",
    Flag = "KillEmote",
    Callback = function(Value)
        Config.KillEmote = Value
    end
})

CosmeticsTab:CreateDropdown({
    Name = "Slot (1-4)",
    Options = {"1", "2", "3", "4"},
    CurrentOption = "1",
    Flag = "KillEmoteSlot",
    Callback = function(Value)
        Config.KillEmoteSlot = tonumber(Value)
    end
})

CosmeticsTab:CreateButton({
    Name = "Apply Kill Emote",
    Callback = function()
        local data = {}
        for i = 1, 4 do
            if i == Config.KillEmoteSlot then
                table.insert(data, {"KillEmote", Config.KillEmote})
            else
                table.insert(data, {"Emote", "None"})
            end
        end
        for i = 1, 4 do
            table.insert(data, true)
        end
        local json = game:GetService("HttpService"):JSONEncode(data)
        LocalPlayer.Data.EmoteEquipped.Value = json
    end
})

CosmeticsTab:CreateSection("Cosmetics")

-- Accessories
local accOptions = {"None", "Chunin Exam Vest", "Halo", "Frozen Gloves", "Devil's Eye", "Devil's Tail", "Devil's Wings", "Flower Wings", "Frozen Crown", "Frozen Tail", "Frozen Wings", "Garland Scarf", "Hades Helmet", "Holiday Scarf", "Krampus Hat", "Red Kagune", "Rudolph Antlers", "Snowflake Wings", "Sorting Hat", "VIP Crown"}
CosmeticsTab:CreateDropdown({
    Name = "Accessories",
    Options = accOptions,
    CurrentOption = "None",
    Flag = "Accessory",
    Callback = function(Value)
        Config.Accessory = Value
    end
})

-- Auras
local auraOptions = {"None", "Butterflies", "Northern Lights", "Ki", "Blue Lightning", "Green Lightning", "Purple Lightning", "Yellow Lightning"}
CosmeticsTab:CreateDropdown({
    Name = "Auras",
    Options = auraOptions,
    CurrentOption = "None",
    Flag = "Aura",
    Callback = function(Value)
        Config.Aura = Value
    end
})

-- Capes
local capeOptions = {"None", "Ice Lord", "Viking", "Christmas Lights", "Dracula", "Krampus", "Krampus Supreme", "Santa", "VIP", "Webbed"}
CosmeticsTab:CreateDropdown({
    Name = "Capes",
    Options = capeOptions,
    CurrentOption = "None",
    Flag = "Cape",
    Callback = function(Value)
        Config.Cape = Value
    end
})

CosmeticsTab:CreateButton({
    Name = "Apply Cosmetics",
    Callback = function()
        local function apply(type, selected)
            local valueName = type .. "Equipped"
            local data = (selected ~= "None") and {selected} or {}
            local json = game:GetService("HttpService"):JSONEncode(data)
            local folder = LocalPlayer:FindFirstChild("Data")
            if folder then
                local val = folder:FindFirstChild(valueName) or Instance.new("StringValue")
                val.Name = valueName
                val.Value = json
                val.Parent = folder
            end
        end
        apply("Accessories", Config.Accessory)
        apply("Auras", Config.Aura)
        apply("Capes", Config.Cape)
    end
})

-- ===== MISC TAB =====
local MiscTab = Window:CreateTab("Misc", "box")
MiscTab:CreateSection("Miscellaneous")

MiscTab:CreateToggle({
    Name = "Fast Spawn (Auto Reset)",
    CurrentValue = false,
    Flag = "AutoReset",
    Callback = function(Value)
        Config.AutoReset = Value
    end
})

MiscTab:CreateToggle({
    Name = "Respawn at Death Position",
    CurrentValue = false,
    Flag = "RespawnAtDeath",
    Callback = function(Value)
        Config.RespawnAtDeath = Value
        if not Value then Config.DeathPosition = nil end
    end
})

-- Invisibility (simplified - may not work perfectly)
MiscTab:CreateToggle({
    Name = "Invisibility (Experimental)",
    CurrentValue = false,
    Flag = "Invisible",
    Callback = function(Value)
        Config.Invisible = Value
        -- Simple invisibility by setting transparency
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = Value and 1 or 0
                end
            end
        end
    end
})

-- ===== SETTINGS TAB =====
local SettingsTab = Window:CreateTab("Settings", "settings")
SettingsTab:CreateSection("UI Settings")

-- Rayfield provides its own settings tab automatically; we can add an extra button to unload
SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end
})

-- Initialize
Rayfield:LoadConfiguration()