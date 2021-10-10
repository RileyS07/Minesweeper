-- Variables
local menuState = {}
menuState.IsActive = false
menuState.Interface = nil
menuState.Connections = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local stateManager = require(coreModule.GetObject("Modules.StateManager"))

-- State Methods
function menuState.StateStarted()
	menuState.Interface = coreModule.GetObject("//Assets.Interfaces." .. script.Name):Clone()
	menuState.Interface.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	-- They want to play!
	menuState.Interface.Background.PlayButton.Activated:Connect(function()
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
	end)
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
end

--
return menuState