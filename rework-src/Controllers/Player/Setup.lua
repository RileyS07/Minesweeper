local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerUtilities = require(ReplicatedStorage.Libraries.PlayerUtilities)

local PlayerSetupController = Knit.CreateController({
    Name = "PlayerSetupController"
})

-- Initialization.
function PlayerSetupController:KnitInit()

    -- As of now the game is single-player so they have no need for the core guis.
    PlayerUtilities.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    -- If they reset they should go back to the main menu.
    local ResetButtonCallback: BindableEvent = Instance.new("BindableEvent")

    ResetButtonCallback.Event:Connect(function()
        print("Send them back!")
    end)

    PlayerUtilities.SetCore("ResetButtonCallback", ResetButtonCallback)
end

return PlayerSetupController
