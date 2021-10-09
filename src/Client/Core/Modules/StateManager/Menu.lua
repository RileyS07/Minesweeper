-- Variables
local menuState = {}
menuState.IsActive = false
menuState.Interface = nil
menuState.Connections = {}

local stateManager = require(script.Parent)
local starterGui = game:GetService("StarterGui")
local tweenService = game:GetService("TweenService")

local coreModule = require(script:FindFirstAncestor("Core"))
local sounds = coreModule.GetObject("//Assets.Sounds")

-- State Methods
function menuState.StateStarted()
	menuState.Interface = coreModule.GetObject("//Assets.Interfaces." .. script.Name):Clone()
	menuState.Interface.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	tweenService:Create(sounds.Music[script.Name], TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0.5}):Play()
	
	-- They want to play!
	menuState.Interface.Background.PlayButton.Activated:Connect(function()
		sounds.Click:Play()
		stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
	end)
	
	repeat task.wait() until pcall(starterGui.SetCoreGuiEnabled, starterGui, Enum.CoreGuiType.All, false)
	repeat task.wait() until pcall(starterGui.SetCore, starterGui, "ResetButtonCallback", false)
end


function menuState.StateFinished()
	if menuState.Interface then
		menuState.Interface:Destroy()
	end
	
	for _, connection in next, menuState.Connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	
	tweenService:Create(sounds.Music[script.Name], TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0}):Play()
end

--
return menuState