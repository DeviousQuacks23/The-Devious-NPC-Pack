local npcManager = require("npcManager")

local brickProjectile = {}
local npcID = NPC_ID

local brickProjectileSettings = {
	id = npcID,
	gfxheight = 16,
	gfxwidth = 16,
	height = 16,
	width = 16,
	frames = 4,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	framestyle = 0,
	jumphurt = 1,
	noblockcollision = 1,
	nofireball = true,
        noyoshi = 1,
	noiceball = 1,
	speed = 0,
	score = 2
}

npcManager.setNpcSettings(brickProjectileSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	},
	{
	}
);

function brickProjectile.onInitAPI()
	npcManager.registerEvent(npcID, brickProjectile, "onTickEndNPC")
end

function brickProjectile.onTickEndNPC(v)
	if Defines.levelFreeze then return end

        if v.underwater then
		v.speedY = v.speedY + 0.15
        else	
		v.speedY = v.speedY - 0.15
        end
end

return brickProjectile