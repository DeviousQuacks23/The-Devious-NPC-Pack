local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")
local particles = require("particles")

local jumpOrb = {}

jumpOrb.shineParticle = Misc.resolveFile("jumpOrbParticle.ini")
jumpOrb.bounceTexture = Graphics.loadImageResolved("jumpOrbPulse.png")
jumpOrb.ringTexture = Graphics.loadImageResolved("jumpOrbRing.png")

local bounceEffects = {}
local ringEffects = {}

jumpOrb.sharedSettings = {
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 0,
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
	notcointransformable = true, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

        -- Custom Settings

        bounceHeight = -10,

        bounceEffectColour = Color.fromHexRGB(0xF8C040),
        shineColour = Color.fromHexRGB(0xF8C040),
}

function jumpOrb.register(npcID)
	npcManager.registerEvent(npcID, jumpOrb, "onTickEndNPC")
	npcManager.registerEvent(npcID, jumpOrb, "onDrawNPC")
        lineguide.registerNpcs(npcID)
end

function jumpOrb.onInitAPI()
        registerEvent(jumpOrb, "onTick")
        registerEvent(jumpOrb, "onDraw")
end

function jumpOrb.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.range = Colliders:Circle()
                data.hasEffected = false
                data.scale = 1
                data.cooldown = 0
	        data.effect = {particle = particles.Emitter(0,0, jumpOrb.shineParticle), nocull = false, priority = -50, tint = cfg.shineColour or Color.white, timescale = 1}
		data.effect.particle:attach(v)
	end

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = 16

        data.cooldown = data.cooldown - 1

        if data.cooldown > 0 then
		data.scale = math.max(1, data.scale - 0.075)
        else
		data.scale = math.max(0.75, data.scale - 0.025)
		if lunatime.tick() % 16 == 0 then data.scale = 1 end
        end

        npcutils.applyLayerMovement(v)

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        for k,p in ipairs(Player.get()) do
                if Colliders.speedCollide(data.range,p) and Misc.canCollideWith(v, p) then
                        if not data.hasEffected then
	                        table.insert(ringEffects, {
			                x = v.x + v.width/2, 
			                y = v.y + v.height/2,
                                        scale = 0,
			                timer = 0,
			                opacityMod = 1,
                                })                        
                                data.hasEffected = true
                        end
			if (p.keys.jump or p.keys.altJump) == KEYS_PRESSED then
                                data.scale = 2
                                data.cooldown = 20
	                        SFX.play("orb.ogg")
				p:mem(0x11C, FIELD_WORD, 0)
			        p.speedY = cfg.bounceHeight
	                        table.insert(bounceEffects, {
			                x = v.x + v.width/2, 
			                y = v.y + v.height/2,
                                        colour = cfg.bounceEffectColour,
                                        scale = 1,
			                timer = 0,
			                opacityMod = 1,
                                })                        
                        end
                else
                        data.hasEffected = false
                end
        end
end

function jumpOrb.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	if data.effect ~= nil then
		data.effect.particle.enabled = true
		data.effect.particle:draw(data.effect.priority, data.effect.nocull, nil, true, data.effect.tint, data.effect.timescale)
	end

	local img = Graphics.sprites.npc[v.id].img
	
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
		priority = -76,
	}

	npcutils.hideNPC(v)
end

function jumpOrb.onTick()
	for k = #bounceEffects, 1, -1 do
		local v = bounceEffects[k]

		v.timer = v.timer + 1
                v.scale = v.scale + 0.05

		if v.timer >= 16 then 
                        v.opacityMod = math.max(v.opacityMod - 0.05, 0) 
                end

		if v.opacityMod == 0 then
			table.remove(bounceEffects, k)
		end
	end

	for k = #ringEffects, 1, -1 do
		local v = ringEffects[k]

		v.timer = v.timer + 1
                v.scale = v.scale + 0.125

		if v.timer >= 8 then 
                        v.opacityMod = math.max(v.opacityMod - 0.15, 0) 
                end

		if v.opacityMod == 0 then
			table.remove(ringEffects, k)
		end
	end
end

function jumpOrb.onDraw()
	for k, v in ipairs(bounceEffects) do
                local img = jumpOrb.bounceTexture
		Graphics.drawBox{
			texture = img,
			x = v.x,
			y = v.y,
			width = v.scale * img.width,
			height = v.scale * img.height,
			color = (v.colour or Color.white) .. v.opacityMod,
			priority = -45,
			sceneCoords = true,
			centered = true,
		}
        end

	for k, v in ipairs(ringEffects) do
                local img = jumpOrb.ringTexture
		Graphics.drawBox{
			texture = img,
			x = v.x,
			y = v.y,
			width = v.scale * img.width,
			height = v.scale * img.height,
			color = Color.white .. v.opacityMod,
			priority = -45,
			sceneCoords = true,
			centered = true,
		}
        end
end

return jumpOrb