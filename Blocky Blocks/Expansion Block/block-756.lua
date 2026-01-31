local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local eggspansionBlock = {}
local blockID = BLOCK_ID

local eggspansionBlockSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 

	bumpable = true, 
}

blockManager.setBlockSettings(eggspansionBlockSettings)

function eggspansionBlock.onInitAPI()
	blockManager.registerEvent(blockID, eggspansionBlock, "onTickBlock")
    	blockManager.registerEvent(blockID, eggspansionBlock, "onCameraDrawBlock")
	registerEvent(eggspansionBlock, "onBlockHit")
end

function eggspansionBlock.onBlockHit(event, v, fromUpper, p)
	if v.id == BLOCK_ID then
		event.cancelled = true

		if not v.data.eggspanded then
			SFX.play("expansionBlock.ogg")

			v.data.eggspanded = true
			v.data.hasBumped = false
			v.data.timer = 300
		end
	end
end

function eggspansionBlock.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
    	if not data.initialized then
    		data.initialized = true

		data.spawnY = v.y
		data.eggspanded = false
		data.timer = 0
		data.hasBumped = false
	end

	data.timer = data.timer - 1

	local oldHeight = v.height
	local oldWidth = v.width

	if data.eggspanded then
		if data.timer <= 0 then data.eggspanded = false end
		v:setSize(math.min(64, v.width + 4), math.min(64, v.height + 4))

		if not data.hasBumped then
			v:translate(0, math.max((data.spawnY - 72) - v.y, -4))
			if v.y <= (data.spawnY - 72) then data.hasBumped = true end
		else
			v:translate(0, math.min((data.spawnY - 64) - v.y, 1))
		end
	else
		v:setSize(math.max(32, v.width - 2), math.max(32, v.height - 2))
		v:translate(0, math.min(data.spawnY - v.y, 2))
	end

	v:translate(oldWidth / 2 - v.width / 2, oldHeight - v.height)
end

function eggspansionBlock.onCameraDrawBlock(v,camIdx)
    	if not blockutils.visible(Camera(camIdx),v.x,v.y,v.width,v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]
    	local data = v.data

    	if data.sprite == nil then
        	data.sprite = Sprite{texture = Graphics.sprites.block[v.id].img,frames = config.frames,pivot = Sprite.align.TOPLEFT}
    	end

    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames) + 1
    	local priority = -64
    
    	data.sprite.x = v.x
    	data.sprite.y = v.y

	data.sprite.width = v.width
	data.sprite.height = v.height

    	data.sprite:draw{frame = frame,priority = priority,sceneCoords = true}

	blockutils.setBlockFrame(v.id,-1000)
end

return eggspansionBlock