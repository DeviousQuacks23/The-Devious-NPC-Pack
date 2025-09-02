local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local jetZokTroop = {}
local npcID = NPC_ID

local jetZokTroopSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 68,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 14,

	frames = 12,
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
	nogravity = true,
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

        spikeballID = 641,
}

npcManager.setNpcSettings(jetZokTroopSettings)

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
local SWOOP = 1
local DROP = 2
local RISE = 3
local SPIKEBALL = 4

function jetZokTroop.onInitAPI()
	npcManager.registerEvent(npcID, jetZokTroop, "onTickEndNPC")
end

function jetZokTroop.onTickEndNPC(v)
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
                data.cooldown = 0
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-200,-50},{-200,50}),
                        [1] = Colliders.Tri(0,0,{0,0},{200,-50},{200,50}),
                }
                data.visionCollider[-1]:Rotate(-45)
                data.visionCollider[1]:Rotate(45)
                end
                if data.visionCollider2 == nil then
                data.visionCollider2 = Colliders.Tri(0,0,{0,0},{-250,-20},{-250,20})
                data.visionCollider2:Rotate(-90)
                end
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

        data.visionCollider2.x = v.x + 0.5 * v.width
        data.visionCollider2.y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = math.floor(lunatime.tick() / 4) % 4
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1
        data.cooldown = data.cooldown - 1

        if data.state == WANDER then
                v.animationFrame = math.floor(data.timer / 4) % 4
                v.speedY = 0.4 * -math.sin(data.timer * 0.04)
	        local p = npcutils.getNearestPlayer(v)	
	        local dist = (p.x + 0.5 * p.width) - (v.x + 0.5 * v.width)	
	        if math.abs(dist) > 48 then v.speedX = math.clamp(v.speedX + 0.01 * math.sign(dist), -0.6, 0.6) end
                for k,p in ipairs(Player.get()) do
                        if data.cooldown <= 0 then
                                if Colliders.collide(data.visionCollider[v.direction], p) then
                                        data.state = (RNG.randomInt(1, 2) == 1 and SPIKEBALL) or SWOOP
                                        data.timer = 0
                                        v.speedX = 0
                                        v.speedY = 0
                                elseif Colliders.collide(data.visionCollider2, p) then
                                        data.state = DROP
                                        data.timer = 0
                                        v.speedX = 0
                                        v.speedY = 0
                                end
                        end
                end
        elseif data.state == SWOOP then
                v.animationFrame = math.floor(data.timer / 4) % 4 + 4
                v.speedY = v.speedY - Defines.npc_grav
                if data.timer < 24 then 
		        if (data.timer % 4) == 0 then SFX.play(10) end
                        v.speedY = 0 
                        if data.timer%4 > 0 and data.timer%4 < 3 then
                                v.x = v.x - 2
                        else
                                v.x = v.x + 2
                        end
                elseif data.timer == 24 then 
                        SFX.play(Misc.resolveSoundFile("sound/character/ub_lunge.wav"), 0.75) 
                        npcutils.faceNearestPlayer(v)
                        v.speedX = RNG.random(2, 6) * v.direction
                        v.speedY = RNG.random(6, 12)
                elseif data.timer > 32 then         
                        if v.y <= v.spawnY then
                                data.state = WANDER
                                data.cooldown = 50
                                data.timer = 0
                        end        
                end
        elseif data.state == DROP then
                v.animationFrame = math.floor(data.timer / 4) % 4
                v.speedY = v.speedY + Defines.npc_grav
                if v.collidesBlockBottom then
	                local a = Animation.spawn(10, 0, 0)
		                a.x = v.x - 3
		                a.y = v.y - a.height/2+32			
		                a.speedX  = -1.5
	                local b = Animation.spawn(10, 0, 0)
		                b.x = v.x + v.width + 3 - b.width
	                        b.y = a.y
		                b.speedX = 1.5
                        SFX.play(3)
                        data.state = RISE
                        v.speedX = 0
                end
        elseif data.state == RISE then
                v.animationFrame = math.floor(data.timer / 4) % 4 + 4
                v.speedY = math.min(-4, v.speedY + 0.4)
                if v.y <= v.spawnY then
                        data.state = WANDER
                        data.cooldown = 50
                        data.timer = 0
                end
        elseif data.state == SPIKEBALL then
                if data.timer == 1 then SFX.play(73) end
                npcutils.faceNearestPlayer(v)
                if v.y > v.spawnY then
                        v.y = math.max(v.spawnY, v.y - 3)
                elseif v.y < v.spawnY then
                        v.y = math.min(v.spawnY, v.y + 3)
                end
                if data.timer >= 16 then
                        v.animationFrame = math.floor(data.timer / 4) % 4 + 8
                else
                        v.animationFrame = math.floor(data.timer / 4) % 4 + 4
                end
                if data.timer == 16 then
	                SFX.play(25)
	                local sb = NPC.spawn(config.spikeballID, v.x, v.y + v.height, v:mem(0x146, FIELD_WORD), false)
	                sb.direction = v.direction
	                sb.layerName = "Spawned NPCs"
	                sb.speedX = 4 * v.direction
	                sb.speedY = 3
	                sb.friendly = v.friendly
                end
                if data.timer >= 24 then
                        npcutils.faceNearestPlayer(v)
                        data.state = WANDER
                        data.cooldown = 50
                        data.timer = 0
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return jetZokTroop