local npcManager = require("npcManager")
local AI = require("koopatrol_ai")

local koopaKnight = {}
local npcID = NPC_ID

local koopaKnightSettings = table.join({
	id = npcID,

	wanderSpeed = 2,
	chargeSpeed = 8,
	jumpHeight = -6,
	knockbackX = 3,
	knockbackY = -8,
	bounceHeight = -4,
	
	shellID = 797,
},AI.sharedSettings)

npcManager.setNpcSettings(koopaKnightSettings)

local deathEffectID = (783)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = {id=deathEffectID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

AI.register(npcID)

return koopaKnight