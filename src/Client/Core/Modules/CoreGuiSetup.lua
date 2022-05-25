-- Variables
local coreguiSetupManager = {}
local starterGuiService = game:GetService("StarterGui")

-- Initialize
function coreguiSetupManager.Initialize()
	repeat
		task.wait()
	until pcall(starterGuiService.SetCoreGuiEnabled, starterGuiService, Enum.CoreGuiType.All, false)
	repeat
		task.wait()
	until pcall(starterGuiService.SetCore, starterGuiService, "ResetButtonCallback", false)
end

--
return coreguiSetupManager