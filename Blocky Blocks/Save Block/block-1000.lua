local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

-- Save Block sprite by BrokenAce, code taken from Marioman2007's Checkpoint Zones

local saveBlock = {}
local blockID = BLOCK_ID

local saveBlockSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8, 

        bumpable = true,

	lightradius=48,
	lightbrightness=1,
	lightcolor=Color.white,
}

blockManager.setBlockSettings(saveBlockSettings)

function saveBlock.onInitAPI()
	blockManager.registerEvent(blockID, saveBlock, "onStartBlock")
	blockManager.registerEvent(blockID, saveBlock, "onTickBlock")
	registerEvent(saveBlock, "onBlockHit")
end

local function initialize(v, data)
	if data.checkpoint ~= nil then return end

    	data.checkpoint = Checkpoint{
        	x = v.x + v.width/2,
        	y = v.y + v.height,
        	section = blockutils.getBlockSection(v),
        	sound = 58,
    	}
end

-- override basegame's onStart, hacky, but it's the only way
local oldOnStart = Checkpoint.onStart

Checkpoint.onStart = function()
    	for k, v in Block.iterate({blockID}) do
        	initialize(v, v.data)
    	end

    	oldOnStart()
end

function saveBlock.onStartBlock(v)
	initialize(v, v.data)
end

function saveBlock.onTickEndBlock(v)
	initialize(v, v.data)
end

function saveBlock.onBlockHit(event, v, fromUpper, p)
	local data = v.data
	if v.id == BLOCK_ID then
		if data.checkpoint ~= nil and not data.checkpoint.collected then
                	Checkpoint.reset()
			data.checkpoint:collect(p)
                        local e = Effect.spawn(blockID, v.x + v.width * 0.5,v.y)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height
                end
	end
end

return saveBlock