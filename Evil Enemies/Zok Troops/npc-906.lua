local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ringZokTroop = {}
local npcID = NPC_ID

local ringZokTroopSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 52,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 7,
	framestyle = 1,
	framespeed = 8, 

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

	score = 2, 

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

	-- Custom Properties

        ringID = npcID + 1,
        largeRingID = npcID + 2,

        sparkEffect = npcID + 1,
        sparkVariants = 4,
}

npcManager.setNpcSettings(ringZokTroopSettings)

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

local WANDER = 0
local THROW = 1
local BIGTHROW = 2

function ringZokTroop.onInitAPI()
	npcManager.registerEvent(npcID, ringZokTroop, "onTickEndNPC")
end

function ringZokTroop.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[npcID]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = WANDER
                data.timer = 0
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-250,-100},{-250,100}),
                        [1] = Colliders.Tri(0,0,{0,0},{250,-100},{250,100}),
                }
                end
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = 1
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if data.state == WANDER then
                if v.collidesBlockBottom then
                        v.animationFrame = math.floor(data.timer / 6) % 4
                else
                        v.animationFrame = 1
                end
                v.speedX = 1.2 * v.direction
                if data.timer % 40 == 0 then npcutils.faceNearestPlayer(v) end
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                data.state = (RNG.randomInt(1, 4) == 1 and BIGTHROW) or THROW
                                data.timer = 0
                                v.speedX = 0
                        end
                end
        elseif data.state == THROW then
                v.animationFrame = math.floor(data.timer / 24) % 3 + 4
		if (data.timer % RNG.randomInt(8, 16)) == 0 then
		        local e = Effect.spawn(config.sparkEffect, 0, 0, RNG.randomInt(1, config.sparkVariants), v.id, false)
		        e.x = v.x + RNG.random(0, v.width) - e.width * 0.5
		        e.y = v.y + RNG.random(0, v.height) - e.height * 0.5
                end
                if data.timer == 48 then
	                SFX.play(41)
		        local e = Effect.spawn(10, v.x + (32 * v.direction), v.y)
		        e.x = e.x - e.width * 0.5
		        e.y = e.y - e.height * 0.5
	                local ring = NPC.spawn(config.ringID, v.x + (32 * v.direction), v.y, v:mem(0x146, FIELD_WORD), false)
	                npcutils.hideNPC(ring)
	                ring.direction = v.direction
	                ring.layerName = "Spawned NPCs"
	                ring.speedX = 0
	                ring.speedY = 0
	                ring.friendly = v.friendly
                end
                if data.timer >= 72 then
                        data.timer = 0
                        for k,p in ipairs(Player.get()) do
                                if not Colliders.collide(data.visionCollider[v.direction], p) then
                                        data.state = WANDER
                                else
                                        if RNG.randomInt(1, 4) == 1 then
                                                data.state = BIGTHROW
                                        end
                                end
                        end
                end
        elseif data.state == BIGTHROW then
                v.animationFrame = math.floor(data.timer / 48) % 3 + 4
		if (data.timer % RNG.randomInt(4, 8)) == 0 then
		        local e = Effect.spawn(config.sparkEffect, 0, 0, RNG.randomInt(1, config.sparkVariants), v.id, false)
		        e.x = v.x + RNG.random(0, v.width) - e.width * 0.5
		        e.y = v.y + RNG.random(0, v.height) - e.height * 0.5
                end
                if data.timer == 96 then
	                SFX.play(41)
		        local e = Effect.spawn(10, v.x + (64 * v.direction), v.y - 16)
		        e.x = e.x - e.width * 0.5
		        e.y = e.y - e.height * 0.5
	                local ring = NPC.spawn(config.largeRingID, v.x + (64 * v.direction), v.y - 16, v:mem(0x146, FIELD_WORD), false)
	                npcutils.hideNPC(ring)
	                ring.direction = v.direction
	                ring.layerName = "Spawned NPCs"
	                ring.speedX = 0
	                ring.speedY = 0
	                ring.friendly = v.friendly
                end
                if data.timer >= 144 then
                        data.timer = 0
                        for k,p in ipairs(Player.get()) do
                                if not Colliders.collide(data.visionCollider[v.direction], p) then
                                        data.state = WANDER
                                else
                                        if RNG.randomInt(1, 4) ~= 1 then
                                                data.state = THROW
                                        end
                                end
                        end
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return ringZokTroop