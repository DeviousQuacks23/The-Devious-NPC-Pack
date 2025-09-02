local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local helmetZokTroop = {}
local npcID = NPC_ID

local helmetZokTroopSettings = {
	id = npcID,

	gfxwidth = 44,
	gfxheight = 54,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 9,
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

	-- Custom Properties

        helmetEffect = npcID - 1,
}

npcManager.setNpcSettings(helmetZokTroopSettings)

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
local CHARGE = 1
local KNOCKED = 2

function helmetZokTroop.onInitAPI()
	npcManager.registerEvent(npcID, helmetZokTroop, "onTickEndNPC")
	registerEvent(helmetZokTroop, "onNPCHarm")
end

function helmetZokTroop.onTickEndNPC(v)
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
                data.hasHelmet = true
                data.timer = 0
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-250,-50},{-250,50}),
                        [1] = Colliders.Tri(0,0,{0,0},{250,-50},{250,50}),
                }
                end
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = 8
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if data.state == WANDER then
                v.speedX = 0.85 * v.direction
                if data.hasHelmet then
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 12) % 4
                        else
                                v.animationFrame = 1
                        end
                else
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 12) % 4 + 4
                        else
                                v.animationFrame = 5
                        end
                end
                if data.timer % RNG.randomInt(50, 500) == 0 then v.direction = -v.direction end
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                SFX.play(Misc.resolveSoundFile("chuck-whistle"))
                                data.state = CHARGE
                                v.speedX = 0
                                v.speedY = -5
                        end
                end
        elseif data.state == CHARGE then
                if data.hasHelmet then
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 4) % 4
                        else
                                v.animationFrame = 1
                        end
                else
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 4) % 4 + 4
                        else
                                v.animationFrame = 5
                        end
                end
                if v.collidesBlockBottom then
		        if (data.timer % RNG.randomInt(8, 16)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                else
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                end
                        end
                end
	        local player = npcutils.getNearestPlayer(v)	
	        local dist = (player.x + 0.5 * player.width) - (v.x + 0.5 * v.width)	
                if v.collidesBlockBottom then
	                if v.collidesBlockLeft or v.collidesBlockRight then v.speedY = -4 SFX.play(3) end
	                if math.abs(dist) > 16 then
		                v.speedX = math.clamp(v.speedX + 0.1 * math.sign(dist), -2, 2)
                        end
	        end
        elseif data.state == KNOCKED then
                v.animationFrame = 8
                if v.collidesBlockBottom and data.timer > 1 then
                        v.speedX = 0
                        for k,p in ipairs(Player.get()) do
                                if Colliders.collide(data.visionCollider[v.direction], p) then
                                        data.state = CHARGE
                                else
                                        data.state = WANDER
                                end
                        end
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

function helmetZokTroop.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        local data = v.data
        local config = NPC.config[npcID]
	
        if data.hasHelmet then
	        if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		        if culprit then
			        if culprit.__type == "Player" then
				        eventObj.cancelled = true
                                        culprit.speedX = math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2)))*3.5
                                        v.speedX = 0
                                        v.speedY = -2
				        SFX.play(3)
			        end
		        end
                elseif reason ~= HARM_TYPE_LAVA and reason ~= HARM_TYPE_OFFSCREEN then
                        local e = Effect.spawn(config.helmetEffect,v.x + v.width*0.5,v.y + v.height*0.5)
                        --e.x = e.x - e.width*0.5
                        --e.y = e.y - e.height*0.5
		        eventObj.cancelled = true
		        SFX.play(2)
                        data.state = KNOCKED
                        data.hasHelmet = false
                        data.timer = 0
                        v.speedX = -4 * v.direction
                        v.speedY = -4
		        if type(culprit) == "NPC" then
			        culprit:harm(HARM_TYPE_NPC)
		        end          
	        end
        elseif reason ~= HARM_TYPE_LAVA and reason ~= HARM_TYPE_OFFSCREEN then
                Misc.givePoints(2,vector(v.x + (v.width/2),v.y),true)
	end	
end

return helmetZokTroop