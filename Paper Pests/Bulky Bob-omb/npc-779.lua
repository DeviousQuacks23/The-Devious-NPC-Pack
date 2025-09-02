local npcManager = require("npcManager")
local AI = require("bulkyBobbys")

local bulky = {}
local npcID = NPC_ID

local bulkySettings = table.join({
	id = npcID,

	wanderSpeed = 1.6,
	chaseSpeed = 3,
	turnDelay = 20,

	smokeDelay = 8,

	kaboomDelay = 400,
	fuseTime = 80,

	explosionEffect = 774,
	earthquake = 12,
	useBulkyExplosion = true,
},AI.sharedSettings)

npcManager.setNpcSettings(bulkySettings)

local deathEffectID = (776)

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

return bulky