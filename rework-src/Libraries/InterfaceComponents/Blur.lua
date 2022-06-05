--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local New = Fusion.New

return function(Properties: {[string]: any})
    Properties = Properties or {}

    return New("Frame")({
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = Properties.Transparency or 0.55,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = Properties.ZIndex or 2,
    })
end
