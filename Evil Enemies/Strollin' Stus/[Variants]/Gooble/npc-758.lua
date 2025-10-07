--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 34,
	gfxheight = 42,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	gfxoffsety = 4,
	speed = 1,
	luahandlesspeed = true,
	frames = 4,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	nowaterphysics = true,
	
	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	
	chaseTime = 128,
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
		--[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=npcID,
		--[HARM_TYPE_OFFSCREEN]=npcID,
		--[HARM_TYPE_SWORD]=npcID,
	}
);

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onNPCKill(eventObj, v, reason)
	if v.id ~= npcID then return end
	if reason ~= HARM_TYPE_OFFSCREEN then
		local data = v.data
		--Cool death effect
		local movementX = {-1.5,-1,1,1.5}
		local movementY = {-3,-4,-4,-3}
		
		for i=1,4 do
			local a = Animation.spawn(npcID,v.x+v.width*0.25,v.y+v.height - 12, (data.goobleColor + 1) or 1)
			a.speedX = movementX[i]
			a.speedY = movementY[i]
		end
	end
end

local STATE_PATROL = 0
local STATE_LUNGE = 1

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.goobleColor = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.timer2 = 0
		data.state = STATE_PATROL
		data.chase = Colliders.Circle(v.x, v.y, v.width * 8, v.height * 8)
		data.walking = 2
		data.random = RNG.randomInt(16, 48)
		if v.data._settings.random then
			v.data._settings.color = RNG.randomInt(0,6)
		end
	end

	data.timer = data.timer + 1
	data.timer2 = data.timer2 + 1

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		v.animationFrame = math.floor(data.timer2 / 8) % 2 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
		 return
	end
	
	data.chase.x = v.x + v.width
	data.chase.y = v.y + v.height
	
	if v.underwater then
		v:kill(HARM_TYPE_JUMP)
	end
	
	--Wander around randomly
	if data.state == STATE_PATROL then
	
		--If it detects a player, charge
		if data.walking <= 2 and Colliders.collide(plr, data.chase) and data.timer2 >= 0 then
			data.random = RNG.randomInt(48, 192)
			data.walking = 3
			data.timer2 = 0
		end
	
		if data.walking == 1 then
			--Move state
			v.animationFrame = math.floor(data.timer2 / 8) % 2
			v.speedX = sampleNPCSettings.speed * v.direction
			if data.timer2 >= data.random then
				data.random = RNG.randomInt(48, 192)
				data.walking = 2
				data.timer2 = 0
			end
		elseif data.walking == 2 then
			--Still state
			v.animationFrame = 0
			v.speedX = 0
			if data.timer2 >= data.random then
				data.random = RNG.randomInt(48, 192)
				v.direction = RNG.irandomEntry{-1,1}
				data.walking = 1
				data.timer2 = 0
			end
		else
			v.animationFrame = math.floor(data.timer2 / 8) % 2
			
			--Chase state
			v.speedX = sampleNPCSettings.speed * v.direction
			if data.timer2 % sampleNPCSettings.chaseTime == 0 then
				npcutils.faceNearestPlayer(v)
			end
			
			--It gets bored easily
			if not Colliders.collide(plr, data.chase) and data.timer2 >= 192 then
				data.walking = 1
				data.timer2 = 0
			end
			
			--Lunge if close enough
			if math.abs(v.x - plr.x) <= 128 and plr.y >= v.y - 64 then
				data.timer = 0
				data.timer2 = 0
				data.state = STATE_LUNGE
				SFX.play("Gooble.wav")
				v.speedX = 0
			end
		end
	else
		--Lunge at the player
		if data.timer2 <= 48 then
			v.animationFrame = 2
			npcutils.faceNearestPlayer(v)
		else
			v.animationFrame = 3
			data.timer = 0
			--The part where it jumps
			if data.timer2 == 49 then
				v.speedX = 4 * v.direction
				v.speedY = -4
			else
				--Die when it lands
				if v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockBottom then
					if v.data._settings.leap then
						v:kill(HARM_TYPE_JUMP)
					else
						data.timer2 = -64
						data.state = STATE_PATROL
						data.walking = 2
					end
				end
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
	
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

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or v.isHidden then return end

	local priority = -45
	if v.forcedState == 1 or v.forcedState == 3 or v.forcedState == 4 or v.forced == 6 then
		priority = -70
	end
	
	if not data.goobleColor then	
		data.goobleColor = v.data._settings.color
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + 4 + math.sin((-data.timer or 0) / 12) * 2,
		width = config.gfxwidth + 4 - math.sin((data.timer or 0) / 12) * 4,height = config.gfxheight - 4 - math.sin((-data.timer or 0) / 12) * 4,

		sourceX = 0 + (data.goobleColor * NPC.config[v.id].gfxwidth),sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC