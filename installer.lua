local ScriptEditorService = game:GetService("ScriptEditorService")
local StudioService = game:GetService("StudioService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local MaterialService = game:GetService("MaterialService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local PhysicsService = game:GetService("PhysicsService")
local Selection = game:GetService("Selection")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

if not RunService:IsEdit() then
	return warn("Oops! You ran the Wall Driver Workshop installer outside of Edit mode. This is usually caused by pasting the installer into a Script. To fix this, delete the script and paste the code into the studio Command Bar instead.")
end

local assetsFolderName = "WALL DRIVER WORKSHOP ASSETS"
local assets = workspace:FindFirstChild(assetsFolderName) or ServerScriptService:FindFirstChild(assetsFolderName)
if not assets then
	for i, v in workspace:GetChildren() do
		if v:GetAttribute("IsWallDriverWorkshopkit") == true then
			assets = v
			break
		end
	end
	if not assets then
		for i, v in ServerScriptService:GetChildren() do
			if v:GetAttribute("IsWallDriverWorkshopkit") == true then
				assets = v
				break
			end
		end
	end
	if not assets then
		return warn("Could not find the required assets to install Wall Driver Workshop. Go to our Discord server at https://discord.gg/xNCCPugM96 and find the model file containing the assets in #wdw-installer")
	end
end

local collisionGroups = {
	"Car",
	"Door",
	"NoCollidePlayer",
	"Player",
	"Wheel"
}

local count = 0
for _, v in PhysicsService:GetRegisteredCollisionGroups() do
	if not table.find(collisionGroups, v.Name) then
		count = count + 1
	end
end

if count > (PhysicsService:GetMaxCollisionGroups() - 5) then
	return warn("Failed to install Wall Driver Workshop. This place has too many collision groups. Please make space for five groups for Wall Driver Workshop.")
end

print("Welcome to the Wall Driver Workshop installer.")

local isHttpEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true

local repo = "https://raw.githubusercontent.com/CandyWirus/WallDriverKit/main/"

local eulaSourceFound, eulaResponse = pcall(function()
	print("Downloading EULA...")
	return HttpService:RequestAsync({
		Url = `{repo}license.lua`
	})
end)

HttpService.HttpEnabled = isHttpEnabled

local eulaSource
if not eulaSourceFound then
	return warn(`Could not download EULA. HTTP Error: {eulaResponse}`)
end

if not eulaResponse.Success then
	return warn(`Could not download EULA. Status Code: {eulaResponse.StatusCode}. {eulaResponse.StatusMessage}`)
end

print("Successfully downloaded EULA.")
local eulaSource = eulaResponse.Body

local eulaScript = Instance.new("ModuleScript")
eulaScript.Name = "EULA"
eulaScript.Source = eulaSource
eulaScript.Parent = workspace

local scriptDidOpen, errorMessage = ScriptEditorService:OpenScriptDocumentAsync(eulaScript)
if not scriptDidOpen then
	return warn(`Failed to open the EULA document: {errorMessage}`)
end

local scriptDocument = ScriptEditorService:FindScriptDocument(eulaScript)
if not scriptDocument then
	eulaScript:Destroy()
	return warn("Failed to find the EULA ScriptDocument")
end

print("Please read the EULA. If you do not agree to the EULA the installer will close. When you are done, close the EULA script.")
local thread = coroutine.running()

local connection
connection = ScriptEditorService.TextDocumentDidClose:Connect(function(doc)
	if doc == scriptDocument then
		connection:Disconnect()
		local isEULAValid, didAgree = pcall(require, eulaScript)
		eulaScript:Destroy()
		local shouldNotInstall = true
		if isEULAValid then
			if didAgree == true then
				shouldNotInstall = false
			elseif didAgree == false then
				print("You did not agree to the EULA. Thank you for considering Wall Driver Workshop. Goodbye.")
			elseif didAgree == nil then
				warn("The EULA value is not set to any value. Booleans (true/false) in Luau are cAsE SeNsItIvE. Please re-run the installer.")
			else
				warn("The EULA value is not a boolean (true/false). Please re-run the installer and follow the instructions exactly.")
			end
		else
			warn("Failed to parse EULA document. Please re-run the installer and follow the instructions exactly.")
		end
		coroutine.resume(thread, shouldNotInstall)
	end
end)

if coroutine.yield() then
	return
end
print("Thank you for using Wall Driver Workshop. Installation will begin now.")

local devGuiEnabled = StarterGui.ShowDevelopmentGui
StarterGui.ShowDevelopmentGui = true

assets.Parent = nil

local replicatedAssets = assets:FindFirstChild("ReplicatedStorage")
local scriptServiceAssets = assets:FindFirstChild("ServerScriptService")
local serverStorageAssets = assets:FindFirstChild("ServerStorage")
local replicatedFirstAssets = assets:FindFirstChild("ReplicatedFirst")
local gui = assets:FindFirstChild("InstallerGui")

local button1, button2, body
local guiLoaded = pcall(function()
	local frame = gui.Frame
	button1 = frame.Yes
	button2 = frame.No
	body = frame.Body
end)

if (not replicatedAssets) or (not scriptServiceAssets) or (not serverStorageAssets) or (not guiLoaded) then
	assets.Parent = workspace
	return warn("Your assets model is missing required files. Please reinstall from our Discord server at https://discord.gg/xNCCPugM96 in #wdw-installer")
end

replicatedAssets.Name = "TaxiSimulatorFuture"
scriptServiceAssets.Name = "TaxiSimulatorFuture"
serverStorageAssets.Name = "TaxiSimulatorFuture"
replicatedFirstAssets.Name = "TaxiSimulatorFuture"

replicatedAssets.Parent = ReplicatedStorage
scriptServiceAssets.Parent = ServerScriptService
serverStorageAssets.Parent = ServerStorage
replicatedFirstAssets.Parent = ReplicatedFirst

print("Installed services")
Players.CharacterAutoLoads = false
print("Disabled character auto loading")

if not workspace:FindFirstChild("Rails") then
	Instance.new("Folder", workspace).Name = "Rails"
	print("Installed rail folder")
end
if not workspace:FindFirstChild("Taxis") then
	Instance.new("Folder", workspace).Name = "Taxis"
	print("Installed Taxi folder")
end

local guiPrompt = function(text)
	body.Text = text
	
	gui.Parent = StarterGui
	
	local thread = coroutine.running()
	
	local yesConnection = button1.MouseButton1Down:Connect(function()
		coroutine.resume(thread, true)
	end)
	local noConnection = button2.MouseButton1Down:Connect(function()
		coroutine.resume(thread, false)
	end)

	local result = coroutine.yield()
	gui.Parent = nil
	
	yesConnection:Disconnect()
	noConnection:Disconnect()
	
	return result
end

local defaultMap = assets:FindFirstChild("Default Drive")
local checkpoints = assets:FindFirstChild("Checkpoints")
local winPad = assets:FindFirstChild("DestinationPoint")
local spawnPoint = assets:FindFirstChild("TaxiSpawnPoint")
local customer = assets:FindFirstChild("Customer")
local playerModule = assets:FindFirstChild("PlayerModule")

local installEssentials = function()
	if checkpoints then
		checkpoints.Parent = workspace
	end
	if winPad then
		winPad.Parent = workspace
	end
	if spawnPoint then
		spawnPoint.Parent = workspace
	end
	if customer then
		customer.Parent = workspace
	end
	print("Installed map items and spawners")
end

if defaultMap and guiPrompt("Would you like to install the showcase course, Default Drive?") then
	installEssentials()
	defaultMap.Parent = workspace
	print("Installed Default Drive")
elseif guiPrompt("Would you like to install essential map items and spawners?") then
	installEssentials()
else
	Instance.new("Folder", workspace).Name = "Checkpoints"
end

local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local foundModule = StarterPlayerScripts:FindFirstChild("PlayerModule")
if foundModule then
	if guiPrompt("There is a PlayerModule installed in StarterPlayerScripts. Wall Driver Workshop is incompatible with the default PlayerModule. Would you like to replace it?") then
		playerModule.Parent = StarterPlayerScripts
		foundModule:Destroy()
		print("Installed legacy PlayerModule")
	end
else
	playerModule.Parent = StarterPlayerScripts
	print("Installed legacy PlayerModule")
end

local robloxMetalNew = assets:FindFirstChild("RobloxMetalNew")
if robloxMetalNew then
	robloxMetalNew.Parent = MaterialService
end
local smoothMetal = assets:FindFirstChild("SmoothMetal")
if smoothMetal then
	smoothMetal.Parent = MaterialService
end

if robloxMetalNew or smoothMetal then
	print("Added custom materials to MaterialService")
end

local skipAdonisPrompt = false

local hdServerHook = assets:FindFirstChild("HDAdminServerHook")
local hdServerRaw = assets:FindFirstChild("HDAdminServerRaw")
local hdClientHook = assets:FindFirstChild("HDAdminClientHook")
local hdClientRaw = assets:FindFirstChild("HDAdminClientRaw")
local hdAdmin = ServerScriptService:FindFirstChild("HD Admin") or workspace:FindFirstChild("HD Admin")
if hdAdmin and hdServerHook and hdServerRaw and hdClientHook and hdClientRaw then
	skipAdonisPrompt = true
	if guiPrompt("The Wall Driver Workshop installer has detected an installation of HD Admin. Would you like to install the Wall Driver Workship plugin for HD Admin?") then
		local config = hdAdmin:FindFirstChild("CustomFeatures")
		if not config then
			config = Instance.new("Configuration")
			config.Name = "CustomFeatures"
			config.Parent = hdAdmin
		end
		
		local serverFolder = config:FindFirstChild("Server")
		if not serverFolder then
			serverFolder = Instance.new("Folder")
			serverFolder.Name = "Server"
			serverFolder.Parent = config
		end
		local serverModules = serverFolder:FindFirstChild("Modules")
		if not serverModules then
			serverModules = Instance.new("Folder")
			serverModules.name = "Modules"
			serverModules.Parent = serverFolder
		end
		local serverModule = serverModules:FindFirstChild("Commands")
		if serverModule then
			serverModule.Name = "HookedByTaxiSimulator"
			serverModule.Parent = hdServerHook
			hdServerHook.Name = "Commands"
			hdServerHook.Parent = serverModules
		else
			hdServerRaw.Name = "Commands"
			hdServerRaw.Parent = serverModules
		end
		
		local clientFolder = config:FindFirstChild("Client")
		if not clientFolder then
			clientFolder = Instance.new("Folder")
			clientFolder.Name = "Server"
			clientFolder.Parent = config
		end
		local clientModules = clientFolder:FindFirstChild("Modules")
		if not clientModules then
			clientModules = Instance.new("Folder")
			clientModules.name = "Modules"
			clientModules.Parent = clientFolder
		end
		local clientModule = clientModules:FindFirstChild("ClientCommands")
		if clientModule then
			clientModule.Name = "HookedByTaxiSimulator"
			clientModule.Parent = hdClientHook
			hdClientHook.Name = "ClientCommands"
			hdClientHook.Parent = clientModules
		else
			hdClientRaw.Name = "ClientCommands"
			hdClientRaw.Parent = clientModules
		end
		print("Installed Wall Driver Workshop plugin for HD Admin")
	end
end

local kohlHook = assets:FindFirstChild("KohlHook")
local kohlRaw = assets:FindFirstChild("KohlRaw")
local kohl = ServerScriptService:FindFirstChild("Kohl's Admin Infinite") or workspace:FindFirstChild("Kohl's Admin Infinite")
if kohl then
	local credit = kohl:FindFirstChild("Credit")
	if credit then
		skipAdonisPrompt = true
		if guiPrompt("The Wall Driver Workshop installer has detected an installation of Kohl's Admin Infinite. Would you like to install the Wall Driver Workship plugin for Kohl's Admin Infinite?") then
			local custom = credit:FindFirstChild("Custom Commands")
			if custom then
				kohlHook.Name = "Custom Commands"
				custom.Name = "HookedByTaxiSimulator"
				custom.Parent = kohlHook
				kohlHook.Parent = credit
			else
				kohlRaw.Name = "Custom Commands"
				kohlRaw.Parent = credit
			end
			print("Installed Wall Driver Workshop plugin for Kohl's Admin Infinite")
		end
	end
end

local adonisPlugin = assets:FindFirstChild("Server-TaxiSimulatorFuture")
local adonis = ServerScriptService:FindFirstChild("Adonis_Loader") or workspace:FindFirstChild("Adonis_Loader")
if adonis then
	skipAdonisPrompt = true
	if guiPrompt("The Wall Driver Workshop installer has detected an installation of Adonis. Would you like to install the Wall Driver Workship plugin for Adonis?") then
		local config = adonis:FindFirstChild("Config")
		if not config then
			config = Instance.new("Folder")
			config.Name = "Config"
			config.Parent = adonis
		end
		local plugins = config:FindFirstChild("Plugins")
		if not plugins then
			plugins = Instance.new("Folder")
			plugins.Name = "Plugins"
			plugins.Parent = config
		end
		adonisPlugin.Parent = plugins --thanks adonis for being easy
		print("Installed Wall Driver Workshop plugin for Adonis")
	end
end

if (not skipAdonisPrompt) and adonisPlugin and guiPrompt("Would you like to install Adonis and the Wall Driver Workshop plugin to give your players access to transmission settings?") then
	local adonis = game:GetObjects("rbxassetid://7510622625")[1]
	adonisPlugin.Parent = adonis.Config.Plugins
	
	local settingsScript = adonis.Config.Settings
	settingsScript.Source = select(1, string.gsub(settingsScript.Source, `"CHANGE_THIS"`, `"WDW_{HttpService:GenerateGUID(false)}"`))
	
	adonis.Parent = ServerScriptService --thanks adonis for being easy
	print("Installed Adonis and the Wall Driver Workshop Plugin")
end

assets:Destroy()
print("Successfully installed all of Wall Driver Workshop's included assets")

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	if guiPrompt("This place uses TextChatService. TextChatService causes NPC dialog to appear incorrectly. Would you like to use LegacyChatService instead?") then
		button1.Visible = false
		button2.Text = "CANCEL"
		body.Text = "Please use the Properties window to change the ChatVersion to LegacyChatService."
		gui.Parent = StarterGui
		Selection:Set({TextChatService})
		
		local thread = coroutine.running()
		local changedConnection = TextChatService:GetPropertyChangedSignal("ChatVersion"):Connect(function()
			coroutine.resume(thread)
		end)
		local cancelConnection = button2.MouseButton1Down:Connect(function()
			coroutine.resume(thread)
		end)
		coroutine.yield()
		gui.Parent = nil
		button2.Text = "NO"
		button1.Visible = true
		cancelConnection:Disconnect()
		changedConnection:Disconnect()
	end
end

if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
	print("Disabled TextChatService")
end

for i = 1, #collisionGroups do
	local name = collisionGroups[i]
	PhysicsService:UnregisterCollisionGroup(name)
	PhysicsService:RegisterCollisionGroup(name)
end
PhysicsService:CollisionGroupSetCollidable("Car", "Wheel", false)
PhysicsService:CollisionGroupSetCollidable("Door", "NoCollidePlayer", false)
PhysicsService:CollisionGroupSetCollidable("Door", "Player", false)
PhysicsService:CollisionGroupSetCollidable("Door", "Wheel", false)
PhysicsService:CollisionGroupSetCollidable("NoCollidePlayer", "NoCollidePlayer", false)
PhysicsService:CollisionGroupSetCollidable("NoCollidePlayer", "Player", false)
print("Added collision groups")

gui:Destroy()
Selection:Set({MaterialService})
StarterGui.ShowDevelopmentGui = devGuiEnabled
print("Please disable MaterialService.Use2022Materials if it is enabled. It may cause the Wall Driver to look different than intended")
print("Wall Driver Workshop installation succeeded. Thank you! Join our Discord server at https://discord.gg/xNCCPugM96")