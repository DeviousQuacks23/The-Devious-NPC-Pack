local blockManager = require("blockManager")

-- Editor symbol based on sprites by Smuglutena

local smokeAndMirrors = {}
local blockID = BLOCK_ID

blockManager.setBlockSettings({
	id = blockID,

	frames = 1,
	framespeed = 8,

	sizable = true, 
	passthrough = true, 

	exitWarpSizableID = (blockID + 1),
})

function smokeAndMirrors.onInitAPI()
	Graphics.sprites.block[blockID].img = Graphics.loadImageResolved("stock-0.png")
	blockManager.registerEvent(blockID, smokeAndMirrors, "onTickBlock")
end

function smokeAndMirrors.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

	local config = Block.config[v.id]
	local settings = v.data._settings
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
    			for _,b in ipairs(Block.get({config.exitWarpSizableID})) do
				local pathSettings = b.data._settings
				
				if not b.isHidden and not v:mem(0x5A, FIELD_BOOL) and not b.layerObj.isHidden then
					if pathSettings.index and pathSettings.index > 0 then
						if settings.index and settings.index > 0 and settings.index == pathSettings.index then
							p:teleport(b.x + (p.x-v.x), b.y + (p.y-v.y))
							if settings.resetSpeed then p.speedX, p.speedY = 0, 0 end
						end
					end
				end
			end
		end
	end
end

return smokeAndMirrors