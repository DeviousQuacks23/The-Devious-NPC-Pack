local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local moneybag = {}

local npcID = NPC_ID
local deathEffectID = (760)

local moneybagSettings = {
	id = npcID,

	gfxwidth = 44,
	gfxheight = 36,
	width = 40,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 3,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= false, 
	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 
	isstationary = true,

	-- Custom Properties

	health = 6,

	jumpCooldown = 10,
	jumpSpeedX = 5,
	jumpSpeedY = -4,
	jumpSFX = ("frog-hop.wav"),

	jumpVolley = 4,
	jumpVolleyCool = 25,

	coinCount = 5,
	coinID = 33,
	spitSFX = 38,
}

npcManager.setNpcSettings(moneybagSettings)
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

function moneybag.onInitAPI()
	npcManager.registerEvent(npcID, moneybag, "onTickEndNPC")
        registerEvent(moneybag, "onNPCHarm") 
        registerEvent(moneybag, "onPostNPCKill") 
end

local function animateMe(v)
	if v.collidesBlockBottom then
	        v.animationFrame = 0
        else
		if v.speedY > 0 then
	        	v.animationFrame = 2
		else
	        	v.animationFrame = 1
		end
	end

        v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = v.animationFrame})
end

function moneybag.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		
		data.jumpTimer = 0
		data.jumpCount = 0
		data.volleyCooldown = 0
		data.hp = config.health
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		animateMe(v)
		return
	end

        local p = npcutils.getNearestPlayer(v)
        local sign = -math.sign(p.x + p.width/2 - v.x - v.width/2)
	if sign == 0 then sign = v.direction end

	v:mem(0x120, FIELD_BOOL, false) 

	if v.collidesBlockBottom then
		data.volleyCooldown = data.volleyCooldown - 1
		data.jumpTimer = data.jumpTimer + 1

		if data.jumpTimer >= config.jumpCooldown and data.volleyCooldown <= 0 then
                        v.speedX = sign * config.jumpSpeedX
			v.speedY = config.jumpSpeedY
			data.jumpCount = data.jumpCount + 1
			data.jumpTimer = 0

			if config.jumpSFX then
				SFX.play(config.jumpSFX)
			end
		end

		if data.jumpCount >= config.jumpVolley then
			data.volleyCooldown = config.jumpVolleyCool
			data.jumpCount = 0
		end
	else
		data.jumpTimer = 0
	end

	animateMe(v)
end

local function spitACoin(v, cfg)
	if not cfg.coinID or cfg.coinID <= 0 then return end

	local coin = NPC.spawn(cfg.coinID, v.x + v.width * 0.5, v.y + v.height * 0.5)
        coin.x = coin.x - coin.width * 0.5
	coin.y = coin.y - coin.height * 0.5
	coin.speedX = RNG.random(-6, 6)
	coin.speedY = RNG.random(-2, -10)
	coin.layerName = "Spawned NPCs"
	coin.friendly = v.friendly

	if NPC.config[coin.id].iscoin then
		coin.ai1 = 1
	end

	if cfg.spitSFX then
		SFX.play(cfg.spitSFX)
	end
end

function moneybag.onNPCHarm(e, v, r, c) 
        if v.id ~= npcID then return end

	local data = v.data
	local cfg = NPC.config[v.id]

	if (r == 3 and type(c) == "NPC" and c.id == 13) or r == 1 then
		if data.hp > ((r == 1 and 2) or 1) then
			e.cancelled = true
			data.hp = data.hp - ((r == 1 and 2) or 1)

			SFX.play(9)
			if c then Effect.spawn(75, c) end
			spitACoin(v, cfg)
		end
	end
end

function moneybag.onPostNPCKill(v, r) 
        if v.id ~= npcID then return end
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end

	local cfg = NPC.config[v.id]

	if (cfg.coinCount > 0) then
                for i = 1, cfg.coinCount do
			spitACoin(v, cfg)
               	end
	end
end

return moneybag