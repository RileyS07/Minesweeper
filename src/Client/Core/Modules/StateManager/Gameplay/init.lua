-- Variables
local gameplayState = {}
gameplayState.IsActive = false
gameplayState.Interface = nil
gameplayState.Connections = {}
gameplayState.Grid = nil
gameplayState.DifficultyInformation = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local stateManager = require(coreModule.GetObject("Modules.StateManager"))
local difficulities = require(coreModule.GetObject("/Difficulties"))
local Grid = require(coreModule.GetObject("Libraries.Grid"))

-- State Methods
function gameplayState.StateStarted()
	gameplayState.Interface = coreModule.GetObject("//Assets.Interfaces." .. script.Name):Clone()
	gameplayState.Interface.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	game:GetService("TweenService"):Create(coreModule.GetObject("//Assets.Sounds.Music." .. script.Name), TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0.5}):Play()

	-- gameplayState.DifficultyInformation hasn't been set yet.
	if not gameplayState.DifficultyInformation then
		gameplayState.DifficultyInformation = difficulities.BEGINNER
	end

	-- Gameplay loop.
	task.defer(function()
		while gameplayState.IsActive do
			gameplayState.Grid = Grid.new(gameplayState.DifficultyInformation.GRID_SIZE, gameplayState.DifficultyInformation.BOMB_COUNT)
			print("\n" .. tostring(gameplayState.Grid))

			-- Setup.
			gameplayState.SetupTimer()
			gameplayState.SetupFlagCounter()
			gameplayState.Interface.Container.Content.UIGridLayout.CellSize = UDim2.fromScale(1 / gameplayState.DifficultyInformation.GRID_SIZE.X, 1 / gameplayState.DifficultyInformation.GRID_SIZE.Y)
			gameplayState.Interface.Container.UIAspectRatioConstraint.AspectRatio = gameplayState.DifficultyInformation.GRID_SIZE.X / gameplayState.DifficultyInformation.GRID_SIZE.Y
			gameplayState.Grid:GenerateGui(gameplayState.Interface.Container.Content)

			-- Waiting till it's finished and what we do after.
			local finishedSuccessfully = gameplayState.Grid.GameFinished.Event:Wait()
			gameplayState.DisconnectListeners()

			local correctSound = coreModule.GetObject("//Assets.Sounds.Music." .. (finishedSuccessfully and "GameWin" or "GameFailure"))
			correctSound:Play()
			correctSound.Ended:Wait()

			stateManager.ChangeState(stateManager.STATES.MENU)
		end
	end)
end


function gameplayState.StateFinished()
	if gameplayState.Interface then
		gameplayState.Interface:Destroy()
	end

	if gameplayState.Grid then
		gameplayState.Grid:Destroy()
	end

	gameplayState.DisconnectListeners()
	game:GetService("TweenService"):Create(coreModule.GetObject("//Assets.Sounds.Music." .. script.Name), TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0}):Play()
end

-- Private Methods
function gameplayState.DisconnectListeners()
	for _, connection in next, gameplayState.Connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
end


function gameplayState.SetupTimer()
	local startTime = math.floor(os.clock())

	gameplayState.Connections.Timer = game:GetService("RunService").Heartbeat:Connect(function()
		local rawSeconds = math.floor(os.clock()) - startTime

		gameplayState.Interface.Container.Header.Counter_Time.Text = "⏰ " .. string.format("%d:%.02d", math.floor(rawSeconds / 60), rawSeconds % 60)
	end)
end


function gameplayState.SetupFlagCounter()
	gameplayState.Connections.FlagCounter = gameplayState.Grid.FlagCountUpdated.Event:Connect(function(newFlagCount: number)
		gameplayState.Interface.Container.Header.Counter_Flag.Text = "🚩 " .. tostring(gameplayState.Grid.BombCount - newFlagCount)
	end)

	gameplayState.Interface.Container.Header.Counter_Flag.Text = "🚩 " .. tostring(gameplayState.Grid.BombCount)
end

--
return gameplayState