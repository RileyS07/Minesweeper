-- Variables
local stateManager = {}
stateManager.STATES = { MENU = "Menu", GAMEPLAY = "Gameplay" }
stateManager.CurrentState = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local tweenService = game:GetService("TweenService")

-- Initialize
function stateManager.Initialize()
	stateManager.ChangeState(stateManager.STATES.MENU)
end

-- Public Methods
-- Updates CurrentState; Also calls StateStarted and StateFinished.
function stateManager.ChangeState(newStateName: string)
	if not script:FindFirstChild(newStateName) then return end
	if not script:FindFirstChild(newStateName):IsA("ModuleScript") then return end

	-- In with the new, out with the old.
	local newStateModule = require(script:FindFirstChild(newStateName))
	local currentStateModule = stateManager.CurrentState and require(script:FindFirstChild(stateManager.CurrentState))
	stateManager._TransitionBetweenStateMusic(newStateName, stateManager.CurrentState)
	stateManager.CurrentState = newStateName

	if currentStateModule then
		currentStateModule.IsActive = false
		currentStateModule.StateFinished()
	end

	newStateModule.IsActive = true
	newStateModule.StateStarted()
end

-- Private Methods
function stateManager._TransitionBetweenStateMusic(newStateName: string, oldStateName: string?)
	local oldSoundInstance = oldStateName and coreModule.GetObject("//Assets.Sounds.Music"):FindFirstChild(oldStateName)
	local newSoundInstance = coreModule.GetObject("//Assets.Sounds.Music"):FindFirstChild(newStateName)

	task.defer(function()

		-- If oldSoundInstance exists we tween it out.
		if oldSoundInstance then
			local soundFadingOutTween = tweenService:Create(oldSoundInstance, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0})
			soundFadingOutTween:Play()
			soundFadingOutTween.Completed:Wait()
			oldSoundInstance:Stop()
		end

		-- If newSoundInstance exists we tween it in.
		if newSoundInstance then
			newSoundInstance.Volume = 0
			newSoundInstance:Play()

			local soundFadingInTween = tweenService:Create(newSoundInstance, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Volume = 0.5})
			soundFadingInTween:Play()
			soundFadingInTween.Completed:Wait()
		end
	end)
end

--
return stateManager