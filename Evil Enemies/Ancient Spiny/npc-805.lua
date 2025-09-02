local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ancientSpiny = {}
local npcID = NPC_ID

local ancientSpinySettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 48,
	width = 48,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 12, 

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
	noiceball = true,
	noyoshi= true, 

	score = 4, 

	jumphurt = true, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 2,

	-- Custom Properties

	speed = 0.4,
	health = 3,

	wanderTime = 4,
	turnInterval = 24,

	minFramespeed = 10,
	maxFramespeed = 16,

	spitTime = 2,
	spitInterval = 12,

	spitID = 525,
	spitSFX = 18,

	spitSpeedMinX = 1,
	spitSpeedMaxX = 6,
	spitSpeedMinY = -1,
	spitSpeedMaxY = -6,
}

npcManager.setNpcSettings(ancientSpinySettings)

local deathEffectID = (npcID - 2)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_OFFSCREEN
	},
	{
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

local WANDER = 0
local SPIT = 1

function ancientSpiny.onInitAPI()
	npcManager.registerEvent(npcID, ancientSpiny, "onTickEndNPC")
	registerEvent(ancientSpiny, "onNPCHarm")
end

function ancientSpiny.onNPCHarm(e, v, r, c)
	if v.id ~= npcID then return end
	local data = v.data
	if type(c) == "NPC" and c.id == 13 and data.hp > 1 then
		e.cancelled = true
		data.hp = data.hp - 1
		SFX.play(9)
		Effect.spawn(75, c.x, c.y)
	end
end

function ancientSpiny.onTickEndNPC(v)
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
		data.state = WANDER
		data.hp = config.health
		data.frameSpeed = RNG.randomInt(config.minFramespeed, config.maxFramespeed)
		data.spitFrame = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

	data.timer = data.timer + 1

	if data.state == WANDER then
		v.speedX = config.speed * v.direction
		v.animationFrame = math.floor(data.timer / data.frameSpeed) % (config.frames / 2)
		if (data.timer % config.turnInterval) == 0 then npcutils.faceNearestPlayer(v) end
		if data.timer >= lunatime.toTicks(config.wanderTime) then
			data.state = SPIT
			data.spitFrame = v.animationFrame + (config.frames / 2)
			data.timer = 0
		end
	elseif data.state == SPIT then
		v.speedX = 0
		v.animationFrame = data.spitFrame
		if (data.timer % config.spitInterval) == 0 then 
			fire = NPC.spawn(config.spitID, (v.x + (v.width * 0.5)) + ((v.width * 0.5) * v.direction), v.y, v.section, false, false)
			fire.x = fire.x - (fire.width * 0.5)
			fire.speedX = ((RNG.random(config.spitSpeedMinX, config.spitSpeedMaxX)) * v.direction)
			fire.speedY = RNG.random(config.spitSpeedMinY, config.spitSpeedMaxY)
			fire.layerName = "Spawned NPCs"
			fire.friendly = v.friendly
			if config.spitSFX then SFX.play(config.spitSFX) end
		end
		if data.timer >= lunatime.toTicks(config.spitTime) then
			data.state = WANDER
			data.timer = 0
			data.frameSpeed = RNG.randomInt(config.minFramespeed, config.maxFramespeed)
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return ancientSpiny