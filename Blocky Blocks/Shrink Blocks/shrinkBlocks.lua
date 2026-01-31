local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local shrinkBlocks = {}

function shrinkBlocks.register(blockID)
	blockManager.registerEvent(blockID, shrinkBlocks, "onTickBlock")
	blockManager.registerEvent(blockID, shrinkBlocks, "onCameraDrawBlock")
end

function shrinkBlocks.onTickBlock(v)
    	if not blockutils.hiddenFilter(v) then return end

	local data = v.data
    	local config = Block.config[v.id]

	data.shrink = data.shrink or false
	data.ogHeight = data.ogHeight or v.height

	if data.shrink then
		local scaleSpeed = config.shrinkSpeed

		v:setSize(v.width - scaleSpeed, v.height - scaleSpeed)
		v:translate((scaleSpeed / 2), (scaleSpeed / 2))

		if v.width <= config.minimumSize or v.height <= config.minimumSize then
			if config.vanishSFX then
				SFX.play(config.vanishSFX)
			end

			for i = 1, 4 do
				local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.5)
				e.speedX = ({-2, -2, 2, 2})[i]
				e.speedY = ({-3, 3, -3, 3})[i]
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
			end

			v:delete()
		end
	else
        	for k,p in ipairs(Player.get()) do
			if v:collidesWith(p) ~= 0 then
				data.shrink = true

				if config.shrinkSFX then
					SFX.play(config.shrinkSFX)
				end
			end
		end
	end
end

function shrinkBlocks.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]
    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	local img = Graphics.sprites.block[v.id].img
    	local priority = -64

	Graphics.drawBox{
		texture = img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + v:mem(0x56,FIELD_WORD),
		width = v.width,
		height = v.height,
		sourceY = frame * (v.data.ogHeight or v.height),
		sourceHeight = (v.data.ogHeight or v.height),
		sceneCoords = true,
		centered = true,
		priority = priority,
	}
end

return shrinkBlocks