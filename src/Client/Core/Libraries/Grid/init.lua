-- Variables
local Grid = {}
local Cell = require(script.Cell)

-- Constructor
function Grid.new(gridDimensions: Vector2, bombCount: number, randomSeed: number?)
	assert(typeof(gridDimensions) == "Vector2", "Argument #1 expected Vector2. Got " .. typeof(gridDimensions))
	assert(typeof(bombCount) == "number", "Argument #2 expected Number. Got " .. typeof(bombCount))
	assert(typeof(randomSeed) == "nil" or typeof(randomSeed) == "number", "Argument #3 expected Number. Got " .. typeof(randomSeed))
	assert(gridDimensions.X * gridDimensions.Y > bombCount, "Number of bombs must be less than total grid area.")

	-- Creating the new object.
	local self = setmetatable({
		BombCount = bombCount,
		Dimensions = gridDimensions,
		FlagCount = 0,
		Grid = {},
		IsLocked = false,

		CellMined = Instance.new("BindableEvent"),
		GameFinished = Instance.new("BindableEvent"),
		FlagCountUpdated = Instance.new("BindableEvent")
	}, {
		__index = Grid,
		__tostring = function(self)
			local outputString = ""

			-- Generating the outputString.
			for rowNumber = 1, self.Dimensions.Y do
				for collumnNumber = 1, self.Dimensions.X do
					outputString = outputString .. self.Grid[rowNumber][collumnNumber].CellType.Symbol
				end

				outputString = outputString .. "\n"
			end

			return outputString:sub(1, -2)
		end,
	})

	-- Object setup.
	self:_GenerateGrid(randomSeed)

	self.CellMined.Event:Connect(function(cellType: Cell.CellType)

		if cellType.Name == Cell.CELL_TYPES.BOMB.Name then
			self.IsLocked = true
			self.GameFinished:Fire(false)
		else
			-- We want to see if they've just won.
			for rowNumber = 1, self.Dimensions.Y do
				for collumnNumber = 1, self.Dimensions.X do
					if not self.Grid[rowNumber][collumnNumber]:Is(Cell.CELL_TYPES.BOMB) and not self.Grid[rowNumber][collumnNumber].IsRevealed then
						return
					end
				end
			end

			self.IsLocked = true
			self.GameFinished:Fire(true)
		end
	end)

	--
	return self
end

-- Public Methods
function Grid:Destroy()
	self.CellMined:Destroy()
	self.GameFinished:Destroy()
	self.FlagCountUpdated:Destroy()

	for rowNumber = 1, self.Dimensions.Y do
		for collumnNumber = 1, self.Dimensions.X do
			self.Grid[rowNumber][collumnNumber]:Destroy()
		end
	end

	self.Grid = nil
end


function Grid:FillEmptyCells(cell: Cell.Cell)
	if not cell or cell:Is(Cell.CELL_TYPES.BOMB) or cell.IsRevealed or cell.IsFlagged then
		return
	end

	if not self:_IsLocationWithinGrid(cell.Location) then
		return
	end

	-- Somehow a flag got through?
	if cell.IsFlagged then
		self.FlagCount -= 1
		cell.IsFlagged = false
		self.FlagCountUpdated:Fire(self.FlagCount)
	end

	-- If it's a border we want to reveal it but stop the flood fill.
	if cell:Is(Cell.CELL_TYPES.BORDER) then
		cell:Reveal()
		return
	end

	-- Flood fill time babey.
	cell:Reveal()
	self:FillEmptyCells(self:_GetNeighborCell(cell, Vector2.new(-1, 0)))
	self:FillEmptyCells(self:_GetNeighborCell(cell, Vector2.new(1, 0)))
	self:FillEmptyCells(self:_GetNeighborCell(cell, Vector2.new(0, -1)))
	self:FillEmptyCells(self:_GetNeighborCell(cell, Vector2.new(0, 1)))
end


function Grid:GenerateGui(parent: Instance?) : {TextButton}
	assert(typeof(parent) == "nil" or typeof(parent) == "Instance", "Argument #1 expected Instance. Got " .. typeof(parent))

	local guiElements = {}

	-- Creating the TextButtons.
	for rowNumber = 1, self.Dimensions.Y do
		for collumnNumber = 1, self.Dimensions.X do
			table.insert(
				guiElements,
				self.Grid[rowNumber][collumnNumber]:GenerateGui(parent)
			)
		end
	end

	return guiElements
end


function Grid:PlaceFlagOnCell(cell: Cell.Cell) : boolean
	assert(typeof(cell) == "table", "Argument #1 expected Cell. Got " .. typeof(cell))
	assert(self:_IsLocationWithinGrid(cell.Location), "Cell out of bounds, bounds = [" .. tostring(self.Dimensions) .. "]. Got [" .. tostring(cell.Location) .. "]")

	-- Does this cell already have a flag?
	-- If so we want to remove the flag.
	if cell.IsFlagged then
		self.FlagCount -= 1
		cell.IsFlagged = false
		self.FlagCountUpdated:Fire(self.FlagCount)

		return false
	end

	-- Can we place this flag?
	if self.FlagCount == self.BombCount then
		return false
	else
		self.FlagCount += 1
		cell.IsFlagged = true
		self.FlagCountUpdated:Fire(self.FlagCount)

		return true
	end
end

-- Private Methods
function Grid:_GenerateGrid(randomSeed: number?)
	assert(typeof(randomSeed) == "nil" or typeof(randomSeed) == "number", "Argument #1 expected Number. Got " .. typeof(randomSeed))

	local numberOfBombsGenerated = 0
	local rawBombGenerationOdds = self.BombCount / (self.Dimensions.X * self.Dimensions.Y)
	local randomInstance = Random.new(randomSeed or os.clock())

	-- On the first pass we don't check for border cells.
	for rowNumber = 1, self.Dimensions.Y do
		for collumnNumber = 1, self.Dimensions.X do
			self.Grid[rowNumber] = self.Grid[rowNumber] or {}

			-- Should we even try to generate a bomb?
			if numberOfBombsGenerated < self.BombCount then
				local numberOfTilesLeft = (self.Dimensions.Y - rowNumber) * self.Dimensions.X + (self.Dimensions.X - collumnNumber + 1)

				-- If the odds say so or we're forced to we make a bomb.
				if randomInstance:NextNumber() <= rawBombGenerationOdds or numberOfTilesLeft == (self.BombCount - numberOfBombsGenerated) then
					numberOfBombsGenerated += 1

					self.Grid[rowNumber][collumnNumber] = Cell.new(
						self,
						Vector2.new(collumnNumber, rowNumber),
						Cell.CELL_TYPES.BOMB
					)
				else
					self.Grid[rowNumber][collumnNumber] = Cell.new(
						self,
						Vector2.new(collumnNumber, rowNumber),
						Cell.CELL_TYPES.EMPTY
					)
				end
			else
				self.Grid[rowNumber][collumnNumber] = Cell.new(
					self,
					Vector2.new(collumnNumber, rowNumber),
					Cell.CELL_TYPES.EMPTY
				)
			end
		end
	end

	-- On the second pass we do check for border cells.
	for rowNumber = 1, self.Dimensions.Y do
		for collumnNumber = 1, self.Dimensions.X do
			if self.Grid[rowNumber][collumnNumber]:Is(Cell.CELL_TYPES.EMPTY) then

				local numberOfBombsNearCell = 0

				-- Getting the number of bombs around this cell.
				for neighborRowNumber = rowNumber - 1, rowNumber + 1 do
					for neighborCollumnNumber = collumnNumber - 1, collumnNumber + 1 do
						if self:_IsLocationWithinGrid(Vector2.new(neighborCollumnNumber, neighborRowNumber)) and self.Grid[neighborRowNumber][neighborCollumnNumber]:Is(Cell.CELL_TYPES.BOMB) then
							numberOfBombsNearCell += 1
						end
					end
				end

				if numberOfBombsNearCell > 0 then
					self.Grid[rowNumber][collumnNumber] = Cell.new(
						self,
						Vector2.new(collumnNumber, rowNumber),
						Cell.CELL_TYPES.BORDER,
						numberOfBombsNearCell
					)
				end
			end
		end
	end
end


function Grid:_GetNeighborCell(cell: Cell.Cell, stepVector: Vector2) : Cell.Cell?
	assert(typeof(cell) == "table", "Argument #1 expected Cell. Got " .. typeof(cell))
	assert(typeof(stepVector) == "Vector2", "Argument #2 expected Vector2. Got " .. typeof(stepVector))

	if not self:_IsLocationWithinGrid(Vector2.new(cell.Location.X + stepVector.X, cell.Location.Y + stepVector.Y)) then
		return
	end

	return self.Grid[cell.Location.Y + stepVector.Y][cell.Location.X + stepVector.X]
end


function Grid:_IsLocationWithinGrid(location: Vector2) : boolean
	assert(typeof(location) == "Vector2", "Argument #1 expected Vector2. Got " .. typeof(location))

	return (location.X > 0 and location.X <= self.Dimensions.X) and (location.Y > 0 and location.Y <= self.Dimensions.Y)
end

--
export type Grid = typeof(Grid.new(Vector2.new(), 0))
return Grid