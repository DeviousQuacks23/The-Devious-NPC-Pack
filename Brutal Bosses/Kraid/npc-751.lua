local npcManager = require("npcManager")

local kraid = {}
local npcID = NPC_ID

local kraidSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 130,
	height = 100,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 9999,
	staticdirection = true, 

	-- Custom Properties:

	bodyImage = Graphics.loadImageResolved("npc-"..npcID.."-body.png"),
	footImage = Graphics.loadImageResolved("npc-"..npcID.."-foot.png"),
	headImage = Graphics.loadImageResolved("npc-"..npcID.."-head.png"),
	tailImage = Graphics.loadImageResolved("npc-"..npcID.."-tail.png"),

        bodyHeight = 492,
        headHeight = 178,
        footHeight = 140,

        headOffset = 32,
        bodyOffsetX = 154,
        bodyOffsetY = 64,
	bodyFrames = 18,
        tailOffsetX = 44,
        tailOffsetY = 76,
        bodyHitboxOffset = 78,

        paletteImage = Graphics.loadImageResolved("kraidPalettes.png"),
        colourCount = 15,

        health = 50,

        rockID = npcID+1,
        spikeID = npcID+2,
	clawID = npcID+3,
}

npcManager.setNpcSettings(kraidSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC
	},
	{
	}
);

local RISE = 0
local PHASE_ONE = 1
local RISE_AGAIN = 2
local PHASE_TWO = 3
local DEATH = 4

local function stopSFX(sfx)
	if not sfx then return end
	if not sfx.isValid or not sfx:isplaying() then return end
	sfx:stop()
end

function kraid.onInitAPI()
	npcManager.registerEvent(npcID, kraid, "onTickEndNPC")
	npcManager.registerEvent(npcID, kraid, "onDrawNPC")
	registerEvent(kraid, "onNPCHarm")
end

local function handleProjectilesAndStuff(v,data,config)
        if (data.timer % RNG.randomInt(100, 400) == 0) and not data.openMouth then
                data.openMouth = true
                data.mouthTimer = 0     
        end
        if data.openTimer == 24 then SFX.play("kraidRoar.wav") end       
        if data.openTimer == 40 then
                for i = 1, RNG.randomInt(2, 6) do
                        rock = NPC.spawn(config.rockID, v.x, v.y, v.section)
			rock.speedX = RNG.random(2, 12) * v.direction
			rock.speedY = RNG.random(-4, -10)
	                rock.layerName = "Spawned NPCs"
                end
        elseif data.openTimer >= 160 then         
                data.openMouth = false
                data.mouthTimer = 0
        end   
end

local function handleEmerging(v,data,config)
        effect = Effect.spawn(10, RNG.randomInt(v.sectionObj.boundary.left, v.sectionObj.boundary.right), RNG.randomInt(v.sectionObj.boundary.bottom, v.sectionObj.boundary.bottom - 64))
        effect.speedX = RNG.random(-4.5, 4.5)
        effect.speedY = RNG.random(-2, -10)
        if data.timer % 4 == 0 then
                rock = NPC.spawn(config.rockID, RNG.randomInt(v.sectionObj.boundary.left, v.sectionObj.boundary.right), v.sectionObj.boundary.bottom, v.section)
	        rock.speedX = RNG.random(-2.5, 2.5)
		rock.speedY = RNG.random(-4, -8)
	        rock.layerName = "Spawned NPCs"
        end
end

local function handleBellySpikes(v,data,config,xOffset,yOffset)
        if (data.timer % RNG.randomInt(200, 600) == 0) and data.flash <= 0 then
                spike = NPC.spawn(config.spikeID, v.x - xOffset, v.y + yOffset, v.section)
                spike.animationFrame = -999
                spike.direction = -1
                spike.ai1 = data.palette
	        spike.layerName = "Spawned NPCs"
        end
end

function kraid.onTickEndNPC(v)
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
		data.headBox = data.headBox or Colliders.Box(0, 0, 1, 1)

		data.bodyBox = data.bodyBox or Colliders.Box(0, 0, 1, 1)
		data.bodyBox2 = data.bodyBox2 or Colliders.Box(0, 0, 1, 1)
		data.bodyBox3 = data.bodyBox3 or Colliders.Box(0, 0, 1, 1)

                data.headFrame = 0
                data.bodyFrame = 0
                data.footFrame = 0
                data.palette = 0

                data.openMouth = false
                data.openTimer = 0
                data.mouthTimer = 0
                data.flash = 0
 
                data.state = RISE
                data.timer = 0
                data.hp = config.health
                data.immunity = 0

                data.quakeSFX = nil
                data.hasPlayed = false

                data.shaking = false
                data.shakeOffset = 0
                data.shakeTimer = 0

                v.y = (v.sectionObj.boundary.bottom + 128)
	end
	
	-- General Stuff

        v.despawnTimer = 180
        data.timer = data.timer + 1
        data.mouthTimer = data.mouthTimer + 1
        data.immunity = data.immunity - 1
        data.flash = data.flash - 1

        -- Animation

        if data.openMouth then
                data.openTimer = data.openTimer + 1
		if data.mouthTimer == 8 then
			data.headFrame = 1
		elseif data.mouthTimer == 16 then
			data.headFrame = 2
		elseif data.mouthTimer == 24  then
			data.headFrame = 3
		end
        else
                data.openTimer = 0
		if data.mouthTimer == 8 then
			data.headFrame = 2
		elseif data.mouthTimer == 16 then
			data.headFrame = 1
		elseif data.mouthTimer == 24 then
			data.headFrame = 0
		end
        end

        data.bodyFrame = math.floor(lunatime.tick() / 6) % config.bodyFrames

        if data.flash >= 0 and lunatime.tick() % 2 == 0 then 
                data.palette = 1
        else
                data.palette = math.lerp(1, 0, data.hp / config.health) - 0.125
        end

	--Text.print(data.palette,0,0)
	--Text.print(data.hp,0,16)

        -- Shaking (for when Kraid rises)

        if data.shaking then
                data.shakeTimer = data.shakeTimer + 1
                if data.shakeTimer%4 > 0 and data.shakeTimer%4 < 3 then
                        data.shakeOffset = data.shakeOffset - 4
                else
                        data.shakeOffset = data.shakeOffset + 4
                end
        else
                data.shakeTimer = 0
                data.shakeOffset = 0
        end

        -- Manage hitboxes

	data.headBox.width = v.width
	data.headBox.height = v.height
	data.headBox.x = v.x
	data.headBox.y = v.y

	data.bodyBox.width = v.width + 32
	data.bodyBox.height = config.bodyHeight - config.bodyOffsetY
	data.bodyBox.x = v.x - 16
	data.bodyBox.y = v.y + config.headHeight - config.bodyHitboxOffset

	data.bodyBox2.width = v.width
	data.bodyBox2.height = config.bodyHeight - config.bodyOffsetY - 128
	data.bodyBox2.x = v.x - config.width - 16
	data.bodyBox2.y = v.y + config.headHeight - config.bodyHitboxOffset + 128

	data.bodyBox3.width = 64
	data.bodyBox3.height = 80
	data.bodyBox3.x = v.x - 80
	data.bodyBox3.y = v.y + config.headHeight - config.bodyHitboxOffset + 48

        -- Debug Stuff

	--data.headBox:Debug(true)
	--data.bodyBox:Debug(true)
	--data.bodyBox2:Debug(true)
	--data.bodyBox3:Debug(true)

        -- The actual AI starts here

        if data.state == RISE then
                if not data.hasPlayed then
                        data.quakeSFX = SFX.play("earthquake.ogg",1,0)
                        data.hasPlayed = true
                end
                Defines.earthquake = 2
                v.speedY = -0.5
                data.shaking = true
                handleEmerging(v,data,config)
                if v.y <= (v.sectionObj.boundary.bottom - 160) then
			if settings.phaseOneEvent ~= "" then triggerEvent(settings.phaseOneEvent) end
                        v.y = (v.sectionObj.boundary.bottom - 160)
                        stopSFX(data.quakeSFX)
                        data.hasPlayed = false
                        data.state = PHASE_ONE
                        data.timer = 0
                end
        elseif data.state == PHASE_ONE then
                v.speedY = 0
                data.shaking = false
                handleProjectilesAndStuff(v,data,config)
                if data.timer >= 512 then
			if settings.phaseOneEmergeEvent ~= "" then triggerEvent(settings.phaseOneEmergeEvent) end
                        data.state = RISE_AGAIN
                        if data.openMouth then
                                data.openMouth = false
                                data.mouthTimer = 0
                        end
                end
        elseif data.state == RISE_AGAIN then
                if not data.hasPlayed then
                        data.quakeSFX = SFX.play("earthquake.ogg",1,0)
                        data.hasPlayed = true
                end
                Defines.earthquake = 2
                v.speedY = -2
                data.shaking = true
                handleEmerging(v,data,config)
                if data.timer % 6 == 0 then
                        rock = NPC.spawn(config.rockID, RNG.randomInt(v.sectionObj.boundary.left, v.sectionObj.boundary.right), v.sectionObj.boundary.top, v.section)
	                rock.layerName = "Spawned NPCs"
                end
                if v.y <= v.spawnY then
			if settings.phaseTwoEvent ~= "" then triggerEvent(settings.phaseTwoEvent) end
                        v.y = v.spawnY
                        stopSFX(data.quakeSFX)
                        data.hasPlayed = false
                        data.state = PHASE_TWO
                        data.timer = 0
                end
        elseif data.state == PHASE_TWO then
                v.speedY = 0
                data.shaking = false
                handleProjectilesAndStuff(v,data,config)
                handleBellySpikes(v,data,config,40,174)
                handleBellySpikes(v,data,config,108,300)
                handleBellySpikes(v,data,config,96,430)
        	if (data.timer % RNG.randomInt(100, 300) == 0) and data.flash <= 0 then
                	claw = NPC.spawn(config.clawID, v.x - 128, v.y + 128, v.section)
                	claw.animationFrame = -999
                	claw.direction = -1
                	claw.ai1 = data.palette
	        	claw.layerName = "Spawned NPCs"
        	end
        elseif data.state == DEATH then
                if not data.openMouth then
                        data.openMouth = true
                        data.mouthTimer = 0
                end
                if data.timer == 20 then SFX.play("kraidDead.wav") end
                v.speedY = 2
		v.friendly = true
                data.shaking = false
                if v.y >= (v.sectionObj.boundary.bottom + 128) then
                        v:kill(9)
                end
        end

        -- Destroy everything in Kraid's path

        for k,p in ipairs(Player.get()) do
                if Colliders.collide(data.bodyBox,p) 
                or Colliders.collide(data.bodyBox2,p) 
                or Colliders.collide(data.bodyBox3,p) 
                and Misc.canCollideWith(v, p) then
                        p:harm()
                end
        end

        for k,n in ipairs(NPC.get()) do
                if (Colliders.collide(data.headBox,n) and (not n.isProjectile))
                or Colliders.collide(data.bodyBox,n) 
                or Colliders.collide(data.bodyBox2,n) 
                or Colliders.collide(data.bodyBox3,n) 
                and Misc.canCollideWith(v, n) then
                        if n.idx ~= v.idx and (not n.isHidden) and (not n.friendly) and NPC.HITTABLE_MAP[n.id] then
                                n:mem(0x122,FIELD_WORD, 3)
                        end
                end
        end

	for k,w in ipairs(Block.get()) do
                if Colliders.collide(data.headBox,w) 
                or Colliders.collide(data.bodyBox,w) 
                or Colliders.collide(data.bodyBox2,w) 
                or Colliders.collide(data.bodyBox3,w) 
                and Misc.canCollideWith(v, w) then
                    if w.isHidden or w.layerObj.isHidden or w.layerName == "Destroyed Blocks" or w:mem(0x5A, FIELD_WORD) == -1 then return end
			if Block.MEGA_SMASH_MAP[w.id] then 
			        w:remove(true)
                                SFX.play(3)
			end
                end
        end
end

function kraid.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
	if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	-- Change palettes depending on HP. by MDA
        local paletteChangeShader

        if paletteChangeShader == nil then
            paletteChangeShader = Shader()
            paletteChangeShader:compileFromFile(nil,"kraidPaletteChange.frag",{COLOUR_COUNT = config.colourCount})
        end

        -- Draw the head

	local img = config.headImage
	
	Graphics.drawBox{
		texture = img,
		x = v.x - config.headOffset + data.shakeOffset,
		y = v.y + (config.height - config.headHeight),
		sourceY = data.headFrame * config.headHeight,
		sourceHeight = config.headHeight,
		sceneCoords = true,
		priority = -76,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = data.palette,
                }
	}

        -- Draw the body

	local img = config.bodyImage
	
	Graphics.drawBox{
		texture = img,
		x = v.x - config.bodyOffsetX + data.shakeOffset,
		y = v.y + v.height - config.bodyOffsetY,
		sourceY = data.bodyFrame * config.bodyHeight,
		sourceHeight = config.bodyHeight,
		sceneCoords = true,
		priority = -76,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = data.palette,
                }
	}

        -- Draw the tail

	local img = config.tailImage
	
	Graphics.drawBox{
		texture = img,
		x = v.x + v.width + config.tailOffsetX + data.shakeOffset,
		y = v.y + config.bodyHeight - config.tailOffsetY,
		sceneCoords = true,
		priority = -76,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = data.palette,
                }
	}

        -- Draw the foot

	local img = config.footImage
	
	Graphics.drawBox{
		texture = img,
		x = v.x - (img.width / 2) - 8 + data.shakeOffset,
		y = v.y + (v.height / 2) + config.bodyHeight - config.footHeight,
		sourceY = data.footFrame * config.footHeight,
		sourceHeight = config.footHeight,
		sceneCoords = true,
		priority = -75,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = data.palette,
                }
	}
end

function kraid.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

	local data = v.data
	local settings = v.data._settings
        eventObj.cancelled = true

        if 0 >= data.immunity then
                data.hp = data.hp - 1
                data.immunity = 20
                data.flash = 10
                SFX.play(39)
                if data.hp <= 0 then
			if settings.deathEvent ~= "" then triggerEvent(settings.deathEvent) end
                        data.state = DEATH
                        data.timer = 0
                        stopSFX(data.quakeSFX)
                        data.hasPlayed = false
                        Misc.givePoints(9,vector(v.x + (v.width/2),v.y),true) -- Give the player points
                end
        end
end

return kraid