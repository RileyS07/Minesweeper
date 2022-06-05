--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local BlurComponent = require(ReplicatedStorage.Libraries.InterfaceComponents.Blur)
local BoardComponment = require(ReplicatedStorage.Libraries.InterfaceComponents.Board)

local New = Fusion.New
local Children = Fusion.Children

local InterfacesController = Knit.CreateController({
    Name = "Testing_InterfacesController"
})

-- Initialization
function InterfacesController:KnitInit()
    New("ScreenGui")({
        IgnoreGuiInset = true,
        Parent = Knit.Player:WaitForChild("PlayerGui"),

        -- The background color.
        [Children] = New("Frame")({
            BackgroundColor3 = Color3.fromRGB(215, 215, 215),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),

            -- Blurring the background so the content is very visible.
            [Children] = {
                BlurComponent({}),
                BoardComponment({}),
            }
        })
    })
end

return InterfacesController
