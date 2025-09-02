local npcManager = require("npcManager")
local ai = require("pipelessJumpingPiranha")

local piranhaPlant = {}
local npcID = NPC_ID

local piranhaPlantSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 48,
	
	frames = 4,
	framestyle = 1,
	framespeed = 6,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true, -- We'll use our own gravity
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
	staticdirection = true,

	-- Custom:

	jumpStartSpeed     = -6,      -- How fast the NPC moves when first jumping off the ground.
	jumpRisingGravity  = 0.1,     -- The gravity of the NPC while rising.
	jumpFallingGravity = 0.01,    -- The gravity of the NPC while falling.
	jumpMaxSpeed       = 1,       -- The terminal velocity of the NPC while falling.
	smallBounces       = 6,       -- How many small bounces the NPC does before jumping up.
	smallBounceHeight  = -1.5,    -- How high the small bounces are.

	isHorizontal = false,	      -- Is the piranha plant horizontal?

	scaleStretchSpeed = 0.05,     -- The speed of the NPC's scale movement.
	scaleX = 1.3,		      -- The stretch of the NPC's X scale. Set to 1 to have no scale.
	scaleY = 0.7,		      -- The stretch of the NPC's Y scale. Set to 1 to have no scale.

	defaultFireID = 527,  	      -- The NPC ID of the fire shot by the NPC. If nil or 0, no fire will be shot.
	fireSound     = 18,           -- The sound effect to play when shooting fire. If nil or 0, no sound will play.
}

npcManager.setNpcSettings(piranhaPlantSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]            = 10,
		[HARM_TYPE_FROMBELOW]       = 10,
		[HARM_TYPE_NPC]             = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_HELD]            = 10,
		[HARM_TYPE_TAIL]            = 10,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

ai.register(npcID)

return piranhaPlant