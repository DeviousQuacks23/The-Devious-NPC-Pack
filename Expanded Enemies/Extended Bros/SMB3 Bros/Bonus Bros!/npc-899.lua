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

	ignorethrownnpcs = true,
	linkshieldable = false,
	nogravity = 1,

	jumphurt = 1,
	noblockcollision = 1,
    	noyoshi = 1,
	noiceball = 1,
}

npcManager.setNpcSettings(hammerSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_OFFSCREEN}, {});

function hammer.onInitAPI()
	npcManager.registerEvent(npcID, hammer, "onTickEndNPC")
	npcManager.registerEvent(npcID, hammer, "onDrawNPC")
	registerEvent(hammer, "onPlayerHarm")
	registerEvent(hammer, "onNPCHarm")
end

function hammer.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0

		data.tail = {}
		data.tailTimer = 0
		data.totalAfterImages = 0
	end

	data.rotation = data.rotation + 30 * v.direction

	if RNG.randomInt(1, 3) == 1 then
       		local e = Effect.spawn(265, v.x + RNG.randomInt(0, v.width), v.y + RNG.randomInt(0, v.height))
	end
end

function hammer.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden or not v.data.initialized then return end

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

	-- Afterimage trails (by 9thCore)

	local afterImageThreshold = 90
	local maxAfterImages = 16
	local afterImageInterval = 2

	if not Misc.isPaused() then
		data.tailTimer = data.tailTimer + 1

		if data.totalAfterImages < maxAfterImages and 1/Routine.deltaTime > Misc.GetEngineTPS()*afterImageThreshold/100 and data.tailTimer % afterImageInterval == 0 then
			data.totalAfterImages = data.totalAfterImages + 1

			local spr = Sprite{texture = img, frames = npcutils.getTotalFramesByFramestyle(v)}
			spr.position = vector(v.x + v.width/2, v.y + v.height/2)
			spr.rotation = data.rotation
			spr.pivot = vector(0.5,0.5)
			spr.texpivot = vector(0.5,0.5)

			data.tail[spr] = 1
		end

	end

	for s,a in pairs(data.tail) do
		if not Misc.isPaused() then a = a - 1/16 end

		data.tail[s] = a

		if a <= 0 then 
			data.tail[s] = nil data.totalAfterImages = data.totalAfterImages - 1
		else
			s:draw{frame = v.animationFrame+1, priority = priority-1, sceneCoords = true, color = Color.white..a}
		end
	end
end

-- Sniped: the code

function hammer.onPlayerHarm(e, p)
    	if e.cancelled then return end

	for _,v in ipairs(NPC.get({npcID})) do
                if Colliders.collide(v, p) and Misc.canCollideWith(v, p) then
			SFX.play("sniperBro-hit.ogg")

                        local e = Effect.spawn(npcID, p.x + p.width * 0.5, p.y + p.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
                end
	end
end

function hammer.onNPCHarm(e, v, r, c)
    	if e.cancelled then return end
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end

	for _,n in ipairs(NPC.get({npcID})) do
                if Colliders.collide(n, v) and Misc.canCollideWith(n, v) and n.data.isHeldHammer then
			SFX.play("sniperBro-hit.ogg")

                        local e = Effect.spawn(npcID, v.x + v.width * 0.5, v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
                end
	end
end
return hammer