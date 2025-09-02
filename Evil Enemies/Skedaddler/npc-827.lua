local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Sprites by Deltom

local skedaddler = {}
local npcID = NPC_ID

local skedaddlerSettings = {
	id = npcID,

	gfxwidth = 54,
	gfxheight = 66,
	width = 24,
	height = 56,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	frames = 6,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = false, 
	nowaterphysics = false,
	cliffturn = false, 
	staticdirection = false, 

	npcblock = false, 
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false, 

	score = 2,

	jumphurt = false, 
	spinjumpsafe = false,
	harmlessgrab = false, 
	harmlessthrown = false, 
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

        -- Custom Properties

        delay = 80,
        projectile = (npcID + 1),

	radius = 145,

	maxSpeed = 5.95,
	acceleration = 0.085,
        deceleration = 0.15,
}

npcManager.setNpcSettings(skedaddlerSettings)

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

local SHOOT = 0
local RUN = 1

function skedaddler.onInitAPI()
	npcManager.registerEvent(npcID, skedaddler, "onTickEndNPC")
end

function skedaddler.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]

	local p = npcutils.getNearestPlayer(v)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true

		data.range = Colliders:Circle()
		data.wasRunning = false
		data.unRunTimer = 0
		data.state = SHOOT
                data.timer = 0
                data.animTimer2 = 0
                data.animTimer = 0
	end

	data.range.x = (v.x + v.width * 0.5)
	data.range.y = (v.y + v.height * 0.5)
	data.range.radius = cfg.radius

	if v.heldIndex ~= 0 
	or v.isProjectile  
	or v.forcedState > 0
	then
		return
	end
	
	-- Squirrel AI

        data.animTimer2 = data.animTimer2 - 1
	data.animTimer = data.animTimer + 1
	data.unRunTimer = data.unRunTimer - 1

        if Colliders.collide(data.range,p) then
		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = SHOOT

			data.unRunTimer = 0
			data.wasRunning = false
		else
			data.state = RUN
		end
        else
		data.state = SHOOT
        end

	local dir = -math.sign((p.x + p.width/2) - (v.x - v.width/2))

        if data.state == RUN then
		data.wasRunning = true
		data.unRunTimer = 20
	        if not v.collidesBlockLeft and not v.collidesBlockRight then 
			v.speedX = math.lerp(v.speedX, cfg.maxSpeed * dir, cfg.acceleration) 
		end
                v.animationFrame = math.floor(data.animTimer / 4) % 3 + 3
	elseif data.state == SHOOT then
		if data.unRunTimer <= 0 then
                	if data.wasRunning then
				data.timer = 0
				v.animationFrame = math.floor(data.animTimer / 4) % 3 + 3
				if v.speedX > 0 then
                        		v.speedX = math.max(0, v.speedX - cfg.deceleration)
                		elseif v.speedX < 0 then
                        		v.speedX = math.min(0, v.speedX + cfg.deceleration)
                		else
                        		v.speedX = 0
                		end
				if v.speedX == 0 then
					data.wasRunning = false
				end
			else
				npcutils.faceNearestPlayer(v)
				data.timer = data.timer + 1
                		if data.timer == cfg.delay then
					local pj = NPC.spawn(cfg.projectile, v.x + 16 * v.direction, v.y, v.section)
					pj.direction = v.direction
					pj.speedX = 2.5 * pj.direction
					pj.despawnTimer = 100
					pj.friendly = v.friendly
					pj.layerName = "Spawned NPCs"
				
					SFX.play(38)
                        		data.timer = 0
                        		data.animTimer2 = 20
				end


                		if data.timer >= (cfg.delay * 0.85) then
                        		v.animationFrame = 1
                		elseif data.animTimer2 > 0 then
                        		v.animationFrame = 2
                		else
                        		v.animationFrame = 0
                		end
                	end
		else
			v.animationFrame = math.floor(data.animTimer / 4) % 3 + 3
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

return skedaddler