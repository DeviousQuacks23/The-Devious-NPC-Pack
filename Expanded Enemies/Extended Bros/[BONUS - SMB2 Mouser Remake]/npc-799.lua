local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local bro = require("extendedBros")

local mrBoombastic = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (134)

local mrBoombasticSettings = {
	id = npcID,

	gfxheight = 64,
	gfxwidth = 48,
	height = 56,
	width = 40,

	gfxoffsety = 2,

	frames = 9,
	framestyle = 1,
	framespeed = 4,

	score = 8,
	weight = 2,

	npcblock = false, 
	npcblocktop = true, 
	playerblock = false, 
	playerblocktop = true,

	noiceball = true,
	noyoshi= true,

	-- Custom properties

	holdoffsetx = 12,
	holdoffsety = 28,
	throwoffsetx = 18,
	throwoffsety = -12,

	waitframeslow = 20,
	waitframeshigh = 80,
	holdframes = 20,

	walkframes = 64,
	jumpframes = 100,
	jumptimerange = 200,
	jumpspeed = 5,
	brospeed = 2,

	animjumpframes = 1,
	animholdframes = 1,
	animshootframes = 1,
	disableanimation = true,

	movewhenjumping = false,
	movewhenshooting = false,
	shootonground = true,
	throwid = throwID,

	onThrowFunction = (function(bro, ham, data, config)
		local v = ham

		v.speedX = RNG.random(5, 8) * v.direction
	        v.speedY = RNG.random(-5, -8)	
	end),

	-- Exclusive to this NPC
	animhurtframes = 4,
	legacyBossMusic = 15,
	health = 4,  
}

npcManager.setNpcSettings(mrBoombasticSettings)
npcManager.registerHarmTypes(npcID,
	{
		-- HARM_TYPE_JUMP,
		-- HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		-- HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		-- HARM_TYPE_HELD,
		-- HARM_TYPE_TAIL,
		-- HARM_TYPE_SPINJUMP,
		-- HARM_TYPE_OFFSCREEN,
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

bro.register(npcID)

function mrBoombastic.onInitAPI()
	npcManager.registerEvent(npcID, mrBoombastic, "onTickEndNPC")
	npcManager.registerEvent(npcID, mrBoombastic, "onDrawNPC")
	registerEvent(mrBoombastic, "onNPCHarm")
end

function mrBoombastic.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.health = config.health
		data.immune = 0
		data.walkTimerPoll = 0
		data.throwTimerPoll = 0
		data.jumpTimerPoll = 0
		data.directionPoll = -1
		data.hasSetMusic = data.hasSetMusic or false
	end

	if v.despawnTimer >= 10 then
		if v.legacyBoss and not data.hasSetMusic and config.legacyBossMusic ~= nil then
			v.sectionObj.music = config.legacyBossMusic
		end
		
		v.despawnTimer = math.max(100, v.despawnTimer)
	end

	data.immune = math.max(0, data.immune - 1)

	if data.immune > 0 then
		data.walkTimer = data.walkTimerPoll
		data.throwTimer = data.throwTimerPoll
		data.jumpTimer = (data.jumpTimerPoll + 2)

		if data.throwingID ~= nil then data.throwingID = nil end
		v.x = v.x - v.speedX

		if data.immune % 12 == 0 then
			data.directionPoll = -data.directionPoll
		end
	else
		data.walkTimerPoll = data.walkTimer
		data.throwTimerPoll = data.throwTimer
		data.jumpTimerPoll = data.jumpTimer
		data.directionPoll = data.facingDirection
	end

	-- No turning around from other NPCs
	if v:mem(0x120, FIELD_BOOL) and not (v.collidesBlockLeft or v.collidesBlockRight) then
		v:mem(0x120, FIELD_BOOL, false)
	end

	--[[
	Text.print(data.immune,0,0) -- Debug stuff
	Text.print(data.health,0,16)
	Text.print(data.walkTimer, 0, 32)
	Text.print(data.throwTimer, 0, 48)
	Text.print(data.jumpTimer, 0, 64)
	Text.print(data.walkTimerPoll, 0, 80)
	Text.print(data.throwTimerPoll, 0, 96)
	Text.print(data.jumpTimerPoll, 0, 112)
	Text.print(data.throwingID, 0, 128)
	Text.print(data.facingDirection, 0, 144)
	Text.print(data.directionPoll, 0, 160)
	]]
end

function mrBoombastic.onDrawNPC(v)
	local data = v.data._basegame
        local config = NPC.config[v.id]

	if not v.data._basegame then return end

	local direction = data.directionPoll or v.direction
	local bro = v

	-- Ripped stright from the AI library

	utils.restoreAnimation(bro)
	walk = utils.getFrameByFramestyle(bro, {
		frames = config.animwalkframes,
		gap = config.animjumpframes + config.animholdframes + config.animshootframes + config.animhurtframes,
		offset = 0,
		direction = direction
	})
	jump = utils.getFrameByFramestyle(bro, {
		frames = config.animjumpframes,
		gap = config.animholdframes + config.animshootframes + config.animhurtframes,
		offset = config.animwalkframes,
		direction = direction
	})
	hold = utils.getFrameByFramestyle(bro, {
		frames = config.animholdframes,
		gap = config.animshootframes + config.animhurtframes,
		offset = config.animwalkframes + config.animjumpframes,
		direction = direction
	})
	shoot = utils.getFrameByFramestyle(bro, {
		frames = config.animshootframes,
		gap = config.animhurtframes,
		offset = config.animwalkframes + config.animjumpframes + config.animholdframes,
		direction = direction
	})
	hurt = utils.getFrameByFramestyle(bro, {
		frames = config.animhurtframes,
		gap = 0,
		offset = config.animwalkframes + config.animjumpframes + config.animholdframes + config.animshootframes,
		direction = direction
	})

	if data.immune and data.immune > 0 then	
		bro.animationFrame = hurt
	elseif data.throwAnimTimer > 0 and config.animshootframes > 0 then
		bro.animationFrame = shoot
	elseif data.throwingID ~= nil then
		bro.animationFrame = hold
	elseif (not bro.collidesBlockBottom) and config.animjumpframes > 0 then
		bro.animationFrame = jump
	else
		bro.animationFrame = walk
	end
end

function mrBoombastic.onNPCHarm(e, v, r, c) 
        if v.id ~= npcID then return end

	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	e.cancelled = true
	if data.immune > 0 then return end

	if r == 3 then
		if type(c) == "NPC" and c.id == 13 then
			data.health = data.health - 0.2
			SFX.play(9)
		else
			data.immune = 60
			data.health = data.health - 1
			SFX.play(39)

			if type(c) == "NPC" then
				c:harm(3)
			end
		end
	elseif r == 10 then
		data.immune = 20
		data.health = data.health - 0.4
		SFX.play(39)
	end

	if data.health <= 0 then
		v:kill(r)
	end
end

return mrBoombastic