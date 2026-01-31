local blockManager = require("blockManager")

-- Code taken from KateBulka's Jump Blocks

local noteBlocks = {}
noteBlocks.idMap = {}

-- taken from MDA's extendedKoopas
local function setConfigDefault(config, name, value)
    	if config[name] == nil then
        	config:setDefaultProperty(name, value)
    	end
end

function noteBlocks.register(blockID)
	blockManager.registerEvent(blockID, noteBlocks, "onTickEndBlock")
	noteBlocks.idMap[blockID] = true

	local config = Block.config[blockID]

	setConfigDefault(config, "playerBumpHeight", 6)
	setConfigDefault(config, "playerBounceHeight", Defines.jumpheight_noteblock)

	setConfigDefault(config, "bounceNPCs", true)
	setConfigDefault(config, "npcBounceHeight", 6)

	setConfigDefault(config, "bumpSFX", 3)
	setConfigDefault(config, "bounceSFX", 1)
	setConfigDefault(config, "sfxVolume", 1)
end

function noteBlocks.onInitAPI()
	registerEvent(noteBlocks, "onBlockHit")
	registerEvent(noteBlocks, "onDraw")
end

function noteBlocks.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) or Defines.levelFreeze then return end

	local blockCfg = Block.config[v.id]

	-- The actual code
        for k, p in ipairs(Player.get()) do
		if Colliders.bounce(p, v) or v:collidesWith(p) == 1 then
			if blockCfg.bumpSFX then SFX.play(blockCfg.bumpSFX, blockCfg.sfxVolume) end
			v:hit(true)

			if p.keys.jump or p.keys.altJump then 
				if blockCfg.bounceSFX then SFX.play(blockCfg.bounceSFX, blockCfg.sfxVolume) end
				p:mem(0x11C, FIELD_WORD, blockCfg.playerBounceHeight)
			end

			p.speedY = -blockCfg.playerBumpHeight
		end
	end

	-- NPCs can bounce too
	if blockCfg.bounceNPCs then
		for k, n in ipairs(NPC.getIntersecting(v.x, v.y - 1, v.x + v.width, v.y)) do
			if n.collidesBlockBottom and v.y >= n.y + n.height and not n.isHidden and n.heldIndex == 0 and n.forcedState == 0 then
				if blockCfg.bumpSFX then SFX.play(blockCfg.bumpSFX, blockCfg.sfxVolume) end
				v:hit(true)
		
				n.collidesBlockBottom = true
				n.speedY = -blockCfg.npcBounceHeight
			end
		end
	end
end

function noteBlocks.onBlockHit(event, v, fromUpper, p)
    	if not noteBlocks.idMap[v.id] then return end

	-- 1.3 note block stuff
	if not fromUpper and p and type(p) == "Player" then
		p.speedY = 3
	end

	-- Make a new data thingy for later
	v.data.thePreviousNoteOrMusicOrJumpBlockID = v.id
end

-- Really hacky method but it works. Thanks "Master" of Disaster!
function noteBlocks.onDraw()
	for k, v in Block.iterate(2) do
		if v.data.thePreviousNoteOrMusicOrJumpBlockID then
			v:transform(v.data.thePreviousNoteOrMusicOrJumpBlockID, false)
		end
	end
end

return noteBlocks