-- Variables
local playMenuState = {}
playMenuState.IsActive = false
playMenuState.Interface = nil
playMenuState.Connections = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local stateManager = require(coreModule.GetObject("Modules.StateManager"))
local gameplayState = require(coreModule.GetObject("Modules.StateManager.Gameplay"))
local difficulities = require(coreModule.GetObject("Modules.StateManager.Gameplay.Difficulties"))

-- State Methods
function playMenuState.StateStarted()
	playMenuState.Interface = coreModule.GetObject("//Assets.Interfaces." .. script.Name):Clone()
	playMenuState.Interface.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	-- Yeah we got buttons [2].
	playMenuState.Connections.Back = playMenuState.Interface.Background.BackButton.Activated:Connect(function()
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		stateManager.ChangeState(stateManager.STATES.MENU, "Menu")
	end)

	playMenuState.Connections.Easy = playMenuState.Interface.Background.Content.Buttons.Easy.Activated:Connect(function()
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		gameplayState.DifficultyInformation = difficulities.BEGINNER
		stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
	end)

	playMenuState.Connections.Normal = playMenuState.Interface.Background.Content.Buttons.Normal.Activated:Connect(function()
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		gameplayState.DifficultyInformation = difficulities.INTERMEDIATE
		stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
	end)

	playMenuState.Connections.Hard = playMenuState.Interface.Background.Content.Buttons.Hard.Activated:Connect(function()
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		gameplayState.DifficultyInformation = difficulities.EXPERT
		stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
	end)
end


function playMenuState.StateFinished()
	if playMenuState.Interface then
		playMenuState.Interface:Destroy()
	end

	for _, connection in next, playMenuState.Connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
end

--
return playMenuState
