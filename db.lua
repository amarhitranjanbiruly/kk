loadstring(game:HttpGet("https://eltonshub-loader.netlify.app/Bypass.lua"))()
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Options = Fluent.Options
local Window = Fluent:CreateWindow({
    Title = "Ultimate Battlegrounds",
    SubTitle = "by elton",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Rage = Window:AddTab({ Title = "Rage", Icon = "skull" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "list" }),
    Cosmetics = Window:AddTab({ Title = "Cosmetics/Emotes", Icon = "smile" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local hb = RunService.Heartbeat

local Folders = {
    Toggles = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Toggles"),
    Multipliers = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"),
    Cooldowns = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Cooldowns")
}

local KillAuraConfig = {
    KillAuraEnabled = false,
    KillAuraRangeEnabled = false,
    KillAuraDistance = 100,
    KillAuraDamage = 9000000000,
    IgnoreFriends = false,
    KillAuraLoop = nil,
    KillAuraOnHit = false,
    KillAuraHitMultiplier = 1
}

local RemoteCache = {
    CharactersFolder = nil,
    RemotesFolder = nil,
    AbilitiesRemote = nil,
    CombatRemote = nil,
    DashRemote = nil
}


task.spawn(function()

    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until Window

    local player = game:GetService("Players").LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    if PlayerGui:FindFirstChild("ControlButtonGUI") then
        PlayerGui.ControlButtonGUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ControlButtonGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999999
    ScreenGui.Parent = PlayerGui

    local ControlButton = Instance.new("ImageButton")
    ControlButton.Size = UDim2.new(0, 55, 0, 55)
    ControlButton.Position = UDim2.new(0.10, -70, 0.22, -25)
    ControlButton.Image = "rbxassetid://116498441103707"
    ControlButton.BackgroundColor3 = Color3.fromRGB(35,35,35)
    ControlButton.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1,0)
    corner.Parent = ControlButton

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(70,70,70)
    stroke.Parent = ControlButton

    local isMinimized = false

    ControlButton.MouseButton1Down:Connect(function()
        TweenService:Create(ControlButton, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 48, 0, 48)
        }):Play()
    end)

    ControlButton.MouseButton1Up:Connect(function()
        TweenService:Create(ControlButton, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
    end)

    ControlButton.MouseEnter:Connect(function()
        TweenService:Create(ControlButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45,45,45)
        }):Play()
    end)

    ControlButton.MouseLeave:Connect(function()
        TweenService:Create(ControlButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(35,35,35)
        }):Play()
    end)

    ControlButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        Window:Minimize(isMinimized)
    end)

    local dragging
    local dragStart
    local startPos

    ControlButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = ControlButton.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

            local delta = input.Position - dragStart

            ControlButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

end)

local function Setidentity()
    pcall(function()
        setthreadidentity(5)
        setthreadcontext(5)
    end)
end

local function InitializeRemoteCache()
    task.spawn(function()
        RemoteCache.CharactersFolder = ReplicatedStorage:WaitForChild("Characters")
        RemoteCache.RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
        RemoteCache.AbilitiesRemote = RemoteCache.RemotesFolder:WaitForChild("Abilities"):WaitForChild("Ability")
        RemoteCache.CombatRemote = RemoteCache.RemotesFolder:WaitForChild("Combat"):WaitForChild("Action")
        RemoteCache.DashRemote = RemoteCache.RemotesFolder:WaitForChild("Character"):WaitForChild("Dash")
    end)
end

InitializeRemoteCache()

local function startKillAuraRange()
    if KillAuraConfig.KillAuraLoop then return end

    KillAuraConfig.KillAuraLoop = task.spawn(function()
        while KillAuraConfig.KillAuraRangeEnabled do
            if RemoteCache.DashRemote then
                local args = {
                    CFrame.new(741.3605346679688, 4.534152507781982, -157.56654357910156, 0.18018516898155212, 1.20432900985179e-07, 0.9836326837539673, -6.735236368626829e-09, 1, -1.212030724673241e-07, -0.9836326837539673, 1.5213997173191274e-08, 0.18018516898155212),
                    "R",
                    Vector3.new(-0.808182418346405, 0, -0.5889323353767395),
                    [5] = 1767116512.290143,
                    [6] = false
                }
                RemoteCache.DashRemote:FireServer(unpack(args))
            end
            task.wait(0.2)
        end

        KillAuraConfig.KillAuraLoop = nil
    end)
end

local function stopKillAuraRange()
    KillAuraConfig.KillAuraRangeEnabled = false
    if KillAuraConfig.KillAuraLoop then
        task.cancel(KillAuraConfig.KillAuraLoop)
        KillAuraConfig.KillAuraLoop = nil
    end
end


local function ExecuteKillAuraMul(targetCharacter)
    if not targetCharacter then return end

    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not humanoid or not targetRootPart then return end

    local health = humanoid:GetAttribute("Health") or humanoid.Health
    if health <= 0 then return end

    local currentCharacterName = LocalPlayer.Data.Character.Value
    if not currentCharacterName then return end

    if not RemoteCache.CharactersFolder then return end
    local CharacterFolder = RemoteCache.CharactersFolder:FindFirstChild(currentCharacterName)
    if not CharacterFolder then return end

    local localRootPart = Character.HumanoidRootPart
    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    local targetName = targetPlayer and targetPlayer.Name or targetCharacter.Name
    local WallComboAbility = CharacterFolder:FindFirstChild("WallCombo")
    if not WallComboAbility then return end

    RemoteCache.AbilitiesRemote:FireServer(
        WallComboAbility,
        KillAuraConfig.KillAuraDamage,
        {},
        targetRootPart.Position
    )

    local startCFrameStr = tostring(localRootPart.CFrame)

    RemoteCache.CombatRemote:FireServer(
        WallComboAbility,
        "Characters:" .. currentCharacterName .. ":WallCombo",
        2,
        KillAuraConfig.KillAuraDamage,
        {
            HitboxCFrames = {
                targetRootPart.CFrame,
                targetRootPart.CFrame
            },
            BestHitCharacter = targetCharacter,
            HitCharacters = { targetCharacter },
            Ignore = {},
            DeathInfo = {},
            BlockedCharacters = {},
            HitInfo = {
                IsFacing = false,
                IsInFront = true
            },
            ServerTime = 1757900883.306848,
            Actions = {
                ActionNumber1 = {
                    [targetName] = {
                        StartCFrameStr = startCFrameStr,
                        Local = true,
                        Collision = false,
                        Animation = "Punch1Hit",
                        Preset = "Punch",
                        Velocity = Vector3.zero,
                        FromPosition = targetRootPart.Position,
                        Seed = 100735804
                    }
                }
            },
            FromCFrame = targetRootPart.CFrame
        },
        "Action150",
        0
    )
end


local lastKillAuraExecution = 0
local KILL_AURA_COOLDOWN = 0.01

local function ExecuteKillAura()
    if not KillAuraConfig.KillAuraEnabled then return end
    
    local now = tick()
    if now - lastKillAuraExecution < KILL_AURA_COOLDOWN then return end
    lastKillAuraExecution = now
    
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local currentCharacterName = LocalPlayer.Data.Character.Value
    if not currentCharacterName then return end
    
    if not RemoteCache.CharactersFolder then return end
    local CharacterFolder = RemoteCache.CharactersFolder:FindFirstChild(currentCharacterName)
    if not CharacterFolder then return end
    
    local localRootPart = Character.HumanoidRootPart
    local WallComboAbility = CharacterFolder:FindFirstChild("WallCombo")
    if not WallComboAbility then return end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer == LocalPlayer or not targetPlayer.Character then
            continue
        end
        
        if not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            continue
        end
        
        if KillAuraConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(targetPlayer.UserId) then
            continue
        end
        
        local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        local targetRootPart = targetPlayer.Character.HumanoidRootPart
        
        if not targetHumanoid then
            continue
        end

        local health = targetHumanoid:GetAttribute("Health") or targetHumanoid.Health
        if health <= 0 then
            continue
        end
        
        local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
        if distance > KillAuraConfig.KillAuraDistance then
            continue
        end

        local abilityArgs = {
            WallComboAbility,
            KillAuraConfig.KillAuraDamage,
            {},
            targetRootPart.Position
        }
        RemoteCache.AbilitiesRemote:FireServer(unpack(abilityArgs))
        
        local startCFrameStr = tostring(localRootPart.CFrame)
        
        local combatArgs = {
            WallComboAbility, 
            "Characters:" .. currentCharacterName .. ":WallCombo", 
            2,
            KillAuraConfig.KillAuraDamage,
            {
                HitboxCFrames = {
                    targetRootPart.CFrame,
                    targetRootPart.CFrame
                },
                BestHitCharacter = targetPlayer.Character,
                HitCharacters = { targetPlayer.Character },
                Ignore = {},
                DeathInfo = {},
                BlockedCharacters = {},
                HitInfo = {
                    IsFacing = false,
                    IsInFront = true
                },
                ServerTime = 1757900883.306848,
                Actions = {
                    ActionNumber1 = {
                        [targetPlayer.Name] = {
                            StartCFrameStr = startCFrameStr,
                            Local = true,
                            Collision = false,
                            Animation = "Punch1Hit",
                            Preset = "Punch",
                            Velocity = Vector3.zero,
                            FromPosition = targetRootPart.Position,
                            Seed = 100735804
                        }
                    }
                },
                FromCFrame = targetRootPart.CFrame
            },
            "Action150",
            0
        }
        RemoteCache.CombatRemote:FireServer(unpack(combatArgs))
    end
end

RunService.Heartbeat:Connect(function()
    for i = 1, 5 do
    ExecuteKillAura()
    end
end)


local RS = game:GetService("ReplicatedStorage")
local ActionRemote = RS:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

local InternalCall = false

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if self == ActionRemote and method == "FireServer" and not InternalCall then
        local data = args[5]
        if type(data) == "table" and data.HitCharacters and KillAuraConfig.KillAuraOnHit then
            for _, char in pairs(data.HitCharacters) do
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local health = humanoid:GetAttribute("Health") or humanoid.Health
                    if health > 0 then
                        InternalCall = true

                        for i = 1, KillAuraConfig.KillAuraHitMultiplier do
                            ExecuteKillAuraMul(char)
                        end

                        InternalCall = false
                    end
                end
            end
        end
    end

    return old(self, ...)
end)

setreadonly(mt, true)


local HitboxSettings = {
    hitSize = 15,
    hitboxActive = false,
    hitLib = nil,
    oldBox = nil,
    pendingEnable = false
}

local enableHitbox

task.spawn(function()

    local CoreModule = ReplicatedStorage:WaitForChild("Core", 10)
    if not CoreModule then return end

    local core

    for _ = 1, 30 do
        local success, result = pcall(function()
            return require(CoreModule)
        end)

        if success and result and type(result.Get) == "function" then
            core = result
            break
        end

        task.wait(0.25)
    end

    if not core then return end

    for _ = 1, 30 do
        local success, result = pcall(function()
            return core.Get("Combat", "Hit")
        end)

        if success and result and type(result.Box) == "function" then
            HitboxSettings.hitLib = result
            break
        end

        task.wait(0.25)
    end

    if not HitboxSettings.hitLib then return end

    HitboxSettings.oldBox = HitboxSettings.hitLib.Box

    if HitboxSettings.pendingEnable then
        enableHitbox()
    end
end)

function enableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.oldBox then
        HitboxSettings.pendingEnable = true
        return false
    end
    if HitboxSettings.hitboxActive then return true end

    HitboxSettings.hitboxActive = true
    HitboxSettings.pendingEnable = false

    HitboxSettings.hitLib.Box = function(_, ...)
        local args = { ... }

        if not HitboxSettings.hitboxActive then
            return HitboxSettings.oldBox(_, unpack(args))
        end

        local size = HitboxSettings.hitSize or 15
        local opts = {}
        if type(args[2]) == "table" then
            for k, v in pairs(args[2]) do
                opts[k] = v
            end
        end
        opts.Size = Vector3.new(size, size, size)
        args[2] = opts

        return HitboxSettings.oldBox(_, unpack(args))
    end

    return true
end

local function disableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.oldBox then return end
    if not HitboxSettings.hitboxActive then return end

    HitboxSettings.hitboxActive = false
    HitboxSettings.pendingEnable = false
    HitboxSettings.hitLib.Box = HitboxSettings.oldBox
end

local function setHitboxSize(size)
    HitboxSettings.hitSize = size
end

HitboxSettings.hitSize = 15

local Section = Tabs.Main:AddSection("Hitbox Settings")

local HitboxToggle = Tabs.Main:AddToggle("HitboxToggle", {
    Title = "Hitbox Extender",
    Default = false,
    Callback = function(Value)
        if Value then
            enableHitbox()
        else
            disableHitbox()
        end
    end
})

local LockHitbox = false

local InputHitbox = Tabs.Main:AddInput("HitboxSizeInput", {
    Title = "Hitbox Size",
    Default = "15",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local size = tonumber(Value) or 15
        size = math.clamp(size, 1, 100)
        setHitboxSize(size)
    end
})


InputHitbox:OnChanged(function()
    if LockHitbox then return end

    local v = tonumber(InputHitbox.Value)
    if not v then return end

    if v > 100 then
        LockHitbox = true
        InputHitbox:SetValue("100")
        setHitboxSize(100)
        LockHitbox = false
    elseif v < 1 then
        LockHitbox = true
        InputHitbox:SetValue("1")
        setHitboxSize(1)
        LockHitbox = false
    end
end)

Tabs.Main:AddKeybind("HitboxKeybind", {
    Title = "Hitbox Keybind",
    Mode = "Toggle",
    Default = "",

    Callback = function(Value)
        HitboxToggle:SetValue(Value)
    end
})
Tabs.Main:AddSection("Other Settings")

Tabs.Main:AddToggle("DisableCombatTimer", {
    Title = "Disable Combat Timer",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("DisableCombatTimer").Value = state
    end
})

Tabs.Main:AddToggle("DisableFinishers", {
    Title = "Disable Finishers",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("DisableFinishers").Value = state
    end
})

Tabs.Main:AddToggle("DisableHitStun", {
    Title = "Disable Hit Stun",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("DisableHitStun").Value = state
    end
})

Tabs.Main:AddToggle("Longerultimate", {
    Title = "Longer ultimate",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("Endless").Value = state
    end
})

Tabs.Main:AddToggle("Instantultimate", {
    Title = "Instant ultimate",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("InstantTransformation").Value = state
    end
})

Tabs.Main:AddToggle("MultiCutscene", {
    Title = "Multi Cutscene",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("MultiUseCutscenes").Value = state
    end
})

Tabs.Main:AddToggle("NoJumpFatigue", {
    Title = "No Jump Fatigue",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("NoJumpFatigue").Value = state
    end
})

Tabs.Main:AddToggle("NoSlowdowns", {
    Title = "No Slowdowns",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("NoSlowdowns").Value = state
    end
})

Tabs.Main:AddToggle("NoStunOnMiss", {
    Title = "No Stun On Miss",
    Default = false,
    Callback = function(state)
        Folders.Toggles:WaitForChild("NoStunOnMiss").Value = state
    end
})


-- ========== RAGE TAB ==========
Tabs.Rage:AddSection("Kill Aura Settings")

local KillAuraToggle = Tabs.Rage:AddToggle("KillAuraToggle", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(Value)
        KillAuraConfig.KillAuraEnabled = Value
        if Value then
            KillAuraConfig.KillAuraRangeEnabled = true
            startKillAuraRange()
        else
            KillAuraConfig.KillAuraRangeEnabled = false
            stopKillAuraRange()
        end
    end
})

Tabs.Rage:AddToggle("IgnoreFriendsToggle", {
    Title = "Ignore Friends",
    Default = false,
    Callback = function(Value)
        KillAuraConfig.IgnoreFriends = Value
    end
})

Tabs.Rage:AddSection("Damage Multplier Settings")

local KillAuraOnHitToggle = Tabs.Rage:AddToggle("KillAuraOnHitToggle", {
    Title = "Damage Multplier",
    Description = "It is recommended to disable it when using Kill Aura",
    Default = false,
    Callback = function(Value)
        KillAuraConfig.KillAuraOnHit = Value
    end
})

local Input
local Lock = false

Input = Tabs.Rage:AddInput("Input", {
    Title = "Multiplier",
    Default = "1",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        KillAuraConfig.KillAuraHitMultiplier = tonumber(Value) or 1
    end
})

Input:OnChanged(function()
    if Lock then return end

    local v = tonumber(Input.Value)
    if not v then return end

    if v > 50 then
        Lock = true
        Input:SetValue("50")
        KillAuraConfig.KillAuraHitMultiplier = 50
        Lock = false
    elseif v < 1 then
        Lock = true
        Input:SetValue("1")
        KillAuraConfig.KillAuraHitMultiplier = 1
        Lock = false
    end
end)


Tabs.Rage:AddSection("God Mode")

local GodModeConfig = {
    GodMode = false,
    GodModev2 = false
}

local GodModeToggle = Tabs.Rage:AddToggle("GodModeToggle", {
    Title = "God Mode",
    Default = false,
    Callback = function(Value)
        GodModeConfig.GodMode = Value

        if GodModeConfig.GodMode then
            task.spawn(function()
                while GodModeConfig.GodMode do
                    local npcNames = {"Attacking Bum", "Blocking Bum", "The Ultimate Bum"}
                    
                    for _, npcName in ipairs(npcNames) do
                        local targetNPC = workspace.Characters.NPCs:FindFirstChild(npcName)
                        if targetNPC then
                            local combatArgs = {
                                [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                                [2] = "Characters:Gon:WallCombo",
                                [3] = 1,
                                [4] = 33036,
                                [5] = {
                                    HitboxCFrames = {},
                                    BestHitCharacter = targetNPC,
                                    HitCharacters = {targetNPC},
                                    Ignore = {},
                                    DeathInfo = {},
                                    Actions = {},
                                    HitInfo = {
                                        IsFacing = true,
                                        IsInFront = true
                                    },
                                    BlockedCharacters = {},
                                    FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                                },
                                [6] = "Action651",
                                [7] = 0
                            }

                            local abilityArgs = {
                                [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                                [2] = 33036,
                                [4] = targetNPC,
                                [5] = Vector3.new(527.693, 4.532, 79.978)
                            }

                            pcall(function()
                                ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                                ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                            end)
                        end
                    end

                    task.wait(0.1)
                end
            end)
        end
    end
})



local AutoTargetToggle = Tabs.Rage:AddToggle("AutoTargetToggle", {
    Title = "God Mode v2 (Ranked)",
    Default = false,
    Callback = function(Value)
        GodModeConfig.GodModev2 = Value

        if GodModeConfig.GodModev2 then
            task.spawn(function()
                while GodModeConfig.GodModev2 do
                    local Character = LocalPlayer.Character
                    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                        task.wait(0.3)
                        continue
                    end

                    local localRootPart = Character.HumanoidRootPart
                    local closestPlayer = nil
                    local closestDistance = math.huge

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local targetRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
                            
                            if targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
                                if KillAuraConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then
                                    continue
                                end
                                
                                local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = player.Character
                                end
                            end
                        end
                    end

                    if closestPlayer then
                        local combatArgs = {
                            [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                            [2] = "Characters:Gon:WallCombo",
                            [3] = 1,
                            [4] = 33036,
                            [5] = {
                                HitboxCFrames = {},
                                BestHitCharacter = closestPlayer,
                                HitCharacters = {closestPlayer},
                                Ignore = {},
                                DeathInfo = {},
                                Actions = {},
                                HitInfo = {
                                    IsFacing = true,
                                    IsInFront = true
                                },
                                BlockedCharacters = {},
                                FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                            },
                            [6] = "Action651",
                            [7] = 0
                        }

                        local abilityArgs = {
                            [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                            [2] = 33036,
                            [4] = closestPlayer,
                            [5] = Vector3.new(527.693, 4.532, 79.978)
                        }

                        pcall(function()
                            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end)
                    end

                    task.wait(0.1)
                end
            end)
        end
    end
})

Tabs.Rage:AddSection("Lag Server")

local LagServerConfig = {
    LagServer = false
}

local LagServerToggle = Tabs.Rage:AddToggle("LagServerToggle", {
    Title = "Lag Server",
    Default = false,
    Callback = function(Value)
        LagServerConfig.LagServer = Value
        if LagServerConfig.LagServer then
            task.spawn(function()
                while LagServerConfig.LagServer do
                    local npcNames = {"Attacking Bum", "The Ultimate Bum"}
                    
                    for _, npcName in ipairs(npcNames) do
                        local targetNPC = workspace.Characters.NPCs:FindFirstChild(npcName)
                        if targetNPC then
                            local combatArgs = {
                                [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                                [2] = "Characters:Gon:WallCombo",
                                [3] = 1,
                                [4] = 33036,
                                [5] = {
                                    HitboxCFrames = {},
                                    BestHitCharacter = targetNPC,
                                    HitCharacters = {targetNPC},
                                    Ignore = {},
                                    DeathInfo = {},
                                    Actions = {},
                                    HitInfo = {
                                        IsFacing = true,
                                        IsInFront = true
                                    },
                                    BlockedCharacters = {},
                                    FromCFrame = CFrame.new(534.693, 5.532, 79.486)
                                },
                                [6] = "Action651",
                                [7] = 0
                            }

                            local abilityArgs = {
                                [1] = ReplicatedStorage.Characters.Gon.WallCombo,
                                [2] = 33036,
                                [4] = targetNPC,
                                [5] = Vector3.new(527.693, 4.532, 79.978)
                            }

                            pcall(function()
                                ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                                ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                            end)
                        end
                    end

                    task.wait()
                end
            end)
        end
    end 
})

local AbilitySpam = {
    enabled = false,
    connection = nil
}

function AbilitySpam:GetCurrentCharacter()
    local ok, res = pcall(function()
        return LocalPlayer.Data.Character.Value
    end)
    if ok and res then return res end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:GetAttribute("CharacterName") or "Unknown"
end

function AbilitySpam:HasAbility4(characterName)
    local ok, res = pcall(function()
        local chars = ReplicatedStorage:WaitForChild("Characters")
        local folder = chars:FindFirstChild(characterName)
        local ab = folder and folder:FindFirstChild("Abilities")
        return ab and ab:FindFirstChild("4") ~= nil
    end)
    return ok and res
end

function AbilitySpam:FindNearestPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, dist = nil, math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChild("Humanoid")
            if tr and th then
                local hp = th:GetAttribute("Health")
                if hp and hp > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = p
                    end
                end
            end
        end
    end
    return nearest
end

function AbilitySpam:GetNearestPlayerCFrame()
    local p = self:FindNearestPlayer()
    return p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
end

function AbilitySpam:UseAbility4()
    local charName = self:GetCurrentCharacter()
    if not self:HasAbility4(charName) then return end

    local target = self:FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = self:GetNearestPlayerCFrame()

    pcall(function()
        local ability = ReplicatedStorage.Characters[charName].Abilities["4"]
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability,9000000)

        local actions = {377,380,383,384,385,387,389}
        for i=1,7 do
            local args = {
                ability,
                charName..":Abilities:4",
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF,targetCF},
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

            if i==7 then
                args[5].RockCFrame = targetCF
                args[5].Actions = {
                    ActionNumber1 = {
                        [target.Name] = {
                            StartCFrameStr = tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",
                            ImpulseVelocity = Vector3.new(1901,-25000,291),
                            AbilityName = "4",
                            RotVelocityStr = "0,0,0",
                            VelocityStr = "1.900635,0.010867,0.291061",
                            Duration = 2,
                            RotImpulseVelocity = Vector3.new(5868,-6649,-7414),
                            Seed = math.random(1,1e6),
                            LookVectorStr = "0.988493,0,0.151268"
                        }
                    }
                }
            end

            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(args))
        end
    end)
end

function AbilitySpam:Start()
    if self.connection then return end
    self.enabled = true
    self.connection = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        self:UseAbility4()
        task.wait(0.5)
        if self.enabled then
            pcall(function()
                local c = self:GetCurrentCharacter()
                ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(
                    ReplicatedStorage.Characters[c].Abilities["4"]
                )
            end)
        end
        task.wait(0.001)
    end)
end

function AbilitySpam:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.enabled = false
end
local MobRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")

Tabs.Rage:AddToggle("AbilitySpamToggle", {
    Title = "Lag Server V2",
    Description = "Only works with mob",
    Default = false,
    Callback = function(state)

        local mob = game:GetService("Players").LocalPlayer.Data.Character.Value

        if state then
            if mob ~= "Mob" then
                MobRemote:FireServer("Mob")
            end
            AbilitySpam:Start()
        else
            AbilitySpam:Stop()
        end
    end
})

Tabs.Rage:AddSection("WallCombo")

local WallComboConfig = {
    WallComboEnabled = false,
    WallComboMethod = "Method 1",
    WallComboModule1 = nil,
    coreModule = nil,
    renderConnectionName = "WallComboV2",
    WallComboActionIDCounter = 0,
    WallComboIgnoreFriends = false
}

task.spawn(function()
    local success, result = pcall(function()
        return require(LocalPlayer.PlayerScripts.Combat.Melee)
    end)

    if success and result and result.WallCombo then
        WallComboConfig.WallComboModule1 = result
    end
end)

task.spawn(function()
    local success, result = pcall(function()
        return require(ReplicatedStorage.Core)
    end)

    if success and result then
        WallComboConfig.coreModule = result
    end
end)

local function getCurrentCharacterName()
    local success, result = pcall(function()
        return LocalPlayer.Data.Character.Value
    end)
    
    if success and result then
        return result
    end
    return "Unknown"
end

local function characterHasWallCombo(characterName)
    local success, result = pcall(function()
        local charactersFolder = ReplicatedStorage:WaitForChild("Characters")
        if not charactersFolder:FindFirstChild(characterName) then
            return false
        end
        
        local characterFolder = charactersFolder[characterName]
        return characterFolder:FindFirstChild("WallCombo") ~= nil
    end)
    
    return success and result
end

local function generateActionId()
    WallComboConfig.WallComboActionIDCounter = WallComboConfig.WallComboActionIDCounter + 1
    return WallComboConfig.WallComboActionIDCounter + math.random(1000, 5000)
end

local function findNearestPlayerTarget()
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if WallComboConfig.WallComboIgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then
                continue
            end
            
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetRoot and targetHumanoid then
                local health = targetHumanoid:GetAttribute("Health") or targetHumanoid.Health
                if health > 0 then
                    local distance = (humanoidRootPart.Position - targetRoot.Position).Magnitude
                    if distance < shortestDistance and distance < 50 then
                        shortestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end


local function getWallPosition()
    local character = LocalPlayer.Character
    if not character then return Vector3.new(0, 0, 0) end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return Vector3.new(0, 0, 0) end
    
    local lookVector = humanoidRootPart.CFrame.LookVector
    local wallPosition = humanoidRootPart.Position + (lookVector * 5)
    
    return wallPosition
end

local function getRootCFrame()
    local character = LocalPlayer.Character
    if not character then return CFrame.new() end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return CFrame.new() end
    
    return humanoidRootPart.CFrame
end

local function wallcomboMethod1()
    local currentCharacter = getCurrentCharacterName()
    
    if not characterHasWallCombo(currentCharacter) then
        return false
    end
    
    local targetPlayer = findNearestPlayerTarget()
    if not targetPlayer or not targetPlayer.Character then
        return false
    end
    
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    
    local success = pcall(function()
        local abilityObject = ReplicatedStorage:WaitForChild("Characters"):WaitForChild(currentCharacter):WaitForChild("WallCombo")
        local abilityRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Abilities"):WaitForChild("Ability")
        local combatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")
        
        local actionId = generateActionId()
        local serverTime = tick()
        local wallPosition = getWallPosition()
        local fromCFrame = getRootCFrame()

        local abilityArgs = {
            abilityObject,
            actionId,
            [4] = targetPlayer.Character,
            [5] = wallPosition
        }
        abilityRemote:FireServer(unpack(abilityArgs))

        local combatArgs1 = {
            abilityObject,
            "Characters:" .. currentCharacter .. ":WallCombo",
            1,
            actionId,
            {
                HitboxCFrames = {},
                BestHitCharacter = targetPlayer.Character,
                HitCharacters = {targetPlayer.Character},
                Ignore = {},
                DeathInfo = {},
                BlockedCharacters = {},
                HitInfo = {
                    IsFacing = true,
                    GetUp = true,
                    IsInFront = true,
                    Blocked = false
                },
                ServerTime = serverTime,
                Actions = {},
                FromCFrame = fromCFrame
            },
            "Action" .. math.random(1000, 9999),
            0
        }
        combatRemote:FireServer(unpack(combatArgs1))

        local combatArgs2 = {
            abilityObject,
            "Characters:" .. currentCharacter .. ":WallCombo",
            2,
            actionId,
            {
                HitboxCFrames = {CFrame.new(wallPosition)},
                BestHitCharacter = targetPlayer.Character,
                HitCharacters = {targetPlayer.Character},
                Ignore = {ActionNumber1 = {targetPlayer.Character}},
                DeathInfo = {},
                BlockedCharacters = {},
                HitInfo = {IsFacing = true, IsInFront = true, Blocked = false},
                ServerTime = serverTime,
                Actions = {ActionNumber1 = {}},
                FromCFrame = fromCFrame
            },
            "Action" .. math.random(1000, 9999)
        }
        combatRemote:FireServer(unpack(combatArgs2))

        local combatArgs3 = {
            abilityObject,
            "Characters:" .. currentCharacter .. ":WallCombo",
            3,
            actionId,
            {
                HitboxCFrames = {CFrame.new(wallPosition)},
                BestHitCharacter = targetPlayer.Character,
                HitCharacters = {targetPlayer.Character},
                Ignore = {ActionNumber1 = {targetPlayer.Character}},
                DeathInfo = {},
                BlockedCharacters = {},
                HitInfo = {IsFacing = true, IsInFront = true, Blocked = false},
                ServerTime = serverTime,
                Actions = {ActionNumber1 = {}},
                FromCFrame = fromCFrame
            },
            "Action" .. math.random(1000, 9999)
        }
        combatRemote:FireServer(unpack(combatArgs3))

        local combatArgs4 = {
            abilityObject,
            "Characters:" .. currentCharacter .. ":WallCombo",
            4,
            actionId,
            {
                HitboxCFrames = {CFrame.new(wallPosition), CFrame.new(wallPosition)},
                BestHitCharacter = targetPlayer.Character,
                HitCharacters = {targetPlayer.Character},
                Ignore = {},
                DeathInfo = {},
                BlockedCharacters = {},
                HitInfo = {IsFacing = true, IsInFront = true, Blocked = false},
                ServerTime = serverTime,
                Actions = {
                    ActionNumber1 = {
                        [targetPlayer.Name] = {
                            StartCFrameStr = tostring(CFrame.new(targetPlayer.Character.HumanoidRootPart.Position)),
                            ImpulseVelocity = Vector3.new(-67499, 150000, 307),
                            AbilityName = "WallCombo",
                            RotVelocityStr = "0.000000,0.000000,-0.000000",
                            VelocityStr = "0.000000,0.000000,0.000000",
                            Gravity = 200000,
                            RotImpulseVelocity = Vector3.new(8977, -5293, 6185),
                            Seed = math.random(100000000, 999999999),
                            LookVectorStr = tostring(fromCFrame.LookVector),
                            Duration = 2
                        }
                    }
                },
                FromCFrame = fromCFrame
            },
            "Action" .. math.random(1000, 9999),
            0.1
        }
        combatRemote:FireServer(unpack(combatArgs4))
    end)
    
    return success
end

local function wallcomboMethod2()
    if not WallComboConfig.coreModule then return end

    local character = LocalPlayer.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local char = LocalPlayer.Data.Character
    local chars = ReplicatedStorage.Characters

    local res = WallComboConfig.coreModule.Get("Combat","Hit").Box(nil, character, {Size = Vector3.new(50,50,50)})
    if res then
        if WallComboConfig.WallComboIgnoreFriends then
            local targetPlayer = Players:GetPlayerFromCharacter(res)
            if targetPlayer and LocalPlayer:IsFriendsWith(targetPlayer.UserId) then
                return
            end
        end
        
        pcall(WallComboConfig.coreModule.Get("Combat","Ability").Activate,
            chars[char.Value].WallCombo,
            res,
            head.Position + Vector3.new(0,0,2.5)
        )
    end
end

local function executeWallCombo()
    if not WallComboConfig.WallComboEnabled then return end

    if WallComboConfig.WallComboMethod == "Method 1" then
        wallcomboMethod1()
    else
        wallcomboMethod2()
    end
end

local WallComboDropdown = Tabs.Rage:AddDropdown("WallComboMethod", {
    Title = "WallCombo Method",
    Values = {"Method 1", "Method 2"},
    Multi = false,
    Default = 1,
})

WallComboDropdown:OnChanged(function(Value)
    WallComboConfig.WallComboMethod = Value
    
    if WallComboConfig.WallComboEnabled then
        if Value == "Method 1" then
            KillAuraConfig.KillAuraRangeEnabled = true
            startKillAuraRange()
        else
            KillAuraConfig.KillAuraRangeEnabled = false
            stopKillAuraRange()
        end
    end
end)

local wallcomboTogg = Tabs.Rage:AddToggle("WallcomboToggle", {
    Title = "Spam WallCombo",
    Default = false,
    Callback = function(Value)
        WallComboConfig.WallComboEnabled = Value
        Setidentity()

        if Value then
            if WallComboConfig.WallComboMethod == "Method 1" then
                KillAuraConfig.KillAuraRangeEnabled = true
                startKillAuraRange()
            end
            RunService:BindToRenderStep(WallComboConfig.renderConnectionName,Enum.RenderPriority.Input.Value,executeWallCombo)
        else
            KillAuraConfig.KillAuraRangeEnabled = false
            stopKillAuraRange()
            RunService:UnbindFromRenderStep(WallComboConfig.renderConnectionName)
        end
    end
})

Tabs.Rage:AddKeybind("Wallcombobind", {

    Title = "WallCombo Keybind",
    Mode = "Toggle",
    Default = "",

    Callback = function(Value)
        wallcomboTogg:SetValue(Value)
    end
})

Tabs.Rage:AddToggle("WallComboIgnoreFriendsToggle", {
    Title = "Ignore Friends",
    Default = false,
    Callback = function(Value)
        WallComboConfig.WallComboIgnoreFriends = Value
    end
})

-- ========== MOVEMENT TAB ==========
local AutoResetEnabled = false

local function resetCharacterForced()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if typeof(replicatesignal) == "function" and LocalPlayer.Kill then
        replicatesignal(LocalPlayer.Kill)
    elseif humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        character:BreakJoints()
    end
end

local function resetCharacter()
    if not AutoResetEnabled then return end
    resetCharacterForced()
end

local function monitorHumanoid(humanoid)
    if not humanoid then return end
    
    humanoid:GetAttributeChangedSignal("Health"):Connect(function()
        if not AutoResetEnabled then return end
        
        local health = humanoid:GetAttribute("Health")
        if health and health <= 0 then
            resetCharacter()
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

Tabs.Movement:AddButton({
    Title = "Reset Character",
    Callback = function()
        resetCharacterForced()
    end
})

Tabs.Movement:AddInput("Dashcooldown", {
    Title = "Dash cooldown",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Cooldowns:WaitForChild("Dash").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("DashSpeed", {
    Title = "Dash Speed",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("DashSpeed").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("JumpHeight", {
    Title = "Jump Height",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("JumpHeight").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("RunSpeed", {
    Title = "Run Speed",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("RunSpeed").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("WalkSpeed", {
    Title = "Walk Speed",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("WalkSpeed").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("RagdollPower", {
    Title = "Ragdoll Power",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("RagdollPower").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("MeleeSpeed", {
    Title = "Melee Speed",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("MeleeSpeed").Value = tonumber(Value) or 0
    end
})

Tabs.Movement:AddInput("Melee cooldown", {
    Title = "Melee cooldown",
    Default = "100",
    Placeholder = "Default is 100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        Folders.Cooldowns:WaitForChild("Melee").Value = tonumber(Value) or 0
    end
})
do

local tpwalkActive = false
local tpwalkSpeed = 0

local chr
local hum
local rootPart

local function onCharacter(character)
    chr = character
    hum = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    onCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacter)

task.spawn(function()
    while true do
        local delta = hb:Wait()

        if tpwalkActive and tpwalkSpeed > 0 and chr and hum and hum.Parent then
            if hum.MoveDirection.Magnitude > 0 then
                chr:TranslateBy(hum.MoveDirection * tpwalkSpeed * delta)
            end
        end
    end
end)

Tabs.Movement:AddInput("TPWalkSpeed", {
    Title = "TP Walk Speed",
    Default = "0",
    Placeholder = "...",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local speed = tonumber(Value) or 0
        tpwalkSpeed = speed
    end
})

local tpwalkToggle = Tabs.Movement:AddToggle("TPWalkToggle", {
    Title = "TP Walk",
    Default = false,
    Callback = function(Value)
        tpwalkActive = Value
    end
})

Tabs.Movement:AddKeybind("TPWalkBind", {
    Title = "TP Walk Keybind",
    Mode = "Toggle",
    Default = "",
    Callback = function(Value)
        tpwalkToggle:SetValue(Value)
    end
})
end
-- ========== FARM TAB ==========
do
    local selectedFarmPlayer = nil
    local farmLoopEnabled = false
    local farmLoopThread = nil
    local autoFarmEnabled = false
    local autoFarmThread = nil

    local function getPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        if #list == 0 then
            table.insert(list, "No players")
        end
        return list
    end

    local function setCameraToPlayer(player)
        if not player or not player.Character then return end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end

    local function resetCamera()
        local myChar = LocalPlayer.Character
        if myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
        end
    end

    local function teleportExact(player)
        if not player or not player.Character then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end

        myHRP.CFrame = targetHRP.CFrame
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end

    local function teleportBelow(player)
        if not player or not player.Character then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end

        myHRP.CFrame = CFrame.new(
            targetHRP.Position.X,
            targetHRP.Position.Y - 10,
            targetHRP.Position.Z
        )
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end

    local function getPlayerByName(name)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == name then return p end
        end
        return nil
    end

    local function isPlayerAlive(player)
        if not player or not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local health = hum:GetAttribute("Health") or hum.Health
        return health > 0
    end

    Tabs.Farm:AddSection("Player Teleport")

    local PlayerDropdown = Tabs.Farm:AddDropdown("FarmPlayerDropdown", {
        Title = "Select Player",
        Values = getPlayerList(),
        Multi = false,
        Default = 1,
    })

    PlayerDropdown:OnChanged(function(Value)
        selectedFarmPlayer = getPlayerByName(Value)
    end)

    local initialList = getPlayerList()
    if initialList[1] ~= "No players" then
        selectedFarmPlayer = getPlayerByName(initialList[1])
    end

    Tabs.Farm:AddButton({
        Title = "Refresh List",
        Callback = function()
            local newList = getPlayerList()
            PlayerDropdown:SetValues(newList)
            if selectedFarmPlayer and selectedFarmPlayer.Parent then
                PlayerDropdown:SetValue(selectedFarmPlayer.Name)
            else
                selectedFarmPlayer = getPlayerByName(newList[1])
            end
        end
    })

    Tabs.Farm:AddButton({
        Title = "Teleport to Selected Player",
        Callback = function()
            if selectedFarmPlayer then
                teleportExact(selectedFarmPlayer)
            end
        end
    })

    local FarmLoopToggle = Tabs.Farm:AddToggle("FarmLoopToggle", {
        Title = "Loop Teleport",
        Default = false,
        Callback = function(Value)
            farmLoopEnabled = Value
            if Value then
                farmLoopThread = RunService.Heartbeat:Connect(function()
                    if not farmLoopEnabled then return end
                    if selectedFarmPlayer and selectedFarmPlayer.Parent then
                        teleportExact(selectedFarmPlayer)
                    end
                end)
            else
                if farmLoopThread then
                    farmLoopThread:Disconnect()
                    farmLoopThread = nil
                end
            end
        end
    })

    Tabs.Farm:AddSection("Auto Farm")

local AutoFarmToggle = Tabs.Farm:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Default = false,
    Callback = function(Value)
        autoFarmEnabled = Value
        

        if Value then
            KillAuraToggle:SetValue(true)
            autoFarmThread = task.spawn(function()
                while autoFarmEnabled do
                    local foundTarget = false

                    for _, p in ipairs(Players:GetPlayers()) do
                        if not autoFarmEnabled then break end

                        if p ~= LocalPlayer
                        and p.Character
                        and p.Character:FindFirstChild("HumanoidRootPart")
                        and isPlayerAlive(p) then

                            foundTarget = true
                            setCameraToPlayer(p)
                            teleportBelow(p)
                            task.wait(0.25)
                        end
                    end

                    if not foundTarget then
                        task.wait(1)
                    Fluent:Notify({
                        Title = "not found target",
                        Content = "No targets found on this server.",
                        Duration = 5 
                    })
                    else
                        task.wait(0.05)
                    end
                end
            end)
        else
            if autoFarmThread then
                task.cancel(autoFarmThread)
                autoFarmThread = nil
            end
            resetCamera()
            KillAuraToggle:SetValue(false)
        end
    end
})


Tabs.Farm:AddSection("Server Hop")

local ServerHopConfig = {
    serverHopEnabled = false,
    serverHopDelay = 30,
    serverHopThread = nil

}

local ServerHopInput
local LockHop = false

ServerHopInput = Tabs.Farm:AddInput("ServerHopDelay", {
    Title = "Server Hop Delay (seconds)",
    Default = "30",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        ServerHopConfig.serverHopDelay = tonumber(Value) or 30
    end
})

ServerHopInput:OnChanged(function()
    if LockHop then return end
    local v = tonumber(ServerHopInput.Value)
    if not v then return end
    if v < 1 then
        LockHop = true
        ServerHopInput:SetValue("1")
        ServerHopConfig.serverHopDelay = 1
        LockHop = false
    else
        ServerHopConfig.serverHopDelay = v
    end
end)

local ServerHopToggle = Tabs.Farm:AddToggle("ServerHopToggle", {
    Title = "Server Hop",
    Description = "Automatically hops to a new server every X seconds",
    Default = false,
    Callback = function(Value)
        ServerHopConfig.serverHopEnabled = Value
        if Value then
            ServerHopConfig.serverHopThread = task.spawn(function()
                while ServerHopConfig.serverHopEnabled do
                    task.wait(ServerHopConfig.serverHopDelay)
                    if not ServerHopConfig.serverHopEnabled then break end

                    pcall(function()
                        local TeleportService = game:GetService("TeleportService")
                        local HttpService = game:GetService("HttpService")
                        local placeId = game.PlaceId
                        local currentJobId = game.JobId

                        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                        local response = HttpService:JSONDecode(game:HttpGet(url))

                        local targetServer = nil
                        if response and response.data then
                            for _, server in ipairs(response.data) do
                                if server.id ~= currentJobId and server.playing > 0 then
                                    targetServer = server.id
                                    break
                                end
                            end
                        end

                        if targetServer then
                            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
                        else
                            TeleportService:Teleport(placeId, LocalPlayer)
                        end
                    end)
                end
            end)
        else
            if ServerHopConfig.serverHopThread then
                task.cancel(ServerHopConfig.serverHopThread)
                ServerHopConfig.serverHopThread = nil
            end
        end
    end
})

    Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        PlayerDropdown:SetValues(getPlayerList())
    end)

    Players.PlayerRemoving:Connect(function(player)
        if selectedFarmPlayer == player then
            selectedFarmPlayer = nil
        end
        PlayerDropdown:SetValues(getPlayerList())
    end)
end
 -- ========== COSMETICS/EMOTES TAB ==========
local EMOTES = {
    --Normal = {"Griddy", "Fright Funk", "Aurora Miracle", "Blizzard", "Candy Cane Duel", "Candy Cane Walk", "Cold World", "Gift Exchange", "Ice Skating", "Snow Angels", "Snowball Barrage", "Snowball Juggle", "Snowball Throw", "Snowman", "Carry", "Sleddies", "Cocoa Cheers", "Ice Trick", "Nutcracker March", "Popcorn", "Gravedigger", "Death Day", "Jingle Bell Shake", "Cold World", "Mic Drop", "Spit", "T-Pose", "Drag", "Yawn", "Facepalm", "Falling Asleep", "Sleepy", "Calculated", "Rambunctious", "Sobbing", "Soccer Stretch", "Shadow Boxing", "Floss", "Relentless Laughing", "Phone Call", "Rock Paper Scissors", "One-Armed Pickup", "Stay Down", "Push-Ups", "Take the L", "Fancy Feet", "Hakari Dance", "Taco Time", "Think", "Cutthroat", "Shoulder Brush", "Heartfelt Salute", "Boogie Down", "Nerd", "Npt Like Us", "Paparazzi", "Frolic", "Sea Rain", "Kodo Pose", "BOO!", "Eating Ramen", "Come At Me", "Sweet Death", "Poppin Bottles", "Mog", "Lifting", "Star of Hope", "Santa Sack", "Domain Expansion"},
    
    Kill = {"None", "Vampire", "Impostor", "Rudolph's Revenge", "ACME", "Avra Kadoovra", "Barbarian", "Blood Sugar", "Frostbound Prison", "Curb Stomp", "Frost Breath", "Split Trap", "Possesion", "Gingerbread", "Heart Rip", "Figure Skater", "Baldie`s Demise", "Laser Eyes", "Mistletoe", "Naughtly List", "Neck Snap", "Orthax", "Surprise", "Goblin Bomb", "Selfie", "Serious Sneeze", "Smite", "Snowball Cannon", "Snowflakes", "Sore Winner", "Spine Breaker", "Think Mark", "Tree Topper Slice", "Werewolf", "Frozen Impalement", "Sick Burn", "Tinsel Strangie", "Wrap It Up", "Cauldron", "Bee", "Pollen Overload", "Glacial Burial"}
}

local COSMETICS = {
    Accessories = {"None", "Chunin Exam Vest", "Halo", "Frozen Gloves", "Devil's Eye", "Devil's Tail", "Devil's Wings", "Flower Wings", "Frozen Crown", "Frozen Tail", "Frozen Wings", "Garland Scarf", "Hades Helmet", "Holiday Scarf", "Krampus Hat", "Red Kagune", "Rudolph Antlers", "Snowflake Wings", "Sorting Hat", "VIP Crown"},
    
    Auras = {"None", "Butterflies", "Northern Lights", "Ki", "Blue Lightning", "Green Lightning", "Purple Lightning", "Yellow Lightning"},
    
    Capes = {"None", "Ice Lord", "Viking", "Christmas Lights", "Dracula", "Krampus", "Krampus Supreme", "Santa", "VIP", "Webbed"}
}

local EmoteSlots = {
    [1] = {Type = "Emote", Name = "None"},
    [2] = {Type = "Emote", Name = "None"},
    [3] = {Type = "Emote", Name = "None"},
    [4] = {Type = "Emote", Name = "None"},
    [5] = {Type = "Emote", Name = "None"},
    [6] = {Type = "Emote", Name = "None"},
    [7] = {Type = "Emote", Name = "None"},
    [8] = {Type = "Emote", Name = "None"},
}

local SelectedKillEmote = "None"
local SelectedKillEmoteSlot = 1

local SelectedAccessory = "None"
local SelectedAura = "None"
local SelectedCape = "None"

local function GetCurrentEmoteData()
    local data = {}
    
    for i = 1, 4 do
        table.insert(data, {EmoteSlots[i].Type, EmoteSlots[i].Name})
    end

    for i = 1, 4 do
        table.insert(data, true)
    end
    
    return data
end

local function ApplyEmotes()
    local emoteData = GetCurrentEmoteData()
    local jsonString = HttpService:JSONEncode(emoteData)
    LocalPlayer.Data.EmoteEquipped.Value = jsonString
    
end

local function ApplyKillEmote()
    local data = {}
    
    for i = 1, 4 do
        table.insert(data, {"Emote", "None"})
    end
    
    for i = 1, 4 do
        table.insert(data, true)
    end
    
    data[SelectedKillEmoteSlot] = {"KillEmote", SelectedKillEmote}
    
    local jsonString = HttpService:JSONEncode(data)
    LocalPlayer.Data.EmoteEquipped.Value = jsonString
    
end

local function ApplyCosmetic(cosmeticType)
    local valueName = cosmeticType .. "Equipped"
    local selectedItem = nil
    
    if cosmeticType == "Accessories" then
        selectedItem = SelectedAccessory
    elseif cosmeticType == "Auras" then
        selectedItem = SelectedAura
    elseif cosmeticType == "Capes" then
        selectedItem = SelectedCape
    end
    
    if selectedItem == "None" then
        selectedItem = nil
    end
    
    local dataToSave = selectedItem and {selectedItem} or {}
    local jsonString = HttpService:JSONEncode(dataToSave)
    
    local dataFolder = LocalPlayer:WaitForChild("Data")
    local valueObject = dataFolder:FindFirstChild(valueName)
    
    if not valueObject then
        valueObject = Instance.new("StringValue")
        valueObject.Name = valueName
        valueObject.Parent = dataFolder
    end
    
    valueObject.Value = jsonString
    
end

local function InitializePasses()
    local passesFolder = LocalPlayer:WaitForChild("Passes", 5)
    if passesFolder then
        for _, passValue in passesFolder:GetChildren() do
            if passValue:IsA("BoolValue") then
                passValue.Value = true
            elseif passValue:IsA("NumberValue") then
                passValue.Value = 1
            end
        end
    end
end


Tabs.Cosmetics:AddSection("Kill Emotes")

local KillEmoteDropdown = Tabs.Cosmetics:AddDropdown("KillEmoteDropdown", {
    Title = "Select Kill Emote",
    Values = EMOTES.Kill,
    Multi = false,
    Default = 1,
})

KillEmoteDropdown:OnChanged(function(Value)
    SelectedKillEmote = Value
end)

local KillEmoteSlotDropdown = Tabs.Cosmetics:AddDropdown("KillEmoteSlotDropdown", {
    Title = "Kill Emote Slot",
    Values = {"Slot 1", "Slot 2", "Slot 3", "Slot 4"},
    Multi = false,
    Default = 1,
})

KillEmoteSlotDropdown:OnChanged(function(Value)
    SelectedKillEmoteSlot = tonumber(Value:match("%d+"))
end)

Tabs.Cosmetics:AddButton({
    Title = "Apply Kill Emote",
    Callback = function()
        ApplyKillEmote()
    end
})

Tabs.Cosmetics:AddSection("Spam Kill Emote")

local EmotesConfg = {
    selectedKillEmoteForSpam = "None",
    isSpammingRandomKillEmote = false,
    isSpammingSelectedKillEmote = false,
    randomSpamDelay = 0.05,
    selectedSpamDelay = 0.05,
    lastRandomSpam = 0,
    lastSelectedSpam = 0,
    lastEmoteUse = 0,
    emoteCooldown = 0.05
}

local Core = require(ReplicatedStorage:WaitForChild("Core"))

local function useKillEmote(emoteName)
    if not emoteName or emoteName == "None" or tick() - EmotesConfg.lastEmoteUse < EmotesConfg.emoteCooldown then 
        return 
    end
    EmotesConfg.lastEmoteUse = tick()

    local emoteModule = ReplicatedStorage.Cosmetics.KillEmote:FindFirstChild(emoteName)
    if not emoteModule then return end

    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local closestTarget = nil
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetRoot and targetHumanoid then
                local distance = (Character.HumanoidRootPart.Position - targetRoot.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestTarget = player.Character
                end
            end
        end
    end

    local charactersFolder = workspace:FindFirstChild("Characters")
    if charactersFolder then
        local npcsFolder = charactersFolder:FindFirstChild("NPCs")
        if npcsFolder then
            for _, npc in pairs(npcsFolder:GetChildren()) do
                if npc:IsA("Model") then
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                    local npcHumanoid = npc:FindFirstChild("Humanoid")
                    
                    if npcRoot and npcHumanoid then
                        local distance = (Character.HumanoidRootPart.Position - npcRoot.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestTarget = npc
                        end
                    end
                end
            end
        end
    end

    if closestTarget then
        task.spawn(function()
            _G.KillEmote = true
            pcall(function()
                pcall(function() setthreadidentity(2) end)
                pcall(function() setthreadcontext(2) end)
                Core.Get("Combat", "Ability").Activate(emoteModule, closestTarget)
            end)
            _G.KillEmote = false
        end)
    end
end

local function useRandomKillEmote()
    local killEmotesList = {}
    local killEmoteFolder = ReplicatedStorage.Cosmetics:FindFirstChild("KillEmote")
    
    if killEmoteFolder then
        for _, emote in pairs(killEmoteFolder:GetChildren()) do
            table.insert(killEmotesList, emote.Name)
        end
    end
    
    if #killEmotesList > 0 then
        local randomEmote = killEmotesList[math.random(1, #killEmotesList)]
        useKillEmote(randomEmote)
    end
end

local killEmotesList = {}
local killEmoteFolder = ReplicatedStorage.Cosmetics:FindFirstChild("KillEmote")

if killEmoteFolder then
    for _, emote in pairs(killEmoteFolder:GetChildren()) do
        table.insert(killEmotesList, emote.Name)
    end
end

table.insert(killEmotesList, 1, "None")

local KillEmoteDropdown = Tabs.Cosmetics:AddDropdown("KillEmoteSpamDropdown", {
    Title = "Select Kill Emote",
    Values = killEmotesList,
    Multi = false,
    Default = 1,
})

KillEmoteDropdown:OnChanged(function(Value)
    EmotesConfg.selectedKillEmoteForSpam = Value
end)

local SpamRandomToggle = Tabs.Cosmetics:AddToggle("SpamRandomKillEmote", {
    Title = "Spam Random Kill Emotes",
    Default = false,
    Callback = function(Value)
        EmotesConfg.isSpammingRandomKillEmote = Value
    end
})

local SpamSelectedToggle = Tabs.Cosmetics:AddToggle("SpamSelectedKillEmote", {
    Title = "Spam Selected Kill Emote",
    Default = false,
    Callback = function(Value)
        EmotesConfg.isSpammingSelectedKillEmote = Value
    end
})

Tabs.Cosmetics:AddKeybind("ToggleRandomSpamBind", {
    Title = "Toggle Random Spam Keybind",
    Mode = "Toggle",
    Default = "",
    Callback = function(Value)
        SpamRandomToggle:SetValue(Value)
    end
})

Tabs.Cosmetics:AddKeybind("ToggleSelectedSpamBind", {
    Title = "Toggle Selected Spam Keybind",
    Mode = "Toggle",
    Default = "",
    Callback = function(Value)
        SpamSelectedToggle:SetValue(Value)
    end
})

local RandomDelayInput
local LockRandom = false

RandomDelayInput = Tabs.Cosmetics:AddInput("RandomSpamDelay", {
    Title = "Random Spam Delay (ms)",
    Default = "50",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local delay = tonumber(Value) or 50
        EmotesConfg.randomSpamDelay = delay / 1000
    end
})

RandomDelayInput:OnChanged(function()
    if LockRandom then return end

    local v = tonumber(RandomDelayInput.Value)
    if not v then return end

    if v > 1000 then
        LockRandom = true
        RandomDelayInput:SetValue("1000")
        EmotesConfg.randomSpamDelay = 1
        LockRandom = false
    elseif v < 1 then
        LockRandom = true
        RandomDelayInput:SetValue("1")
        EmotesConfg.randomSpamDelay = 0.001
        LockRandom = false
    else
        EmotesConfg.randomSpamDelay = v / 1000
    end
end)

local SelectedDelayInput
local LockSelected = false

SelectedDelayInput = Tabs.Cosmetics:AddInput("SelectedSpamDelay", {
    Title = "Selected Spam Delay (ms)",
    Default = "50",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local delay = tonumber(Value) or 50
        EmotesConfg.selectedSpamDelay = delay / 1000
    end
})

SelectedDelayInput:OnChanged(function()
    if LockSelected then return end

    local v = tonumber(SelectedDelayInput.Value)
    if not v then return end

    if v > 1000 then
        LockSelected = true
        SelectedDelayInput:SetValue("1000")
        EmotesConfg.selectedSpamDelay = 1
        LockSelected = false
    elseif v < 1 then
        LockSelected = true
        SelectedDelayInput:SetValue("1")
        EmotesConfg.selectedSpamDelay = 0.001
        LockSelected = false
    else
        EmotesConfg.selectedSpamDelay = v / 1000
    end
end)

RunService.Heartbeat:Connect(function()
    local now = tick()

    if EmotesConfg.isSpammingRandomKillEmote and now - EmotesConfg.lastRandomSpam >= EmotesConfg.randomSpamDelay then
        useRandomKillEmote()
        EmotesConfg.lastRandomSpam = now
    end

    if EmotesConfg.isSpammingSelectedKillEmote and EmotesConfg.selectedKillEmoteForSpam ~= "None" and now - EmotesConfg.lastSelectedSpam >= EmotesConfg.selectedSpamDelay then
        useKillEmote(EmotesConfg.selectedKillEmoteForSpam)
        EmotesConfg.lastSelectedSpam = now
    end
end)


Tabs.Cosmetics:AddSection("Cosmetics")

local AccessoryDropdown = Tabs.Cosmetics:AddDropdown("AccessoryDropdown", {
    Title = "Accessories",
    Values = COSMETICS.Accessories,
    Multi = false,
    Default = 1,
})

AccessoryDropdown:OnChanged(function(Value)
    SelectedAccessory = Value
end)

Tabs.Cosmetics:AddButton({
    Title = "Apply Accessory",
    Callback = function()
        ApplyCosmetic("Accessories")
    end
})

local AuraDropdown = Tabs.Cosmetics:AddDropdown("AuraDropdown", {
    Title = "Auras",
    Values = COSMETICS.Auras,
    Multi = false,
    Default = 1,
})

AuraDropdown:OnChanged(function(Value)
    SelectedAura = Value
end)

Tabs.Cosmetics:AddButton({
    Title = "Apply Aura",
    Callback = function()
        ApplyCosmetic("Auras")
    end
})

local CapeDropdown = Tabs.Cosmetics:AddDropdown("CapeDropdown", {
    Title = "Capes",
    Values = COSMETICS.Capes,
    Multi = false,
    Default = 1,
})

CapeDropdown:OnChanged(function(Value)
    SelectedCape = Value
end)

Tabs.Cosmetics:AddButton({
    Title = "Apply Cape",
    Callback = function()
        ApplyCosmetic("Capes")
    end
})
-- ========== MISC TAB ==========
local RespawnAtDeathEnabled = false
local deathPosition = nil

local function saveDeathPosition()
    if not RespawnAtDeathEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        deathPosition = hrp.CFrame
    end
end

local function teleportToDeathPosition()
    if not RespawnAtDeathEnabled or not deathPosition then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:WaitForChild("HumanoidRootPart")
    task.wait(0.2)
    hrp.CFrame = deathPosition
end

local function monitorDeathForRespawn(humanoid)
    if not humanoid then return end
    
    humanoid:GetAttributeChangedSignal("Health"):Connect(function()
        if not RespawnAtDeathEnabled then return end
        
        local health = humanoid:GetAttribute("Health")
        if health and health <= 0 then
            saveDeathPosition()
        end
    end)
end

local function connectCharacterForRespawn(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        monitorDeathForRespawn(humanoid)
    end
    
    if RespawnAtDeathEnabled and deathPosition then
        teleportToDeathPosition()
    end
end

if LocalPlayer.Character then
    connectCharacterForRespawn(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(connectCharacterForRespawn)

local RespawnAtDeathToggle = Tabs.Misc:AddToggle("RespawnAtDeathToggle", {
    Title = "Respawn at Death Position",
    Default = false,
    Callback = function(Value)
        RespawnAtDeathEnabled = Value
        if not Value then
            deathPosition = nil
        end
    end
})

local AutoResetToggle = Tabs.Misc:AddToggle("AutoResetToggle", {
    Title = "Fast spawn",
    Default = false,
    Callback = function(Value)
        AutoResetEnabled = Value
    end
})

local InvisibleConfig = {
    isInvisible = false,
    platform = nil,
    mirrorModel = nil,
    mirrorPart = nil,
    originalCameraSubject = nil,
    movementConnection = nil,
    lastJumpHeight = 0
}

local function createPlatform_Invisible()
    local groundUnion = workspace.Map.Structural.Ground.Union
    local character = LocalPlayer.Character
    if not groundUnion or not character then return nil end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local part = Instance.new("Part")
    part.Name = "InvisibilityPlatform"
    part.Size = Vector3.new(2000, 1, 2000)
    part.Position = Vector3.new(hrp.Position.X, groundUnion.Position.Y - 20, hrp.Position.Z)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.5
    part.BrickColor = BrickColor.new("Bright blue")
    part.Parent = workspace

    return part
end

local function createMirrorClone()
    local character = LocalPlayer.Character
    if not character then return nil end

    character.Archivable = true
    local clone = character:Clone()
    clone.Name = "MirrorClone"
    clone.Parent = workspace

    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end

    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            d.Massless = true
            d.Anchored = false
        end
    end

    local hrp = clone:FindFirstChild("HumanoidRootPart")
    if not hrp then
        clone:Destroy()
        return nil
    end

    clone.PrimaryPart = hrp

    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = true
        hum.AutoRotate = false
    end

    local srcHRP = character:FindFirstChild("HumanoidRootPart")
    if srcHRP then
        clone:PivotTo(srcHRP.CFrame)
    end

    InvisibleConfig.mirrorModel = clone
    return hrp
end

local function updateMirrorPosition(dt)
    local character = LocalPlayer.Character
    if not character or not InvisibleConfig.mirrorModel or not InvisibleConfig.mirrorModel.PrimaryPart then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local groundY = workspace.Map.Structural.Ground.Union.Position.Y
    local platformTopY = InvisibleConfig.platform and (InvisibleConfig.platform.Position.Y + InvisibleConfig.platform.Size.Y * 0.5) or groundY

    local targetJumpHeight = math.max(0, (hrp.Position.Y - platformTopY) * 0.5)
    targetJumpHeight = math.min(targetJumpHeight, 20)

    local smoothing = math.clamp((dt or 1 / 60) * 10, 0, 1)
    InvisibleConfig.lastJumpHeight = InvisibleConfig.lastJumpHeight + (targetJumpHeight - InvisibleConfig.lastJumpHeight) * smoothing

    local newPos = Vector3.new(hrp.Position.X, groundY + 3 + InvisibleConfig.lastJumpHeight, hrp.Position.Z)

    local look = hrp.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)

    if flatLook.Magnitude > 0 then
        InvisibleConfig.mirrorModel:PivotTo(CFrame.new(newPos, newPos + flatLook))
    else
        InvisibleConfig.mirrorModel:PivotTo(CFrame.new(newPos))
    end
end

local function enableInvisible()
    if InvisibleConfig.isInvisible then return end
    local character = LocalPlayer.Character
    if not character then return end

    InvisibleConfig.platform = createPlatform_Invisible()
    if not InvisibleConfig.platform then return end

    InvisibleConfig.mirrorPart = createMirrorClone()
    if not InvisibleConfig.mirrorPart then
        InvisibleConfig.platform:Destroy()
        InvisibleConfig.platform = nil
        return
    end

    InvisibleConfig.originalCameraSubject = workspace.CurrentCamera.CameraSubject

    for _, p in ipairs(character:GetChildren()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        local hip = hum.HipHeight
        local hrpHalf = hrp.Size.Y * 0.5
        local platformTopY = InvisibleConfig.platform.Position.Y + InvisibleConfig.platform.Size.Y * 0.5

        require(LocalPlayer.PlayerScripts.Character.FullCustomReplication)
            .Override(character, CFrame.new(
                hrp.Position.X,
                platformTopY + hip + hrpHalf,
                hrp.Position.Z
            ))
    end

    local mirrorHum = InvisibleConfig.mirrorModel:FindFirstChildOfClass("Humanoid")
    workspace.CurrentCamera.CameraSubject = mirrorHum or InvisibleConfig.mirrorPart

    InvisibleConfig.movementConnection = RunService.Heartbeat:Connect(updateMirrorPosition)

    InvisibleConfig.isInvisible = true
end

local function disableInvisible()
    if not InvisibleConfig.isInvisible then return end
    local character = LocalPlayer.Character

    if InvisibleConfig.movementConnection then 
        InvisibleConfig.movementConnection:Disconnect() 
        InvisibleConfig.movementConnection = nil
    end

    if character and InvisibleConfig.mirrorModel and InvisibleConfig.mirrorModel.PrimaryPart then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum then
            for _, p in ipairs(character:GetChildren()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end

            local hip = hum.HipHeight
            local hrpHalf = hrp.Size.Y * 0.5
            local groundY = workspace.Map.Structural.Ground.Union.Position.Y

            task.wait()

            require(LocalPlayer.PlayerScripts.Character.FullCustomReplication)
                .Override(character, CFrame.new(
                    InvisibleConfig.mirrorModel.PrimaryPart.Position.X,
                    groundY + hip + hrpHalf,
                    InvisibleConfig.mirrorModel.PrimaryPart.Position.Z
                ))

            task.wait()
            
            workspace.CurrentCamera.CameraSubject =
                character:FindFirstChildOfClass("Humanoid") or hrp
        end
    else
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            for _, p in ipairs(character:GetChildren()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
            workspace.CurrentCamera.CameraSubject =
                character:FindFirstChildOfClass("Humanoid") or hrp
        end
    end

    if InvisibleConfig.platform then InvisibleConfig.platform:Destroy() end
    if InvisibleConfig.mirrorModel then InvisibleConfig.mirrorModel:Destroy() end

    InvisibleConfig.platform = nil
    InvisibleConfig.mirrorModel = nil
    InvisibleConfig.mirrorPart = nil
    InvisibleConfig.lastJumpHeight = 0
    InvisibleConfig.isInvisible = false
end

local InvisibilityToggle = Tabs.Misc:AddToggle("InvisibilityToggle", {
    Title = "Invisibility",
    Description = "Enable hitbox to take damage",
    Default = false,
    Callback = function(Value)
        task.spawn(function()
            if Value then
                enableInvisible()
            else
                disableInvisible()
            end
        end)
    end
})
do
local RagdollESPEnabled = false
local EvasiveESPEnabled = false
local ragdollESPData = {}
local evasiveESPData = {}
local evasiveCooldowns = {}
local evasiveStates = {}
local ragdollRenderConnection = nil
local evasiveRenderConnection = nil
local ragdollPlayerAddedConnection = nil
local ragdollPlayerRemovingConnection = nil
local evasivePlayerAddedConnection = nil
local evasivePlayerRemovingConnection = nil

local CONFIG_RAGDOLL = {
    TextSize = 15,
    TextFont = 3,
    TextOutline = true,
    
    ColorHigh = Color3.fromRGB(0, 255, 100),
    ColorMid = Color3.fromRGB(255, 200, 0),
    ColorLow = Color3.fromRGB(255, 50, 50),
    OutlineColor = Color3.new(0, 0, 0),
    
    OffsetY = 3.5,
}

local CONFIG_EVASIVE = {
    TextSize = 20,
    Font = 3,
    Outline = true,
    
    ColorReady = Color3.fromRGB(100, 200, 255),
    ColorCooldown = Color3.fromRGB(255, 100, 255),
    OutlineColor = Color3.new(0, 0, 0),
    
    OffsetY = 5.5,
}

local EVASIVE_BASE = 25

local RagdollModule
local DashModule

task.spawn(function()
    Setidentity()
    
    local success, result = pcall(function()
        return require(LocalPlayer.PlayerScripts.Combat.Ragdoll)
    end)
    
    if success and result then
        RagdollModule = result
    end
end)

task.spawn(function()
    Setidentity()
    
    local success, result = pcall(function()
        return require(LocalPlayer.PlayerScripts.Combat.Dash)
    end)
    
    if success and result then
        DashModule = result
    end
end)

local function getColorFromProgress(progress)
    if progress > 0.5 then
        local t = (progress - 0.5) * 2
        return CONFIG_RAGDOLL.ColorMid:Lerp(CONFIG_RAGDOLL.ColorHigh, t)
    else
        local t = progress * 2
        return CONFIG_RAGDOLL.ColorLow:Lerp(CONFIG_RAGDOLL.ColorMid, t)
    end
end

local function getMultiplier()
    local settings = ReplicatedStorage:FindFirstChild("Settings")
    if not settings then return 1 end
    local cds = settings:FindFirstChild("Cooldowns")
    if not cds then return 1 end
    local v = cds:FindFirstChild("Evasive") or cds:FindFirstChild("Ragdoll")
    return (v and v.Value / 100) or 1
end

local function createRagdollESP(player)
    if player == LocalPlayer then return end
    
    local text = Drawing.new("Text")
    text.Center = true
    text.Size = CONFIG_RAGDOLL.TextSize
    text.Outline = CONFIG_RAGDOLL.TextOutline
    text.OutlineColor = CONFIG_RAGDOLL.OutlineColor
    text.Font = CONFIG_RAGDOLL.TextFont
    text.Visible = false
    
    ragdollESPData[player] = { Text = text }
end

local function removeRagdollESP(player)
    local data = ragdollESPData[player]
    if data then
        data.Text:Remove()
        ragdollESPData[player] = nil
    end
end

local function startRagdollESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createRagdollESP(player)
        end
    end
    
    ragdollPlayerAddedConnection = Players.PlayerAdded:Connect(createRagdollESP)
    ragdollPlayerRemovingConnection = Players.PlayerRemoving:Connect(removeRagdollESP)
    
    ragdollRenderConnection = RunService.RenderStepped:Connect(function()
        if not RagdollModule then return end
        
        for player, data in pairs(ragdollESPData) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local ragdollStart = char:GetAttribute("Ragdoll")
                
                if typeof(ragdollStart) == "number" and RagdollModule.EndClocks[char] then
                    local endTime = RagdollModule.EndClocks[char]
                    local remaining = math.max(endTime - os.clock(), 0)
                    local totalTime = endTime - RagdollModule.StartClocks[char]
                    local progress = remaining / totalTime
                    
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
                        hrp.Position + Vector3.new(0, CONFIG_RAGDOLL.OffsetY, 0)
                    )
                    
                    if onScreen and remaining > 0 then
                        local color = getColorFromProgress(progress)
                        
                        data.Text.Text = string.format("%.1fs", remaining)
                        data.Text.Color = color
                        data.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
                        data.Text.Visible = true
                    else
                        data.Text.Visible = false
                    end
                else
                    data.Text.Visible = false
                end
            else
                data.Text.Visible = false
            end
        end
    end)
end

local function stopRagdollESP()
    if ragdollRenderConnection then
        ragdollRenderConnection:Disconnect()
        ragdollRenderConnection = nil
    end
    
    if ragdollPlayerAddedConnection then
        ragdollPlayerAddedConnection:Disconnect()
        ragdollPlayerAddedConnection = nil
    end
    
    if ragdollPlayerRemovingConnection then
        ragdollPlayerRemovingConnection:Disconnect()
        ragdollPlayerRemovingConnection = nil
    end
    
    for player, _ in pairs(ragdollESPData) do
        removeRagdollESP(player)
    end
end

local function startEvasiveCooldown(player)
    evasiveCooldowns[player] = {
        start = os.clock(),
        duration = EVASIVE_BASE * getMultiplier()
    }
end

local function getEvasiveRemaining(player)
    local data = evasiveCooldowns[player]
    if not data then return 0 end
    
    local t = data.duration - (os.clock() - data.start)
    if t <= 0 then
        evasiveCooldowns[player] = nil
        return 0
    end
    return t
end

local function monitorEvasivePlayer(player)
    evasiveStates[player] = {
        wasRagdoll = false,
        wasDash = false
    }
    
    local function onCharacter(char)
        local function update()
            local ragdoll = char:GetAttribute("Ragdoll")
            local dash = char:GetAttribute("Dash")
            
            local s = evasiveStates[player]
            if not s then return end
            
            if s.wasRagdoll and dash and not s.wasDash then
                startEvasiveCooldown(player)
            end
            
            s.wasRagdoll = ragdoll
            s.wasDash = dash
        end
        
        char:GetAttributeChangedSignal("Ragdoll"):Connect(update)
        char:GetAttributeChangedSignal("Dash"):Connect(update)
        update()
    end
    
    if player.Character then
        onCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacter)
end

local function createEvasiveESP(player)
    local text = Drawing.new("Text")
    text.Center = true
    text.Size = CONFIG_EVASIVE.TextSize
    text.Font = CONFIG_EVASIVE.Font
    text.Outline = CONFIG_EVASIVE.Outline
    text.OutlineColor = CONFIG_EVASIVE.OutlineColor
    text.Visible = false
    
    evasiveESPData[player] = { Text = text }
end

local function removeEvasiveESP(player)
    local d = evasiveESPData[player]
    if d then
        d.Text:Remove()
        evasiveESPData[player] = nil
    end
    evasiveCooldowns[player] = nil
    evasiveStates[player] = nil
end

local function startEvasiveESP()
    for _, p in pairs(Players:GetPlayers()) do
        monitorEvasivePlayer(p)
        createEvasiveESP(p)
    end
    
    evasivePlayerAddedConnection = Players.PlayerAdded:Connect(function(p)
        monitorEvasivePlayer(p)
        createEvasiveESP(p)
    end)
    
    evasivePlayerRemovingConnection = Players.PlayerRemoving:Connect(removeEvasiveESP)
    
    evasiveRenderConnection = RunService.RenderStepped:Connect(function()
        for player, ui in pairs(evasiveESPData) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if not hrp then
                ui.Text.Visible = false
                continue
            end
            
            local remaining = getEvasiveRemaining(player)
            
            if player == LocalPlayer then
                local text = remaining > 0 
                    and string.format("Evasive: %.1fs", remaining) 
                    or "Evasive: READY"
                
                local color = remaining > 0 
                    and CONFIG_EVASIVE.ColorCooldown 
                    or CONFIG_EVASIVE.ColorReady
                
                ui.Text.Text = text
                ui.Text.Color = color
                ui.Text.Position = Vector2.new(100, 100)
                ui.Text.Visible = true
            else
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
                    hrp.Position + Vector3.new(0, CONFIG_EVASIVE.OffsetY, 0)
                )
                
                if not onScreen then
                    ui.Text.Visible = false
                    continue
                end
                
                local text = remaining > 0 
                    and string.format("%.1fs", remaining) 
                    or "EVASIVE: READY"
                
                local color = remaining > 0 
                    and CONFIG_EVASIVE.ColorCooldown 
                    or CONFIG_EVASIVE.ColorReady
                
                ui.Text.Text = text
                ui.Text.Color = color
                ui.Text.Position = Vector2.new(pos.X, pos.Y)
                ui.Text.Visible = true
            end
        end
    end)
end

local function stopEvasiveESP()
    if evasiveRenderConnection then
        evasiveRenderConnection:Disconnect()
        evasiveRenderConnection = nil
    end
    
    if evasivePlayerAddedConnection then
        evasivePlayerAddedConnection:Disconnect()
        evasivePlayerAddedConnection = nil
    end
    
    if evasivePlayerRemovingConnection then
        evasivePlayerRemovingConnection:Disconnect()
        evasivePlayerRemovingConnection = nil
    end
    
    for player, _ in pairs(evasiveESPData) do
        removeEvasiveESP(player)
    end
end

Tabs.Misc:AddSection("ESP Settings")

local RagdollESPToggle = Tabs.Misc:AddToggle("RagdollESPToggle", {
    Title = "Ragdoll Timer ESP",
    Default = false,
    Callback = function(Value)
        RagdollESPEnabled = Value
        
        if Value then
            startRagdollESP()
        else
            stopRagdollESP()
        end
    end
})
local EvasiveESPToggle = Tabs.Misc:AddToggle("EvasiveESPToggle", {
    Title = "Evasive Cooldown ESP",
    Default = false,
    Callback = function(Value)
        EvasiveESPEnabled = Value
        
        if Value then
            startEvasiveESP()
        else
            stopEvasiveESP()
        end
    end
})

end

local QueueRegistered = false

local AutoLoadToggle = Tabs.Settings:AddToggle("", {
    Title = "Auto Load Script",
    Default = false,
    Callback = function(state)
        if state and not QueueRegistered then
            queue_on_teleport(
                'loadstring(game:HttpGet("https://loader-navy.vercel.app/api/raw/4359abeaca6aba76aa6cf435ddff8423"))()'
            )
            QueueRegistered = true
        elseif not state then
            QueueRegistered = false
        end
    end
})

task.spawn(function()

    local folder = "EltonsHub/Saves/Ultimate Battlegrounds1/settings"
    local file

    for _, v in pairs(listfiles(folder)) do
        if string.find(v, "autoload.txt") then
            file = v
            break
        end
    end

    if not file then return end

    local callback = Instance.new("BindableFunction")

    callback.OnInvoke = function(answer)
        if answer == "Yes" and isfile(file) then
            delfile(file)
        end
    end

    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Confirm",
            Text = "Delete autoload config?",
            Duration = 8,
            Callback = callback,
            Button1 = "Yes",
            Button2 = "No"
        })
    end)
end)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("EltonsHub/Ultimate Battlegrounds1")
SaveManager:SetFolder("EltonsHub/Saves/Ultimate Battlegrounds1")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
