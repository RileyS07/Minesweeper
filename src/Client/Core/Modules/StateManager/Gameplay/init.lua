-- Variables
local gameplayState = {}
gameplayState.STATES = {
	RETRY = "Retry",
	PLAY_AGAIN = "Play_Again",
	GO_TO_MENU = "Go_To_Menu"
}

gameplayState.IsActive = false
gameplayState.Interface = nil
gameplayState.Connections = {}
gameplayState.Grid = nil
gameplayState.DifficultyInformation = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local stateManager = require(coreModule.GetObject("Modules.StateManager"))
local difficulities = require(coreModule.GetObject("/Difficulties"))
local Grid = require(coreModule.GetObject("Libraries.Grid"))
local Cell = require(coreModule.GetObject("Libraries.Grid.Cell"))

local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")

-- State Methods
function gameplayState.StateStarted()
	gameplayState.Interface = coreModule.GetObject("//Assets.Interfaces." .. script.Name):Clone()
	gameplayState.Interface.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	-- gameplayState.DifficultyInformation hasn't been set yet.
	if not gameplayState.DifficultyInformation then
		gameplayState.DifficultyInformation = difficulities.EXPERT
	end

	-- Gameplay loop.
	task.defer(function()
		while gameplayState.IsActive do
			gameplayState.Grid = Grid.new(gameplayState.DifficultyInformation.GRID_SIZE, gameplayState.DifficultyInformation.BOMB_COUNT)
			print("\n" .. tostring(gameplayState.Grid))

			-- Setup.
			gameplayState.SetupTimer()
			gameplayState.SetupFlagCounter()
			gameplayState.SetupActionTypeSwitcher()
			gameplayState.Interface.Container.Content.UIGridLayout.CellSize = UDim2.fromScale(1 / gameplayState.DifficultyInformation.GRID_SIZE.X, 1 / gameplayState.DifficultyInformation.GRID_SIZE.Y)
			gameplayState.Interface.Container.UIAspectRatioConstraint.AspectRatio = gameplayState.DifficultyInformation.GRID_SIZE.X / gameplayState.DifficultyInformation.GRID_SIZE.Y
			gameplayState.Grid:GenerateGui(gameplayState.Interface.Container.Content)

			-- Waiting till it's finished and what we do after.
			local finishedSuccessfully = gameplayState.Grid.GameFinished.Event:Wait()
			gameplayState.DisconnectListeners()

			local correctSound = coreModule.GetObject("//Assets.Sounds.Music." .. (finishedSuccessfully and "GameWin" or "GameFailure"))
			correctSound:Play()

			-- Let's show them game finished menu!
			local desiredAction = gameplayState.GetDesiredActionOnGameFinish(finishedSuccessfully)

			-- Now what do we do?
			if desiredAction == gameplayState.STATES.PLAY_AGAIN then
				stateManager.ChangeState(stateManager.STATES.GAMEPLAY)
				break
			elseif desiredAction == gameplayState.STATES.GO_TO_MENU then
				stateManager.ChangeState(stateManager.STATES.PLAY_MENU, "Menu")
			else
				stateManager.ChangeState(stateManager.STATES.MENU)
			end
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


function gameplayState.SetupActionTypeSwitcher()
	local modeFlag = gameplayState.Interface.Container.Header.ActivationTypeSwitcher.Mode_Flag
	local modeMine = gameplayState.Interface.Container.Header.ActivationTypeSwitcher.Mode_Mine

	modeFlag.Activated:Connect(function()
		if not gameplayState.Grid then return end

		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		gameplayState.Grid.ActivationType = Cell.ACTIVATION_TYPE.PLACE_FLAG
		modeMine.LayoutOrder = 2
		modeFlag.LayoutOrder = 1
	end)

	modeMine.Activated:Connect(function()
		if not gameplayState.Grid then return end

		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
		gameplayState.Grid.ActivationType = Cell.ACTIVATION_TYPE.MINE
		modeMine.LayoutOrder = 1
		modeFlag.LayoutOrder = 2
	end)
end


function gameplayState.GetDesiredActionOnGameFinish(finishedSuccessfully: boolean)
	tweenService:Create(gameplayState.Interface.Overlay, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {BackgroundTransparency = 0.55}):Play()

	local gameFinishedMenu = gameplayState.Interface.GameFinishedMenu
	gameFinishedMenu.StatusText.Text = finishedSuccessfully and "You've won!" or "You've lost!"
	gameFinishedMenu.Position = UDim2.fromScale(0.5, 2)
	gameFinishedMenu.Visible = true

	local upwardsTweenInstance = tweenService:Create(gameFinishedMenu, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0.5, 0.5)})
	upwardsTweenInstance:Play()
	upwardsTweenInstance.Completed:Wait()

	-- Let's wait for input.
	local desiredAction = ""

	gameplayState.Connections.Button1 = gameFinishedMenu.Content.Retry.Activated:Connect(function()
		desiredAction = gameplayState.STATES.RETRY
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
	end)

	gameplayState.Connections.Button2 = gameFinishedMenu.Content.NewGame.Activated:Connect(function()
		desiredAction = gameplayState.STATES.PLAY_AGAIN
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
	end)

	gameplayState.Connections.Button3 = gameFinishedMenu.Content.Return.Activated:Connect(function()
		desiredAction = gameplayState.STATES.GO_TO_MENU
		coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
	end)

	repeat task.wait() until desiredAction ~= ""
	return desiredAction
end

--
return gameplayState