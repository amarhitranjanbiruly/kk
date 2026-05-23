local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")

local me = plrs.LocalPlayer

local gui_parent = game:GetService("CoreGui") or me:WaitForChild("PlayerGui")

local sg = Instance.new("ScreenGui")
sg.Name = "Farmer"
sg.ResetOnSpawn = false
sg.Parent = gui_parent

local frame = Instance.new("Frame")
frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
frame.BorderColor3 = Color3.fromRGB(80, 80, 100)
frame.BorderSizePixel = 2
frame.Position = UDim2.new(0.4, 0, 0.3, 0)
frame.Size = UDim2.new(0, 260, 0, 100)
frame.Parent = sg

local tbar = Instance.new("Frame")
tbar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
tbar.BorderColor3 = Color3.fromRGB(80, 80, 100)
tbar.BorderSizePixel = 1
tbar.Size = UDim2.new(1, 0, 0, 24)
tbar.Parent = frame

local tlabel = Instance.new("TextLabel")
tlabel.BackgroundTransparency = 1
tlabel.Position = UDim2.new(0, 6, 0, 0)
tlabel.Size = UDim2.new(1, -90, 1, 0)
tlabel.Font = Enum.Font.Code
tlabel.Text = "Be a streamer auto farmer"
tlabel.TextColor3 = Color3.fromRGB(220, 220, 240)
tlabel.TextSize = 12
tlabel.TextXAlignment = Enum.TextXAlignment.Left
tlabel.Parent = tbar

local cbtn = Instance.new("TextButton")
cbtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
cbtn.BorderSizePixel = 0
cbtn.Position = UDim2.new(1, -22, 0.5, -8)
cbtn.Size = UDim2.new(0, 16, 0, 16)
cbtn.Font = Enum.Font.Code
cbtn.Text = "X"
cbtn.TextColor3 = Color3.fromRGB(25, 25, 25)
cbtn.TextSize = 10
cbtn.Parent = tbar

local mbtn = Instance.new("TextButton")
mbtn.BackgroundColor3 = Color3.fromRGB(220, 190, 60)
mbtn.BorderSizePixel = 0
mbtn.Position = UDim2.new(1, -42, 0.5, -8)
mbtn.Size = UDim2.new(0, 16, 0, 16)
mbtn.Font = Enum.Font.Code
mbtn.Text = "_"
mbtn.TextColor3 = Color3.fromRGB(25, 25, 25)
mbtn.TextSize = 10
mbtn.Parent = tbar

local toggles = {}

local function mktoggle(txt, y, fn)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, y)
	row.Size = UDim2.new(1, -16, 0, 18)
	row.Parent = frame

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -22, 1, 0)
	lbl.Font = Enum.Font.Code
	lbl.Text = txt
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextButton")
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	box.BorderColor3 = Color3.fromRGB(80, 80, 100)
	box.BorderSizePixel = 1
	box.Position = UDim2.new(1, -16, 0.5, -7)
	box.Size = UDim2.new(0, 14, 0, 14)
	box.Font = Enum.Font.Code
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(200, 200, 255)
	box.TextSize = 10
	box.Parent = row

	local on = false
	box.MouseButton1Click:Connect(function()
		on = not on
		box.Text = on and "X" or ""
		box.BackgroundColor3 = on and Color3.fromRGB(70, 100, 70) or Color3.fromRGB(35, 35, 45)
		fn(on)
	end)
end

local sevt = rs:WaitForChild("StreamingEvent")
local gmbox = rs:WaitForChild("GetMailBox")

mktoggle("Auto Respond", 32, function(s)
	toggles.respond = s
	if not s then return end
	task.spawn(function()
		while toggles.respond do
			sevt:FireServer("Responded")
			task.wait(0.1)
		end
	end)
end)

mktoggle("Auto Collect", 54, function(s)
	toggles.collect = s
	if not s then return end
	task.spawn(function()
		while toggles.collect do
			gmbox:FireServer()
			task.wait(0.1)
		end
	end)
end)

cbtn.MouseButton1Click:Connect(function()
	sg:Destroy()
end)

local minimized = false
mbtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	for _, c in ipairs(frame:GetChildren()) do
		if c ~= tbar then
			c.Visible = not minimized
		end
	end
	frame.Size = minimized and UDim2.new(0, 260, 0, 24) or UDim2.new(0, 260, 0, 452)
end)

local drag, ds, sp
tbar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = true
		ds = i.Position
		sp = frame.Position
	end
end)
tbar.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = false
	end
end)
uis.InputChanged:Connect(function(i)
	if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - ds
		frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
	end
end)

local pp_connections = {}

local function patch_pp(pp)
	if pp:IsA("ProximityPrompt") then
		pp.HoldDuration = 0
	end
end

local function start_pp_patch()
	-- patch all existing prompts
	for _, v in ipairs(workspace:GetDescendants()) do
		patch_pp(v)
	end
	-- watch for new ones
	local c = workspace.DescendantAdded:Connect(function(v)
		patch_pp(v)
	end)
	table.insert(pp_connections, c)
end

local function stop_pp_patch()
	for _, c in ipairs(pp_connections) do
		c:Disconnect()
	end
	pp_connections = {}
end

mktoggle("Instant ProxPrompt", 76, function(s)
	toggles.proxprompt = s
	if s then
		start_pp_patch()
	else
		stop_pp_patch()
	end
end)
