local Character: Model? = game:GetService("Players").LocalPlayer.Character

if (not Character) then
    return notify("Make sure your fully loaded in before running this", "Promethium", 10)
end

local SecondaryAmmo = Character:FindFirstChild("SecondaryAmmo", true)
local PrimaryAmmo = Character:FindFirstChild("PrimaryAmmo", true)
local MaxStamina = Character:FindFirstChild("MaxStamina", true)
local Stamina = Character:FindFirstChild("Stamina", true)

if (not SecondaryAmmo) or (not PrimaryAmmo) or (not MaxStamina) or (not Stamina) then
    return notify("Make sure your in game before running this", "Promethium", 10)
end

local OldSecondaryAmmo = SecondaryAmmo.Value
local OldPrimaryAmmo = PrimaryAmmo.Value
local OldMaxStamina = MaxStamina.Value
local OldStamina = Stamina.Value

-- for some reason if u change it enough the game just stops trying to change it
game:GetService("RunService").RenderStepped:Connect(function()
    if (UI.GetValue("InfAmmo")) then
        Character.SecondaryAmmo.Value = 67
        Character.PrimaryAmmo.Value = 67
    end
end)

UI.AddTab("Notoriety", function(Tab)
    local Mods = Tab:Section("Mods", "Left")

    Mods:Toggle("InfStamina", "Inf Stamina", function(Value)
        if (not Value) then
            Character.MaxStamina.Value = OldMaxStamina
            Character.Stamina.Value = OldStamina
        else
            Character.MaxStamina.Value = 9e9
            Character.Stamina.Value = 9e9
        end
    end)

    Mods:Toggle("InfAmmo", "Inf Ammo", function(Value)
        if (not Value) then
            Character.SecondaryAmmo.Value = OldSecondaryAmmo
            Character.PrimaryAmmo.Value = OldPrimaryAmmo
        end
    end)
end)
