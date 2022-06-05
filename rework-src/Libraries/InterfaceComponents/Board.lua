--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local New = Fusion.New
local Children = Fusion.Children

return function(Properties: {[string]: any})
    Properties = Properties or {}

    return New("Frame")({
        AnchorPoint = Properties.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = Properties.Position or UDim2.fromScale(0.5, 0.5),
        Size = Properties.Size or UDim2.fromScale(1, 1),
        ZIndex = Properties.ZIndex or 2,

        [Children] = {
            New("UIAspectRatioConstraint")({}),
            New("UIStroke")({
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Properties.StrokeColor or Color3.fromRGB(215, 184, 153),
                LineJoinMode = Enum.LineJoinMode.Round,
                Thickness = Properties.StrokeThickness or 5,
            }),

            -- This frame is what will hold all of the content.
            [Children] = New("Frame")({
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.fromScale(1, 1),

                -- The actual content.
                [Children] = {
                    New("UIGridLayout")({
                        CellPadding = UDim2.new(0, 0, 0, 0),
                        CellSize = UDim2.fromScale(0.1, 0.1),--UDim2.fromScale(1 / Properties.Grid:GetSize().X, 1 / Properties.Grid:GetSize().Y),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        StartCorner = Enum.StartCorner.TopLeft,
                        VerticalAlignment = Enum.VerticalAlignment.Top
                    })
                }
            })
        }
    })
end
