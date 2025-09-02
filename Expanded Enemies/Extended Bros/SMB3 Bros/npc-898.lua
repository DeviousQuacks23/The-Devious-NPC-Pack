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
	linkshieldable = true,
	noshieldfireeffect = true,

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
	end

	data.rotation = data.rotation + 15 * v.direction
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