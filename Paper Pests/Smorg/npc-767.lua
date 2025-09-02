local npcManager = require("npcManager")

local smorg = {}
local npcID = NPC_ID

-- Sprites by A.J. Nitro

local smorgSettings = {
	id = npcID,

	gfxwidth = 38,
	gfxheight = 38,
	width = 30,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 4, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	staticdirection = false, 

	-- Custom Properties

        deathEffect = 760,

	jumpDelay = 10,

	jumpSpeedX = 2,
	jumpSpeedY = -3,
}

npcManager.setNpcSettings(smorgSettings)

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
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

function smorg.onInitAPI()
	npcManager.registerEvent(npcID, smorg, "onTickEndNPC")
	registerEvent(smorg, "onPostNPCKill")
end

function smorg.onPostNPCKill(v, reason)
    	if v.id ~= npcID or (reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN or reason == HARM_TYPE_SWORD) then return end

        local config = NPC.config[v.id]

    	local e = Effect.spawn(config.deathEffect, v.x + v.width * 0.5,v.y + v.height * 0.5, v.animationFrame + 1)
    	e.x = e.x - e.width * 0.5
    	e.y = e.y - e.height * 0.5
end

function smorg.onTickEndNPC(v)
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
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

	if v.collidesBlockBottom then
		data.timer = data.timer + 1
		v.speedX = 0
		if data.timer >= config.jumpDelay then	
			v.speedX = RNG.irandomEntry({-config.jumpSpeedX,config.jumpSpeedX})
			v.speedY = config.jumpSpeedY
			SFX.play("smorg"..RNG.randomInt(1, 3)..".ogg")
		end
	else
		data.timer = 0
	end

	--Prevent them from not turning around from other NPCs
	if v:mem(0x120, FIELD_BOOL) and not (v.collidesBlockLeft or v.collidesBlockRight) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

return smorg