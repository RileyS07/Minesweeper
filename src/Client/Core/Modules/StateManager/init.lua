-- Variables
local stateManager = {}
stateManager.STATES = { MENU = "Menu", GAMEPLAY = "Gameplay" }
stateManager.CurrentState = stateManager.STATES.MENU

-- Initialize
function stateManager.Initialize()
	if not script:FindFirstChild(stateManager.CurrentState) then return end
	if not script:FindFirstChild(stateManager.CurrentState):IsA("ModuleScript") then return end
	
	local currentStateModule = require(script:FindFirstChild(stateManager.CurrentState))
	currentStateModule.IsActive = true
	currentStateModule.StateStarted()
end

-- Methods
-- Updates CurrentState; Also calls StateStarted and StateFinished.
function stateManager.ChangeState(newStateName: string)
	if not script:FindFirstChild(newStateName) then return end
	if not script:FindFirstChild(newStateName):IsA("ModuleScript") then return end
	
	-- In with the new, out with the old.
	local newStateModule = require(script:FindFirstChild(newStateName))
	local currentStateModule = require(script:FindFirstChild(stateManager.CurrentState))
	stateManager.CurrentState = newStateName
	
	currentStateModule.IsActive = false
	currentStateModule.StateFinished()
	
	newStateModule.IsActive = true
	newStateModule.StateStarted()
end

--
return stateManager