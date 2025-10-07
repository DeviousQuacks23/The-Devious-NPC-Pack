--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local typemap = {}

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 192,
	gfxheight = 330,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 148,
	height = 304,
	gfxoffsety = 4,
	speed = 3,
	luahandlesspeed = true,
	frames = 7,
	framestyle = 1,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes
	nowaterphysics = true,
	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noiceball = true,
	noyoshi = true,
	
	eggDelay = 192,
	radius = 256,
	volume = 0.4
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
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
		[HARM_TYPE_JUMP]=npcID + 1,
		[HARM_TYPE_NPC]=npcID + 1,
		[HARM_TYPE_PROJECTILE_USED]=npcID + 1,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID + 1,
		[HARM_TYPE_TAIL]=npcID + 1,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

typemap[npcID] = typ

local function init(v, typ)
	local data = v.data._basegame
	
	local siz = {}
	
	data.sound = SFX.create
	{
		x = v.x + v.width*0.5,
		y = v.y + v.height*0.5,
		sound = Misc.resolveFile("Charge.wav"),
		parent = v,
		type = typ,
		volume = NPC.config[v.id].volume,
		falloffRadius = NPC.config[v.id].radius,
		falloffType = SFX.FALLOFF_LINEAR,
		sourceRadius = 32,
		sourceWidth = v.width,
		sourceHeight = v.height,
		sourceVector = vector.v2(64, 0)
	}
end

local eggOffset = {
[-1] = 32,
[1] = -64
}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
	registerEvent(sampleNPC, "onNPCKill")
	registerEvent(sampleNPC, "onTick")
end

function sampleNPC.onNPCKill(e, v, r)
	if v.id ~= npcID then return end
	if typemap[v.id] then
		if v.data._basegame.sound then
			v.data._basegame.sound:destroy()
		end
	end
end

local fludd
pcall(function() fludd = require("AI/fludd") end)
fludd = fludd or {}

function fludd.onNPCHarmByWater(eventObj, n, v, p)

	local config = NPC.config[n.id]
	local data = n.data

	if data.headTimer then
		eventObj.cancelled = true
		if not data.maskOff and v.y <= n.y + n.height * 0.75 then
			data.headTimer = data.headTimer + 0.5
		end
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end
	local data = v.data
	eventObj.cancelled = true
	if culprit then
		if culprit.y <= v.y + 32 then
		
			if not data.maskOff then
				data.headTimer = data.headTimer + 32
				
				culprit.speedY = -4
				culprit.speedX = -8 * math.sign((v.x + v.width * 0.5) - culprit.x)
				SFX.play(9)
			else
				data.timer = 0
				v.speedX = 0
				v.friendly = true
				data.state = STATE_KILL
				SFX.play("burts_hurt.ogg")
				if v.data._basegame.sound then
					v.data._basegame.sound:stop()
				end
			end
			
		else
			if culprit.y <= v.y + v.height * 0.5 and culprit.y > v.y + 32 then
				
				data.headRotationTimer = 32
				
				if type(culprit) == "Player" then SFX.play("smrpg_stomp.wav") end
				
				if type(culprit) == "NPC" and Colliders.collide(culprit, data.push) then
					culprit.direction = -culprit.direction
					SFX.play("smrpg_stomp.wav")
					if culprit.heldIndex == 0 then
						culprit.speedX = -8 * math.sign((v.x + v.width * 0.5) - culprit.x)
						Effect.spawn(75, culprit.x, culprit.y)
					end
				end
				
			end
		end
	end
end

local STATE_PATROL = 0
local STATE_KILL = 1

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		if v.data._basegame.sound then
			v.data._basegame.sound:stop()
		end
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.state = STATE_PATROL
		data.hurt = Colliders.Box(v.x, v.y, v.width, 96)
		data.push = Colliders.Poly(v.x + v.width * 0.5,v.y + v.height * 0.25, {0,-70}, {-34, -48}, {-52,46}, {-32, 96}, {0, 102}, {32, 96}, {52, 46}, {34, -48})
		if not v.data._basegame.sound then
			init(v, typemap[v.id])
		else
			v.data._basegame.sound:play()
		end
	end
	
	data.timer = data.timer + 1
	
	data.push.x = v.x + v.width * 0.5
	data.push.y = v.y + v.height * 0.25

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		 return
	end
	
	data.hurt.x = v.x
	data.hurt.y = v.y + v.height * 0.7
	
	data.headRotationTimer = math.clamp((data.headRotationTimer or 0) - 1, 0, 1000)
	data.headTimer = math.clamp((data.headTimer or 0) - 0.5, 0, 140)
	
	if data.headTimer >= 140 and not data.maskOff then
		data.maskOff = true
		SFX.play(2)
		local e = Effect.spawn(npcID, v.x - v.width * 0.125, v.y - v.height * 0.45)
		e.direction = v.direction
	end
	
	--Wander around randomly
	if data.state == STATE_PATROL then
	
		v.speedX = sampleNPCSettings.speed * v.direction
		
		v.animationFrame = math.floor(lunatime.tick() / sampleNPCSettings.framespeed) % 6 + 1 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
		
		--Player interactions
		for _,plr in ipairs(Player.get()) do
			if Colliders.collide(plr, data.hurt) and not v.friendly then
				plr:harm()
			end
			
			if Colliders.collide(plr, data.push) and not v.friendly then
				plr.speedX = (sampleNPCSettings.speed + 2) * -math.sign((v.x + v.width * 0.5) - plr.x)
			end
		end
		
		if data.timer % 12 == 0 then
			local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.9)
			e.speedX = 2 * -v.direction
		end
		
		--Make a consistent sound
		if data.sound ~= nil then
			local cx = v.x + v.width*0.5
			local cy = v.y + v.height*0.5
			local r = data.sound.falloffRadius
			for _,c in ipairs(Camera.get()) do
				if cx + r > c.x and cx - r < c.x + c.width and 
				   cy + r > c.y and cy - r < c.y + c.height then
					if not v:mem(0x124, FIELD_BOOL) then
						v:mem(0x124, FIELD_BOOL, true)
					end
					v:mem(0x12A, FIELD_WORD, 180)
				end
			end
			
			if v.isHidden and data.sound.playing then
				data.sound:stop()
			elseif not v.isHidden and not data.sound.playing  then
				data.sound:play()
			end
		end
		
		if data.timer % sampleNPCSettings.eggDelay == 0 and v.data._settings.spawns then
			local n = NPC.spawn(npcID + 1, v.x + v.width * 0.5 + eggOffset[v.direction], v.y + v.height * 0.5)
			n.speedX = 2 * -v.direction
			n.ai1 = RNG.irandomEntry{v.data._settings.spawnedNPC1, v.data._settings.spawnedNPC2}
			if n.ai1 == 0 then n.ai1 = 1 end
		end
	else
		v.animationFrame = 0 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
		if not data.x then
			data.xThing = data.xThing or 0 + 1
			data.x = true
			v.x = v.x + data.xThing
		else
			data.x = nil
			v.x = v.x - data.xThing
		end
		
		if data.timer >= 80 then
			if data.timer % 16 == 0 then
				Effect.spawn(10, RNG.randomInt(v.x, v.x + v.width), RNG.randomInt(v.y, v.y + v.height))
				SFX.play(36)
			end
			
			if data.timer == 176 then
				v:kill()
				SFX.play(43)
			end
		end
	end
	
end

--[[************************
Rotation code by MrDoubleA
**************************]]

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

local gfx1 = Graphics.loadImageResolved("tramplin_stu_head.png")
local gfx2 = Graphics.loadImageResolved("tramplin_stu_mask.png")

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or v.isHidden then return end

	local priority = -45
	if v.forcedState == 1 or v.forcedState == 3 or v.forcedState == 4 or v.forcedState == 6 then
		priority = -70
	end
	
	Graphics.drawBox{
		type= RTYPE_IMAGE,
		texture = gfx1,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 - 9,
		sceneCoords = true,
		sourceX = 0,
		sourceY = v.animationFrame * sampleNPCSettings.gfxheight,
		sourceWidth = sampleNPCSettings.gfxwidth,
		sourceHeight = sampleNPCSettings.gfxheight,
		priority = -47,
		centered = true,
	}
	
	if not data.maskOff then
		Graphics.drawBox{
			type= RTYPE_IMAGE,
			texture = gfx2,
			x = v.x + v.width * 0.5,
			y = v.y + v.height * 0.5 - 9 - (data.headTimer or 0),
			sceneCoords = true,
			sourceX = 0,
			sourceY = v.animationFrame * sampleNPCSettings.gfxheight,
			sourceWidth = sampleNPCSettings.gfxwidth,
			sourceHeight = sampleNPCSettings.gfxheight,
			priority = -46,
			centered = true,
			rotation = math.sin(((data.headRotationTimer or 0) * -v.direction) / 12) * 6
		}
	end
	
	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC