local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local noteBlock = {}
local blockID = BLOCK_ID

local noteBlockSettings = {
	id = blockID,

	width = 64,
	height = 64,

	frames = 4,
	framespeed = 8,
	bumpable = true,
}

blockManager.setBlockSettings(noteBlockSettings)

local AI = require("noteBlocks")
AI.register(blockID)

function noteBlock.onInitAPI()
	blockManager.registerEvent(blockID, noteBlock, "onCameraDrawBlock")
end

function noteBlock.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]

    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
    	local priority = -64

	Graphics.drawBox{
		texture = Graphics.sprites.block[v.id].img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + (v:mem(0x56,FIELD_WORD) * 2),
		width = v.width,
		height = v.height,
		sourceY = frame * v.height,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	blockutils.setBlockFrame(v.id, -1000)
end

return noteBlock