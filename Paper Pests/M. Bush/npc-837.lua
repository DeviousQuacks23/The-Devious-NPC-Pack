local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

local mBush = {}
local npcID = NPC_ID

local mBushSettings = {
	id = npcID,

	gfxwidth = 56,
	gfxheight = 48,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 7,
	framestyle = 0,
	framespeed = 8, 

	luahandlesspeed = true, 

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

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 
}

npcManager.setNpcSettings(mBushSettings)

local deathEffectID = (npcID)

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
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

local HIDING = 0
local AMBUSH = 1
local NORMAL = 2

function effectconfig.onInit.INIT_SETDIR_MBUSH(v)
	if v.speedX > 0 then
		v.direction = -1
	elseif v.speedX < 0 then
		v.direction = 1
	elseif v.speedX == 0 then
		v.direction = RNG.irandomEntry({-1, 1})
	end
end

function effectconfig.onTick.TICK_MBUSH(v)
	v.speedX = 3 * v.direction
	v.rotation = 15 * v.direction
end

function effectconfig.onDeath.DEATH_MBUSH(v)
	SFX.play(Misc.resolveSoundFile("leaf"))
	local e = Effect.spawn(10, v.x, v.y)
        e.x = e.x - e.width * 0.5
        e.y = e.y - e.height * 0.5
	for j = 1, RNG.randomInt(12, 32) do
                local e = Effect.spawn(74, v.x, v.y)
		e.speedX = RNG.random(-6, 6)
		e.speedY = RNG.random(-6, 6)
	end  
end

function mBush.onInitAPI()
	npcManager.registerEvent(npcID, mBush, "onTickEndNPC")
end

function mBush.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = (v.data._settings.dontStartHidden and NORMAL) or HIDING
		data.timer = 0
		data.range = Colliders:Circle()
	end

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = 160

	if v.heldIndex ~= 0  or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end
	
	-- Main AI

	data.timer = data.timer + 1

	if data.state == HIDING then
		v.animationFrame = 0
		v.speedY = -Defines.npc_grav
        	if v.speedX > 0 then
            		v.speedX = v.speedX - 0.05
        	elseif v.speedX < 0 then
            		v.speedX = v.speedX + 0.05
        	end
        	if v.speedX >= -0.05 and v.speedX <= 0.05 then
            		v.speedX = 0
        	end
        	for k,p in ipairs(Player.get()) do
                	if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) then
				data.state = AMBUSH
				data.timer = 0
                        	v.speedY = -8
				Animation.spawn(10, v.x, v.y)
                        	local e = Effect.spawn(1, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
				SFX.play(4)
                        	SFX.play(25)
                	end
        	end
	elseif data.state == AMBUSH then
		v.animationFrame = math.floor(data.timer / 4) % 2 + 1
        	if v.speedX > 0 then
            		v.speedX = v.speedX - 0.05
        	elseif v.speedX < 0 then
            		v.speedX = v.speedX + 0.05
        	end
        	if v.speedX >= -0.05 and v.speedX <= 0.05 then
            		v.speedX = 0
        	end
		if data.timer > 2 and v.collidesBlockBottom then
			npcutils.faceNearestPlayer(v)
			data.state = NORMAL
			data.timer = 0
		end
	elseif data.state == NORMAL then
		v.animationFrame = math.floor(data.timer / 6) % 4 + 3
		v.speedX = 1.5 * v.direction
		if data.timer % 50 == 0 then npcutils.faceNearestPlayer(v) end
	end
end

return mBush