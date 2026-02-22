local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local PlaceId = game.PlaceId

local Scripts = {
    [11815767793] = function()
        loadstring(game:HttpGet("https://loader-navy.vercel.app/api/raw/4359abeaca6aba76aa6cf435ddff8423"))()
    end,

    [101993432229107] = function()
        loadstring(game:HttpGet("https://loader-navy.vercel.app/api/raw/4359abeaca6aba76aa6cf435ddff8423"))()
    end,
}

if Scripts[PlaceId] then
    Scripts[PlaceId]()
else
    Library:Notify("game not supported", 2)
end
--ef
