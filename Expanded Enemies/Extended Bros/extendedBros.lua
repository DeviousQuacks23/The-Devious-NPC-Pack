--[[
	Based off of basegame code, written by Minus and Saturnyoshi
--]]

local npcManager = require("npcManager")
local playerStun = require("playerstun")

local hammerBros = {}

local configs = {}

-- taken from MDA's extendedKoopas
local function setConfigDefault(config, name, value)
    	if config[name] == nil then
        	config:setDefaultProperty(name, value)
    	end
end

function hammerBros.register(id)
	npcManager.registerEvent(id, hammerBros, "onTickNPC")
	npcManager.registerEvent(id, hammerBros, "onDrawNPC")

	local config = NPC.config[id]

	-- If a config isn't defined, set it here
	setConfigDefault(config, "holdoffsetx", 22)
	setConfigDefault(config, "holdoffsety", 24)
	setConfigDefault(config, "throwoffsetx", 22)
	setConfigDefault(config, "throwoffsety", 18)

	setConfigDefault(config, "walkframes", 100)
	setConfigDefault(config, "jumpframes", 260)
	setConfigDefault(config, "jumptimerange", 60)

	setConfigDefault(config, "jumpspeed", 7)
	setConfigDefault(config, "secondjumpspeed", 6)
	setConfigDefault(config, "secondjumpchance", 0)

	setConfigDefault(config, "throwspeedx", 3.4)
	setConfigDefault(config, "throwspeedy", -8)

	setConfigDefault(config, "initialtimer", 100)
	setConfigDefault(config, "initialtimerrange", 50)

	setConfigDefault(config, "waitframeslow", 50)
	setConfigDefault(config, "waitframeshigh", 90)
	setConfigDefault(config, "holdframes", 30)
	setConfigDefault(config, "npcheldfirerate", 6)

	setConfigDefault(config, "throwid", id)
	setConfigDefault(config, "throwidheld", 0)
	setConfigDefault(config, "doheldharm", true)
	setConfigDefault(config, "syncheldspeed", true)

	setConfigDefault(config, "volley", 1)
	setConfigDefault(config, "volleyframes", 10)

	setConfigDefault(config, "quake", false)
	setConfigDefault(config, "stalltime", 8)
	setConfigDefault(config, "stunframes", 130)
	setConfigDefault(config, "quakeintensity", 15)

	setConfigDefault(config, "brospeed", 0.8)
	setConfigDefault(config, "movewhenjumping", false)
	setConfigDefault(config, "movewhenshooting", true)

	setConfigDefault(config, "chaseplayer", false)
	setConfigDefault(config, "followplayer", true)

	setConfigDefault(config, "animwalkframes", 2)
	setConfigDefault(config, "animjumpframes", 0)
	setConfigDefault(config, "animholdframes", 2)
	setConfigDefault(config, "animshootframes", 0)
	setConfigDefault(config, "shootframeduration", 15)

	setConfigDefault(config, "drawheldnpc", true)
	setConfigDefault(config, "drawnpcinfront", true)

	setConfigDefault(config, "jumpSFX", false)
	setConfigDefault(config, "quakeSFX", 37)
	setConfigDefault(config, "holdSFX", false)
	setConfigDefault(config, "throwSFX", 25)

	setConfigDefault(config, "onThrowFunction", nil)

	configs[id] = config
end

local hammers = {}

local function heldFilterFunc(other)
	return other.despawnTimer >= 0 and (not other.isGenerator) and (not other.friendly) and other:mem(0x12C, FIELD_WORD) == 0 and other.forcedState == 0
end

function hammerBros.onTickEnd()
	for i=#hammers, 1, -1 do
		local v = hammers[i]
		if v.isValid then
			if (not v.friendly) then
				for k,n in ipairs(Colliders.getColliding{
					a = v,
					b = NPC.HITTABLE,
					btype = Colliders.NPC,
					collisionGroup = v.collisionGroup,
					filter = heldFilterFunc
				}) do
					n:harm(3)
				end
			end
		else
			table.remove(hammers, i)
		end
	end
end

registerEvent(hammerBros, "onTickEnd")

function hammerBros.setDefaultHarmTypes(id, effect)
	npcManager.registerHarmTypes(id,
		{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP},
		{
			[HARM_TYPE_JUMP] = {id = effect, speedX = 0, speedY = 0},
			[HARM_TYPE_FROMBELOW] = effect,
			[HARM_TYPE_HELD] = effect,
			[HARM_TYPE_PROJECTILE_USED] = effect,
			[HARM_TYPE_NPC] = effect,
			[HARM_TYPE_TAIL] = effect,
			[HARM_TYPE_SPINJUMP] = 10,
			[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
		}
	)
end

-----------------------------------------------------------

-- Get the x-coordinate of the player whose x-position is closest to the given bro.
local function getNearestPlayerX(bro)
	local nearestX = -1
	local nearestDist
	for k, p in ipairs(Player.get()) do
		if nearestX == -1 or math.abs(p.x - bro.x) < nearestDist then
			nearestX = p.x
			nearestDist = math.abs(p.x - bro.x)
		end
	end

	return nearestX
end

-- Get the direction the bro is actually facing.  This is independent of the "direction" field for the NPC, due to the fact that said field always adjusts
-- itself based on the speedX of the associated NPC, whereas hammer bros can walk backward but still be facing the same direction, for instance.
-- The direction the sprite is drawn and the direction hammers are thrown is always based on what we get from this value.
local function getDirectionFacing(bro)
	if not NPC.config[bro.id].followplayer then  
		if NPC.config[bro.id].chaseplayer then
			return bro.data._basegame.walkDirection
		else
			return bro.data._basegame.initialDirection
		end
	end

	local grabbed = bro:mem(0x12E, FIELD_WORD) ~= 0 or bro:mem(0x136, FIELD_BOOL)

	-- The hammer bro faces the player if not grabbed or in a colliding state (i.e., when thrown or fired from a projectile generator), or the direction in
	-- the NPC direction field, otherwise.

	if (not grabbed) and bro.x < getNearestPlayerX(bro) or grabbed and bro.direction == 1 then
		return 1
	end

	return -1
end

local function drawHeldNPC(id, x, y, direction, priority)
	local config = NPC.config[id]
	local offsy = 0
	local height = config.gfxheight
	if height <= 0 then
		height = config.height
	end
	local width = config.gfxwidth
	if width <= 0 then
		width = config.width
	end
	if config.framestyle ~= 0 and direction == 1 then
		offsy = height * config.frames
	end
	Graphics.drawImageToSceneWP(Graphics.sprites.npc[id].img, x + config.gfxoffsetx - width / 2, y - height + config.gfxoffsety, 0, offsy, width, height, 1, priority)
end

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the hammer bro's relevant parameters (no data is used here, due to
-- the small number of such parameters needed).
local function initialize(bro)
	local config = configs[bro.id]
	local data = bro.data._basegame
	
	-- Flag used to denote whether or not this NPC has been initialized previously.  Set to 1 when initialized.
	bro.ai1 = 1

	-- Left/right movement timer.  Starts at 100.  Once it reaches 0, the bro switches directions.
	data.walkTimer = config.walkframes
  
	-- The bro's jumping timer.  Starts at config + up to a second.  Once it reaches 0, the bro leaps high into the air.
	data.jumpTimer = config.jumpframes + RNG.randomInt(0, config.jumptimerange)

	-- The bro's toss timer.  Some value between 50 and 80.  Once it reaches the target, the bro pulls out a hammer.  Once it reaches 0, the hammer is tossed.
	data.throwTimer = math.min(config.holdframes + RNG.randomInt(config.waitframeslow, config.waitframeshigh), (config.initialtimer + RNG.randomInt(0, config.initialtimerrange)))
	
	-- The ID of the NPC the bro is currently holding.
	data.throwingID = nil 

	-- Set up the direction
	data.walkDirection = bro.direction
	if data.walkDirection == 0 then
		-- Random
		local rand = RNG.randomInt(1)

		if rand == 0 then
			data.walkDirection = -1
		else
			data.walkDirection = 1
		end
	end
	data.initialDirection = data.walkDirection
	data.facingDirection = data.walkDirection
	data.stallTimer = 8

	-- The timer for the throwing animation
	data.throwAnimTimer = 0

	-- Whether the bro is being held by a player
	data.held = (bro:mem(0x12C, FIELD_WORD) > 0)

	-- How many projectiles the bro has thrown
	data.volleyCount = 0

	bro.speedX = data.walkDirection * config.brospeed
end

local function scanLedges(v, range)
	local x1, x2 = v.x, v.x + v.width
	local y1 = v.y - range
	local y2 = v.y + v.height + range
	local foundBlockTops = {}
	local foundBlockBottoms = {v.y + v.height}
	local foundYs = {}
	local bounds = Section(v.section).boundary
	for k,b in NPC.iterateIntersecting(x1, y1, x2, y2) do
		if NPC.config[b.id].npcblock then
			table.insert(foundBlockBottoms, b.y + b.height)
		end
		if NPC.config[b.id].playerblocktop then
			if not foundYs[b.y] then
				foundYs[b.y] = true
				if b.y >= bounds.top and b.y <= bounds.bottom then
					table.insert(foundBlockTops, b.y)
				end
			end
		end
	end
	for k,b in Block.iterateIntersecting(x1, y1, x2, y2) do
		if not foundYs[b.y] then
			if Block.SEMISOLID_MAP[b.id] then
				foundYs[b.y] = true
				if b.y >= bounds.top and b.y <= bounds.bottom then
					table.insert(foundBlockTops, b.y)
				end
			elseif Block.SOLID_MAP[b.id] or Block.PLAYER_MAP[b.id] then
				foundYs[b.y] = true
				table.insert(foundBlockBottoms, b.y + b.height)
				if b.y >= bounds.top and b.y <= bounds.bottom then
					table.insert(foundBlockTops, b.y)
				end
			end
		end
	end
	for i = #foundBlockTops, 1, -1 do
		local t = foundBlockTops[i]
		local invalid = math.abs((v.y + v.height) - t) < 12
		if not invalid then
			for k,b in ipairs(foundBlockBottoms) do
				if b <= t and b >= t - v.height - 8 then
					invalid = true
					break
				end
			end
		end
		if invalid then
			table.remove(foundBlockTops, i)
		end
	end
	if #foundBlockTops == 0 then
		return nil
	end
	return RNG.irandomEntry(foundBlockTops)
end

local function performLedgeJump(v, data)
	local targetLedgeY = scanLedges(v,v.data._settings.ledgeSeekRange)

	if targetLedgeY == nil then return false end

	if targetLedgeY > v.y + v.height then
		v.speedY = -4
		data.isPerformingHighJump = 1
	else
		v.speedY = -NPC.config[v.id].jumpspeed
		data.isPerformingHighJump = -1
	end
	data.targetY = targetLedgeY
	v.noblockcollision = true
	return true
end

local function spawnNPC(bro, data, config)
	local ham = NPC.spawn(data.throwingID, bro.x - (config.throwoffsetx * data.facingDirection), bro.y - config.throwoffsety, bro:mem(0x146, FIELD_WORD), false)
	ham.data._basegame.ownerBro = bro
	ham.direction = data.facingDirection
	ham.layerName = "Spawned NPCs"
	ham.x = ham.x + (bro.width / 2) - (ham.width / 2)
	ham.speedX = ham.direction * config.throwspeedx or 0
	ham.speedY = config.throwspeedy or 0
	ham.friendly = bro.friendly
	
	if config.onThrowFunction ~= nil then
		config.onThrowFunction(bro, ham, data, config)
	end
	
	data.throwAnimTimer = config.shootframeduration
	data.throwTimer = config.holdframes + RNG.randomInt(config.waitframeslow, config.waitframeshigh)
	data.throwingID = nil
	
	if config.throwSFX then SFX.play(config.throwSFX) end
	
	if data.held and config.doheldharm then
		ham:mem(0x12E, FIELD_WORD, 9999)
		ham:mem(0x130, FIELD_WORD, bro:mem(0x12C, FIELD_WORD))
		table.insert(hammers, ham)
	end

	if config.syncheldspeed then
        	if bro:mem(0x12C,FIELD_WORD) > 0 then
        		local p = Player(bro:mem(0x12C,FIELD_WORD))
			ham.speedX = ham.speedX + p.speedX
		end
	end
end

function hammerBros.onTickNPC(bro)
	if Defines.levelFreeze or bro.isHidden or bro:mem(0x12A, FIELD_WORD) <= 0 or bro:mem(0x124, FIELD_WORD) == 0 or bro.forcedState > 0 then
		return
	end

	if bro.ai1 ~= 1 then
		-- Set up newly spawned bros
		initialize(bro)
	end

	local data = bro.data._basegame
	local config = configs[bro.id]

	if bro:mem(0x12C, FIELD_WORD) > 0 then
		-- Held
		
		data.throwTimer = data.throwTimer - 1 * config.npcheldfirerate
		data.throwAnimTimer = data.throwAnimTimer - 1 * (config.npcheldfirerate * 0.5)
		data.facingDirection = bro.direction
		if data.throwTimer <= 0 then
			data.throwTimer = config.holdFrames + config.waitframeslow
			if data.throwingID ~= nil then
				spawnNPC(bro, data, config)
			end
		elseif data.throwTimer < config.holdFrames and data.throwingID == nil then
			if config.holdSFX then SFX.play(config.holdSFX) end

			local npcToThrow
			if config.throwidheld and config.throwidheld > 0 then
				npcToThrow = config.throwidheld
			else
				npcToThrow = config.throwid
			end

			data.throwingID = npcToThrow
		end
		data.isJumping = false
		data.held = true
		return 
	end

	if data.held then
		-- Just released, kill the bro
		bro:mem(0x122,FIELD_WORD, 3)
		return
	end
	
	data.held = false
	data.facingDirection = getDirectionFacing(bro)
	data.throwAnimTimer = data.throwAnimTimer - 1

	if data.throwTimer >= 0 then
		if (data.throwingID ~= nil and not config.movewhenshooting) then
			bro.speedX = 0
			bro:mem(0x5C, FIELD_FLOAT, 0)
		else
			bro.speedX = data.walkDirection * config.brospeed
		end

		if data.walkTimer <= 0 then
			-- Switch directions.

			if config.chaseplayer then
				local p = Player.getNearest(bro.x + 0.5 * bro.width, bro.y + 0.5 * bro.height)

                        	if p.x + 0.5 * p.width > bro.x + 0.5 * bro.width then
                        		data.walkDirection = 1
                        	else
                        		data.walkDirection = -1
                        	end
			else
				data.walkDirection = -data.walkDirection
			end
			data.walkTimer = config.walkframes
		elseif (bro.collidesBlockBottom or config.movewhenjumping) and (data.throwingID == nil or config.movewhenshooting) then
			-- Only update the direction timer if the bro is not in the air.
			
			data.walkTimer = data.walkTimer - 1
		end

		if data.jumpTimer <= 0 and not data.isJumping and bro.collidesBlockBottom then
			-- The bro performs a leap.
			local jumpToOtherPlatform = false
			if bro.data._settings.ledgeSeekRange > 0 then
				jumpToOtherPlatform = RNG.random(0, 1) <= bro.data._settings.ledgeJumpChance
			end
			if jumpToOtherPlatform then
				if not performLedgeJump(bro, data) then
					bro.speedY = -config.jumpspeed
				end
			else
				if RNG.random(0, 1) <= config.secondjumpchance then
					bro.speedY = -config.secondjumpspeed
				else
					bro.speedY = -config.jumpspeed
				end
				if bro.data._settings.regularJumpNoBlockCollision then
					data.targetY = bro.y + bro.height
					data.isPerformingHighJump = -1
					bro.noblockcollision = true
				end
			end
			
			if config.jumpSFX then SFX.play(config.jumpSFX) end
			data.isJumping = true
			data.jumpTimer = -1
			if config.stalltime > 0 then
				data.stallTimer = config.stalltime
			end
		elseif data.jumpTimer <= 0 and data.isJumping then
			-- The bro has performed a large leap into the air.  Check to see if the bro has landed.
			
			if not config.movewhenjumping then
				bro.speedX = 0
				bro:mem(0x5C, FIELD_FLOAT, 0)
			end

			if data.isPerformingHighJump then
				if data.isPerformingHighJump > 0 and bro.y + bro.height + bro.speedY + Defines.npc_grav >= data.targetY - bro.speedX then
					bro.noblockcollision = false
					data.isPerformingHighJump = nil
				elseif data.isPerformingHighJump < 0 then
					local jumpMaxY = bro.y + bro.height - (config.jumpspeed + config.jumpspeed * config.jumpspeed / Defines.npc_grav) / 2
					if jumpMaxY >= data.targetY - 32 then
						bro.speedY = -config.jumpspeed
					end
					if bro.y + bro.height + bro.speedY + Defines.npc_grav >= data.targetY - bro.speedX and bro.speedY >= 0 then
						bro.noblockcollision = false
						data.isPerformingHighJump = nil
					end
				end
			end
			if config.quake and bro.speedY > 0 and data.stallTimer > 0 then
				bro.speedY = -Defines.npc_grav
				data.stallTimer = data.stallTimer - 1
				if data.stallTimer == 0 then
					bro.speedY = 8
				end
			end
			
			if data.isJumping and bro.collidesBlockBottom then
				if config.quake then
					if (not bro:mem(0x126, FIELD_BOOL) or not bro:mem(0x128, FIELD_BOOL)) then
						-- Create an earthquake and, if not set to friendly, stun any players on the ground that are not already stunned in
						-- the NPC's section and visible on the same camera as the NPC.
						
						Defines.earthquake = math.max(Defines.earthquake, config.quakeintensity)
						if config.quakeSFX then SFX.play(config.quakeSFX) end
						Effect.spawn(10, bro.x - 8, bro.y + bro.height - 16).speedX = -2
						Effect.spawn(10, bro.x + 8, bro.y + bro.height - 16).speedX = 2
						
						if not bro.friendly then
							for k, p in ipairs(Player.get()) do
								if (k == 1 and not bro:mem(0x126, FIELD_BOOL)) or (k == 2 and not bro:mem(0x128, FIELD_BOOL)) or k > 2 then
									if p:isGroundTouching() and not playerStun.isStunned(k) and bro:mem(0x146, FIELD_WORD) == p.section then
										playerStun.stunPlayer(k, config.stunframes)
									end
								end
							end
						end
					end
				end
				
				data.jumpTimer = config.jumpframes + RNG.randomInt(0, config.jumptimerange)
				data.isJumping = false
			end
		elseif bro.collidesBlockBottom then
			-- Only update the jump timer if the bro is not in the air.
			data.jumpTimer = data.jumpTimer - 1
		end

		data.throwTimer = data.throwTimer - 1

		if data.throwTimer <= config.holdframes and data.throwingID == nil then
			if config.holdSFX then SFX.play(config.holdSFX) end
			data.throwingID = config.throwid
		end
	elseif data.throwingID ~= nil then
		-- Fire a hammer and reset the hammer timer.

		spawnNPC(bro, data, config)

		data.volleyCount = data.volleyCount + 1
		
		if data.volleyCount < config.volley then
			data.throwTimer = config.volleyframes
			data.throwingID = config.throwid
		else
			data.volleyCount = 0
		end
	end
end

local utils = require("npcs/npcutils")

-- Get priority function (for the held hammers). Originally written by S.Koopa0.
local overheadHoldingCharacters = table.map({CHARACTER_PEACH, CHARACTER_TOAD, CHARACTER_MEGAMAN, CHARACTER_KLONOA, CHARACTER_NINJABOMBERMAN, CHARACTER_ROSALINA, CHARACTER_ULTIMATERINKA})
local function isHeldOverhead(v) return overheadHoldingCharacters[v.heldPlayer.character] end
local function getRenderPriority(v)
	local p = -45
	if v.forcedState == NPCFORCEDSTATE_BLOCK_RISE or v.forcedState == NPCFORCEDSTATE_BLOCK_FALL or v.forcedState == NPCFORCEDSTATE_WARP then
		p = -75
	elseif v.heldIndex > 0 then
		if isHeldOverhead(v) then
			p = -25
		else
			p = -30
		end
	elseif NPC.config[v.id].foreground then
		p = -15
	end
	return p
end

function hammerBros.onDrawNPC(bro)
	if not bro.isValid or bro:mem(0x12A, FIELD_WORD) <= 0 or bro:mem(0x124, FIELD_WORD) == 0 then return end

	local config = configs[bro.id]
	local data = bro.data._basegame

	if bro.ai1 ~= 1 then
		-- Detects that the NPC hasn't been set up yet
		return
	end

	local direction = data.facingDirection
	if data.held then
		direction = bro.direction
	end

	-- taken from Murphmario's bros.lua
	utils.restoreAnimation(bro)
	walk = utils.getFrameByFramestyle(bro, {
		frames = config.animwalkframes,
		gap = config.animjumpframes + config.animholdframes + config.animshootframes,
		offset = 0,
		direction = direction
	})
	jump = utils.getFrameByFramestyle(bro, {
		frames = config.animjumpframes,
		gap = config.animholdframes + config.animshootframes,
		offset = config.animwalkframes,
		direction = direction
	})
	hold = utils.getFrameByFramestyle(bro, {
		frames = config.animholdframes,
		gap = config.animshootframes,
		offset = config.animwalkframes + config.animjumpframes,
		direction = direction
	})
	shoot = utils.getFrameByFramestyle(bro, {
		frames = config.animshootframes,
		gap = 0,
		offset = config.animwalkframes + config.animjumpframes + config.animholdframes,
		direction = direction
	})

	local prio
	if config.drawnpcinfront then
		prio = getRenderPriority(bro) + 1
	else
		prio = getRenderPriority(bro) - 1
	end

	-- If the hammer bro is about to fire a hammer, set its frame to the associated tossing sprite (adding index frames).
	if data.throwAnimTimer > 0 and config.animshootframes > 0 then
		bro.animationFrame = shoot
	elseif data.throwingID ~= nil then
		bro.animationFrame = hold

		if config.drawheldnpc then
			drawHeldNPC(data.throwingID, bro.x - direction * config.holdoffsetx + bro.width / 2, bro.y + config.holdoffsety, direction, prio)
		end
	elseif data.isJumping and config.animjumpframes > 0 then
		bro.animationFrame = jump
	else
		bro.animationFrame = walk
	end
end

return hammerBros