local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local invisWalkways = {}

function invisWalkways.register(blockID)
	blockManager.registerEvent(blockID, invisWalkways, "onCameraDrawBlock")
end

local function getDistance(v, config)
	local data = v.data

	if not data.init then
		data.init = true
		data.opacity = 0
		data.range = Colliders:Circle()
		data.fadeSpeed = 0
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5
	data.range.radius = config.radius

	local n = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
    	local playerDistanceX, playerDistanceY, playerDistance = math.huge, math.huge, math.huge
	local average = ((v.width + v.height) / 2) * config.distScale

        if n then
        	playerDistanceX = (n.x + (n.width / 2)) - (v.x + (v.width / 2))
        	playerDistanceY = (n.y + (n.height / 2)) - (v.y + (v.height / 2))
        	playerDistance = math.abs(playerDistanceX) + math.abs(playerDistanceY)

		data.opacity = (average / playerDistance) * data.fadeSpeed

                if Colliders.collide(data.range, n) then
			data.fadeSpeed = math.min(1, data.fadeSpeed + config.fadeSpeed)
		else
			data.fadeSpeed = math.max(0, data.fadeSpeed - config.fadeSpeed)
		end
	end

	return data.opacity
end

function invisWalkways.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]
    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
    	local priority = -64

	if getDistance(v, config) <= 0 then return end

	Graphics.drawBox{
		texture = Graphics.sprites.block[v.id].img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5,
		width = v.width,
		height = v.height,
		sourceY = frame * v.height,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		color = Color.white .. getDistance(v, config),
		priority = priority,
	}

	blockutils.setBlockFrame(v.id, -1000)
end

return invisWalkways