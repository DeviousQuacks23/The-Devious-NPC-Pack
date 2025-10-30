local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local easing = require("ext/easing")
local redirector = require("redirector")

-- Some help from Marioman2007

local directionalBlock = {}
local blockID = BLOCK_ID

local directionalBlockSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 

	bumpable = true, 
}

blockManager.setBlockSettings(directionalBlockSettings)

function directionalBlock.onInitAPI()
	blockManager.registerEvent(blockID, directionalBlock, "onTickBlock")
    	blockManager.registerEvent(blockID, directionalBlock, "onCameraDrawBlock")
	registerEvent(directionalBlock, "onBlockHit")
end

function directionalBlock.onBlockHit(event, v, fromUpper, p)
	if v.id ~= blockID then
		return
	end

	local data = v.data

	event.cancelled = true

	if data.canBump and not data.occupied and not data.disabled then
		data.canBump = false
		data.occupied = true
		data.scalingUp = true

		SFX.play(23)
		SFX.play(2)

		if data.direction == 0 then
			data.goalY = v.y - 44
		elseif data.direction == 1 then
			data.goalX = v.x - 44
		elseif data.direction == 2 then
			data.goalX = v.x + 44
		end
	end
end

function directionalBlock.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
    	if not data.initialized then
    		data.initialized = true
		data.direction = v.data._settings.dir

		data.occupied = false
		data.canBump = true
		data.disabled = false

		data.goalX = v.x
		data.goalY = v.y
		data.spawnX = v.x
		data.spawnY = v.y

		data.scale = 1
		data.scaleTimer = 0
		data.scalingUp = false
	end

	if data.scalingUp then
		if data.scaleTimer < 5 then
			data.scale = easing.outQuad(data.scaleTimer, 1, 1.5 - 1, 5)
		else
			data.scale = easing.inQuad(data.scaleTimer - 5, 1.5, 1 - 1.5, 5)
		end
		
		
		if data.scaleTimer >= 10 then
			data.scalingUp = false
			data.scale = 1
		else
			data.scaleTimer = data.scaleTimer + 1
		end
	else
		data.scaleTimer = 0
		data.scale = 1
	end

	if data.occupied then
		if data.direction == 0 then
			v:translate(0, math.max(data.goalY - v.y, -8))

			if v.y <= data.goalY then 
				data.spawnY = v.y + 12
				data.goalY = 0
				data.occupied = false
			end
		elseif data.direction == 1 then
			v:translate(math.max(data.goalX - v.x, -8), 0)

			if v.x <= data.goalX then 
				data.spawnX = v.x + 12
				data.goalX = 0
				data.occupied = false
			end
		elseif data.direction == 2 then
			v:translate(math.min(data.goalX - v.x, 8), 0)

			if v.x >= data.goalX then 
				data.spawnX = v.x - 12
				data.goalX = 0
				data.occupied = false
			end
		end
	else
		if data.direction == 0 then
			v:translate(0, math.min(data.spawnY - v.y, 2))

			if v.y == data.spawnY then
				data.canBump = true
			end
		elseif data.direction == 1 then
			v:translate(math.min(data.spawnX - v.x, 2), 0)

			if v.x == data.spawnX then
				data.canBump = true
			end
		elseif data.direction == 2 then
			v:translate(math.max(data.spawnX - v.x, -2), 0)

			if v.x == data.spawnX then
				data.canBump = true
			end
		end

		if data.canBump then
			for _, bgo in ipairs(BGO.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if bgo.id == redirector.TERMINUS then 
					data.disabled = true
				end
			end
		end
	end
end

function directionalBlock.onCameraDrawBlock(v,camIdx)
	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

	local config = Block.config[v.id]
	local data = v.data

	local frame = data.direction

	Graphics.drawBox{
		texture = Graphics.sprites.block[v.id].img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5,
		width = v.width * data.scale,
		height = v.height * data.scale,
		sourceY = frame * v.height,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	blockutils.setBlockFrame(v.id, -1000)
end

return directionalBlock