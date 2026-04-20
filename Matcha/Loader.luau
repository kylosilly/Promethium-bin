local Script = game:HttpGet(`https://raw.githubusercontent.com/kylosilly/Promethium-bin/refs/heads/main/Matcha/Games/{game.GameId}.luau`)

if (not Script) then
    return notify("Game not supported", "Promethium", 10)
end

loadstring(Script)()