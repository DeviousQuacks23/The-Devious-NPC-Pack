local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local hammer = {}
local npcID = NPC_ID

local hammerSettings = {
	id = npcID,

	gfxheight = 32,
	gfxwidth = 32,

	height = 32,
	width = 32,

	frames = 1,
	framespeed = 8,
	framestyle = 1,

	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,

	jumphurt = 1,
	noblockcollision = 0,
    	noyoshi = 1,
	noiceball = 1,

	totalBounces = 2,
	bounceEffect = npcID,
}

npcManager.setNpcSettings(hammerSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_OFFSCREEN}, {});

function hammer.onInitAPI()
	npcManager.registerEvent(npcID, hammer, "onTickEndNPC")
	npcManager.registerEvent(npcID, hammer, "onDrawNPC")
end

function hammer.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
		data.rotation = 0
		data.bounces = 0
	end

	data.timer = data.timer + 1
	if data.timer % 2 == 0 then
		data.rotation = data.rotation + 45 * v.direction
	end

	-- Yoinked from Beetroot code (by MrNameless)

	if v.collidesBlockUp or v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
		data.bounces = data.bounces + 1

		local hittedBlock = false
		local hittedBrittle = false
		
		for i,b in Block.iterateIntersecting(v.x - 2,v.y -4, v.x + v.width + 2, v.y + v.height + 4) do
			if b.isHidden == false and b:mem(0x5A, FIELD_BOOL) == false then
				if Block.MEGA_SMASH_MAP[b.id] then 
					if b.contentID > 0 then 
						b:hitWithoutPlayer(false)
					else
						b:remove(true)
						hittedBrittle = true
					end
					hittedBlock = true
				elseif (Block.SOLID_MAP[b.id] or Block.PLAYERSOLID_MAP[b.id] or Block.MEGA_HIT_MAP[b.id]) then 
					b:hitWithoutPlayer(false)
					hittedBlock = true
				end
			end
		end
		
		if not v.collidesBlockUp then v.speedY = -4 end
		v.speedX = -v.speedX

		Effect.spawn(config.bounceEffect, v)
		SFX.play(9)
		
		if data.bounces >= config.totalBounces then
			v.noblockcollision = true
			v.friendly = true
		end
	end

	if v:mem(0x120, FIELD_BOOL) and not (v.collidesBlockLeft or v.collidesBlockRight) then
		v:mem(0x120, FIELD_BOOL, false)
	end

        if RNG.randomInt(1, 15) == 1 then
                local e = Effect.spawn(80, v.x + RNG.randomInt(0, v.width), v.y + RNG.randomInt(0, v.height))
                e.speedX = RNG.random(-1, 1)
                e.speedY = RNG.random(-1, 1)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
	end
end

function hammer.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden or not v.data.rotation then return end

	local config = NPC.config[v.id]
	local data = v.data

	local img = Graphics.sprites.npc[v.id].img

	local lowPriorityStates = table.map{1,3,4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    	Graphics.drawBox{
        	texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
        	width = config.gfxwidth,
		height = config.gfxheight,
        	sourceY = v.animationFrame * config.gfxheight,
        	sourceHeight = config.gfxheight,
        	sceneCoords = true,
        	centered = true,
        	priority = priority,
		rotation = data.rotation
    	}

	npcutils.hideNPC(v)
end

return hammer