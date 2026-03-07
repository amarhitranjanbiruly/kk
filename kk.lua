local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Break in 2 Script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Give items and more :D",
   LoadingSubtitle = "by Ar-xploits",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})
local Main = Window:CreateTab("Main", 4483362458) -- Title, Image
local Character = Window:CreateTab("Player", 4483362458) -- Title, Image
local Section1 = Main:CreateSection(" Give Items (Op)")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local itemList = {
   "Bat", "Pitchfork", "Hammer", "Wrench", "Broom", "Armor2",
   "MedKit", "Key", "GoldKey", "Louise", "Lollipop", "Chips",
   "GoldenApple", "Pizza", "GoldPizza", "RainbowPizza", "RainbowPizzaBox",
   "Book", "Cookie", "Apple", "BloxyCola", "Bottle", "Ladder", "Battery"
}

local vendingCategories = {
   Bat = "Weapons",
   Pitchfork = "Weapons",
   Hammer = "Weapons",
   Wrench = "Weapons",
   Broom = "Weapons",
   Armor2 = "Armor"
}

local Dropdown = Main:CreateDropdown({
   Name = "Give Item",
   Options = itemList,
   CurrentOption = {"Bat"},
   MultipleOptions = false,
   Flag = "Dropdown1",
   Callback = function(Options)
       local selected = Options[1] -- since MultipleOptions = false, we use the first item
       print("Selected:", selected)

       if vendingCategories[selected] then
           local args = {
               [1] = 3,
               [2] = selected,
               [3] = vendingCategories[selected],
               [4] = LocalPlayer.Name,
               [5] = 1
           }
           ReplicatedStorage:WaitForChild("Events"):WaitForChild("Vending"):FireServer(unpack(args))
       else
           local args = {
               [1] = selected
           }
           ReplicatedStorage:WaitForChild("Events"):WaitForChild("GiveTool"):FireServer(unpack(args))
       end
   end,
})
local Button = Main:CreateButton({
   Name = "Get ZA GOLDEN APPLE",
   Callback = function()
   local args = {
    [1] = "GoldenApple"
}

game:GetService("ReplicatedStorage").Events.GiveTool:FireServer(unpack(args))
   end,
})
local Section = Main:CreateSection("Stats Change")
local Button = Main:CreateButton({
   Name = "Get Speed stat",
   Callback = function()
   local args = {
    [1] = "Speed"
}

game:GetService("ReplicatedStorage").Events.RainbowWhatStat:FireServer(unpack(args))

   end,
})local Button = Main:CreateButton({
   Name = "Get Strength stat",
   Callback = function()
   local args = {
    [1] = "Strength"
}

game:GetService("ReplicatedStorage").Events.RainbowWhatStat:FireServer(unpack(args))

   end,
})
local movement= Character:CreateSection("Edit Player Movement and stuff")
local Slider = Character:CreateSlider({
   Name = "Movement speed",
   Range = {16, 300},
   Increment = 2,
   Suffix = "this is your speed",
   CurrentValue = 16,
   Flag = "Slider1", 
   Callback = function(Value)
   game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})
local Slider = Character:CreateSlider({
   Name = "JumpPower",
   Range = {10, 100},
   Increment = 1,
   Suffix = "this is your jump power",
   CurrentValue = 10,
   Flag = "Slider2", 
   Callback = function(Value)
   game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
   end,
})
local Button = Character:CreateButton({
   Name = "Full bright",
   Callback = function()
   local Light = game:GetService("Lighting")

function dofullbright()
Light.Ambient = Color3.new(1, 1, 1)
Light.ColorShift_Bottom = Color3.new(1, 1, 1)
Light.ColorShift_Top = Color3.new(1, 1, 1)
end

dofullbright()

Light.LightingChanged:Connect(dofullbright)-- credits to msexcel for the script
   end,
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Store the connection so we can turn it off later
local noclipConnection

local Toggle = Character:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        if Value then
            -- Turn ON noclip
            noclipConnection = RunService.Stepped:Connect(function()
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            -- Turn OFF noclip
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end,
})

