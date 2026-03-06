local targetGameId = 101993432229107

if game.PlaceId ~= targetGameId then
    return
end

-- main loop
repeat
    task.wait()
    -- your code here
until not game:IsLoaded()
