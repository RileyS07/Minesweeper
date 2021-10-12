-- Variables
export type CellType = { Name: string, Symbol: string }

local Cell = {}
Cell.CELL_TYPES = {
	EMPTY = {Name = "Empty", Symbol = "⬜"},
	BORDER = {Name = "Border", Symbol = "🟥"},
	BOMB = {Name = "Bomb", Symbol = "💣"},
	FLAG = {Name = "Flag", Symbol = "🚩"},
}

Cell.COLOR_SCHEMES = {
	UNREVEALED = { Color3.fromRGB(170, 215, 81), Color3.fromRGB(162, 209, 73) },
	REVEALED = { Color3.fromRGB(229, 194, 159), Color3.fromRGB(215, 184, 153) },
	BORDER_CELL_TEXT_COLOR = {
		Color3.fromRGB(25, 118, 210),
		Color3.fromRGB(59, 143, 62),
		Color3.fromRGB(212, 55, 53),
		Color3.fromRGB(123, 31, 162),
		Color3.fromRGB(128, 2, 1),
		Color3.fromRGB(0, 129, 126),
		Color3.fromRGB(0, 0, 0),
		Color3.fromRGB(128, 128, 128),
	}
}

Cell.ACTIVATION_TYPE = {
	MINE = "Mine", PLACE_FLAG = "Place_Flag"
}

local coreModule = require(script:FindFirstAncestor("Core"))

-- Constructor
function Cell.new(grid: {any}, location: Vector2, cellType: CellType, bombsNearby: number?)
	assert(typeof(grid) == "table", "Argument #1 expected to be Grid. Got " .. typeof(grid))
	assert(typeof(location) == "Vector2", "Argument #2 expected Vector2. Got " .. typeof(location))
	assert(typeof(cellType) == "table", "Argument #3 expected number. Got " .. typeof(cellType))
	assert(typeof(bombsNearby) == "nil" or typeof(bombsNearby) == "number", "Argument #4 expected number. Got " .. typeof(bombsNearby))

	return setmetatable({
		BombsNearby = bombsNearby or 0,
		CellType = cellType,
		Grid = grid,
		IsFlagged = false,
		IsRevealed = false,
		Location = location,

		_TextButton = nil
	}, {
		__index = Cell,
		__tostring = function(self)
			return cellType.Symbol .. " " .. cellType.Name .. " [" .. tostring(self.Location.X) .. ", " .. tostring(self.Location.Y) .. "]"
		end,
	})
end

-- Public Methods
function Cell:Destroy()
	if self._TextButton then
		self._TextButton:Destroy()
	end
end


function Cell:Is(cellType: CellType) : boolean
	return self.CellType.Name == cellType.Name
end


function Cell:Reveal()
	assert(self._TextButton ~= nil, "Cannot reveal cell without generating it first.")

	local currentCellValue = ((self.Location.Y - 1) * self.Grid.Dimensions.X + self.Location.X + self.Location.Y)
	self._TextButton.BackgroundColor3 = Cell.COLOR_SCHEMES.REVEALED[(self.Grid.Dimensions.X % 2 == 1 and currentCellValue - self.Location.Y or currentCellValue) % 2 + 1]
	self.IsRevealed = true

	-- What do we do?
	if self:Is(Cell.CELL_TYPES.BORDER) then
		self._TextButton.TextColor3 = Cell.COLOR_SCHEMES.BORDER_CELL_TEXT_COLOR[math.min(self.BombsNearby, #Cell.COLOR_SCHEMES.BORDER_CELL_TEXT_COLOR)]
		self._TextButton.Text = self.BombsNearby
	elseif self:Is(Cell.CELL_TYPES.BOMB) then
		self._TextButton.Text = Cell.CELL_TYPES.BOMB.Symbol
	end
end


function Cell:GenerateGui(parent: Instance?) : TextButton
	assert(typeof(parent) == "nil" or typeof(parent) == "Instance", "Argument #1 expected Instance. Got " .. typeof(parent))

	local currentCellValue = ((self.Location.Y - 1) * self.Grid.Dimensions.X + self.Location.X + self.Location.Y)
	local textButton = Instance.new("TextButton")
	textButton.BorderSizePixel = 0
	textButton.BackgroundColor3 = Cell.COLOR_SCHEMES.UNREVEALED[(self.Grid.Dimensions.X % 2 == 1 and currentCellValue - self.Location.Y or currentCellValue) % 2 + 1]
	textButton.Name = tostring(self)
	textButton.LayoutOrder = currentCellValue
	textButton.TextScaled = true
	textButton.Text = ""

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.1, 0)
	uiPadding.PaddingLeft = UDim.new(0.1, 0)
	uiPadding.PaddingRight = UDim.new(0.1, 0)
	uiPadding.PaddingTop = UDim.new(0.1, 0)
	uiPadding.Parent = textButton
	self._TextButton = textButton

	-- For when they click it.
	textButton.Activated:Connect(function()
		if self.IsRevealed then return end
		if self.Grid.ActivationType == Cell.ACTIVATION_TYPE.MINE and self.IsFlagged then return end
		if self.Grid.IsLocked then return end

		if self.Grid.ActivationType == Cell.ACTIVATION_TYPE.MINE then

			-- We only check for Empty specifically.
			if self:Is(Cell.CELL_TYPES.EMPTY) then
				self.Grid:FillEmptyCells(self)
			else
				self:Reveal()
			end

			coreModule.GetObject("//Assets.Sounds.SoundEffects.Click"):Play()
			self.Grid.CellMined:Fire(self.CellType)

		else
			-- Inverting, removing the flag.
			if self.IsFlagged then
				coreModule.GetObject("//Assets.Sounds.SoundEffects.Unflag"):Play()
				textButton.Text = ""
			end

			-- Now we need to check if it was successfully placed.
			local wasSuccessful = self.Grid:PlaceFlagOnCell(self)

			-- Update
			if wasSuccessful then
				coreModule.GetObject("//Assets.Sounds.SoundEffects.Flag"):Play()
				textButton.Text = Cell.CELL_TYPES.FLAG.Symbol
			end
		end
	end)

	-- Right click to place a flag.
	textButton.MouseButton2Click:Connect(function()
		if self.IsRevealed then return end
		if self.Grid.IsLocked then return end

		-- Inverting, removing the flag.
		if self.IsFlagged then
			coreModule.GetObject("//Assets.Sounds.SoundEffects.Unflag"):Play()
			textButton.Text = ""
		end

		-- Now we need to check if it was successfully placed.
		local wasSuccessful = self.Grid:PlaceFlagOnCell(self)

		-- Update
		if wasSuccessful then
			coreModule.GetObject("//Assets.Sounds.SoundEffects.Flag"):Play()
			textButton.Text = Cell.CELL_TYPES.FLAG.Symbol
		end
	end)

	textButton.Parent = parent
	return textButton
end

--
export type Cell = typeof(Cell.new({}, Vector2.new(), Cell.CELL_TYPES.EMPTY))
return Cell