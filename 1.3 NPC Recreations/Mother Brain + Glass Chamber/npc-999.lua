local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

local glassBox = {}

-- Some code taken from Marioman2007's Jewel Blocks

local npcID = NPC_ID
local deathEffectIDs = npcID

local glassBoxSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 128,
	gfxheight = 128,
	width = 128,
	height = 128,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 5,
	framestyle = 1,
	framespeed = 8,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = false,
	weight = 2,
	isstationary = true,
	staticdirection = true,

	npcblock = true, 
	npcblocktop = false, 
	playerblock = true, 
	playerblocktop = true, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	score = 0,

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

	-- Custom properties

	health = 5,

	glassFrames = 1,
	glassFramespeed = 8,
	crackFrames = 5,

	swordImmune = 10,
	hammerImmune = 60,
	immune = 20,

	crackSFX = 64,
	shatterSFX = 67,

	itemRenderPriority = -70,

	shatterEffectIDs = deathEffectIDs,
	shatterAmount = 100,
}

npcManager.setNpcSettings(glassBoxSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_SWORD
	},
	{}
);

function effectconfig.onInit.INIT_GLASSSHARDS2(v)
	v.variant = RNG.randomInt(1, v.variants)
	v.animationFrame = RNG.randomInt(0, v.frames - 1)
end

function glassBox.onInitAPI()
	npcManager.registerEvent(npcID, glassBox, "onTickEndNPC")
	npcManager.registerEvent(npcID, glassBox, "onDrawNPC")
	registerEvent(glassBox, "onNPCHarm")
	registerEvent(glassBox, "onPostNPCKill")
end

function glassBox.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
    		settings.contentList = settings.contentList or {}
		data.hp = 0
		data.animTimer = 0
	end

	if v.despawnTimer > 1 then v.despawnTimer = 100 end
        if v.isProjectile then v.isProjectile = false end

	for _,n in ipairs(NPC.getIntersecting(v.x - 2, v.y + 4, v.x + v.width + 2, v.y + v.height - 4)) do
		if n.idx ~= v.idx and n.id ~= v.id and n.id ~= 171 and n.isProjectile and not n.isHidden and not n.friendly then
			v:harm(3)
		end
	end

	npcutils.applyLayerMovement(v)

	-- Animation

	v.animationFrame = (math.floor(data.animTimer / config.glassFramespeed) % config.glassFrames) + math.lerp(0, config.glassFrames * config.crackFrames, data.hp / config.health)

	data.animTimer = data.animTimer + 1
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = data.frame, frames = config.frames})
end

local function drawTrappedNPC(v, item, priority)
    	local npcConfig = NPC.config[item.id]
    	local img = Graphics.sprites.npc[item.id].img

	if not img then return end

    	local gfxwidth, gfxheight = npcConfig.gfxwidth, npcConfig.gfxheight

    	if gfxwidth == 0 then gfxwidth = npcConfig.width end
    	if gfxheight == 0 then gfxheight = npcConfig.height end

	local offsy = 0
	if npcConfig.framestyle ~= 0 and v.direction == 1 then
		offsy = gfxheight * npcConfig.frames
	end

    	Graphics.drawImageToSceneWP(
        	img,
        	v.x + (item.offsetX or 0) * v.width - gfxwidth/2,
        	v.y + (item.offsetY or 0) * v.height - gfxheight/2,
        	0, offsy,
        	gfxwidth,
        	gfxheight,
        	priority
    	)
end

function glassBox.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local settings = v.data._settings

    	for idx, item in ipairs(settings.contentList) do
		drawTrappedNPC(v, item, config.itemRenderPriority)
    	end
end

function glassBox.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	eventObj.cancelled = true
	if v:mem(0x156, FIELD_WORD) > 0 then return end
	
	if reason == HARM_TYPE_NPC or reason == HARM_TYPE_SWORD then
		data.hp = data.hp + 1

		if data.hp >= config.health then
			v:kill(3)
		else
			if config.crackSFX then SFX.play(config.crackSFX) end
		end

		if reason == HARM_TYPE_NPC then
			if not (type(culprit) == "NPC" and culprit.id == 13) then
				if (type(culprit) == "NPC" and culprit.id == 171) then
					v:mem(0x156, FIELD_WORD, config.hammerImmune)
				else
					v:mem(0x156, FIELD_WORD, config.immune)
				end
			end
		elseif reason == HARM_TYPE_SWORD then
			v:mem(0x156, FIELD_WORD, config.swordImmune)
		end
	end
end

function glassBox.onPostNPCKill(v, reason)
	if v.id ~= npcID then return end
	
	local config = NPC.config[v.id]
	local settings = v.data._settings

	if reason == HARM_TYPE_NPC or reason == HARM_TYPE_SWORD then
		if config.shatterSFX then SFX.play(config.shatterSFX) end

		for c = 1, config.shatterAmount do
			local e = Effect.spawn(config.shatterEffectIDs, v.x + RNG.random(0, v.width), v.y + RNG.random(0, v.height))
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
		end
	end

	-- Spawn NPCs

    	for k, item in ipairs(settings.contentList) do
        	for i = 1, (item.count or 1) do
			local tagsInput = (item.advanced.tagsInput or "")
		
			local str = [[
				return function(v, data, settings)
					]] .. tagsInput .. [[
				end
			]]
		
			local chunk, err = load(str)
		
            		local n = NPC.spawn(item.id, v.x + (item.offsetX or 0.5) * v.width, v.y + (item.offsetY or 0.5) * v.height, v.section, false, true)
            		n:mem(0x124, FIELD_BOOL, true)
            		n.layerName = "Spawned NPCs"
            		n.direction = v.direction
			n.friendly = v.friendly

			if chunk then
				local func = chunk()
			
				func(n, n.data, n.data._settings)
			end
            	end
    	end
end

return glassBox