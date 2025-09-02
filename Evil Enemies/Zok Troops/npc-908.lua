local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bigZokRing = {}
local npcID = NPC_ID

local bigZokRingSettings = {
	id = npcID,

	gfxwidth = 192,
	gfxheight = 124,
	width = 96,
	height = 96,
	gfxoffsetx = 0,
	gfxoffsety = 14,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = true,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	iselectric = true,

	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 12,
	lightcolor = Color.lightblue,

	-- Custom Properties

        radius = 46,
        rotationSpeed = 2,
        ringSpeed = 0.5,

        waveHeight = -1.6,
        waveSpeed = 0.05,

        scaleSpeed = 0.01,

        sparkEffect = npcID - 1,
        sparkVariants = 4,
}

npcManager.setNpcSettings(bigZokRingSettings)

local deathEffectID = (10)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

function bigZokRing.onInitAPI()
	npcManager.registerEvent(npcID, bigZokRing, "onTickEndNPC")
	npcManager.registerEvent(npcID, bigZokRing, "onDrawNPC")
	registerEvent(bigZokRing, "onNPCHarm")
end

function bigZokRing.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.range = Colliders:Circle()
                data.scale = 0
                data.rotation = 0
                data.timer = 0
	end
	
	-- Main AI

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = config.radius

        if data.scale >= 1 then
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) and not v.friendly then
                                p:harm()
                        end
                end
        end

        if data.scale < 1 then data.scale = data.scale + config.scaleSpeed end
        data.rotation = data.rotation + config.rotationSpeed * v.direction

	if (data.timer % RNG.randomInt(8, 16)) == 0 then
		local e = Effect.spawn(config.sparkEffect, 0, 0, RNG.randomInt(1, config.sparkVariants), v.id, false)
		e.x = v.x + RNG.random(0, v.width) - e.width * 0.5
	        e.y = v.y + RNG.random(0, v.height) - e.height * 0.5
        end

        data.timer = data.timer + 1

        v.speedX = config.ringSpeed * v.direction
        v.speedY = math.sin(data.timer * config.waveSpeed) * config.waveHeight
end

local lowPriorityStates = table.map{1,3,4}

function bigZokRing.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45
	
	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth * data.scale,
		height = config.gfxheight * data.scale,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
		centered = true,
                rotation = data.rotation,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

function bigZokRing.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        local data = v.data

        local correctAngle = data.rotation % 180
        if correctAngle <= 40 or correctAngle >= 140 then return end

	if reason == HARM_TYPE_JUMP then
		if culprit then
			if culprit.__type == "Player" then
				eventObj.cancelled = true
                                culprit:harm()
			end
		end
        elseif reason == HARM_TYPE_SPINJUMP then
		if culprit then
			if culprit.__type == "Player" then
				eventObj.cancelled = true
			end
	        end
	end	
end

return bigZokRing