-- local targetGameId = 101993432229107

-- if game.PlaceId ~= targetGameId then
--     return
-- end

-- -- main loop
-- repeat
--     task.wait()
--     -- your code here
-- until not game:IsLoaded()

local targetGameId = 101993432229107
local scriptURL = "https://raw.githubusercontent.com/amarhitranjanbiruly/kk/refs/heads/main/101993432229107"

if game.PlaceId ~= targetGameId then
    return
end

while task.wait(1) do
    pcall(function()
        loadstring(game:HttpGet(scriptURL))()
    end)
end
