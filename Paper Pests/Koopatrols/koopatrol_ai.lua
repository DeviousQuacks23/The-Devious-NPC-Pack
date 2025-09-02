local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local koopatrol = {}
koopatrol.idMap = {}

-- Original Koopatrol code by MegaDood, sprites by Shikaternia

koopatrol.sharedSettings = {
	gfxwidth = 32,
	gfxheight = 62,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
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

	grabside = false,
	grabtop = false,

	weight = 2,

        -- Custom Settings

	wanderSpeed = 1,
	chargeSpeed = 4,
	jumpHeight = -4,
	knockbackX = 1.5,
	knockbackY = -5,
	bounceHeight = -3,
	
	shellID = 795,
}

function koopatrol.register(npcID)
	npcManager.registerEvent(npcID, koopatrol, "onTickEndNPC")
	npcManager.registerEvent(npcID, koopatrol, "onDrawNPC")
        koopatrol.idMap[npcID] = true
end

function koopatrol.onInitAPI()
    	registerEvent(koopatrol, "onNPCHarm")
end

local STATE_WANDER = 0
local STATE_CHARGE = 1
local STATE_VULNERABLE = 2

function koopatrol.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if not data.rotation then
		data.rotation = 0
		data.offset = 0
	end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.timer = 0
		data.animTimer = 0
		data.rotationTimer = 0
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = data.timer or 0
		data.rotationTimer = data.rotationTimer or 0
		data.state = STATE_WANDER
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-150,-50},{-150,50}),
                        [1] = Colliders.Tri(0,0,{0,0},{150,-50},{150,50}),
                }
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
		data.opposite = v.direction
		data.hasBounced = false
		data.hasPlayedSFX = false
		data.hasDoneStuff = false
	end
	
        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height - 24

	data.attackCollider.x = v.x + 12 * v.direction
	data.attackCollider.y = v.y
	
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then 
		data.rotation = 0 
		v.animationFrame = 0
		return 
	end
	
	data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1
	
	if data.state == STATE_WANDER then
		v.speedX = config.wanderSpeed * v.direction
		data.opposite = v.direction
		v.animationFrame = math.floor(data.animTimer / 8) % 2
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
				data.state = STATE_CHARGE
				data.timer = 0
				v.speedX = 0
			end
		end
	elseif data.state == STATE_CHARGE then
		v.animationFrame = math.floor(data.animTimer / 6) % 2
		--First tick, play a sound, then charge at the player. Jump up into the air if on the ground too
		if data.timer == 1 then
			if v.collidesBlockBottom then
				v.speedY = config.jumpHeight
			end
			SFX.play(Misc.resolveSoundFile("chuck-whistle"))
		else
			if v.collidesBlockBottom then
				v.speedX = config.chargeSpeed * v.direction
				if not data.hasDoneStuff then
					data.hasDoneStuff = true
                        		SFX.play(Misc.resolveSoundFile("sound/character/ub_lunge.wav"), 0.75) 
                        		local e = Effect.spawn(10, v.x - v.width * v.direction, v.y + v.height * 0.5)
                        		e.y = e.y - e.height * 0.5
                        		e.speedX = -1 * v.direction
				end
			end

                	if v.collidesBlockBottom then
		        	if (data.timer % 12) == 0 then SFX.play(Misc.resolveSoundFile("sound/character/wario_footstep"..RNG.randomInt(1, 3)..".ogg"), 0.75) end
		        	if (data.timer % RNG.randomInt(1, 8)) == 0 then
		                	local e = Effect.spawn(74,0,0)
		                	e.y = v.y+v.height-e.height * 0.5
                                	if v.direction == -1 then
		                        	e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                	else
		                        	e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                	end
                        	end
                	end

			local list = Colliders.getColliding{
			a = data.attackCollider,
			btype = Colliders.BLOCK,
			filter = function(other)
				if other.isHidden and other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}

			for _,b in ipairs(list) do
				if Block.MEGA_SMASH_MAP[b.id] or Block.MEGA_HIT_MAP[b.id] or (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
					b:remove(true)
				end
			end

			for _,p in ipairs(NPC.getIntersecting(v.x - 6, v.y - 6, v.x + v.width + 6, v.y + v.height + 6)) do
				if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
					p:harm(HARM_TYPE_NPC)
				end
			end

			--Bump into a wall, flipping it over onto its back
			if data.timer <= 3 and v.speedX ~= 0 and v.direction ~= data.opposite then
				v.direction = -v.direction
				SFX.play(37)
				Defines.earthquake = 5
				v.speedX = 0
				v.speedY = config.knockbackY
				data.timer = 0
				data.hasDoneStuff = false
				data.state = STATE_VULNERABLE
			end
			if (v.collidesBlockLeft or v.collidesBlockRight) then data.timer = 2 end
		end
	else
		--Get knocked back
		if data.timer == 1 then
			v.speedX = config.knockbackX * -v.direction
			v.animationFrame = 3
			data.offset = v.height / 2
		else
			--Set the variable to rotate the NPC to a timer called "data.rotationTimer"
			data.rotation = data.rotationTimer
			
			--Animation stuff, plus stop the NPC from moving once it touches the ground
			if v.collidesBlockBottom then
				if not data.hasBounced then
					data.hasBounced = true
					v.speedY = config.bounceHeight
					SFX.play(3)
				else
					v.speedX = 0
					v.animationFrame = math.floor(data.animTimer / 24) % 2 + 2
					if not data.hasPlayedSFX then data.hasPlayedSFX = true SFX.play(3) end
				end
			else
				v.animationFrame = 3
			end
			
			--Initially, cause the NPC to flip onto its back
			if data.timer <= 23 then
				data.rotationTimer = data.rotationTimer + 4 * v.direction
			--After a bit, flip it back onto its feet
			elseif data.timer >= 96 and data.timer <= 116 then
				data.offset = 0
				if data.timer == 96 then
					v.speedY = -6
					SFX.play(1)
				end
				data.rotationTimer = data.rotationTimer - 4 * v.direction
			--After this, reset the NPC
			elseif data.timer > 116 and v.collidesBlockBottom then
				data.timer = 0
				data.rotation = 0
				data.rotationTimer = 0
				data.state = STATE_WANDER
				data.hasBounced = false
				data.hasPlayedSFX = false
				npcutils.faceNearestPlayer(v)
			end
		end
	end

	if v:mem(0x138, FIELD_WORD) == 5 then v:transform(config.shellID) end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

local function drawSprite(args) -- handy function to draw sprites (MrDoubleA wrote this)
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

function koopatrol.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end
	
	if data.state == STATE_VULNERABLE then
		drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + data.offset,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
		}
		npcutils.hideNPC(v)
	end
end

function koopatrol.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if not koopatrol.idMap[v.id] then return end
	--If not in a vulnerable state, then harm the player who jumps on it normally. If spinjumped, bounce off it without harming it.
	if data.state == STATE_VULNERABLE then
		if reason == HARM_TYPE_JUMP then
			eventObj.cancelled = true
		        v:transform(config.shellID)
		end
	else
		if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
			eventObj.cancelled = true
			if reason == HARM_TYPE_JUMP then
				culprit:harm()
			end
		end
	end

	-- General koopa logic

	if reason == 2 or reason == 7 then
		eventObj.cancelled = true
		v:transform(config.shellID)
		if reason == 7 then -- Play a different sound when swiping with a tail, for parity to SMBX Koopas
			SFX.play(9)
		else
			SFX.play(2)	
		end
		v.ai4 = 1
		v.dontMove = false
		if reason == 2 or reason == 7 then
			v.speedY = -5
		end
		v.speedX = 0
	end
end

return koopatrol