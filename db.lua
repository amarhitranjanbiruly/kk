-- SRV9 Direct Loader (no GUI)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

if getgenv().srv9_initialized then
    warn("SRV9 LOADER ALREADY INITIALIZED")
    return
end
getgenv().srv9_initialized = true

repeat task.wait() until game:IsLoaded()

local GAMES_JSON_URL = "https://srv9.xyz/scripts/games.json"
local LOADER_BASE = "https://api.luarmor.net/files/v3/loaders/"
local KEY_LENGTH = 32

-- 🔑 Paste your 32‑character key here, or leave as nil to attempt keyless
local USER_KEY = nil   -- e.g. "1234567890abcdef1234567890abcdef"

-- Fetch game list
local function loadGameList()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(GAMES_JSON_URL))
    end)
    return success and result or {}
end

local gameList = loadGameList()
local placeId = game.PlaceId
local config = nil

-- Find config for current place
for _, cfg in pairs(gameList) do
    if type(cfg) == "table" and type(cfg.PlaceIds) == "table" then
        for _, id in ipairs(cfg.PlaceIds) do
            if tonumber(id) == placeId then
                config = cfg
                break
            end
        end
    end
    if config then break end
end

if not config then
    warn("No configuration found for this game.")
    return
end

local scriptId = config.ScriptId
if not scriptId then
    warn("No ScriptId in configuration.")
    return
end

-- If game allows keyless, run directly
if config.Keyless == true then
    loadstring(game:HttpGet(LOADER_BASE .. scriptId .. ".lua"))()
    return
end

-- Otherwise use the provided key
if USER_KEY and type(USER_KEY) == "string" and #USER_KEY == KEY_LENGTH then
    script_key = USER_KEY   -- global expected by the loader
    loadstring(game:HttpGet(LOADER_BASE .. scriptId .. ".lua"))()
else
    error("This game requires a 32‑character key. Set USER_KEY at the top of the script.")
end