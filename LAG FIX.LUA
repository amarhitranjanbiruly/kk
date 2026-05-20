-- Directly executable anti-lag / low graphics script
-- Copy and execute in your Roblox executor

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local Terrain = workspace:FindFirstChildWhichIsA("Terrain")

if Terrain then
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
end

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.FogStart = 9e9

settings().Rendering.QualityLevel = 1

for _, v in pairs(game:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CastShadow = false
		v.Material = "Plastic"
		v.Reflectance = 0
		v.BackSurface = "SmoothNoOutlines"
		v.BottomSurface = "SmoothNoOutlines"
		v.FrontSurface = "SmoothNoOutlines"
		v.LeftSurface = "SmoothNoOutlines"
		v.RightSurface = "SmoothNoOutlines"
		v.TopSurface = "SmoothNoOutlines"
	elseif v:IsA("Decal") then
		v.Transparency = 1
		v.Texture = ""
	elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
		v.Lifetime = NumberRange.new(0)
	end
end

for _, v in pairs(Lighting:GetDescendants()) do
	if v:IsA("PostEffect") then
		v.Enabled = false
	end
end

workspace.DescendantAdded:Connect(function(child)
	task.spawn(function()
		if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
			RunService.Heartbeat:Wait()
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.CastShadow = false
		end
	end)
end)

print("Anti-lag / low graphics mode activated")
