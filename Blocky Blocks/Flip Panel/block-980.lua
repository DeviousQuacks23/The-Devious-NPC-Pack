local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local easing = require("ext/easing")

local flipPanel = {}
local blockID = BLOCK_ID

local flipPanelSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 
	passthrough = false, 

	width = 64,
	height = 64,

	-- Custom

	scaleSpeed = 0.075,
	flashTime = 25,
	disappearSFX = Misc.resolveSoundFile("number-platform-countdown"),
}

blockManager.setBlockSettings(flipPanelSettings)

function flipPanel.onInitAPI()
	blockManager.registerEvent(blockID, flipPanel, "onTickBlock")
	blockManager.registerEvent(blockID, flipPanel, "onCameraDrawBlock")
end

local function init(v, data)
	data.init = true

	data.lerp = data.lerp or 1
	data.scale = data.scale or 0
	data.isFlashing = data.isFlashing or false
	data.flipPlaced = data.flipPlaced or false
	data.timer = data.timer or 0
end

function flipPanel.onTickBlock(v)
    	if not blockutils.hiddenFilter(v) then return end

	local data = v.data
    	local config = Block.config[v.id]

	if not data.init then
		init(v, data)
	end

	data.lerp = math.min(1, data.lerp + config.scaleSpeed)

	local scaleTime = (1 / config.scaleSpeed)
	local scaleLerp = math.lerp(1, 0, (data.timer / scaleTime))

	if data.flipPlaced and (data.timer <= scaleTime) then
		data.scale = easing.inBack(scaleLerp, 1, -1, 1, 3)
	else
		data.scale = easing.outElastic(data.lerp, 0, 1, 1, 2, 1)
	end

	if data.flipPlaced then
		data.timer = math.max(0, data.timer - 1)

		if data.timer <= config.flashTime then
			if not data.isFlashing then
				data.isFlashing = true
			end
		end

		if data.timer <= 0 then
			for i = 1, 4 do
				local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.5)
				e.speedX = ({-2, -2, 2, 2})[i]
				e.speedY = ({-3, 3, -3, 3})[i]
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
			end

			if config.disappearSFX then
				blockutils.playSound(v.id, config.disappearSFX)
			end

			v:delete()

		end
	end
end

function flipPanel.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

	local data = v.data
    	local config = Block.config[v.id]

	if not data.init then
		init(v, data)
	end

    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	local img = Graphics.sprites.block[v.id].img
    	local priority = -64

	blockutils.setBlockFrame(v.id, -1000)
	if data.scale <= 0 then return end

	Graphics.drawBox{
		texture = img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + v:mem(0x56,FIELD_WORD),
		width = v.width * data.scale,
		height = v.height * data.scale,
		sourceX = ((data.isFlashing and 1) or 0) * v.width,
		sourceY = frame * v.height,
		sourceWidth = v.width,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}
end

return flipPanel