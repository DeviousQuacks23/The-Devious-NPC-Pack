--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local yiYoshi
pcall(function() yiYoshi = require("yiYoshi/yiYoshi") end)

local BabyGone = 0 

local sampleNPC = {}
local npcIDs = {}

function sampleNPC.register(id)
	npcManager.registerEvent(id, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(id, sampleNPC, "onDrawNPC")
	npcIDs[id] = true
end

--Register events
function sampleNPC.onInitAPI()
	registerEvent(sampleNPC, "onNPCHarm")
	registerEvent(sampleNPC, "onPlayerHarm")
end

--Dont hurt the player when stunned
function sampleNPC.onPlayerHarm(eventObj, p)
	for _,v in ipairs(NPC.get(npcID)) do
		if v.data.state == STATE_TUMBLE and Colliders.collide(p, v) then
			eventObj.cancelled = true
		end
	end
end

function sampleNPC.onNPCHarm(e, v, r, c)
	if not npcIDs[v.id] then return end
	if r == HARM_TYPE_TAIL and c then
		e.cancelled = true
		v.data.timer = 0
		v.data.state = STATE_TUMBLE
		v.data.squish = 0
		
		if not NPC.config[v.id].isBandit then
			v.speedX = 6 * c.direction
			v.speedY = -4
		else
			v.speedY = -3
		end
		
		SFX.play(2)
	end
	
	if v.data.npc and v.data.npc.isValid and Colliders.collide(v, v.data.npc) then
		v.data.npc.friendly = false
		v.data.npc.speedY = -8
	end
end

local STATE_PATROL = 0
local STATE_CHASE = 1
local STATE_SLAM = 2
local STATE_RETURN = 3
local STATE_TUMBLE = 4

local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

local fludd
pcall(function() fludd = require("AI/fludd") end)
fludd = fludd or {}

function fludd.onNPCHarmByWater(eventObj, n, v, p)
	if not npcIDs[n.id] then return end

	local config = NPC.config[n.id]
	local data = n.data

    eventObj.cancelled = true
    data.timer = 0
	n.speedX = 6 * p.direction
	n.speedY = -4
	data.squish = 0
	SFX.play(2)
	data.state = STATE_TUMBLE
	
	if data.npc and data.npc.isValid and Colliders.collide(v, data.npc) then
		data.npc.friendly = false
		data.npc.speedY = -8
	end
end

local function forcedPlayerStates(p)
	return p.forcedState == 1
	or p.forcedState == 2
	or p.forcedState == 4
	or p.forcedState == 5
	or p.forcedState == 11
	or p.forcedState == 12
	or p.forcedState == 41
	or player.isMega
end

local powerups = {0, 9, 14, 34, 168, 179, 264}

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.spin = 0
		data.spinDir = 1
		data.npc = nil
		data.state = STATE_PATROL
		data.canSlam = false
		data.patrolBox = Colliders.Box(v.x, v.y, v.width * NPC.config[v.id].detectionWidth, v.height * NPC.config[v.id].detectionHeight)
	end
	
	data.patrolBox.x = v.x - v.width * (NPC.config[v.id].detectionWidth / 2.125)
	data.patrolBox.y = v.y

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- Handling of those special states. Most NPCs want to not execute their main code when held/coming out of a block/etc.
		-- If that applies to your NPC, simply return here.
		-- return
	end
	
	if data.state ~= STATE_CHASE then data.speedX = 0 end
	
	data.timer = data.timer + 1
	data.squish = math.clamp((data.squish or 0) - 1, 0, 32)
	
	for _,p in ipairs(Player.get()) do
		if yiYoshi and p.character == CHARACTER_KLONOA then
		
			if not forcedPlayerStates(p) then
				if (Colliders.collide(p, v) and not v.friendly and p:mem(0x140, FIELD_WORD) <= 0) and (not data.noHurtYet or data.noHurtYet <= 0) and NPC.config[v.id].isBandit then
					--Nab the baby!
					if data.HasBaby == 0 and yiYoshi.playerData.babyMario.state == 0 and not p:isInvincible() and not v.friendly and not v.isProjectile and v:mem(0x12C, FIELD_WORD) == 0 then
						data.HasBaby = 1
						data.caughtProcess = 1
						data.thief = v
						currentlyStolen = true
						yiYoshi.playerData.babyMario.state = 2
						
					end
				end
			end
		
			if not currentlyStolen then
			
				if yiYoshi.playerData.babyMario.x <= v.x then
					v.direction = -1
				else
					v.direction = 1
				end
				
				if math.abs(yiYoshi.playerData.babyMario.x - v.x - 16) <= 48 and math.abs(yiYoshi.playerData.babyMario.y - v.y - 32) <= 48 then
					yiYoshi.playerData.babyMario.state = 1
					yiYoshi.playerData.babyMario.timer = 0
					yiYoshi.playerData.babyMario.direction = p.direction
					yiYoshi.playerData.babyMario.x = p.x + p.width*0.5
					yiYoshi.playerData.babyMario.y = p.y + p.height
					yiYoshi.playerData.starCounterState = 1
					yiYoshi.playerData.starCounterTimer = 0
					SFX.play("baby_kidnapped.ogg")
					v.direction = -v.direction
					data.thief = v
					data.HasBaby = 1
					data.caughtProcess = 1
					currentlyStolen = true
				end
				
			end
		
			if data.HasBaby == 1 and BabyGone == 0 and yiYoshi.playerData.babyMario.state == 1 then
				BabyGone = BabyGone + 1
				data.HasBaby = 0 
				data.isHolding = true
			elseif yiYoshi.playerData.babyMario.state == 0 then
				if BabyGone ~= 0 then data.state = data.state data.timer = 0 data.decision = RNG.randomInt(0,1) v.friendly = false data.playSound = nil end
				BabyGone = 0
				data.HasBaby = 0 
				data.caughtProcess = 0
				if data.isHolding then data.isHolding = nil v.speedX = 0 data.timer = 0 end
			end

			if data.caughtProcess ~= 0 and data.thief then
				--When Mario is being handed over, make him land on the NPC
				if yiYoshi.playerData.babyMario.state == 1 then
					if data.playSound == nil then SFX.play("baby_kidnapped.ogg") data.playSound = 0 end
					yiYoshi.playerData.babyMario.y = data.thief.y+16 + data.thief.height
					yiYoshi.playerData.babyMario.x = data.thief.x + data.thief.width / 2
				elseif yiYoshi.playerData.babyMario.state == 2 then
					if data.playSound == nil then SFX.play("baby_kidnapped.ogg") data.playSound = 0 end
					yiYoshi.playerData.babyMario.y = data.thief.y+16 + data.thief.height
					yiYoshi.playerData.babyMario.x = data.thief.x + data.thief.width / 2
				end
			end

			if v.isValid and yiYoshi.playerData.starCounter == 0 then
				yiYoshi.playerData.babyMario.state = 5
			end
			
			if yiYoshi.playerData.babyMario.state == 0 then
				BabyGone = 0
			end
		end
	end
	
	if data.npc and data.npc.isValid then
		data.npc.x = v.x-16+v.width*0.5
		data.npc.y = v.y-8+v.height*0.5
	end
	
	if data.state == STATE_PATROL then
	
		data.rotation = 0
	
		--Fly in place in a simple manner
		v.speedX = NPC.config[v.id].patrolSpeed * v.direction
		v.speedY = -math.sin(data.timer / 12) * 2
		if data.timer % NPC.config[v.id].patrolTime == 0 then
			v.direction = -v.direction
		end
		
		--Start chasing players when close to them
		if Colliders.collide(plr, data.patrolBox) and not data.isHolding and not data.npc then
			data.state = STATE_CHASE
			data.timer = 0
			v.speedX = 0
			v.speedY = 0
		end
		
	elseif data.state == STATE_CHASE then
	
		--Act "surprised"
		if data.timer <= 16 then
			v.speedY = math.clamp(data.timer - 8, -2, 2)
			npcutils.faceNearestPlayer(v)
		
		--Brief moment to let the player understand what's happening
		elseif data.timer > 16 and data.timer <= 40 then
			v.speedY = 0
			npcutils.faceNearestPlayer(v)
		else
		
			--Chase the player and start the actual attack
			chasePlayers(v)
			data.speedX = math.clamp(data.speedX + NPC.config[v.id].chaseAccuracy * v.data._basegame.direction, -NPC.config[v.id].chaseSpeed, NPC.config[v.id].chaseSpeed)
			v.speedX = data.speedX
			
			if data.timer >= NPC.config[v.id].chaseTime then
			
				if math.abs(v.x - plr.x) <= 32 and v.y < plr.y and not data.canSlam then
					data.timer = NPC.config[v.id].chaseTime
					SFX.play(49)
					data.canSlam = true
				end
				
				if data.canSlam then
					v.speedX = 0
					--Begin slamming down
					if data.timer >= NPC.config[v.id].chaseTime + 16 then
						data.timer = 0
						data.state = STATE_SLAM
						data.canSlam = false
						data.y = v.y
					end
				end
				
				if data.timer >= NPC.config[v.id].chaseTime + 256 then
					data.timer = 0
					data.state = STATE_PATROL
				end
			end
		end
	elseif data.state == STATE_SLAM then
		--Attack the player with all its might (it doesnt have very much)
		if data.timer <= 8 then
			v.speedY = -1
		else
			v.animationTimer = 1
			--When it hits the ground, make a small effect and hit blocks
			v.speedY = math.clamp(v.speedY + NPC.config[v.id].fallSpeed, 0, 8)
			if v.collidesBlockBottom then
			
				SFX.play(3)
				data.state = STATE_RETURN
				data.timer = 0
				data.squish = 32
				
				for i=0, 1 do
					local iOff = i/(1) - 0.5
					local dir = math.sign(iOff)
					local e = Effect.spawn(74, v.x, v.y)
					e.x = v.x - ((e.width / 2) - v.width) - (v.width / 2) + NPC.config[v.id].gfxoffsetx
					e.y = v.y + v.height - 16
					e.speedX = 2 * dir
				end
				
				for _,b in ipairs(Block.getIntersecting(v.x - 4, v.y, v.x + v.width + 4, v.y + v.height + 4)) do
					if (not b.isHidden) and Block.SOLID_MAP[b.id] and (not b:mem(0x5A, FIELD_BOOL)) then
						b:hit()
					end
				end
			end
		end
		
		if NPC.config[v.id].isBandit then
			if not forcedPlayerStates(player) then
				if (Colliders.collide(player, v) and not v.friendly and player:mem(0x140, FIELD_WORD) <= 0) and (not data.noHurtYet or data.noHurtYet <= 0) then
					if yiYoshi and player.character == CHARACTER_KLONOA then
					else
						player:harm()
						if player.mount == 0 then
							for _, e in ipairs(powerups) do
								if powerups[player.powerup] ~= 0 then
									data.npc = NPC.spawn(powerups[player.powerup], v.x-16+v.width*0.5, v.y-8+v.height*0.5, player.section)
									data.npc.friendly = true
									SFX.play("baby_kidnapped.ogg")
									return
								end
							end
						end
					end
				end
			end
		end
		
	elseif data.state == STATE_RETURN then
		--Fly back up
		v.speedY = -2
		data.spin = 0
		data.spinDir = 1
		if v.y <= data.y then
			data.y = nil
			data.state = STATE_PATROL
			data.timer = 0
		end
	else
		--Tumble out of the sky
		v.speedY = v.speedY + Defines.npc_grav
		
		if not NPC.config[v.id].isBandit then
			if v.collidesBlockBottom then
				SFX.play(3)
				v.speedY = -6
			end
			
			if v.collidesBlockLeft or v.collidesBlockRight or v.underwater then
				v:kill(9)
				SFX.play(9)
				Effect.spawn(10, v.x, v.y)
				for i = 0,4 do
					local n = NPC.spawn(10, v.x, v.y)
					n.speedY = RNG.randomInt(-3, -6)
					n.speedX = RNG.randomInt(-3, 3)
					n.ai1 = 2
				end
			end
			
			data.rotation = (data.rotation or 0) + v.speedX * 3
			
			for _,b in ipairs(Block.getIntersecting(v.x - 4, v.y, v.x + v.width + 4, v.y + v.height)) do
				if (not b.isHidden) and Block.SOLID_MAP[b.id] and (not b:mem(0x5A, FIELD_BOOL)) then
					b:hit()
					v:kill(9)
					SFX.play(9)
					Effect.spawn(10, v.x, v.y)
					for i = 0,4 do
						local n = NPC.spawn(10, v.x, v.y)
						n.speedY = RNG.randomInt(-3, -6)
						n.speedX = RNG.randomInt(-3, 3)
						n.ai1 = 2
					end
				end
			end
					
			for _,p in ipairs(NPC.getIntersecting(v.x - 4, v.y - 4, v.x + v.width + 4, v.y + v.height + 4)) do
				if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
					p:harm(HARM_TYPE_NPC)
					v:kill(9)
					SFX.play(9)
					Effect.spawn(10, v.x, v.y)
					for i = 0,4 do
						local n = NPC.spawn(10, v.x, v.y)
						n.speedY = RNG.randomInt(-3, -6)
						n.speedX = RNG.randomInt(-3, 3)
						n.ai1 = 2
					end
				end
			end
			
			if data.timer >= 64 then
				data.timer = 0
				data.state = STATE_PATROL
			end
		else
			v.speedX = 0
			data.y = v.spawnY
			data.spin = data.spin - 8 * data.spinDir
			if data.spin % 128 == 16 then data.spinDir = -data.spinDir end
			if data.timer >= 48 then
				data.timer = 0
				data.state = STATE_RETURN
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

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or v.isHidden then return end

	local priority = -45
	if v.forcedState == 1 or v.forcedState == 3 or v.forcedState == 4 or v.forced == 6 then
		priority = -70
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth + (data.spin or 0),height = config.gfxheight + math.sin(-(data.squish or 0) / 24) * 12,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

return sampleNPC