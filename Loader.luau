local Repository = "https://raw.githubusercontent.com/pubmain/LinoriaLib/refs/heads/main/"

local Library = loadstring(game:HttpGet(`{Repository}Library.lua`))()
local ThemeManager = loadstring(game:HttpGet(`{Repository}addons/ThemeManager.lua`))()
local SaveManager = loadstring(game:HttpGet(`{Repository}addons/SaveManager.lua`))()

local Options = Library.Options

local HttpService = game:GetService("HttpService")

local ScriptNames = {}
local ScriptData = {}

local Success, Results = pcall(function()
    return HttpService:JSONDecode(game:HttpGet("https://api.github.com/repos/kylosilly/Promethium-bin/contents/Main/Scripts"))
end)

if (not Success) then
    return Library:Notify("You are currently rate limited. Please try running the script in a few minutes.")
end

for _, Data in (Results) do
    local OriginalScriptName = Data.name

    if (not OriginalScriptName:find(".luau")) then
        continue
    end

    local ScriptName = OriginalScriptName:gsub(".luau", "")

    ScriptData[ScriptName] = Data.download_url
    table.insert(ScriptNames, ScriptName)
end

local Window = Library:CreateWindow({
	Title = "Loader",
	Center = true,
	AutoShow = true,
	Resizable = true,       
	ShowCustomCursor = true,
	UnlockMouseWhileOpen = true,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Settings = Window:AddTab("Settings")
}

local Loader = Tabs.Main:AddLeftGroupbox("Loader")

Loader:AddDropdown("Selected Script", {
    Values = ScriptNames,
    Default = "",
    Multi = false,
    Text = "Select Script:"
})
Loader:AddButton("Load Script", function()
    local SelectedScript = Options["Selected Script"].Value

    if (not SelectedScript) or (SelectedScript == "") then
        return Library:Notify("Please select a script!")
    end

    Library:Unload()
    loadstring(game:HttpGet(ScriptData[SelectedScript]))()
end)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Promethium")
SaveManager:SetFolder("Promethium/Loader")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
