--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local buddies = require("swipinStus")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 48,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	nowaterphysics = true,
	cliffturn = false, -- Makes the NPC turn on ledges
	
	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	
	patrolSpeed = 2,
	patrolTime = 128,
	chaseTime = 160,
	chaseSpeed = 5,
	chaseAccuracy = 0.25,
	fallSpeed = 0.5,
	detectionWidth = 8,
	detectionHeight = 10,
	isBandit = false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
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
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

buddies.register(npcID)

--Gotta return the library table!
return sampleNPC