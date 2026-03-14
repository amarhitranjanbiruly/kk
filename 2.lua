-- Load Rayfield UI Library
-- Load Rayfield UI Library
local Rayfield = (function()
        --[[

	Rayfield Interface Suite
	by Sirius

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
	warn('Initialising Rayfield')
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn(`Request for {url} timed out after {timeout} seconds`)
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn(`Failed to process {url}: {result}`)
	end
	return if success then result else nil
end

local requestsDisabled = true --getgenv and getgenv().DISABLE_RAYFIELD_REQUESTS
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		-- if needs be in order just make getSetting(name)
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
		-- buildwarnings
		-- rayfieldprompts

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.rayfieldOpen"] = "J"
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[`{category}.{name}`] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[`{category}.{name}`] ~= nil then
		return overriddenSettings[`{category}.{name}`]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

-- Environment Check
local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end -- No-op fallback
	}
end


-- The function below provides a safe alternative for calling error-prone functions
-- Especially useful for filesystem function (writefile, makefolder, etc.)
local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("Rayfield | Function failed with error: ", result)
			return false
		else
			return result
		end
	end
end

-- Ensures a folder exists by creating it if needed
local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		task.spawn(function()
			if callSafely(isfolder, RayfieldFolder) then
				if callSafely(isfile, RayfieldFolder..'/settings'..ConfigurationExtension) then
					file = callSafely(readfile, RayfieldFolder..'/settings'..ConfigurationExtension)
				end
			end

			-- for debug in studio
			if useStudio then
				file = [[
		{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
	]]
			end


			if file then
				local success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
				if success then
					file = decodedFile
				else
					file = {}
				end
			else
				file = {}
			end


			if not settingsCreated then 
				cachedSettings = file
				return
			end

			if file ~= {} then
				for categoryName, settingCategory in pairs(settingsTable) do
					if file[categoryName] then
						for settingName, setting in pairs(settingCategory) do
							if file[categoryName][settingName] then
								setting.Value = file[categoryName][settingName].Value
								setting.Element:Set(getSetting(categoryName, settingName))
							end
						end
					end
				end
			end
			settingsInitialized = true
		end)
	end)

	if not success then 
		if writefile then
			warn('Rayfield had an issue accessing configuration saving capability.')
		end
	end
end

if debugX then
	warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
	warn('Settings Loaded')
end

local analyticsLib
local sendReport = function(ev_n, sc_n) warn("Failed to load report function") end
if not requestsDisabled then
	if debugX then
		warn('Querying Settings for Reporter Information')
	end	
	analyticsLib = loadWithTimeout("https://analytics.sirius.menu/script")
	if not analyticsLib then
		warn("Failed to load analytics reporter")
		analyticsLib = nil
	elseif analyticsLib and type(analyticsLib.load) == "function" then
		analyticsLib:load()
	else
		warn("Analytics library loaded but missing load function")
		analyticsLib = nil
	end
	sendReport = function(ev_n, sc_n)
		if not (type(analyticsLib) == "table" and type(analyticsLib.isLoaded) == "function" and analyticsLib:isLoaded()) then
			warn("Analytics library not loaded")
			return
		end
		if useStudio then
			print('Sending Analytics')
		else
			if debugX then warn('Reporting Analytics') end
			analyticsLib:report(
				{
					["name"] = ev_n,
					["script"] = {["name"] = sc_n, ["version"] = Release}
				},
				{
					["version"] = InterfaceBuild
				}
			)
			if debugX then warn('Finished Report') end
		end
	end
	if cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
		sendReport("execution", "Rayfield")
	elseif not cachedSettings then
		sendReport("execution", "Rayfield")
	end
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
	prompt.create(
		'Be cautious when running scripts',
	    [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
		'Okay',
		'',
		function()

		end
	)
end

if debugX then
	warn('Moving on to continue initialisation')
end

local RayfieldLibrary = {
	Flags = {},
	Theme = {
		Default = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(25, 25, 25),
			Topbar = Color3.fromRGB(34, 34, 34),
			Shadow = Color3.fromRGB(20, 20, 20),

			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

			TabBackground = Color3.fromRGB(80, 80, 80),
			TabStroke = Color3.fromRGB(85, 85, 85),
			TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
			TabTextColor = Color3.fromRGB(240, 240, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

			ElementBackground = Color3.fromRGB(35, 35, 35),
			ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
			SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
			ElementStroke = Color3.fromRGB(50, 50, 50),
			SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

			SliderBackground = Color3.fromRGB(50, 138, 220),
			SliderProgress = Color3.fromRGB(50, 138, 220),
			SliderStroke = Color3.fromRGB(58, 163, 255),

			ToggleBackground = Color3.fromRGB(30, 30, 30),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(100, 100, 100),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

			DropdownSelected = Color3.fromRGB(40, 40, 40),
			DropdownUnselected = Color3.fromRGB(30, 30, 30),

			InputBackground = Color3.fromRGB(30, 30, 30),
			InputStroke = Color3.fromRGB(65, 65, 65),
			PlaceholderColor = Color3.fromRGB(178, 178, 178)
		},

		Ocean = {
			TextColor = Color3.fromRGB(230, 240, 240),

			Background = Color3.fromRGB(20, 30, 30),
			Topbar = Color3.fromRGB(25, 40, 40),
			Shadow = Color3.fromRGB(15, 20, 20),

			NotificationBackground = Color3.fromRGB(25, 35, 35),
			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

			TabBackground = Color3.fromRGB(40, 60, 60),
			TabStroke = Color3.fromRGB(50, 70, 70),
			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
			TabTextColor = Color3.fromRGB(210, 230, 230),
			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

			ElementBackground = Color3.fromRGB(30, 50, 50),
			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
			ElementStroke = Color3.fromRGB(45, 70, 70),
			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

			SliderBackground = Color3.fromRGB(0, 110, 110),
			SliderProgress = Color3.fromRGB(0, 140, 140),
			SliderStroke = Color3.fromRGB(0, 160, 160),

			ToggleBackground = Color3.fromRGB(30, 50, 50),
			ToggleEnabled = Color3.fromRGB(0, 130, 130),
			ToggleDisabled = Color3.fromRGB(70, 90, 90),
			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

			DropdownSelected = Color3.fromRGB(30, 60, 60),
			DropdownUnselected = Color3.fromRGB(25, 40, 40),

			InputBackground = Color3.fromRGB(30, 50, 50),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(140, 160, 160)
		},

		AmberGlow = {
			TextColor = Color3.fromRGB(255, 245, 230),

			Background = Color3.fromRGB(45, 30, 20),
			Topbar = Color3.fromRGB(55, 40, 25),
			Shadow = Color3.fromRGB(35, 25, 15),

			NotificationBackground = Color3.fromRGB(50, 35, 25),
			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

			TabBackground = Color3.fromRGB(75, 50, 35),
			TabStroke = Color3.fromRGB(90, 60, 45),
			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
			TabTextColor = Color3.fromRGB(250, 220, 200),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

			ElementBackground = Color3.fromRGB(60, 45, 35),
			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
			ElementStroke = Color3.fromRGB(85, 60, 45),
			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

			SliderBackground = Color3.fromRGB(220, 130, 60),
			SliderProgress = Color3.fromRGB(250, 150, 75),
			SliderStroke = Color3.fromRGB(255, 170, 85),

			ToggleBackground = Color3.fromRGB(55, 40, 30),
			ToggleEnabled = Color3.fromRGB(240, 130, 30),
			ToggleDisabled = Color3.fromRGB(90, 70, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

			DropdownSelected = Color3.fromRGB(70, 50, 40),
			DropdownUnselected = Color3.fromRGB(55, 40, 30),

			InputBackground = Color3.fromRGB(60, 45, 35),
			InputStroke = Color3.fromRGB(90, 65, 50),
			PlaceholderColor = Color3.fromRGB(190, 150, 130)
		},

		Light = {
			TextColor = Color3.fromRGB(40, 40, 40),

			Background = Color3.fromRGB(245, 245, 245),
			Topbar = Color3.fromRGB(230, 230, 230),
			Shadow = Color3.fromRGB(200, 200, 200),

			NotificationBackground = Color3.fromRGB(250, 250, 250),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

			TabBackground = Color3.fromRGB(235, 235, 235),
			TabStroke = Color3.fromRGB(215, 215, 215),
			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
			TabTextColor = Color3.fromRGB(80, 80, 80),
			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
			ElementStroke = Color3.fromRGB(210, 210, 210),
			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

			SliderBackground = Color3.fromRGB(150, 180, 220),
			SliderProgress = Color3.fromRGB(100, 150, 200), 
			SliderStroke = Color3.fromRGB(120, 170, 220),

			ToggleBackground = Color3.fromRGB(220, 220, 220),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(150, 150, 150),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 180, 180),
			PlaceholderColor = Color3.fromRGB(140, 140, 140)
		},

		Amethyst = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(30, 20, 40),
			Topbar = Color3.fromRGB(40, 25, 50),
			Shadow = Color3.fromRGB(20, 15, 30),

			NotificationBackground = Color3.fromRGB(35, 20, 40),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

			TabBackground = Color3.fromRGB(60, 40, 80),
			TabStroke = Color3.fromRGB(70, 45, 90),
			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
			TabTextColor = Color3.fromRGB(230, 230, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

			ElementBackground = Color3.fromRGB(45, 30, 60),
			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
			ElementStroke = Color3.fromRGB(70, 50, 85),
			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

			SliderBackground = Color3.fromRGB(100, 60, 150),
			SliderProgress = Color3.fromRGB(130, 80, 180),
			SliderStroke = Color3.fromRGB(150, 100, 200),

			ToggleBackground = Color3.fromRGB(45, 30, 55),
			ToggleEnabled = Color3.fromRGB(120, 60, 150),
			ToggleDisabled = Color3.fromRGB(94, 47, 117),
			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

			DropdownSelected = Color3.fromRGB(50, 35, 70),
			DropdownUnselected = Color3.fromRGB(35, 25, 50),

			InputBackground = Color3.fromRGB(45, 30, 60),
			InputStroke = Color3.fromRGB(80, 50, 110),
			PlaceholderColor = Color3.fromRGB(178, 150, 200)
		},

		Green = {
			TextColor = Color3.fromRGB(30, 60, 30),

			Background = Color3.fromRGB(235, 245, 235),
			Topbar = Color3.fromRGB(210, 230, 210),
			Shadow = Color3.fromRGB(200, 220, 200),

			NotificationBackground = Color3.fromRGB(240, 250, 240),
			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

			TabBackground = Color3.fromRGB(215, 235, 215),
			TabStroke = Color3.fromRGB(190, 210, 190),
			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
			TabTextColor = Color3.fromRGB(50, 80, 50),
			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

			ElementBackground = Color3.fromRGB(225, 240, 225),
			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
			ElementStroke = Color3.fromRGB(180, 200, 180),
			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

			SliderBackground = Color3.fromRGB(90, 160, 90),
			SliderProgress = Color3.fromRGB(70, 130, 70),
			SliderStroke = Color3.fromRGB(100, 180, 100),

			ToggleBackground = Color3.fromRGB(215, 235, 215),
			ToggleEnabled = Color3.fromRGB(60, 130, 60),
			ToggleDisabled = Color3.fromRGB(150, 175, 150),
			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

			DropdownSelected = Color3.fromRGB(225, 240, 225),
			DropdownUnselected = Color3.fromRGB(210, 225, 210),

			InputBackground = Color3.fromRGB(235, 245, 235),
			InputStroke = Color3.fromRGB(180, 200, 180),
			PlaceholderColor = Color3.fromRGB(120, 140, 120)
		},

		Bloom = {
			TextColor = Color3.fromRGB(60, 40, 50),

			Background = Color3.fromRGB(255, 240, 245),
			Topbar = Color3.fromRGB(250, 220, 225),
			Shadow = Color3.fromRGB(230, 190, 195),

			NotificationBackground = Color3.fromRGB(255, 235, 240),
			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

			TabBackground = Color3.fromRGB(240, 210, 220),
			TabStroke = Color3.fromRGB(230, 200, 210),
			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
			TabTextColor = Color3.fromRGB(80, 40, 60),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

			ElementBackground = Color3.fromRGB(255, 235, 240),
			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
			ElementStroke = Color3.fromRGB(230, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

			SliderBackground = Color3.fromRGB(240, 130, 160),
			SliderProgress = Color3.fromRGB(250, 160, 180),
			SliderStroke = Color3.fromRGB(255, 180, 200),

			ToggleBackground = Color3.fromRGB(240, 210, 220),
			ToggleEnabled = Color3.fromRGB(255, 140, 170),
			ToggleDisabled = Color3.fromRGB(200, 180, 185),
			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

			DropdownSelected = Color3.fromRGB(250, 220, 225),
			DropdownUnselected = Color3.fromRGB(240, 210, 220),

			InputBackground = Color3.fromRGB(255, 235, 240),
			InputStroke = Color3.fromRGB(220, 190, 200),
			PlaceholderColor = Color3.fromRGB(170, 130, 140)
		},

		DarkBlue = {
			TextColor = Color3.fromRGB(230, 230, 230),

			Background = Color3.fromRGB(20, 25, 30),
			Topbar = Color3.fromRGB(30, 35, 40),
			Shadow = Color3.fromRGB(15, 20, 25),

			NotificationBackground = Color3.fromRGB(25, 30, 35),
			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

			TabBackground = Color3.fromRGB(35, 40, 45),
			TabStroke = Color3.fromRGB(45, 50, 60),
			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

			ElementBackground = Color3.fromRGB(30, 35, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
			ElementStroke = Color3.fromRGB(45, 50, 60),
			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

			SliderBackground = Color3.fromRGB(0, 90, 180),
			SliderProgress = Color3.fromRGB(0, 120, 210),
			SliderStroke = Color3.fromRGB(0, 150, 240),

			ToggleBackground = Color3.fromRGB(35, 40, 45),
			ToggleEnabled = Color3.fromRGB(0, 120, 210),
			ToggleDisabled = Color3.fromRGB(70, 70, 80),
			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

			DropdownSelected = Color3.fromRGB(30, 70, 90),
			DropdownUnselected = Color3.fromRGB(25, 30, 35),

			InputBackground = Color3.fromRGB(25, 30, 35),
			InputStroke = Color3.fromRGB(45, 50, 60), 
			PlaceholderColor = Color3.fromRGB(150, 150, 160)
		},

		Serenity = {
			TextColor = Color3.fromRGB(50, 55, 60),
			Background = Color3.fromRGB(240, 245, 250),
			Topbar = Color3.fromRGB(215, 225, 235),
			Shadow = Color3.fromRGB(200, 210, 220),

			NotificationBackground = Color3.fromRGB(210, 220, 230),
			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

			TabBackground = Color3.fromRGB(200, 210, 220),
			TabStroke = Color3.fromRGB(180, 190, 200),
			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
			TabTextColor = Color3.fromRGB(50, 55, 60),
			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

			ElementBackground = Color3.fromRGB(210, 220, 230),
			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
			ElementStroke = Color3.fromRGB(190, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

			SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
			SliderProgress = Color3.fromRGB(70, 130, 180),
			SliderStroke = Color3.fromRGB(150, 180, 220),

			ToggleBackground = Color3.fromRGB(210, 220, 230),
			ToggleEnabled = Color3.fromRGB(70, 160, 210),
			ToggleDisabled = Color3.fromRGB(180, 180, 180),
			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

			DropdownSelected = Color3.fromRGB(220, 230, 240),
			DropdownUnselected = Color3.fromRGB(200, 210, 220),

			InputBackground = Color3.fromRGB(220, 230, 240),
			InputStroke = Color3.fromRGB(180, 190, 200),
			PlaceholderColor = Color3.fromRGB(150, 150, 150)
		},
	}
}


-- Services
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

-- Interface Management

local Rayfield = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
local buildAttempts = 0
local correctBuild = false
local warned
local globalLoaded
local rayfieldDestroyed = false -- True when RayfieldLibrary:Destroy() is called

repeat
	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
		correctBuild = true
		break
	end

	correctBuild = false

	if not warned then
		warn('Rayfield | Build Mismatch')
		print('Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.')
		warned = true
	end

	toDestroy, Rayfield = Rayfield, useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
	if toDestroy and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	Rayfield.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
end


local minSize = Vector2.new(1024, 768)
local useMobileSizing

if Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y then
	useMobileSizing = true
end

if UserInputService.TouchEnabled then
	useMobilePrompt = true
end


-- Object Variables

local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

-- Thanks to Latte Softworks for the Lucide integration for Roblox
local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')
-- Variables

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {} -- For storing keybind connections to disconnect when Rayfield is destroyed

local SelectedTheme = RayfieldLibrary.Theme.Default

local function ChangeTheme(Theme)
	if typeof(Theme) == 'string' then
		SelectedTheme = RayfieldLibrary.Theme[Theme]
	elseif typeof(Theme) == 'table' then
		SelectedTheme = Theme
	end

	Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
	Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(Rayfield:GetDescendants()) do
		if text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		for _, Element in ipairs(TabPage:GetChildren()) do
			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
				Element.BackgroundColor3 = SelectedTheme.ElementBackground
				Element.UIStroke.Color = SelectedTheme.ElementStroke
			end
		end
	end
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
	if not Icons then
		warn("Lucide Icons: Cannot use icons as icons library is not loaded")
		return
	end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then
		error(`Lucide Icons: Failed to find icon by the name of "{name}"`, 2)
	end

	local rirs = r[2]
	local riro = r[3]

	if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
		error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
	end

	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])

	local asset = {
		id = r[1],
		imageRectSize = irs,
		imageRectOffset = iro,
	}

	return asset
end
-- Converts ID to asset URI. Returns rbxassetid://0 if ID is not a number
local function getAssetUri(id: any): string
	local assetUri = "rbxassetid://0" -- Default to empty image
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	elseif type(id) == "string" and not Icons then
		warn("Rayfield | Cannot use Lucide icons as icons library is not loaded")
	else
		warn("Rayfield | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
	end
	return assetUri
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end

	local function connectFunctions()
		if dragBar and enableTaptic then
			dragBar.MouseEnter:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
				end
			end)

			dragBar.MouseLeave:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
				end
			end)
		end
	end

	connectFunctions()

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true

			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
			end
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false

			connectFunctions()

			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
			end
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			if enableTaptic and tapticOffset then
				TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
				TweenService:Create(dragObject.Parent, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}):Play()
			else
				if dragBar and tapticOffset then
					dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
				end
				object.Position = UDim2.fromOffset(position.X, position.Y)
			end
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end


local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed

	if not success then warn('Rayfield had an issue decoding the configuration file, please try delete the file and reopen Rayfield.') return end

	-- Iterate through current UI elements' flags
	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
		local FlagValue = Data[FlagName]

		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		else
			warn("Rayfield | Unable to find '"..FlagName.. "' in the save file.")
			print("The error above may not be an issue if new elements have been added or not been set values.")
			--RayfieldLibrary:Notify({Title = "Rayfield Flags", Content = "Rayfield was unable to find '"..FlagName.. "' in the save file. Check sirius.menu/discord for help.", Image = 3944688398})
		end
	end

	return changed
end

local function SaveConfiguration()
	if not CEnabled or not globalLoaded then return end

	if debugX then
		print('Saving')
	end

	local Data = {}
	for i, v in pairs(RayfieldLibrary.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			if typeof(v.CurrentValue) == 'boolean' then
				if v.CurrentValue == false then
					Data[i] = false
				else
					Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
				end
			else
				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
			end
		end
	end

	if useStudio then
		if script.Parent:FindFirstChild('configuration') then script.Parent.configuration:Destroy() end

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Parent = script.Parent
		ScreenGui.Name = 'configuration'

		local TextBox = Instance.new("TextBox")
		TextBox.Parent = ScreenGui
		TextBox.Size = UDim2.new(0, 800, 0, 50)
		TextBox.AnchorPoint = Vector2.new(0.5, 0)
		TextBox.Position = UDim2.new(0.5, 0, 0, 30)
		TextBox.Text = HttpService:JSONEncode(Data)
		TextBox.ClearTextOnFocus = false
	end

	if debugX then
		warn(HttpService:JSONEncode(Data))
	end


	callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

function RayfieldLibrary:Notify(data) -- action e.g open messages
	task.spawn(function()

		-- Notification Object Creation
		local newNotification = Notifications.Template:Clone()
		newNotification.Name = data.Title or 'No Title Provided'
		newNotification.Parent = Notifications
		newNotification.LayoutOrder = #Notifications:GetChildren()
		newNotification.Visible = false

		-- Set Data
		newNotification.Title.Text = data.Title or "Unknown Title"
		newNotification.Description.Text = data.Content or "Unknown Content"

		if data.Image then
			if typeof(data.Image) == 'string' and Icons then
				local asset = getIcon(data.Image)

				newNotification.Icon.Image = 'rbxassetid://'..asset.id
				newNotification.Icon.ImageRectOffset = asset.imageRectOffset
				newNotification.Icon.ImageRectSize = asset.imageRectSize
			else
				newNotification.Icon.Image = getAssetUri(data.Image)
			end
		else
			newNotification.Icon.Image = "rbxassetid://" .. 0
		end

		-- Set initial transparency values

		newNotification.Title.TextColor3 = SelectedTheme.TextColor
		newNotification.Description.TextColor3 = SelectedTheme.TextColor
		newNotification.BackgroundColor3 = SelectedTheme.Background
		newNotification.UIStroke.Color = SelectedTheme.TextColor
		newNotification.Icon.ImageColor3 = SelectedTheme.TextColor

		newNotification.BackgroundTransparency = 1
		newNotification.Title.TextTransparency = 1
		newNotification.Description.TextTransparency = 1
		newNotification.UIStroke.Transparency = 1
		newNotification.Shadow.ImageTransparency = 1
		newNotification.Size = UDim2.new(1, 0, 0, 800)
		newNotification.Icon.ImageTransparency = 1
		newNotification.Icon.BackgroundTransparency = 1

		task.wait()

		newNotification.Visible = true

		if data.Actions then
			warn('Rayfield | Not seeing your actions in notifications?')
			print("Notification Actions are being sunset for now, keep up to date on when they're back in the discord. (sirius.menu/discord)")
		end

		-- Calculate textbounds and set initial values
		local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
		newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

		newNotification.Icon.Size = UDim2.new(0, 32, 0, 32)
		newNotification.Icon.Position = UDim2.new(0, 20, 0.5, 0)

		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()

		task.wait(0.15)
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

		task.wait(0.05)

		TweenService:Create(newNotification.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

		task.wait(0.05)
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.82}):Play()

		local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
		task.wait(data.Duration or waitDuration)

		newNotification.Icon.Visible = false
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)}):Play()

		task.wait(1)

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)}):Play()

		newNotification.Visible = false
		newNotification:Destroy()
	end)
end

local function openSearch()
	searchOpen = true

	Main.Search.BackgroundTransparency = 1
	Main.Search.Shadow.ImageTransparency = 1
	Main.Search.Input.TextTransparency = 1
	Main.Search.Search.ImageTransparency = 1
	Main.Search.UIStroke.Transparency = 1
	Main.Search.Size = UDim2.new(1, 0, 0, 80)
	Main.Search.Position = UDim2.new(0.5, 0, 0, 70)

	Main.Search.Input.Interactable = true

	Main.Search.Visible = true

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = false
			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		end
	end

	Main.Search.Input:CaptureFocus()
	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {ImageTransparency = 0.95}):Play()
	TweenService:Create(Main.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 57), BackgroundTransparency = 0.9}):Play()
	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.8}):Play()
	TweenService:Create(Main.Search.Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
	TweenService:Create(Main.Search.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
	TweenService:Create(Main.Search, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -35, 0, 35)}):Play()
end

local function closeSearch()
	searchOpen = false

	TweenService:Create(Main.Search, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(1, -55, 0, 30)}):Play()
	TweenService:Create(Main.Search.Search, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
	TweenService:Create(Main.Search.Input, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = true
			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			else
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			end
		end
	end

	Main.Search.Input.Text = ''
	Main.Search.Input.Interactable = false
end

local function Hide(notify: boolean?)
	if MPrompt then
		MPrompt.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		MPrompt.Position = UDim2.new(0.5, 0, 0, -50)
		MPrompt.Size = UDim2.new(0, 40, 0, 10)
		MPrompt.BackgroundTransparency = 1
		MPrompt.Title.TextTransparency = 1
		MPrompt.Visible = true
	end

	task.spawn(closeSearch)

	Debounce = true
	if notify then
		if useMobilePrompt then 
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping 'Show'.", Duration = 7, Image = 4400697855})
		else
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = `The interface has been hidden, you can unhide the interface by tapping {getSetting("General", "rayfieldOpen")}.`, Duration = 7, Image = 4400697855})
		end
	end

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 0)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 45)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

	if useMobilePrompt and MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.3}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
	end

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			TweenService:Create(TopbarButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		end
	end

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		end
	end

	dragInteract.Visible = false

	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						elseif element.Name == 'Divider' then
							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
						else
							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = false
							end
						end
					end
				end
			end
		end
	end

	task.wait(0.5)
	Main.Visible = false
	Debounce = false
end

local function Maximise()
	Debounce = true
	Topbar.ChangeSize.Image = "rbxassetid://"..10137941941

	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
	TabList.Visible = true
	task.wait(0.2)

	Elements.Visible = true

	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
						elseif element.Name == 'Divider' then
							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()
						else
							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = true
							end
						end
					end
				end
			end
		end
	end

	task.wait(0.1)

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			else
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			end

		end
	end

	task.wait(0.5)
	Debounce = false
end


local function Unhide()
	Debounce = true
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Visible = true
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

	if MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 40, 0, 10), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.spawn(function()
			task.wait(0.5)
			MPrompt.Visible = false
		end)
	end

	if Minimised then
		task.spawn(Maximise)
	end

	dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset)

	dragInteract.Visible = true

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			if TopbarButton.Name == 'Icon' then
				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			else
				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
			end

		end
	end

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			else
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			end
		end
	end

	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
						elseif element.Name == 'Divider' then
							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()
						else
							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = true
							end
						end
					end
				end
			end
		end
	end

	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()

	task.wait(0.5)
	Minimised = false
	Debounce = false
end

local function Minimise()
	Debounce = true
	Topbar.ChangeSize.Image = "rbxassetid://"..11036884234

	Topbar.UIStroke.Color = SelectedTheme.ElementStroke

	task.spawn(closeSearch)

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		end
	end

	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						elseif element.Name == 'Divider' then
							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
						else
							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = false
							end
						end
					end
				end
			end
		end
	end

	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()

	task.wait(0.3)

	Elements.Visible = false
	TabList.Visible = false

	task.wait(0.2)
	Debounce = false
end

local function saveSettings() -- Save settings to config file
	local encoded
	local success, err = pcall(function()
		encoded = HttpService:JSONEncode(settingsTable)
	end)

	if success then
		if useStudio then
			if script.Parent['get.val'] then
				script.Parent['get.val'].Value = encoded
			end
		end
		callSafely(writefile, RayfieldFolder..'/settings'..ConfigurationExtension, encoded)
	end
end

local function updateSetting(category: string, setting: string, value: any)
	if not settingsInitialized then
		return
	end
	settingsTable[category][setting].Value = value
	overriddenSettings[`{category}.{setting}`] = nil -- If user changes an overriden setting, remove the override
	saveSettings()
end

local function createSettings(window)
	if not (writefile and isfile and readfile and isfolder and makefolder) and not useStudio then
		if Topbar['Settings'] then Topbar.Settings.Visible = false end
		Topbar['Search'].Position = UDim2.new(1, -75, 0.5, 0)
		warn('Can\'t create settings as no file-saving functionality is available.')
		return
	end

	local newTab = window:CreateTab('Rayfield Settings', 0, true)

	if TabList['Rayfield Settings'] then
		TabList['Rayfield Settings'].LayoutOrder = 1000
	end

	if Elements['Rayfield Settings'] then
		Elements['Rayfield Settings'].LayoutOrder = 1000
	end

	-- Create sections and elements
	for categoryName, settingCategory in pairs(settingsTable) do
		newTab:CreateSection(categoryName)

		for settingName, setting in pairs(settingCategory) do
			if setting.Type == 'input' then
				setting.Element = newTab:CreateInput({
					Name = setting.Name,
					CurrentValue = setting.Value,
					PlaceholderText = setting.Placeholder,
					Ext = true,
					RemoveTextAfterFocusLost = setting.ClearOnFocus,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == 'toggle' then
				setting.Element = newTab:CreateToggle({
					Name = setting.Name,
					CurrentValue = setting.Value,
					Ext = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == 'bind' then
				setting.Element = newTab:CreateKeybind({
					Name = setting.Name,
					CurrentKeybind = setting.Value,
					HoldToInteract = false,
					Ext = true,
					CallOnChange = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			end
		end
	end

	settingsCreated = true
	loadSettings()
	saveSettings()
end



function RayfieldLibrary:CreateWindow(Settings)
	if Rayfield:FindFirstChild('Loading') then
		if getgenv and not getgenv().rayfieldCached then
			Rayfield.Enabled = true
			Rayfield.Loading.Visible = true

			task.wait(1.4)
			Rayfield.Loading.Visible = false
		end
	end

	if getgenv then getgenv().rayfieldCached = true end

	if not correctBuild and not Settings.DisableBuildWarnings then
		task.delay(3, 
			function() 
				RayfieldLibrary:Notify({Title = 'Build Mismatch', Content = 'Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.\n\nTry rejoining and then run the script twice.', Image = 4335487866, Duration = 15})		
			end)
	end

	if Settings.ToggleUIKeybind then -- Can either be a string or an Enum.KeyCode
		local keybind = Settings.ToggleUIKeybind
		if type(keybind) == "string" then
			keybind = string.upper(keybind)
			assert(pcall(function()
				return Enum.KeyCode[keybind]
			end), "ToggleUIKeybind must be a valid KeyCode")
			overrideSetting("General", "rayfieldOpen", keybind)
		elseif typeof(keybind) == "EnumItem" then
			assert(keybind.EnumType == Enum.KeyCode, "ToggleUIKeybind must be a KeyCode enum")
			overrideSetting("General", "rayfieldOpen", keybind.Name)
		else
			error("ToggleUIKeybind must be a string or KeyCode enum")
		end
	end

	ensureFolder(RayfieldFolder)

	-- Attempt to report an event to analytics
	if not requestsDisabled then
		sendReport("window_created", Settings.Name or "Unknown")
	end
	local Passthrough = false
	Topbar.Title.Text = Settings.Name

	Main.Size = UDim2.new(0, 420, 0, 100)
	Main.Visible = true
	Main.BackgroundTransparency = 1
	if Main:FindFirstChild('Notice') then Main.Notice.Visible = false end
	Main.Shadow.Image.ImageTransparency = 1

	LoadingFrame.Title.TextTransparency = 1
	LoadingFrame.Subtitle.TextTransparency = 1

	if Settings.ShowText then
		MPrompt.Title.Text = 'Show '..Settings.ShowText
	end

	LoadingFrame.Version.TextTransparency = 1
	LoadingFrame.Title.Text = Settings.LoadingTitle or "Rayfield"
	LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Interface Suite"

	if Settings.LoadingTitle ~= "Rayfield Interface Suite" then
		LoadingFrame.Version.Text = "Rayfield UI"
	end

	if Settings.Icon and Settings.Icon ~= 0 and Topbar:FindFirstChild('Icon') then
		Topbar.Icon.Visible = true
		Topbar.Title.Position = UDim2.new(0, 47, 0.5, 0)

		if Settings.Icon then
			if typeof(Settings.Icon) == 'string' and Icons then
				local asset = getIcon(Settings.Icon)

				Topbar.Icon.Image = 'rbxassetid://'..asset.id
				Topbar.Icon.ImageRectOffset = asset.imageRectOffset
				Topbar.Icon.ImageRectSize = asset.imageRectSize
			else
				Topbar.Icon.Image = getAssetUri(Settings.Icon)
			end
		else
			Topbar.Icon.Image = "rbxassetid://" .. 0
		end
	end

	if dragBar then
		dragBar.Visible = false
		dragBarCosmetic.BackgroundTransparency = 1
		dragBar.Visible = true
	end

	if Settings.Theme then
		local success, result = pcall(ChangeTheme, Settings.Theme)
		if not success then
			local success, result2 = pcall(ChangeTheme, 'Default')
			if not success then
				warn('CRITICAL ERROR - NO DEFAULT THEME')
				print(result2)
			end
			warn('issue rendering theme. no theme on file')
			print(result)
		end
	end

	Topbar.Visible = false
	Elements.Visible = false
	LoadingFrame.Visible = true

	if not Settings.DisableRayfieldPrompts then
		task.spawn(function()
			while true do
				task.wait(math.random(180, 600))
				RayfieldLibrary:Notify({
					Title = "Rayfield Interface",
					Content = "Enjoying this UI library? Find it at sirius.menu/discord",
					Duration = 7,
					Image = 4370033185,
				})
			end
		end)
	end

	pcall(function()
		if not Settings.ConfigurationSaving.FileName then
			Settings.ConfigurationSaving.FileName = tostring(game.PlaceId)
		end

		if Settings.ConfigurationSaving.Enabled == nil then
			Settings.ConfigurationSaving.Enabled = false
		end

		CFileName = Settings.ConfigurationSaving.FileName
		ConfigurationFolder = Settings.ConfigurationSaving.FolderName or ConfigurationFolder
		CEnabled = Settings.ConfigurationSaving.Enabled

		if Settings.ConfigurationSaving.Enabled then
			ensureFolder(ConfigurationFolder)
		end
	end)


	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})
	if dragBar then dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset) makeDraggable(Main, dragInteract, true, {dragOffset, dragOffsetMobile}) end

	for _, TabButton in ipairs(TabList:GetChildren()) do
		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" then
			TabButton.BackgroundTransparency = 1
			TabButton.Title.TextTransparency = 1
			TabButton.Image.ImageTransparency = 1
			TabButton.UIStroke.Transparency = 1
		end
	end

	if Settings.Discord and Settings.Discord.Enabled and not useStudio then
		ensureFolder(RayfieldFolder.."/Discord Invites")

		if callSafely(isfile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension) then
			if requestFunc then
				pcall(function()
					requestFunc({
						Url = 'http://127.0.0.1:6463/rpc?v=1',
						Method = 'POST',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = ''
						},
						Body = HttpService:JSONEncode({
							cmd = 'INVITE_BROWSER',
							nonce = HttpService:GenerateGUID(false),
							args = {code = Settings.Discord.Invite}
						})
					})
				end)
			end

			if Settings.Discord.RememberJoins then -- We do logic this way so if the developer changes this setting, the user still won't be prompted, only new users
				callSafely(writefile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension,"Rayfield RememberJoins is true for this invite, this invite will not ask you to join again")
			end
		end
	end

	if (Settings.KeySystem) then
		if not Settings.KeySettings then
			Passthrough = true
			return
		end

		ensureFolder(RayfieldFolder.."/Key System")

		if typeof(Settings.KeySettings.Key) == "string" then Settings.KeySettings.Key = {Settings.KeySettings.Key} end

		if Settings.KeySettings.GrabKeyFromSite then
			for i, Key in ipairs(Settings.KeySettings.Key) do
				local Success, Response = pcall(function()
					Settings.KeySettings.Key[i] = tostring(game:HttpGet(Key):gsub("[\n\r]", " "))
					Settings.KeySettings.Key[i] = string.gsub(Settings.KeySettings.Key[i], " ", "")
				end)
				if not Success then
					print("Rayfield | "..Key.." Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
				end
			end
		end

		if not Settings.KeySettings.FileName then
			Settings.KeySettings.FileName = "No file name specified"
		end

		if callSafely(isfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension) then
			for _, MKey in ipairs(Settings.KeySettings.Key) do
				local savedKeys = callSafely(readfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension)
				if keyFileContents and string.find(savedKeys, MKey) then
					Passthrough = true
				end
			end
		end

		if not Passthrough then
			local AttemptsRemaining = math.random(2, 5)
			Rayfield.Enabled = false
			local KeyUI = useStudio and script.Parent:FindFirstChild('Key') or game:GetObjects("rbxassetid://11380036235")[1]

			KeyUI.Enabled = true

			if gethui then
				KeyUI.Parent = gethui()
			elseif syn and syn.protect_gui then 
				syn.protect_gui(KeyUI)
				KeyUI.Parent = CoreGui
			elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
				KeyUI.Parent = CoreGui:FindFirstChild("RobloxGui")
			elseif not useStudio then
				KeyUI.Parent = CoreGui
			end

			if gethui then
				for _, Interface in ipairs(gethui():GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			elseif not useStudio then
				for _, Interface in ipairs(CoreGui:GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			end

			local KeyMain = KeyUI.Main
			KeyMain.Title.Text = Settings.KeySettings.Title or Settings.Name
			KeyMain.Subtitle.Text = Settings.KeySettings.Subtitle or "Key System"
			KeyMain.NoteMessage.Text = Settings.KeySettings.Note or "No instructions"

			KeyMain.Size = UDim2.new(0, 467, 0, 175)
			KeyMain.BackgroundTransparency = 1
			KeyMain.Shadow.Image.ImageTransparency = 1
			KeyMain.Title.TextTransparency = 1
			KeyMain.Subtitle.TextTransparency = 1
			KeyMain.KeyNote.TextTransparency = 1
			KeyMain.Input.BackgroundTransparency = 1
			KeyMain.Input.UIStroke.Transparency = 1
			KeyMain.Input.InputBox.TextTransparency = 1
			KeyMain.NoteTitle.TextTransparency = 1
			KeyMain.NoteMessage.TextTransparency = 1
			KeyMain.Hide.ImageTransparency = 1

			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
			TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.15)
			TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.3}):Play()


			KeyUI.Main.Input.InputBox.FocusLost:Connect(function()
				if #KeyUI.Main.Input.InputBox.Text == 0 then return end
				local KeyFound = false
				local FoundKey = ''
				for _, MKey in ipairs(Settings.KeySettings.Key) do
					--if string.find(KeyMain.Input.InputBox.Text, MKey) then
					--	KeyFound = true
					--	FoundKey = MKey
					--end


					-- stricter key check
					if KeyMain.Input.InputBox.Text == MKey then
						KeyFound = true
						FoundKey = MKey
					end
				end
				if KeyFound then 
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
					TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					task.wait(0.51)
					Passthrough = true
					KeyMain.Visible = false
					if Settings.KeySettings.SaveKey then
						callSafely(writefile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension, FoundKey)
						RayfieldLibrary:Notify({Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284})
					end
				else
					if AttemptsRemaining == 0 then
						TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
						TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
						TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
						TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
						TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
						task.wait(0.45)
						Players.LocalPlayer:Kick("No Attempts Remaining")
						game:Shutdown()
					end
					KeyMain.Input.InputBox.Text = ""
					AttemptsRemaining = AttemptsRemaining - 1
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.495,0,0.5,0)}):Play()
					task.wait(0.1)
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.505,0,0.5,0)}):Play()
					task.wait(0.1)
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
				end
			end)

			KeyMain.Hide.MouseButton1Click:Connect(function()
				TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
				TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
				TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
				task.wait(0.51)
				RayfieldLibrary:Destroy()
				KeyUI:Destroy()
			end)
		else
			Passthrough = true
		end
	end
	if Settings.KeySystem then
		repeat task.wait() until Passthrough
	end

	Notifications.Template.Visible = false
	Notifications.Visible = true
	Rayfield.Enabled = true

	task.wait(0.5)
	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	task.wait(0.1)
	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()


	Elements.Template.LayoutOrder = 100000
	Elements.Template.Visible = false

	Elements.UIPageLayout.FillDirection = Enum.FillDirection.Horizontal
	TabList.Template.Visible = false

	-- Tab
	local FirstTab = false
	local Window = {}
	function Window:CreateTab(Name, Image, Ext)
		local SDone = false
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Title.TextWrapped = false
		TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 30, 0, 30)

		if Image and Image ~= 0 then
			if typeof(Image) == 'string' and Icons then
				local asset = getIcon(Image)

				TabButton.Image.Image = 'rbxassetid://'..asset.id
				TabButton.Image.ImageRectOffset = asset.imageRectOffset
				TabButton.Image.ImageRectSize = asset.imageRectSize
			else
				TabButton.Image.Image = getAssetUri(Image)
			end

			TabButton.Title.AnchorPoint = Vector2.new(0, 0.5)
			TabButton.Title.Position = UDim2.new(0, 37, 0.5, 0)
			TabButton.Image.Visible = true
			TabButton.Title.TextXAlignment = Enum.TextXAlignment.Left
			TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 52, 0, 30)
		end



		TabButton.BackgroundTransparency = 1
		TabButton.Title.TextTransparency = 1
		TabButton.Image.ImageTransparency = 1
		TabButton.UIStroke.Transparency = 1

		TabButton.Visible = not Ext or false

		-- Create Elements Page
		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true

		TabPage.LayoutOrder = #Elements:GetChildren() or Ext and 10000

		for _, TemplateElement in ipairs(TabPage:GetChildren()) do
			if TemplateElement.ClassName == "Frame" and TemplateElement.Name ~= "Placeholder" then
				TemplateElement:Destroy()
			end
		end

		TabPage.Parent = Elements
		if not FirstTab and not Ext then
			Elements.UIPageLayout.Animated = false
			Elements.UIPageLayout:JumpTo(TabPage)
			Elements.UIPageLayout.Animated = true
		end

		TabButton.UIStroke.Color = SelectedTheme.TabStroke

		if Elements.UIPageLayout.CurrentPage == TabPage then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
		else
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
		end


		-- Animate
		task.wait(0.1)
		if FirstTab or Ext then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
		elseif not Ext then
			FirstTab = Name
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		end


		TabButton.Interact.MouseButton1Click:Connect(function()
			if Minimised then return end
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackgroundSelected}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.SelectedTabTextColor}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.SelectedTabTextColor}):Play()

			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			if Elements.UIPageLayout.CurrentPage ~= TabPage then
				Elements.UIPageLayout:JumpTo(TabPage)
			end
		end)

		local Tab = {}

		-- Button
		function Tab:CreateButton(ButtonSettings)
			local ButtonValue = {}

			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage

			Button.BackgroundTransparency = 1
			Button.UIStroke.Transparency = 1
			Button.Title.TextTransparency = 1

			TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	


			Button.Interact.MouseButton1Click:Connect(function()
				local Success, Response = pcall(ButtonSettings.Callback)
				-- Prevents animation from trying to play if the button's callback called RayfieldLibrary:Destroy()
				if rayfieldDestroyed then
					return
				end
				if not Success then
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Button.Title.Text = "Callback Error"
					print("Rayfield | "..ButtonSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Button.Title.Text = ButtonSettings.Name
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				else
					if not ButtonSettings.Ext then
						SaveConfiguration(ButtonSettings.Name..'\n')
					end
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					task.wait(0.2)
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end
			end)

			Button.MouseEnter:Connect(function()
				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.7}):Play()
			end)

			Button.MouseLeave:Connect(function()
				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
			end)

			function ButtonValue:Set(NewButton)
				Button.Title.Text = NewButton
				Button.Name = NewButton
			end

			return ButtonValue
		end

		-- ColorPicker
		function Tab:CreateColorPicker(ColorPickerSettings) -- by Throit
			ColorPickerSettings.Type = "ColorPicker"
			local ColorPicker = Elements.Template.ColorPicker:Clone()
			local Background = ColorPicker.CPBackground
			local Display = Background.Display
			local Main = Background.MainCP
			local Slider = ColorPicker.ColorSlider
			ColorPicker.ClipsDescendants = true
			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			ColorPicker.Size = UDim2.new(1, -10, 0, 45)
			Background.Size = UDim2.new(0, 39, 0, 22)
			Display.BackgroundTransparency = 0
			Main.MainPoint.ImageTransparency = 1
			ColorPicker.Interact.Size = UDim2.new(1, 0, 1, 0)
			ColorPicker.Interact.Position = UDim2.new(0.5, 0, 0.5, 0)
			ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
			ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
			Main.ImageTransparency = 1
			Background.BackgroundTransparency = 1

			for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
				if rgbinput:IsA("Frame") then
					rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
					rgbinput.UIStroke.Color = SelectedTheme.InputStroke
				end
			end

			ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
			ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke

			local opened = false 
			local mouse = Players.LocalPlayer:GetMouse()
			Main.Image = "http://www.roblox.com/asset/?id=11415645739"
			local mainDragging = false 
			local sliderDragging = false 
			ColorPicker.Interact.MouseButton1Down:Connect(function()
				task.spawn(function()
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					task.wait(0.2)
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end)

				if not opened then
					opened = true 
					TweenService:Create(Background, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 18, 0, 15)}):Play()
					task.wait(0.1)
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 120)}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 173, 0, 86)}):Play()
					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.289, 0, 0.5, 0)}):Play()
					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 40)}):Play()
					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 73)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0.574, 0, 1, 0)}):Play()
					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = SelectedTheme ~= RayfieldLibrary.Theme.Default and 0.25 or 0.1}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				else
					opened = false
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 39, 0, 22)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 1, 0)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 70)}):Play()
					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 90)}):Play()
					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				end

			end)

			UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
					mainDragging = false
					sliderDragging = false
				end end)
			Main.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Main.MainPoint.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Slider.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			Slider.SliderPoint.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			local h,s,v = ColorPickerSettings.Color:ToHSV()
			local color = Color3.fromHSV(h,s,v) 
			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
			ColorPicker.HexInput.InputBox.Text = hex
			local function setDisplay()
				--Main
				Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
				Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
				Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
				Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
				--Slider 
				local x = h * Slider.AbsoluteSize.X
				Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
				Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
				local color = Color3.fromHSV(h,s,v) 
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
				ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
				ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
				hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
			end
			setDisplay()
			ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
				if not pcall(function()
						local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
						local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
						h,s,v = rgbColor:ToHSV()
						hex = ColorPicker.HexInput.InputBox.Text
						setDisplay()
						ColorPickerSettings.Color = rgbColor
					end) 
				then 
					ColorPicker.HexInput.InputBox.Text = hex 
				end
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end)
			--RGB
			local function rgbBoxes(box,toChange)
				local value = tonumber(box.Text) 
				local color = Color3.fromHSV(h,s,v) 
				local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				local save 
				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
				if value then 
					value = math.clamp(value,0,255)
					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()

					setDisplay()
				else 
					box.Text = tostring(save)
				end
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration(ColorPickerSettings.Flag..'\n'..tostring(ColorPickerSettings.Color))
				end
			end
			ColorPicker.RGB.RInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.RInput.InputBox,"R")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.GInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.GInput.InputBox,"G")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.BInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.BInput.InputBox,"B")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)

			RunService.RenderStepped:connect(function()
				if mainDragging then 
					local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
					local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
					Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
					s = localX / Main.AbsoluteSize.X
					v = 1 - (localY / Main.AbsoluteSize.Y)
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
				if sliderDragging then 
					local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
					h = localX / Slider.AbsoluteSize.X
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and ColorPickerSettings.Flag then
					RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPickerSettings
				end
			end

			function ColorPickerSettings:Set(RGBColor)
				ColorPickerSettings.Color = RGBColor
				h,s,v = ColorPickerSettings.Color:ToHSV()
				color = Color3.fromHSV(h,s,v)
				setDisplay()
			end

			ColorPicker.MouseEnter:Connect(function()
				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			ColorPicker.MouseLeave:Connect(function()
				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
					if rgbinput:IsA("Frame") then
						rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
						rgbinput.UIStroke.Color = SelectedTheme.InputStroke
					end
				end

				ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
				ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return ColorPickerSettings
		end

		-- Section
		function Tab:CreateSection(SectionName)

			local SectionValue = {}

			if SDone then
				local SectionSpace = Elements.Template.SectionSpacing:Clone()
				SectionSpace.Visible = true
				SectionSpace.Parent = TabPage
			end

			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage

			Section.Title.TextTransparency = 1
			TweenService:Create(Section.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()

			function SectionValue:Set(NewSection)
				Section.Title.Text = NewSection
			end

			SDone = true

			return SectionValue
		end

		-- Divider
		function Tab:CreateDivider()
			local DividerValue = {}

			local Divider = Elements.Template.Divider:Clone()
			Divider.Visible = true
			Divider.Parent = TabPage

			Divider.Divider.BackgroundTransparency = 1
			TweenService:Create(Divider.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()

			function DividerValue:Set(Value)
				Divider.Visible = Value
			end

			return DividerValue
		end

		-- Label
		function Tab:CreateLabel(LabelText : string, Icon: number, Color : Color3, IgnoreTheme : boolean)
			local LabelValue = {}

			local Label = Elements.Template.Label:Clone()
			Label.Title.Text = LabelText
			Label.Visible = true
			Label.Parent = TabPage

			Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
			Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke

			if Icon then
				if typeof(Icon) == 'string' and Icons then
					local asset = getIcon(Icon)

					Label.Icon.Image = 'rbxassetid://'..asset.id
					Label.Icon.ImageRectOffset = asset.imageRectOffset
					Label.Icon.ImageRectSize = asset.imageRectSize
				else
					Label.Icon.Image = getAssetUri(Icon)
				end
			else
				Label.Icon.Image = "rbxassetid://" .. 0
			end

			if Icon and Label:FindFirstChild('Icon') then
				Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
				Label.Title.Size = UDim2.new(1, -100, 0, 14)

				if Icon then
					if typeof(Icon) == 'string' and Icons then
						local asset = getIcon(Icon)

						Label.Icon.Image = 'rbxassetid://'..asset.id
						Label.Icon.ImageRectOffset = asset.imageRectOffset
						Label.Icon.ImageRectSize = asset.imageRectSize
					else
						Label.Icon.Image = getAssetUri(Icon)
					end
				else
					Label.Icon.Image = "rbxassetid://" .. 0
				end

				Label.Icon.Visible = true
			end

			Label.Icon.ImageTransparency = 1
			Label.BackgroundTransparency = 1
			Label.UIStroke.Transparency = 1
			Label.Title.TextTransparency = 1

			TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = Color and 0.8 or 0}):Play()
			TweenService:Create(Label.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = Color and 0.7 or 0}):Play()
			TweenService:Create(Label.Icon, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
			TweenService:Create(Label.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = Color and 0.2 or 0}):Play()	

			function LabelValue:Set(NewLabel, Icon, Color)
				Label.Title.Text = NewLabel

				if Color then
					Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
					Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke
				end

				if Icon and Label:FindFirstChild('Icon') then
					Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
					Label.Title.Size = UDim2.new(1, -100, 0, 14)

					if Icon then
						if typeof(Icon) == 'string' and Icons then
							local asset = getIcon(Icon)

							Label.Icon.Image = 'rbxassetid://'..asset.id
							Label.Icon.ImageRectOffset = asset.imageRectOffset
							Label.Icon.ImageRectSize = asset.imageRectSize
						else
							Label.Icon.Image = getAssetUri(Icon)
						end
					else
						Label.Icon.Image = "rbxassetid://" .. 0
					end

					Label.Icon.Visible = true
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Label.BackgroundColor3 = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementBackground
				Label.UIStroke.Color = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementStroke
			end)

			return LabelValue
		end

		-- Paragraph
		function Tab:CreateParagraph(ParagraphSettings)
			local ParagraphValue = {}

			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Content.Text = ParagraphSettings.Content
			Paragraph.Visible = true
			Paragraph.Parent = TabPage

			Paragraph.BackgroundTransparency = 1
			Paragraph.UIStroke.Transparency = 1
			Paragraph.Title.TextTransparency = 1
			Paragraph.Content.TextTransparency = 1

			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke

			TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	
			TweenService:Create(Paragraph.Content, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			function ParagraphValue:Set(NewParagraphSettings)
				Paragraph.Title.Text = NewParagraphSettings.Title
				Paragraph.Content.Text = NewParagraphSettings.Content
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
			end)

			return ParagraphValue
		end

		-- Input
		function Tab:CreateInput(InputSettings)
			local Input = Elements.Template.Input:Clone()
			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			Input.Visible = true
			Input.Parent = TabPage

			Input.BackgroundTransparency = 1
			Input.UIStroke.Transparency = 1
			Input.Title.TextTransparency = 1

			Input.InputFrame.InputBox.Text = InputSettings.CurrentValue or ''

			Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke

			TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Input.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
			Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

			Input.InputFrame.InputBox.FocusLost:Connect(function()
				local Success, Response = pcall(function()
					InputSettings.Callback(Input.InputFrame.InputBox.Text)
					InputSettings.CurrentValue = Input.InputFrame.InputBox.Text
				end)

				if not Success then
					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Input.Title.Text = "Callback Error"
					print("Rayfield | "..InputSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Input.Title.Text = InputSettings.Name
					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if InputSettings.RemoveTextAfterFocusLost then
					Input.InputFrame.InputBox.Text = ""
				end

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end)

			Input.MouseEnter:Connect(function()
				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Input.MouseLeave:Connect(function()
				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Input.InputFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
			end)

			function InputSettings:Set(text)
				Input.InputFrame.InputBox.Text = text
				InputSettings.CurrentValue = text

				local Success, Response = pcall(function()
					InputSettings.Callback(text)
				end)

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and InputSettings.Flag then
					RayfieldLibrary.Flags[InputSettings.Flag] = InputSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return InputSettings
		end

		-- Dropdown
		function Tab:CreateDropdown(DropdownSettings)
			local Dropdown = Elements.Template.Dropdown:Clone()
			if string.find(DropdownSettings.Name,"closed") then
				Dropdown.Name = "Dropdown"
			else
				Dropdown.Name = DropdownSettings.Name
			end
			Dropdown.Title.Text = DropdownSettings.Name
			Dropdown.Visible = true
			Dropdown.Parent = TabPage

			Dropdown.List.Visible = false
			if DropdownSettings.CurrentOption then
				if type(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end
				if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end
			else
				DropdownSettings.CurrentOption = {}
			end

			if DropdownSettings.MultipleOptions then
				if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
					if #DropdownSettings.CurrentOption == 1 then
						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
					elseif #DropdownSettings.CurrentOption == 0 then
						Dropdown.Selected.Text = "None"
					else
						Dropdown.Selected.Text = "Various"
					end
				else
					DropdownSettings.CurrentOption = {}
					Dropdown.Selected.Text = "None"
				end
			else
				Dropdown.Selected.Text = DropdownSettings.CurrentOption[1] or "None"
			end

			Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
			TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()

			Dropdown.BackgroundTransparency = 1
			Dropdown.UIStroke.Transparency = 1
			Dropdown.Title.TextTransparency = 1

			Dropdown.Size = UDim2.new(1, -10, 0, 45)

			TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Dropdown.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			for _, ununusedoption in ipairs(Dropdown.List:GetChildren()) do
				if ununusedoption.ClassName == "Frame" and ununusedoption.Name ~= "Placeholder" then
					ununusedoption:Destroy()
				end
			end

			Dropdown.Toggle.Rotation = 180

			Dropdown.Interact.MouseButton1Click:Connect(function()
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				task.wait(0.1)
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				if Debounce then return end
				if Dropdown.List.Visible then
					Debounce = true
					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
							TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						end
					end
					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
					task.wait(0.35)
					Dropdown.List.Visible = false
					Debounce = false
				else
					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 180)}):Play()
					Dropdown.List.Visible = true
					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 0.7}):Play()
					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 0}):Play()	
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
							if DropdownOpt.Name ~= Dropdown.Selected.Text then
								TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							end
							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
						end
					end
				end
			end)

			Dropdown.MouseEnter:Connect(function()
				if not Dropdown.List.Visible then
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				end
			end)

			Dropdown.MouseLeave:Connect(function()
				TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			local function SetDropdownOptions()
				for _, Option in ipairs(DropdownSettings.Options) do
					local DropdownOption = Elements.Template.Dropdown.List.Template:Clone()
					DropdownOption.Name = Option
					DropdownOption.Title.Text = Option
					DropdownOption.Parent = Dropdown.List
					DropdownOption.Visible = true

					DropdownOption.BackgroundTransparency = 1
					DropdownOption.UIStroke.Transparency = 1
					DropdownOption.Title.TextTransparency = 1

					--local Dropdown = Tab:CreateDropdown({
					--	Name = "Dropdown Example",
					--	Options = {"Option 1","Option 2"},
					--	CurrentOption = {"Option 1"},
					--  MultipleOptions = true,
					--	Flag = "Dropdown1",
					--	Callback = function(TableOfOptions)

					--	end,
					--})


					DropdownOption.Interact.ZIndex = 50
					DropdownOption.Interact.MouseButton1Click:Connect(function()
						if not DropdownSettings.MultipleOptions and table.find(DropdownSettings.CurrentOption, Option) then 
							return
						end

						if table.find(DropdownSettings.CurrentOption, Option) then
							table.remove(DropdownSettings.CurrentOption, table.find(DropdownSettings.CurrentOption, Option))
							if DropdownSettings.MultipleOptions then
								if #DropdownSettings.CurrentOption == 1 then
									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
								elseif #DropdownSettings.CurrentOption == 0 then
									Dropdown.Selected.Text = "None"
								else
									Dropdown.Selected.Text = "Various"
								end
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
							end
						else
							if not DropdownSettings.MultipleOptions then
								table.clear(DropdownSettings.CurrentOption)
							end
							table.insert(DropdownSettings.CurrentOption, Option)
							if DropdownSettings.MultipleOptions then
								if #DropdownSettings.CurrentOption == 1 then
									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
								elseif #DropdownSettings.CurrentOption == 0 then
									Dropdown.Selected.Text = "None"
								else
									Dropdown.Selected.Text = "Various"
								end
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
							end
							TweenService:Create(DropdownOption.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(DropdownOption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
							Debounce = true
						end


						local Success, Response = pcall(function()
							DropdownSettings.Callback(DropdownSettings.CurrentOption)
						end)

						if not Success then
							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Dropdown.Title.Text = "Callback Error"
							print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
							warn('Check docs.sirius.menu for help with Rayfield specific development.')
							task.wait(0.5)
							Dropdown.Title.Text = DropdownSettings.Name
							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						end

						for _, droption in ipairs(Dropdown.List:GetChildren()) do
							if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" and not table.find(DropdownSettings.CurrentOption, droption.Name) then
								TweenService:Create(droption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
							end
						end
						if not DropdownSettings.MultipleOptions then
							task.wait(0.1)
							TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
							for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
								if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
									TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
									TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
									TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
								end
							end
							TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
							TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
							task.wait(0.35)
							Dropdown.List.Visible = false
						end
						Debounce = false
						if not DropdownSettings.Ext then
							SaveConfiguration()
						end
					end)

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						DropdownOption.UIStroke.Color = SelectedTheme.ElementStroke
					end)
				end
			end
			SetDropdownOptions()

			for _, droption in ipairs(Dropdown.List:GetChildren()) do
				if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
					if not table.find(DropdownSettings.CurrentOption, droption.Name) then
						droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
					else
						droption.BackgroundColor3 = SelectedTheme.DropdownSelected
					end

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end)
				end
			end

			function DropdownSettings:Set(NewOption)
				DropdownSettings.CurrentOption = NewOption

				if typeof(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end

				if not DropdownSettings.MultipleOptions then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end

				if DropdownSettings.MultipleOptions then
					if #DropdownSettings.CurrentOption == 1 then
						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
					elseif #DropdownSettings.CurrentOption == 0 then
						Dropdown.Selected.Text = "None"
					else
						Dropdown.Selected.Text = "Various"
					end
				else
					Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
				end


				local Success, Response = pcall(function()
					DropdownSettings.Callback(NewOption)
				end)
				if not Success then
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Dropdown.Title.Text = "Callback Error"
					print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Dropdown.Title.Text = DropdownSettings.Name
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end
				end
				--SaveConfiguration()
			end

			function DropdownSettings:Refresh(optionsTable: table) -- updates a dropdown with new options from optionsTable
				DropdownSettings.Options = optionsTable
				for _, option in Dropdown.List:GetChildren() do
					if option.ClassName == "Frame" and option.Name ~= "Placeholder" then
						option:Destroy()
					end
				end
				SetDropdownOptions()
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and DropdownSettings.Flag then
					RayfieldLibrary.Flags[DropdownSettings.Flag] = DropdownSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			return DropdownSettings
		end

		-- Keybind
		function Tab:CreateKeybind(KeybindSettings)
			local CheckingForKey = false
			local Keybind = Elements.Template.Keybind:Clone()
			Keybind.Name = KeybindSettings.Name
			Keybind.Title.Text = KeybindSettings.Name
			Keybind.Visible = true
			Keybind.Parent = TabPage

			Keybind.BackgroundTransparency = 1
			Keybind.UIStroke.Transparency = 1
			Keybind.Title.TextTransparency = 1

			Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke

			TweenService:Create(Keybind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Keybind.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
			Keybind.KeybindFrame.Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)

			Keybind.KeybindFrame.KeybindBox.Focused:Connect(function()
				CheckingForKey = true
				Keybind.KeybindFrame.KeybindBox.Text = ""
			end)
			Keybind.KeybindFrame.KeybindBox.FocusLost:Connect(function()
				CheckingForKey = false
				if Keybind.KeybindFrame.KeybindBox.Text == nil or Keybind.KeybindFrame.KeybindBox.Text == "" then
					Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
					if not KeybindSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			Keybind.MouseEnter:Connect(function()
				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Keybind.MouseLeave:Connect(function()
				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			local connection = UserInputService.InputBegan:Connect(function(input, processed)
				if CheckingForKey then
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						local SplitMessage = string.split(tostring(input.KeyCode), ".")
						local NewKeyNoEnum = SplitMessage[3]
						Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeyNoEnum)
						KeybindSettings.CurrentKeybind = tostring(NewKeyNoEnum)
						Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
						if not KeybindSettings.Ext then
							SaveConfiguration()
						end

						if KeybindSettings.CallOnChange then
							KeybindSettings.Callback(tostring(NewKeyNoEnum))
						end
					end
				elseif not KeybindSettings.CallOnChange and KeybindSettings.CurrentKeybind ~= nil and (input.KeyCode == Enum.KeyCode[KeybindSettings.CurrentKeybind] and not processed) then -- Test
					local Held = true
					local Connection
					Connection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							Connection:Disconnect()
							Held = false
						end
					end)

					if not KeybindSettings.HoldToInteract then
						local Success, Response = pcall(KeybindSettings.Callback)
						if not Success then
							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Keybind.Title.Text = "Callback Error"
							print("Rayfield | "..KeybindSettings.Name.." Callback Error " ..tostring(Response))
							warn('Check docs.sirius.menu for help with Rayfield specific development.')
							task.wait(0.5)
							Keybind.Title.Text = KeybindSettings.Name
							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						end
					else
						task.wait(0.25)
						if Held then
							local Loop; Loop = RunService.Stepped:Connect(function()
								if not Held then
									KeybindSettings.Callback(false) -- maybe pcall this
									Loop:Disconnect()
								else
									KeybindSettings.Callback(true) -- maybe pcall this
								end
							end)
						end
					end
				end
			end)
			table.insert(keybindConnections, connection)

			Keybind.KeybindFrame.KeybindBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Keybind.KeybindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)}):Play()
			end)

			function KeybindSettings:Set(NewKeybind)
				Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeybind)
				KeybindSettings.CurrentKeybind = tostring(NewKeybind)
				Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
				if not KeybindSettings.Ext then
					SaveConfiguration()
				end

				if KeybindSettings.CallOnChange then
					KeybindSettings.Callback(tostring(NewKeybind))
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and KeybindSettings.Flag then
					RayfieldLibrary.Flags[KeybindSettings.Flag] = KeybindSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return KeybindSettings
		end

		-- Toggle
		function Tab:CreateToggle(ToggleSettings)
			local ToggleValue = {}

			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.BackgroundTransparency = 1
			Toggle.UIStroke.Transparency = 1
			Toggle.Title.TextTransparency = 1
			Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Toggle.Switch.Shadow.Visible = false
			end

			TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Toggle.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			if ToggleSettings.CurrentValue == true then
				Toggle.Switch.Indicator.Position = UDim2.new(1, -20, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
			else
				Toggle.Switch.Indicator.Position = UDim2.new(1, -40, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
			end

			Toggle.MouseEnter:Connect(function()
				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Toggle.MouseLeave:Connect(function()
				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Toggle.Interact.MouseButton1Click:Connect(function()
				if ToggleSettings.CurrentValue == true then
					ToggleSettings.CurrentValue = false
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				else
					ToggleSettings.CurrentValue = true
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()		
				end

				local Success, Response = pcall(function()
					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (Interact)') end

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end)

			function ToggleSettings:Set(NewToggleValue)
				if NewToggleValue == true then
					ToggleSettings.CurrentValue = true
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()	
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				else
					ToggleSettings.CurrentValue = false
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				end

				local Success, Response = pcall(function()
					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (:Set)') end

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end

			if not ToggleSettings.Ext then
				if Settings.ConfigurationSaving then
					if Settings.ConfigurationSaving.Enabled and ToggleSettings.Flag then
						RayfieldLibrary.Flags[ToggleSettings.Flag] = ToggleSettings
					end
				end
			end


			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Toggle.Switch.Shadow.Visible = false
				end

				task.wait()

				if not ToggleSettings.CurrentValue then
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
				else
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
				end
			end)

			return ToggleSettings
		end

		-- Slider
		function Tab:CreateSlider(SliderSettings)
			local SLDragging = false
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage

			Slider.BackgroundTransparency = 1
			Slider.UIStroke.Transparency = 1
			Slider.Title.TextTransparency = 1

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Slider.Main.Shadow.Visible = false
			end

			Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
			Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress

			TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Slider.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (SliderSettings.CurrentValue / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

			if not SliderSettings.Suffix then
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue)
			else
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue) .. " " .. SliderSettings.Suffix
			end

			Slider.MouseEnter:Connect(function()
				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Slider.MouseLeave:Connect(function()
				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Slider.Main.Interact.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					SLDragging = true 
				end 
			end)

			Slider.Main.Interact.InputEnded:Connect(function(Input) 
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
					SLDragging = false 
				end 
			end)

			Slider.Main.Interact.MouseButton1Down:Connect(function(X)
				local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
				local Start = Current
				local Location = X
				local Loop; Loop = RunService.Stepped:Connect(function()
					if SLDragging then
						Location = UserInputService:GetMouseLocation().X
						Current = Current + 0.025 * (Location - Start)

						if Location < Slider.Main.AbsolutePosition.X then
							Location = Slider.Main.AbsolutePosition.X
						elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current < Slider.Main.AbsolutePosition.X + 5 then
							Current = Slider.Main.AbsolutePosition.X + 5
						elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current <= Location and (Location - Start) < 0 then
							Start = Location
						elseif Current >= Location and (Location - Start) > 0 then
							Start = Location
						end
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Current - Slider.Main.AbsolutePosition.X, 1, 0)}):Play()
						local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

						NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000
						NewValue = math.clamp(NewValue, SliderSettings.Range[1], SliderSettings.Range[2])

						if not SliderSettings.Suffix then
							Slider.Main.Information.Text = tostring(NewValue)
						else
							Slider.Main.Information.Text = tostring(NewValue) .. " " .. SliderSettings.Suffix
						end

						if SliderSettings.CurrentValue ~= NewValue then
							local Success, Response = pcall(function()
								SliderSettings.Callback(NewValue)
							end)
							if not Success then
								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Slider.Title.Text = "Callback Error"
								print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
								warn('Check docs.sirius.menu for help with Rayfield specific development.')
								task.wait(0.5)
								Slider.Title.Text = SliderSettings.Name
								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							end

							SliderSettings.CurrentValue = NewValue
							if not SliderSettings.Ext then
								SaveConfiguration()
							end
						end
					else
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
						Loop:Disconnect()
					end
				end)
			end)

			function SliderSettings:Set(NewVal)
				local NewVal = math.clamp(NewVal, SliderSettings.Range[1], SliderSettings.Range[2])

				TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (NewVal / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
				Slider.Main.Information.Text = tostring(NewVal) .. " " .. (SliderSettings.Suffix or "")

				local Success, Response = pcall(function()
					SliderSettings.Callback(NewVal)
				end)

				if not Success then
					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Slider.Title.Text = "Callback Error"
					print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Slider.Title.Text = SliderSettings.Name
					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				SliderSettings.CurrentValue = NewVal
				if not SliderSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and SliderSettings.Flag then
					RayfieldLibrary.Flags[SliderSettings.Flag] = SliderSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Slider.Main.Shadow.Visible = false
				end

				Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
				Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress
			end)

			return SliderSettings
		end

		Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
			TabButton.UIStroke.Color = SelectedTheme.TabStroke

			if Elements.UIPageLayout.CurrentPage == TabPage then
				TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
				TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			else
				TabButton.BackgroundColor3 = SelectedTheme.TabBackground
				TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			end
		end)

		return Tab
	end

	Elements.Visible = true


	task.wait(1.1)
	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 390, 0, 90)}):Play()
	task.wait(0.3)
	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	task.wait(0.1)
	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

	Topbar.BackgroundTransparency = 1
	Topbar.Divider.Size = UDim2.new(0, 0, 0, 1)
	Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	Topbar.CornerRepair.BackgroundTransparency = 1
	Topbar.Title.TextTransparency = 1
	Topbar.Search.ImageTransparency = 1
	if Topbar:FindFirstChild('Settings') then
		Topbar.Settings.ImageTransparency = 1
	end
	Topbar.ChangeSize.ImageTransparency = 1
	Topbar.Hide.ImageTransparency = 1


	task.wait(0.5)
	Topbar.Visible = true
	TweenService:Create(Topbar, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	task.wait(0.1)
	TweenService:Create(Topbar.Divider, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, 1)}):Play()
	TweenService:Create(Topbar.Title, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(Topbar.Search, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.05)
	if Topbar:FindFirstChild('Settings') then
		TweenService:Create(Topbar.Settings, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
		task.wait(0.05)
	end
	TweenService:Create(Topbar.ChangeSize, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.05)
	TweenService:Create(Topbar.Hide, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.3)

	if dragBar then
		TweenService:Create(dragBarCosmetic, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
	end

	function Window.ModifyTheme(NewTheme)
		local success = pcall(ChangeTheme, NewTheme)
		if not success then
			RayfieldLibrary:Notify({Title = 'Unable to Change Theme', Content = 'We are unable find a theme on file.', Image = 4400704299})
		else
			RayfieldLibrary:Notify({Title = 'Theme Changed', Content = 'Successfully changed theme to '..(typeof(NewTheme) == 'string' and NewTheme or 'Custom Theme')..'.', Image = 4483362748})
		end
	end

	local success, result = pcall(function()
		createSettings(Window)
	end)

	if not success then warn('Rayfield had an issue creating settings.') end

	return Window
end

local function setVisibility(visibility: boolean, notify: boolean?)
	if Debounce then return end
	if visibility then
		Hidden = false
		Unhide()
	else
		Hidden = true
		Hide(notify)
	end
end

function RayfieldLibrary:SetVisibility(visibility: boolean)
	setVisibility(visibility, false)
end

function RayfieldLibrary:IsVisible(): boolean
	return not Hidden
end

local hideHotkeyConnection -- Has to be initialized here since the connection is made later in the script
function RayfieldLibrary:Destroy()
	rayfieldDestroyed = true
	hideHotkeyConnection:Disconnect()
	for _, connection in keybindConnections do
		connection:Disconnect()
	end
	Rayfield:Destroy()
end

Topbar.ChangeSize.MouseButton1Click:Connect(function()
	if Debounce then return end
	if Minimised then
		Minimised = false
		Maximise()
	else
		Minimised = true
		Minimise()
	end
end)

Main.Search.Input:GetPropertyChangedSignal('Text'):Connect(function()
	if #Main.Search.Input.Text > 0 then
		if not Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks') then 
			local searchTitle = Elements.Template.SectionTitle:Clone()
			searchTitle.Parent = Elements.UIPageLayout.CurrentPage
			searchTitle.Name = 'SearchTitle-fsefsefesfsefesfesfThanks'
			searchTitle.LayoutOrder = -100
			searchTitle.Title.Text = "Results from '"..Elements.UIPageLayout.CurrentPage.Name.."'"
			searchTitle.Visible = true
		end
	else
		local searchTitle = Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks')

		if searchTitle then
			searchTitle:Destroy()
		end
	end

	for _, element in ipairs(Elements.UIPageLayout.CurrentPage:GetChildren()) do
		if element.ClassName ~= 'UIListLayout' and element.Name ~= 'Placeholder' and element.Name ~= 'SearchTitle-fsefsefesfsefesfesfThanks' then
			if element.Name == 'SectionTitle' then
				if #Main.Search.Input.Text == 0 then
					element.Visible = true
				else
					element.Visible = false
				end
			else
				if string.lower(element.Name):find(string.lower(Main.Search.Input.Text), 1, true) then
					element.Visible = true
				else
					element.Visible = false
				end
			end
		end
	end
end)

Main.Search.Input.FocusLost:Connect(function(enterPressed)
	if #Main.Search.Input.Text == 0 and searchOpen then
		task.wait(0.12)
		closeSearch()
	end
end)

Topbar.Search.MouseButton1Click:Connect(function()
	task.spawn(function()
		if searchOpen then
			closeSearch()
		else
			openSearch()
		end
	end)
end)

if Topbar:FindFirstChild('Settings') then
	Topbar.Settings.MouseButton1Click:Connect(function()
		task.spawn(function()
			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			Elements.UIPageLayout:JumpTo(Elements['Rayfield Settings'])
		end)
	end)

end


Topbar.Hide.MouseButton1Click:Connect(function()
	setVisibility(Hidden, not useMobileSizing)
end)

hideHotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if (input.KeyCode == Enum.KeyCode[getSetting("General", "rayfieldOpen")]) and not processed then
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		else
			Hidden = true
			Hide()
		end
	end
end)

if MPrompt then
	MPrompt.Interact.MouseButton1Click:Connect(function()
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		end
	end)
end

for _, TopbarButton in ipairs(Topbar:GetChildren()) do
	if TopbarButton.ClassName == "ImageButton" and TopbarButton.Name ~= 'Icon' then
		TopbarButton.MouseEnter:Connect(function()
			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
		end)

		TopbarButton.MouseLeave:Connect(function()
			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
		end)
	end
end


function RayfieldLibrary:LoadConfiguration()
	local config

	if debugX then
		warn('Loading Configuration')
	end

	if useStudio then
		config = [[{"Toggle1adwawd":true,"ColorPicker1awd":{"B":255,"G":255,"R":255},"Slider1dawd":100,"ColorPicfsefker1":{"B":255,"G":255,"R":255},"Slidefefsr1":80,"dawdawd":"","Input1":"hh","Keybind1":"B","Dropdown1":["Ocean"]}]]
	end

	if CEnabled then
		local notified
		local loaded

		local success, result = pcall(function()
			if useStudio and config then
				loaded = LoadConfiguration(config)
				return
			end

			if isfile then 
				if callSafely(isfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension) then
					loaded = LoadConfiguration(callSafely(readfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension))
				end
			else
				notified = true
				RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We couldn't enable Configuration Saving as you are not using software with filesystem support.", Image = 4384402990})
			end
		end)

		if success and loaded and not notified then
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "The configuration file for this script has been loaded from a previous session.", Image = 4384403532})
		elseif not success and not notified then
			warn('Rayfield Configurations Error | '..tostring(result))
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We've encountered an issue loading your configuration correctly.\n\nCheck the Developer Console for more information.", Image = 4384402990})
		end
	end

	globalLoaded = true
end



if useStudio then
	-- run w/ studio
	-- Feel free to place your own script here to see how it'd work in Roblox Studio before running it on your execution software.


	--local Window = RayfieldLibrary:CreateWindow({
	--	Name = "Rayfield Example Window",
	--	LoadingTitle = "Rayfield Interface Suite",
	--	Theme = 'Default',
	--	Icon = 0,
	--	LoadingSubtitle = "by Sirius",
	--	ConfigurationSaving = {
	--		Enabled = true,
	--		FolderName = nil, -- Create a custom folder for your hub/game
	--		FileName = "Big Hub52"
	--	},
	--	Discord = {
	--		Enabled = false,
	--		Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
	--		RememberJoins = true -- Set this to false to make them join the discord every time they load it up
	--	},
	--	KeySystem = false, -- Set this to true to use our key system
	--	KeySettings = {
	--		Title = "Untitled",
	--		Subtitle = "Key System",
	--		Note = "No method of obtaining the key is provided",
	--		FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
	--		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
	--		GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
	--		Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
	--	}
	--})

	--local Tab = Window:CreateTab("Tab Example", 'key-round') -- Title, Image
	--local Tab2 = Window:CreateTab("Tab Example 2", 4483362458) -- Title, Image

	--local Section = Tab2:CreateSection("Section")


	--local ColorPicker = Tab2:CreateColorPicker({
	--	Name = "Color Picker",
	--	Color = Color3.fromRGB(255,255,255),
	--	Flag = "ColorPicfsefker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place every time the color picker is moved/changed
	--		-- The variable (Value) is a Color3fromRGB value based on which color is selected
	--	end
	--})

	--local Slider = Tab2:CreateSlider({
	--	Name = "Slider Example",
	--	Range = {0, 100},
	--	Increment = 10,
	--	Suffix = "Bananas",
	--	CurrentValue = 40,
	--	Flag = "Slidefefsr1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the slider changes
	--		-- The variable (Value) is a number which correlates to the value the slider is currently at
	--	end,
	--})

	--local Input = Tab2:CreateInput({
	--	Name = "Input Example",
	--	CurrentValue = '',
	--	PlaceholderText = "Input Placeholder",
	--	Flag = 'dawdawd',
	--	RemoveTextAfterFocusLost = false,
	--	Callback = function(Text)
	--		-- The function that takes place when the input is changed
	--		-- The variable (Text) is a string for the value in the text box
	--	end,
	--})


	----RayfieldLibrary:Notify({Title = "Rayfield Interface", Content = "Welcome to Rayfield. These - are the brand new notification design for Rayfield, with custom sizing and Rayfield calculated wait times.", Image = 4483362458})

	--local Section = Tab:CreateSection("Section Example")

	--local Button = Tab:CreateButton({
	--	Name = "Change Theme",
	--	Callback = function()
	--		-- The function that takes place when the button is pressed
	--		Window.ModifyTheme('DarkBlue')
	--	end,
	--})

	--local Toggle = Tab:CreateToggle({
	--	Name = "Toggle Example",
	--	CurrentValue = false,
	--	Flag = "Toggle1adwawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the toggle is pressed
	--		-- The variable (Value) is a boolean on whether the toggle is true or false
	--	end,
	--})

	--local ColorPicker = Tab:CreateColorPicker({
	--	Name = "Color Picker",
	--	Color = Color3.fromRGB(255,255,255),
	--	Flag = "ColorPicker1awd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place every time the color picker is moved/changed
	--		-- The variable (Value) is a Color3fromRGB value based on which color is selected
	--	end
	--})

	--local Slider = Tab:CreateSlider({
	--	Name = "Slider Example",
	--	Range = {0, 100},
	--	Increment = 10,
	--	Suffix = "Bananas",
	--	CurrentValue = 40,
	--	Flag = "Slider1dawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the slider changes
	--		-- The variable (Value) is a number which correlates to the value the slider is currently at
	--	end,
	--})

	--local Input = Tab:CreateInput({
	--	Name = "Input Example",
	--	CurrentValue = "Helo",
	--	PlaceholderText = "Adaptive Input",
	--	RemoveTextAfterFocusLost = false,
	--	Flag = 'Input1',
	--	Callback = function(Text)
	--		-- The function that takes place when the input is changed
	--		-- The variable (Text) is a string for the value in the text box
	--	end,
	--})

	--local thoptions = {}
	--for themename, theme in pairs(RayfieldLibrary.Theme) do
	--	table.insert(thoptions, themename)
	--end

	--local Dropdown = Tab:CreateDropdown({
	--	Name = "Theme",
	--	Options = thoptions,
	--	CurrentOption = {"Default"},
	--	MultipleOptions = false,
	--	Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Options)
	--		--Window.ModifyTheme(Options[1])
	--		-- The function that takes place when the selected option is changed
	--		-- The variable (Options) is a table of strings for the current selected options
	--	end,
	--})


	--Window.ModifyTheme({
	--	TextColor = Color3.fromRGB(50, 55, 60),
	--	Background = Color3.fromRGB(240, 245, 250),
	--	Topbar = Color3.fromRGB(215, 225, 235),
	--	Shadow = Color3.fromRGB(200, 210, 220),

	--	NotificationBackground = Color3.fromRGB(210, 220, 230),
	--	NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

	--	TabBackground = Color3.fromRGB(200, 210, 220),
	--	TabStroke = Color3.fromRGB(180, 190, 200),
	--	TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
	--	TabTextColor = Color3.fromRGB(50, 55, 60),
	--	SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

	--	ElementBackground = Color3.fromRGB(210, 220, 230),
	--	ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
	--	SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
	--	ElementStroke = Color3.fromRGB(190, 200, 210),
	--	SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

	--	SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
	--	SliderProgress = Color3.fromRGB(70, 130, 180),
	--	SliderStroke = Color3.fromRGB(150, 180, 220),

	--	ToggleBackground = Color3.fromRGB(210, 220, 230),
	--	ToggleEnabled = Color3.fromRGB(70, 160, 210),
	--	ToggleDisabled = Color3.fromRGB(180, 180, 180),
	--	ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
	--	ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
	--	ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
	--	ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

	--	DropdownSelected = Color3.fromRGB(220, 230, 240),
	--	DropdownUnselected = Color3.fromRGB(200, 210, 220),

	--	InputBackground = Color3.fromRGB(220, 230, 240),
	--	InputStroke = Color3.fromRGB(180, 190, 200),
	--	PlaceholderColor = Color3.fromRGB(150, 150, 150)
	--})

	--local Keybind = Tab:CreateKeybind({
	--	Name = "Keybind Example",
	--	CurrentKeybind = "Q",
	--	HoldToInteract = false,
	--	Flag = "Keybind1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Keybind)
	--		-- The function that takes place when the keybind is pressed
	--		-- The variable (Keybind) is a boolean for whether the keybind is being held or not (HoldToInteract needs to be true)
	--	end,
	--})

	--local Label = Tab:CreateLabel("Label Example")

	--local Label2 = Tab:CreateLabel("Warning", 4483362458, Color3.fromRGB(255, 159, 49),  true)

	--local Paragraph = Tab:CreateParagraph({Title = "Paragraph Example", Content = "Paragraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph Example"})
end

if CEnabled and Main:FindFirstChild('Notice') then
	Main.Notice.BackgroundTransparency = 1
	Main.Notice.Title.TextTransparency = 1
	Main.Notice.Size = UDim2.new(0, 0, 0, 0)
	Main.Notice.Position = UDim2.new(0.5, 0, 0, -100)
	Main.Notice.Visible = true


	TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 280, 0, 35), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 0.5}):Play()
	TweenService:Create(Main.Notice.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.1}):Play()
end
-- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA why :(
--if not useStudio then
--	task.spawn(loadWithTimeout, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/boost.lua")
--end

task.delay(4, function()
	RayfieldLibrary.LoadConfiguration()
	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
		TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
		TweenService:Create(Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.wait(0.5)
		Main.Notice.Visible = false
	end
end)

return RayfieldLibrary
end)()

-- Store references to UI elements that need to be updated programmatically
local UI = {}

-- Custom Control Button (Minimize / Show)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until Rayfield

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

    local isVisible = true

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
        isVisible = not isVisible
        if isVisible then
            Window:Toggle()  -- Show window
        else
            Window:Toggle()  -- Hide window
        end
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

-- Main Window
local Window = Rayfield:CreateWindow({
    Name = "Ultimate Battlegrounds",
    LoadingTitle = "Ultimate Battlegrounds",
    LoadingSubtitle = "by elton",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EltonsHub/Saves/Ultimate Battlegrounds1",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key",
        Subtitle = "Enter Key",
        Note = "",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = ""
    }
})

-- Tabs
local Tabs = {}
Tabs.Main = Window:CreateTab("Main", "")      -- Icon asset ID optional
Tabs.Rage = Window:CreateTab("Rage", "")
Tabs.Movement = Window:CreateTab("Movement", "")
Tabs.Farm = Window:CreateTab("Farm", "")
Tabs.Cosmetics = Window:CreateTab("Cosmetics/Emotes", "")
Tabs.Misc = Window:CreateTab("Misc", "")
Tabs.Settings = Window:CreateTab("Settings", "")

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

-- ========== MAIN TAB ==========
Tabs.Main:CreateSection("Hitbox Settings")

UI.HitboxToggle = Tabs.Main:CreateToggle({
    Name = "Hitbox Extender",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        if Value then
            enableHitbox()
        else
            disableHitbox()
        end
    end
})

local LockHitbox = false

UI.HitboxSizeInput = Tabs.Main:CreateInput({
    Name = "Hitbox Size",
    PlaceholderText = "15",
    CurrentValue = "15",
    Numeric = true,
    Flag = "HitboxSizeInput",
    Callback = function(Value)
        if LockHitbox then return end
        local size = tonumber(Value) or 15
        size = math.clamp(size, 1, 100)
        if size ~= tonumber(Value) then
            LockHitbox = true
            UI.HitboxSizeInput:Set(tostring(size))
            LockHitbox = false
        end
        setHitboxSize(size)
    end
})

UI.HitboxKeybind = Tabs.Main:CreateKeybind({
    Name = "Hitbox Keybind",
    CurrentKeybind = "",
    Flag = "HitboxKeybind",
    Callback = function(Keybind)
        -- When keybind is pressed, we toggle the hitbox toggle
        UI.HitboxToggle:Set(not UI.HitboxToggle.CurrentValue)
    end
})

Tabs.Main:CreateSection("Other Settings")

UI.DisableCombatTimer = Tabs.Main:CreateToggle({
    Name = "Disable Combat Timer",
    CurrentValue = false,
    Flag = "DisableCombatTimer",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("DisableCombatTimer").Value = Value
    end
})

UI.DisableFinishers = Tabs.Main:CreateToggle({
    Name = "Disable Finishers",
    CurrentValue = false,
    Flag = "DisableFinishers",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("DisableFinishers").Value = Value
    end
})

UI.DisableHitStun = Tabs.Main:CreateToggle({
    Name = "Disable Hit Stun",
    CurrentValue = false,
    Flag = "DisableHitStun",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("DisableHitStun").Value = Value
    end
})

UI.Longerultimate = Tabs.Main:CreateToggle({
    Name = "Longer ultimate",
    CurrentValue = false,
    Flag = "Longerultimate",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("Endless").Value = Value
    end
})

UI.Instantultimate = Tabs.Main:CreateToggle({
    Name = "Instant ultimate",
    CurrentValue = false,
    Flag = "Instantultimate",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("InstantTransformation").Value = Value
    end
})

UI.MultiCutscene = Tabs.Main:CreateToggle({
    Name = "Multi Cutscene",
    CurrentValue = false,
    Flag = "MultiCutscene",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("MultiUseCutscenes").Value = Value
    end
})

UI.NoJumpFatigue = Tabs.Main:CreateToggle({
    Name = "No Jump Fatigue",
    CurrentValue = false,
    Flag = "NoJumpFatigue",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("NoJumpFatigue").Value = Value
    end
})

UI.NoSlowdowns = Tabs.Main:CreateToggle({
    Name = "No Slowdowns",
    CurrentValue = false,
    Flag = "NoSlowdowns",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("NoSlowdowns").Value = Value
    end
})

UI.NoStunOnMiss = Tabs.Main:CreateToggle({
    Name = "No Stun On Miss",
    CurrentValue = false,
    Flag = "NoStunOnMiss",
    Callback = function(Value)
        Folders.Toggles:WaitForChild("NoStunOnMiss").Value = Value
    end
})

-- ========== RAGE TAB ==========
Tabs.Rage:CreateSection("Kill Aura Settings")

UI.KillAuraToggle = Tabs.Rage:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
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

UI.IgnoreFriendsToggle = Tabs.Rage:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Flag = "IgnoreFriendsToggle",
    Callback = function(Value)
        KillAuraConfig.IgnoreFriends = Value
    end
})

Tabs.Rage:CreateSection("Damage Multiplier Settings")

UI.KillAuraOnHitToggle = Tabs.Rage:CreateToggle({
    Name = "Damage Multiplier",
    CurrentValue = false,
    Flag = "KillAuraOnHitToggle",
    Callback = function(Value)
        KillAuraConfig.KillAuraOnHit = Value
    end
})

local Lock = false

UI.KillAuraHitMultiplierInput = Tabs.Rage:CreateInput({
    Name = "Multiplier",
    PlaceholderText = "1",
    CurrentValue = "1",
    Numeric = true,
    Flag = "KillAuraHitMultiplier",
    Callback = function(Value)
        if Lock then return end
        local v = tonumber(Value) or 1
        v = math.clamp(v, 1, 50)
        if v ~= tonumber(Value) then
            Lock = true
            UI.KillAuraHitMultiplierInput:Set(tostring(v))
            Lock = false
        end
        KillAuraConfig.KillAuraHitMultiplier = v
    end
})

Tabs.Rage:CreateSection("God Mode")

local GodModeConfig = {
    GodMode = false,
    GodModev2 = false
}

UI.GodModeToggle = Tabs.Rage:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodModeToggle",
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

UI.AutoTargetToggle = Tabs.Rage:CreateToggle({
    Name = "God Mode v2 (Ranked)",
    CurrentValue = false,
    Flag = "AutoTargetToggle",
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

Tabs.Rage:CreateSection("Lag Server")

local LagServerConfig = {
    LagServer = false
}

UI.LagServerToggle = Tabs.Rage:CreateToggle({
    Name = "Lag Server",
    CurrentValue = false,
    Flag = "LagServerToggle",
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

UI.AbilitySpamToggle = Tabs.Rage:CreateToggle({
    Name = "Lag Server V2",
    CurrentValue = false,
    Flag = "AbilitySpamToggle",
    Callback = function(Value)
        local mob = game:GetService("Players").LocalPlayer.Data.Character.Value

        if Value then
            if mob ~= "Mob" then
                MobRemote:FireServer("Mob")
            end
            AbilitySpam:Start()
        else
            AbilitySpam:Stop()
        end
    end
})

Tabs.Rage:CreateSection("WallCombo")

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

UI.WallComboMethod = Tabs.Rage:CreateDropdown({
    Name = "WallCombo Method",
    Options = {"Method 1", "Method 2"},
    CurrentOption = "Method 1",
    Flag = "WallComboMethod",
    Callback = function(Value)
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
    end
})

UI.wallcomboTogg = Tabs.Rage:CreateToggle({
    Name = "Spam WallCombo",
    CurrentValue = false,
    Flag = "WallcomboToggle",
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

UI.Wallcombobind = Tabs.Rage:CreateKeybind({
    Name = "WallCombo Keybind",
    CurrentKeybind = "",
    Flag = "Wallcombobind",
    Callback = function(Keybind)
        UI.wallcomboTogg:Set(not UI.wallcomboTogg.CurrentValue)
    end
})

UI.WallComboIgnoreFriendsToggle = Tabs.Rage:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Flag = "WallComboIgnoreFriendsToggle",
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

Tabs.Movement:CreateButton({
    Name = "Reset Character",
    Callback = function()
        resetCharacterForced()
    end
})

UI.Dashcooldown = Tabs.Movement:CreateInput({
    Name = "Dash cooldown",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "Dashcooldown",
    Callback = function(Value)
        Folders.Cooldowns:WaitForChild("Dash").Value = tonumber(Value) or 0
    end
})

UI.DashSpeed = Tabs.Movement:CreateInput({
    Name = "Dash Speed",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "DashSpeed",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("DashSpeed").Value = tonumber(Value) or 0
    end
})

UI.JumpHeight = Tabs.Movement:CreateInput({
    Name = "Jump Height",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "JumpHeight",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("JumpHeight").Value = tonumber(Value) or 0
    end
})

UI.RunSpeed = Tabs.Movement:CreateInput({
    Name = "Run Speed",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "RunSpeed",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("RunSpeed").Value = tonumber(Value) or 0
    end
})

UI.WalkSpeed = Tabs.Movement:CreateInput({
    Name = "Walk Speed",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "WalkSpeed",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("WalkSpeed").Value = tonumber(Value) or 0
    end
})

UI.RagdollPower = Tabs.Movement:CreateInput({
    Name = "Ragdoll Power",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "RagdollPower",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("RagdollPower").Value = tonumber(Value) or 0
    end
})

UI.MeleeSpeed = Tabs.Movement:CreateInput({
    Name = "Melee Speed",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "MeleeSpeed",
    Callback = function(Value)
        Folders.Multipliers:WaitForChild("MeleeSpeed").Value = tonumber(Value) or 0
    end
})

UI.MeleeCooldown = Tabs.Movement:CreateInput({
    Name = "Melee cooldown",
    PlaceholderText = "Default is 100",
    CurrentValue = "100",
    Numeric = true,
    Flag = "MeleeCooldown",
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

    UI.TPWalkSpeed = Tabs.Movement:CreateInput({
        Name = "TP Walk Speed",
        PlaceholderText = "...",
        CurrentValue = "0",
        Numeric = true,
        Flag = "TPWalkSpeed",
        Callback = function(Value)
            local speed = tonumber(Value) or 0
            tpwalkSpeed = speed
        end
    })

    UI.tpwalkToggle = Tabs.Movement:CreateToggle({
        Name = "TP Walk",
        CurrentValue = false,
        Flag = "TPWalkToggle",
        Callback = function(Value)
            tpwalkActive = Value
        end
    })

    UI.TPWalkBind = Tabs.Movement:CreateKeybind({
        Name = "TP Walk Keybind",
        CurrentKeybind = "",
        Flag = "TPWalkBind",
        Callback = function(Keybind)
            UI.tpwalkToggle:Set(not UI.tpwalkToggle.CurrentValue)
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

    Tabs.Farm:CreateSection("Player Teleport")

    UI.FarmPlayerDropdown = Tabs.Farm:CreateDropdown({
        Name = "Select Player",
        Options = getPlayerList(),
        CurrentOption = getPlayerList()[1] or "No players",
        Flag = "FarmPlayerDropdown",
        Callback = function(Value)
            selectedFarmPlayer = getPlayerByName(Value)
        end
    })

    local initialList = getPlayerList()
    if initialList[1] ~= "No players" then
        selectedFarmPlayer = getPlayerByName(initialList[1])
    end

    Tabs.Farm:CreateButton({
        Name = "Refresh List",
        Callback = function()
            local newList = getPlayerList()
            UI.FarmPlayerDropdown:Set(newList)
            if selectedFarmPlayer and selectedFarmPlayer.Parent then
                UI.FarmPlayerDropdown:Set(selectedFarmPlayer.Name)
            else
                selectedFarmPlayer = getPlayerByName(newList[1])
            end
        end
    })

    Tabs.Farm:CreateButton({
        Name = "Teleport to Selected Player",
        Callback = function()
            if selectedFarmPlayer then
                teleportExact(selectedFarmPlayer)
            end
        end
    })

    UI.FarmLoopToggle = Tabs.Farm:CreateToggle({
        Name = "Loop Teleport",
        CurrentValue = false,
        Flag = "FarmLoopToggle",
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

    Tabs.Farm:CreateSection("Auto Farm")

    UI.AutoFarmToggle = Tabs.Farm:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Flag = "AutoFarmToggle",
        Callback = function(Value)
            autoFarmEnabled = Value

            if Value then
                UI.KillAuraToggle:Set(true)
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
                            Rayfield:Notify({
                                Title = "Not Found Target",
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
                UI.KillAuraToggle:Set(false)
            end
        end
    })

    Tabs.Farm:CreateSection("Server Hop")

    local ServerHopConfig = {
        serverHopEnabled = false,
        serverHopDelay = 30,
        serverHopThread = nil
    }

    local LockHop = false

    UI.ServerHopDelay = Tabs.Farm:CreateInput({
        Name = "Server Hop Delay (seconds)",
        PlaceholderText = "30",
        CurrentValue = "30",
        Numeric = true,
        Flag = "ServerHopDelay",
        Callback = function(Value)
            if LockHop then return end
            local v = tonumber(Value) or 30
            if v < 1 then
                LockHop = true
                UI.ServerHopDelay:Set("1")
                ServerHopConfig.serverHopDelay = 1
                LockHop = false
            else
                ServerHopConfig.serverHopDelay = v
            end
        end
    })

    UI.ServerHopToggle = Tabs.Farm:CreateToggle({
        Name = "Server Hop",
        CurrentValue = false,
        Flag = "ServerHopToggle",
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
        UI.FarmPlayerDropdown:Set(getPlayerList())
    end)

    Players.PlayerRemoving:Connect(function(player)
        if selectedFarmPlayer == player then
            selectedFarmPlayer = nil
        end
        UI.FarmPlayerDropdown:Set(getPlayerList())
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

Tabs.Cosmetics:CreateSection("Kill Emotes")

UI.KillEmoteDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Select Kill Emote",
    Options = EMOTES.Kill,
    CurrentOption = "None",
    Flag = "KillEmoteDropdown",
    Callback = function(Value)
        SelectedKillEmote = Value
    end
})

UI.KillEmoteSlotDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Kill Emote Slot",
    Options = {"Slot 1", "Slot 2", "Slot 3", "Slot 4"},
    CurrentOption = "Slot 1",
    Flag = "KillEmoteSlotDropdown",
    Callback = function(Value)
        SelectedKillEmoteSlot = tonumber(Value:match("%d+"))
    end
})

Tabs.Cosmetics:CreateButton({
    Name = "Apply Kill Emote",
    Callback = function()
        ApplyKillEmote()
    end
})

Tabs.Cosmetics:CreateSection("Spam Kill Emote")

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

UI.KillEmoteSpamDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Select Kill Emote",
    Options = killEmotesList,
    CurrentOption = "None",
    Flag = "KillEmoteSpamDropdown",
    Callback = function(Value)
        EmotesConfg.selectedKillEmoteForSpam = Value
    end
})

UI.SpamRandomToggle = Tabs.Cosmetics:CreateToggle({
    Name = "Spam Random Kill Emotes",
    CurrentValue = false,
    Flag = "SpamRandomKillEmote",
    Callback = function(Value)
        EmotesConfg.isSpammingRandomKillEmote = Value
    end
})

UI.SpamSelectedToggle = Tabs.Cosmetics:CreateToggle({
    Name = "Spam Selected Kill Emote",
    CurrentValue = false,
    Flag = "SpamSelectedKillEmote",
    Callback = function(Value)
        EmotesConfg.isSpammingSelectedKillEmote = Value
    end
})

UI.ToggleRandomSpamBind = Tabs.Cosmetics:CreateKeybind({
    Name = "Toggle Random Spam Keybind",
    CurrentKeybind = "",
    Flag = "ToggleRandomSpamBind",
    Callback = function(Keybind)
        UI.SpamRandomToggle:Set(not UI.SpamRandomToggle.CurrentValue)
    end
})

UI.ToggleSelectedSpamBind = Tabs.Cosmetics:CreateKeybind({
    Name = "Toggle Selected Spam Keybind",
    CurrentKeybind = "",
    Flag = "ToggleSelectedSpamBind",
    Callback = function(Keybind)
        UI.SpamSelectedToggle:Set(not UI.SpamSelectedToggle.CurrentValue)
    end
})

local LockRandom = false
UI.RandomSpamDelay = Tabs.Cosmetics:CreateInput({
    Name = "Random Spam Delay (ms)",
    PlaceholderText = "50",
    CurrentValue = "50",
    Numeric = true,
    Flag = "RandomSpamDelay",
    Callback = function(Value)
        if LockRandom then return end
        local v = tonumber(Value) or 50
        if v > 1000 then
            LockRandom = true
            UI.RandomSpamDelay:Set("1000")
            EmotesConfg.randomSpamDelay = 1
            LockRandom = false
        elseif v < 1 then
            LockRandom = true
            UI.RandomSpamDelay:Set("1")
            EmotesConfg.randomSpamDelay = 0.001
            LockRandom = false
        else
            EmotesConfg.randomSpamDelay = v / 1000
        end
    end
})

local LockSelected = false
UI.SelectedSpamDelay = Tabs.Cosmetics:CreateInput({
    Name = "Selected Spam Delay (ms)",
    PlaceholderText = "50",
    CurrentValue = "50",
    Numeric = true,
    Flag = "SelectedSpamDelay",
    Callback = function(Value)
        if LockSelected then return end
        local v = tonumber(Value) or 50
        if v > 1000 then
            LockSelected = true
            UI.SelectedSpamDelay:Set("1000")
            EmotesConfg.selectedSpamDelay = 1
            LockSelected = false
        elseif v < 1 then
            LockSelected = true
            UI.SelectedSpamDelay:Set("1")
            EmotesConfg.selectedSpamDelay = 0.001
            LockSelected = false
        else
            EmotesConfg.selectedSpamDelay = v / 1000
        end
    end
})

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

Tabs.Cosmetics:CreateSection("Cosmetics")

UI.AccessoryDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Accessories",
    Options = COSMETICS.Accessories,
    CurrentOption = "None",
    Flag = "AccessoryDropdown",
    Callback = function(Value)
        SelectedAccessory = Value
    end
})

Tabs.Cosmetics:CreateButton({
    Name = "Apply Accessory",
    Callback = function()
        ApplyCosmetic("Accessories")
    end
})

UI.AuraDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Auras",
    Options = COSMETICS.Auras,
    CurrentOption = "None",
    Flag = "AuraDropdown",
    Callback = function(Value)
        SelectedAura = Value
    end
})

Tabs.Cosmetics:CreateButton({
    Name = "Apply Aura",
    Callback = function()
        ApplyCosmetic("Auras")
    end
})

UI.CapeDropdown = Tabs.Cosmetics:CreateDropdown({
    Name = "Capes",
    Options = COSMETICS.Capes,
    CurrentOption = "None",
    Flag = "CapeDropdown",
    Callback = function(Value)
        SelectedCape = Value
    end
})

Tabs.Cosmetics:CreateButton({
    Name = "Apply Cape",
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

UI.RespawnAtDeathToggle = Tabs.Misc:CreateToggle({
    Name = "Respawn at Death Position",
    CurrentValue = false,
    Flag = "RespawnAtDeathToggle",
    Callback = function(Value)
        RespawnAtDeathEnabled = Value
        if not Value then
            deathPosition = nil
        end
    end
})

UI.AutoResetToggle = Tabs.Misc:CreateToggle({
    Name = "Fast spawn",
    CurrentValue = false,
    Flag = "AutoResetToggle",
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

UI.InvisibilityToggle = Tabs.Misc:CreateToggle({
    Name = "Invisibility",
    CurrentValue = false,
    Flag = "InvisibilityToggle",
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

    Tabs.Misc:CreateSection("ESP Settings")

    UI.RagdollESPToggle = Tabs.Misc:CreateToggle({
        Name = "Ragdoll Timer ESP",
        CurrentValue = false,
        Flag = "RagdollESPToggle",
        Callback = function(Value)
            RagdollESPEnabled = Value
            
            if Value then
                startRagdollESP()
            else
                stopRagdollESP()
            end
        end
    })

    UI.EvasiveESPToggle = Tabs.Misc:CreateToggle({
        Name = "Evasive Cooldown ESP",
        CurrentValue = false,
        Flag = "EvasiveESPToggle",
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

-- ========== SETTINGS TAB ==========
local QueueRegistered = false

UI.AutoLoadToggle = Tabs.Settings:CreateToggle({
    Name = "Auto Load Script",
    CurrentValue = false,
    Flag = "AutoLoadToggle",
    Callback = function(Value)
        if Value and not QueueRegistered then
            queue_on_teleport(
                'loadstring(game:HttpGet("https://loader-navy.vercel.app/api/raw/4359abeaca6aba76aa6cf435ddff8423"))()'
            )
            QueueRegistered = true
        elseif not Value then
            QueueRegistered = false
        end
    end
})

-- Load configuration
Rayfield:LoadConfiguration()

-- Autoload delete prompt (unchanged)
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
