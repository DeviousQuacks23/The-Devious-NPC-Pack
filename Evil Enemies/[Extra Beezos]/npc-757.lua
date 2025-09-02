local npcManager = require("npcManager")

local spear = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 6,
	gfxwidth = 32,
	width = 32,
	height = 6,
	frames = 1,
	framestyle = 1,
	jumphurt = 1,
	nofireball=1,
	noiceball =1,
	noyoshi=1,
	ignorethrownnpcs = true,
	linkshieldable=true,
	nogravity=-1,
	noblockcollision=-1,
	staticdirection = true, 
	spinjumpsafe=false
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN
	},
	{		});

function spear.onInitAPI()
	npcManager.registerEvent(npcID, spear, "onTickNPC")
	npcManager.registerEvent(npcID, spear, "onDrawNPC")
end

function spear.onTickNPC(v)
	if Defines.levelFreeze then return end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end

	v.speedX = 8 * v.direction
        v.ai2 = v.ai2 + 1
end

function spear.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	if v.ai2 >= 16 then
		Graphics.drawBox{
			texture = Graphics.sprites.npc[npcID].img,
			
			x = v.x + v.width * 0.5,
			y = v.y + v.height * 0.5,
			
			width = (v.width * 2) + v.ai1,
			height = v.height + v.ai1,

		        sourceY = v.ai3 * NPC.config[v.id].gfxheight,
		        sourceHeight = NPC.config[v.id].gfxheight,
			
			sceneCoords = true,
                        centered = true,
			
			priority = -45,
		}
		
		v.animationFrame = -99
                v.ai1 = math.min(8, v.ai1 + 0.25) -- Visually make it expand in size to make it easier to see
                v.ai3 = ((v.direction == -1 and 0) or 1)
	end
end

return spear
