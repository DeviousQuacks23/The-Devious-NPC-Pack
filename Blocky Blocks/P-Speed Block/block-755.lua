local blockManager = require("blockManager")

local pSpeedBlock = {}
local blockID = BLOCK_ID

local pSpeedBlockSettings = {
	id = blockID,

	frames = 4,
	framespeed = 8, 
}

blockManager.setBlockSettings(pSpeedBlockSettings)

local characterPSpeeds = {
	[CHARACTER_MARIO] = 35,
	[CHARACTER_LUIGI] = 40,
	[CHARACTER_PEACH] = 80,
	[CHARACTER_TOAD]  = 60,
	[CHARACTER_LINK]  = 10,
}

function pSpeedBlock.onInitAPI()
	blockManager.registerEvent(blockID, pSpeedBlock, "onTickEndBlock")
end

function pSpeedBlock.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

        for k,p in ipairs(Player.get()) do
		if v:collidesWith(p) == 1 then
			if p.powerup == 4 or p.powerup == 5 then
				p:mem(0x168, FIELD_FLOAT, characterPSpeeds[p.character])
				p:mem(0x16C, FIELD_BOOL, 1)
			end
		end
	end	
end

return pSpeedBlock