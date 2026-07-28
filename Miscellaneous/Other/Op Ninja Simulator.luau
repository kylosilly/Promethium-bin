local Repository = "https://raw.githubusercontent.com/pubmain/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(`{Repository}Library.lua`))()
local ThemeManager = loadstring(game:HttpGet(`{Repository}addons/ThemeManager.lua`))()
local SaveManager = loadstring(game:HttpGet(`{Repository}addons/SaveManager.lua`))()

local Options = Library.Options

if (game.PlaceId ~= 4225025295) then
    return Library:Notify("Invalid Place Id")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local NetworkClient = game:GetService("NetworkClient")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local LocalCharacter
local Humanoid

local PersonalRemoteService = assert(require(ReplicatedStorage:FindFirstChild("PersonalRemoteService", true)), "PersonalRemoteService not found")
local PlayerDataService = assert(require(ReplicatedStorage:FindFirstChild("PlrDataService", true)), "PlayerDataService not found")
local ShurikenService = assert(require(ReplicatedStorage:FindFirstChild("ShurikenService", true)), "ShurikenService not found")
local AscensionService = assert(require(ReplicatedStorage:FindFirstChild("AscensionService", true)), "AscensionService not found")
local UpgradeRules = assert(require(ReplicatedStorage:FindFirstChild("UpgradeRules", true)), "UpgradeRules not found")
local ToolsService = assert(require(ReplicatedStorage:FindFirstChild("ToolsService", true)), "ToolsService not found")
local ClassService = assert(require(ReplicatedStorage:FindFirstChild("ClassService", true)), "ClassService not found")
local SwordService = assert(require(ReplicatedStorage:FindFirstChild("SwordService", true)), "SwordService not found")
local SuccessRate = assert(require(ReplicatedStorage:FindFirstChild("SuccessRate", true)), "SuccessRate not found")
local BucksConfig = assert(require(ReplicatedStorage:FindFirstChild("BucksConfig", true)), "BucksConfig not found")
local UIService = assert(require(ReplicatedStorage:FindFirstChild("UIService", true)), "UIService not found")
local UIFormat = assert(require(ReplicatedStorage:FindFirstChild("UIFormat", true)), "UIFormet not found") -- ToScientificNotation

local UIServiceInvokePersonalRemote = assert(UIService.InvokePersonalRemote, "InvokePersonalRemote for UIService not found")
local GetFinalSuccessRate = assert(SuccessRate.GetFinalSuccessRate, "GetFinalSuccessRate not found")
local RemoteEvent = assert(PersonalRemoteService.RemoteEvent, "RemoteEvent not found")
local GetSuccessRate = assert(SuccessRate.GetSuccessRate, "GetSuccessRate not found")
local PlayerData = assert(PlayerDataService.PlrData, "PlayerData not found")

local Webhook = {}; do
    Webhook.WebhookFooter = { text = "Made By @kylosillly On Discord" }

    Webhook.Send = function(Embed: Table, IsTest: boolean)
         if (not IsTest) and (not Options["Webhook"].Value) then
            return
        end

        local WebhookUrl = Options["Webhook Url"].Value

        if (not WebhookUrl) or (WebhookUrl == "") then
            return
        end

        request({
            Url = WebhookUrl,
            Method = "POST",
            Body = HttpService:JSONEncode({
                username = "Script",
                embeds = Embed
            }),
            Headers = { ["Content-Type"] = "application/json" }
        })
    end
    
    Webhook.SendStats = function(IsTest: boolean)
        Webhook.Send({{
            title = `{LocalPlayer.DisplayName}'s Stats`,
            color = 0xFFFFFF,
            thumbnail = {
                url = "https://cdn.discordapp.com/attachments/1363440970909356200/1481697239779901592/attachment.gif?ex=6a6a3096&is=6a68df16&hm=ae317e87f1620b82840ce34a15bcc159f8333d3f78b5edd4a2aec11c72496107&"
            },
            fields = {
                {
                    name = "Current Ascension:",
                    value = AscensionService:GetCurrent(PlayerData.Ascension).Name,
					inline = true
                },
                {
                    name = "Current Class:",
                    value = ClassService:GetCurrent(PlayerData.Class).Name,
					inline = true
                },
                {
                    name = "Current Sword:",
                    value = SwordService:GetSwordByNumber(PlayerData.Sword).Name,
					inline = true
                },
                {
                    name = "Bucks:",
                    value = UIFormat.ToScientificNotation(PlayerData.Bucks.Balance),
					inline = true
                },
                {
                    name = "Power:",
                    value = UIFormat.ToScientificNotation(PlayerData.Power),
					inline = true
                },
                {
                    name = "Ninjutsu:",
                    value = UIFormat.ToScientificNotation(PlayerData.Ninjutsu),
					inline = true
                },
                {
                    name = "Soul Force:",
                    value = UIFormat.ToScientificNotation(PlayerData["Soul Force"]),
					inline = true
                },
            },
            footer = Webhook.WebhookFooter
        }}, IsTest)
    end

    Webhook.Kicked = function(Reason: string)
        Webhook.Send({{
            title = "Session Terminated",
            description = `You have been disconnected for **{Reason}**`,
            color = 0xFF0000,
            footer = Webhook.WebhookFooter
        }}, false)
    end
end

local Script = {}; do
    Script.Cooldowns = {
        LastSwing = 0
    }

    Script.Threads = {}

    Script.UpdateLocals = function()
        LocalCharacter = LocalPlayer.Character

        if (not LocalCharacter) then
            return
        end

        Humanoid = LocalCharacter:WaitForChild("Humanoid", 5)
    end

    Script.Init = function()
        Script.UpdateLocals()

        Script.Threads.WebhookStats = task.spawn(function()
            while (task.wait(Options["Stat Send Interval"].Value)) do
                Webhook.SendStats(false)
            end
        end)

        Script.Threads.Main = task.spawn(function()
            while (task.wait()) do
                local Now = os.clock()

                if (Options["Auto Swing"].Value) and (Script.Cooldowns.LastSwing - Now <= math.max(PlayerData.SlashCooldown or .2, .05)) then
                    local SwingMode = Options["Swing Mode"].Value

                    if (SwingMode == "Blatant") then
                        RemoteEvent:FireServer("SwordSlash", 1)
                    else
                        ToolsService.Sword:Activated()
                    end
                end

                if (Options["Auto Upgrade"].Value) then
                    for Upgrade in (Options["Auto Upgrade Upgrades"].Value) do
                        if (Upgrade == "Sword") then -- UIServiceInvokePersonalRemote("Max sword upgrade", "อัพเกรดดาบแม็กซ์")
                            local NextSwordData = SwordService:GetNextSword()

                            if not (NextSwordData and UpgradeRules.CanUpgrade(PlayerData, NextSwordData.Requirements)) then
                                continue
                            end

                            UIServiceInvokePersonalRemote("Max sword upgrade", "อัพเกรดดาบแม็กซ์")
                        elseif (Upgrade == "Shuriken") then
                            local NextShurikenData = ShurikenService:GetNext()

                            if not (NextShurikenData and UpgradeRules.CanUpgrade(PlayerData, NextShurikenData.Requirements)) then
                                continue
                            end

                            UIServiceInvokePersonalRemote("Shuriken upgrade", "อัพเกรดดาวกระจาย", GetFinalSuccessRate(GetSuccessRate(NextShurikenData.SuccessRate, (BucksConfig.HasGamepassBenefit(PlayerData, "x2Luck"))) + (tonumber(PlayerData.ShPityRate) or 0))) -- omori reference agadgagdgsadgasdas
                        elseif (Upgrade == "Class") then
                            local NextClassData = ClassService:GetNext(PlayerData.Class, PlayerData.ClassSubTier)

                            if not (NextClassData and UpgradeRules.CanUpgrade(PlayerData, NextClassData.Requirements)) then
                                continue
                            end

                            UIServiceInvokePersonalRemote("Class upgrade", "อัพเกรดคลาส", GetFinalSuccessRate(GetSuccessRate(NextClassData.SuccessRate, (BucksConfig.HasGamepassBenefit(PlayerData, "x2Luck"))) + (tonumber(PlayerData.CPityRate) or 0))) -- thai people are SUS
                        elseif (Upgrade == "Realm") then
                            local NextRealmData = AscensionService:GetNext(PlayerData.Ascension, PlayerData.AscensionSubTier)

                            if not (NextRealmData and UpgradeRules.CanUpgrade(PlayerData, NextRealmData.Requirements)) then
                                continue
                            end

                            UIServiceInvokePersonalRemote("Ascension upgrade", "อัพเกรดแอสเซนต์", GetFinalSuccessRate(GetSuccessRate(NextRealmData.SuccessRate, (BucksConfig.HasGamepassBenefit(PlayerData, "x2Luck"))) + (tonumber(PlayerData.APityRate) or 0)))
                        end
                    end
                end
            end
        end)

        Library:GiveSignal(NetworkClient.ChildRemoved:Connect(function(Instance: any)
            if (not Instance:IsA("ClientReplicator")) then
                return
            end

            if (not Options["Log Disconnects"].Value) then
                return
            end

            Webhook.Kicked(GuiService:GetErrorMessage())
        end))

        Library:GiveSignal(RunService.RenderStepped:Connect(function(Delta: number)
            if (Options["Tp Walk"].Value) and (Humanoid) then
                LocalCharacter:TranslateBy(Humanoid.MoveDirection * Options["Tp Walk Speed"].Value * Delta)
            end
        end))

        Library:GiveSignal(LocalPlayer.CharacterAdded:Connect(Script.UpdateLocals))

        Library:GiveSignal(UserInputService.JumpRequest:Connect(function()
            if (Options["Inf Jump"].Value) then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    end
end

local Window = Library:CreateWindow({
	Title = "@kylosillly On Discord | Op Ninja Simulator",
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

local Main = Tabs.Main:AddLeftGroupbox("Main")

Main:AddToggle("Auto Upgrade", {
    Text = "Auto Upgrade",
    Default = false,
    Tooltip = "Automatically buys upgrades",
    Callback = function(Value)
        Options["Auto Upgrade Upgrades"]:SetVisible(Value)
    end
}):AddKeyPicker("Auto Upgrade Keybind", {
    Default = "",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Auto Upgrade Keybind"
})
Main:AddDropdown("Auto Upgrade Upgrades", {
    Values = { "Sword", "Shuriken", "Class", "Realm" },
    Default = { "Sword", "Shuriken", "Class", "Realm" },
    Multi = true,

    Text = "Selected Upgrades:",
    Tooltip = "Upgrades to automatically buy",
    Visible = false,
})
Main:AddToggle("Auto Swing", {
    Text = "Auto Swing",
    Default = false,
    Tooltip = "Swings your sword automatically",
    Callback = function(Value)
        Options["Swing Mode"]:SetVisible(Value)
    end
}):AddKeyPicker("Auto Swing Keybind", {
    Default = "",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Auto Swing Keybind"
})
Main:AddDropdown("Swing Mode", {
	Values = { "Blatant", "Legit" },
	Default = "Legit",
	Multi = false,

	Text = "Swing Mode:",
	Tooltip = "Blatant can't hit anyone and will not play a swing animation.",
	Visible = false,
})

local WebhookTab = Tabs.Main:AddLeftGroupbox("Webhook")

WebhookTab:AddToggle("Webhook", {
    Text = "Enable",
    Default = false,
    Tooltip = "Allows webhooks to be send"
})
WebhookTab:AddToggle("Log Disconnects", {
    Text = "Log Disconnects",
    Default = false,
    Tooltip = "Logs when you disconnect"
})
WebhookTab:AddToggle("Send Stats", {
    Text = "Send Stats",
    Default = false,
    Tooltip = "Sends you current stats",
    Callback = function(Value)
        if (Value) then
            Webhook.SendStats(false)
        end
    end
})
WebhookTab:AddButton("Test", function()
    Webhook.SendStats(true)
end)

WebhookTab:AddInput("Webhook Url", {
	Default = "",
	Numeric = false,
	Finished = true,
	ClearTextOnFocus = true,
		
	Text = "Webhook Url",
	Tooltip = "Webhook that will be used",

	Placeholder = "Hot Thai Ladyboys"
})
WebhookTab:AddSlider("Stat Send Interval", {
    Text = "Stat Send Interval",
    Default = 1,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Suffix = " Mins",
    Callback = function(Value)
        Options["Stat Send Interval"].Value *= 60
    end
})

local Character = Tabs.Main:AddRightGroupbox("Character")

Character:AddToggle("Inf Jump", {
    Text = "Inf Jump",
    Default = false,
    Tooltip = "Lets you jump forever"
})
Character:AddToggle("Tp Walk", {
    Text = "Tp Walk",
    Default = false,
    Tooltip = "Lets you walk faster",
    Callback = function(Value)
        Options["Tp Walk Speed"]:SetVisible(Value)
    end
}):AddKeyPicker("Tp Walk Keybind", {
    Default = "",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Tp Walk Keybind"
})
Character:AddSlider("Tp Walk Speed", {
    Text = "Tp Walk Speed",
    Default = 100,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Visible = false
})

Library:OnUnload(function()
    for _, Thread in (Script.Threads) do
        if (type(Thread) == "thread") then
            task.cancel(Thread)
        end
    end

	Library.Unloaded = true
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
ThemeManager:SetFolder("Script")
SaveManager:SetFolder("Script/Op Ninja Simulator")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Script.Init()
