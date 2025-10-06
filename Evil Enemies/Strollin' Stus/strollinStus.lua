local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Compat with Marioman2007's FLUDD
local fludd
pcall(function() fludd = require("AI/fludd") end)
fludd = fludd or {}

-- Sprites by Geno (on MFGG)
-- Code based on MDA's Galoombas

local strollinStu = {}
strollinStu.idMap  = {}

strollinStu.sharedSettings = {
    	luahandlesspeed = true,

   	speed = 1,
    	chargeSpeed = 3,
	detectDistance = 128,
	noticeBounce = 4,

    	isStunned = false,

    	stunnedID = 0,
	recoverID = 0,

    	kickedSpeedX = 5.5,
    	kickedSpeedY = -2.5,
    	recoverTime = 300,
    	shakeTime = 50,
    	recoverHopSpeed = -5,
		
	scaleStretchSpeed = 0.025,     
	scaleX = 1.1,		   
	scaleY = 0.9,		   

	coinID = 33,
	coinAmount = 3,
}

function strollinStu.register(npcID, settings)
   	npcManager.setNpcSettings(table.join(settings, strollinStu.sharedSettings))
    	npcManager.registerEvent(npcID, strollinStu, "onTickEndNPC")
    	npcManager.registerEvent(npcID, strollinStu, "onDrawNPC")
    	strollinStu.idMap[npcID] = true
end

function strollinStu.onInitAPI()
    	registerEvent(strollinStu, "onNPCHarm")
    	registerEvent(strollinStu, "onPostNPCKill")
end

local NORMAL = 0
local WIDE = 1
local SLIM = 2

local function changeSpriteSize(v, data, config, settings, scale)
	local oldWidth, oldHeight = config.width, config.height
	data.spriteScale = scale

	Routine.run(function()
		Routine.waitFrames(1)

		v.width = config.width * data.spriteScale
		v.height = config.height * data.spriteScale
		v.x = v.x + oldWidth / 2 - v.width / 2
		v.y = v.y + oldHeight - v.height
	end)
end

local function initialise(v, data, config, settings)
    	data.initialized = true
	changeSpriteSize(v, data, config, settings, data.spriteScale or settings.scale)

   	data.timer = 0
    	data.animationTimer = 0
    	data.rotation = 0

	data.bounceState = NORMAL
	data.scale = data.scale or vector(1, 1)
	data.effectDir = 0

	data.isCharging = false
	data.chargeDir = 0
end

-- takes start and makes it get closer to goal, at speed change
-- taken from SMATRS
local function approach(start, goal, change)
    	if start > goal then
        	return math.max(goal,start - change)
    	elseif start < goal then
        	return math.min(goal,start + change)
    	else
        	return goal
    	end
end

local function doStun(v, data, config, settings)
    	if config.stunnedID ~= nil and config.stunnedID > 0 then
        	v:transform(config.stunnedID)
	else
		return
    	end

    	initialise(v, data, NPC.config[config.stunnedID], settings)
	data.rotation = 180 * v.direction
end

local function kickStunned(v, data, config, culprit)
    	if type(culprit) == "Player" then
        	if (v.x + v.width * 0.5) < (culprit.x + culprit.width * 0.5) then
            		v.direction = DIR_LEFT
        	else
            		v.direction = DIR_RIGHT
        	end

        	v:mem(0x12E,FIELD_WORD, 10)
        	v:mem(0x130,FIELD_WORD, culprit.idx)
    	end

    	v:mem(0x136,FIELD_BOOL,true)

    	v.speedX = config.kickedSpeedX * v.direction
    	v.speedY = config.kickedSpeedY

    	SFX.play(9)
end

local function handleAnimation(v,data,config)
    	local direction = v.direction
    	local frame = 0
    	local shakeTimer = 0

    	if config.isStunned then
        	shakeTimer = (data.timer - (config.recoverTime - config.shakeTime))
    	end        

    	frame = math.floor(data.animationTimer / config.framespeed) % config.frames

    	if shakeTimer > 0 or data.isCharging then
        	data.animationTimer = data.animationTimer + 2
    	else
        	data.animationTimer = data.animationTimer + 1
    	end

    	if shakeTimer > 0 then
        	data.rotation = math.sin((shakeTimer / 18) * math.pi * 2) * 25
    	else
        	if data.rotation > 0 then
            		data.rotation = math.max(0, data.rotation - 10)
        	else
            		data.rotation = math.min(0, data.rotation + 10)
        	end

        	if math.abs(data.rotation) >= 90 then
            		direction = -direction
        	end
    	end

	local scaleSpeed = (data.isCharging and (config.scaleStretchSpeed * 2)) or config.scaleStretchSpeed

	if data.bounceState == NORMAL then
		data.scale.x = approach(data.scale.x, 1, scaleSpeed)
		data.scale.y = approach(data.scale.y, 1, scaleSpeed)
		data.bounceState = WIDE
	elseif data.bounceState == WIDE then
		data.scale.x = approach(data.scale.x, config.scaleX, scaleSpeed)
		data.scale.y = approach(data.scale.y, config.scaleY, scaleSpeed)
		if data.scale.x == config.scaleX and data.scale.y == config.scaleY then data.bounceState = SLIM end
	elseif data.bounceState == SLIM then
		data.scale.x = approach(data.scale.x, config.scaleY, scaleSpeed)
		data.scale.y = approach(data.scale.y, config.scaleX, scaleSpeed)
		if data.scale.x == config.scaleY and data.scale.y == config.scaleX then data.bounceState = WIDE end
	end

    	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame, direction = direction})
end

local function roundNumber(num, numDecimalPlaces)
  	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function strollinStu.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
    	local config = NPC.config[v.id]
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.spriteScale = nil
		return
	end

	if not data.initialized then
		initialise(v, data, config, settings)
	end

    	if config.isStunned and v:mem(0x138,FIELD_WORD) == 0 then
		npcutils.applyStationary(v)
        	data.timer = data.timer + 1

        	if data.timer >= config.recoverTime and v.collidesBlockBottom then
            		-- Jump out of player's arms
            		if v:mem(0x12C,FIELD_WORD) > 0 then
                		local p = Player(v:mem(0x12C,FIELD_WORD))

                		p:harm()
                		p:mem(0x154,FIELD_WORD,0)
                		v:mem(0x12C,FIELD_WORD,0)
            		end

			v.speedX = 0
           		v.speedY = config.recoverHopSpeed
            		v.collidesBlockBottom = false

            		v:transform(config.recoverID)

            		initialise(v, data, NPC.config[config.recoverID], settings)
			data.rotation = 180 * v.direction
        	end

		if v:mem(0x136,FIELD_BOOL) and not v.collidesBlockBottom and (v.collidesBlockLeft or v.collidesBlockRight) then
			Defines.earthquake = math.max(Defines.earthquake, data.spriteScale + 1)
			v:harm(HARM_TYPE_SPINJUMP)
			SFX.play(91)

			if config.coinAmount and config.coinAmount > 0 and config.coinID and config.coinID > 0 then
        			for i = 1, roundNumber((config.coinAmount * data.spriteScale), 0) do
                			local coin = NPC.spawn(config.coinID, v.x + v.height * 0.5, v.y + v.height * 0.5, v.section)
					coin.x = coin.x - coin.width * 0.5
					coin.y = coin.y - coin.height * 0.5
                			coin.speedX = RNG.random(-1, -6) * v.direction
                			coin.speedY = RNG.random(-2, -12)
                			coin.ai1 = 1	
				end
        		end
		end
    	end

	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
		if v.isProjectile then npcutils.applyStationary(v) end
        	handleAnimation(v, data, config)
        	return
    	end
	
    	if not config.isStunned then
		if data.isCharging then
			if not v.collidesBlockBottom and not data.hasLanded then
				v.speedX = 0
			else
				data.hasLanded = true
				v.speedX = config.chargeSpeed * v.direction

		        	if (lunatime.tick() % math.abs(v.speedX)) == 0 and v.collidesBlockBottom then
		                	local e = Effect.spawn(74,0,0)
		                	e.y = v.y+v.height-e.height * 0.5
                                	if v.direction == -1 then
		                        	e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                	else
		                        	e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                	end
                        	end
			end

			if v.direction ~= data.chargeDir then
				data.isCharging = false
			end
		else
            		v.speedX = config.speed * v.direction

			local n = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2))
			if n then
				local distanceX = (n.x+(n.width /2))-(v.x+(v.width /2))
				local distanceY = (n.y+(n.height/2))-(v.y+(v.height/2))
				local distance = math.abs(distanceX)+math.abs(distanceY)

				if distance <= config.detectDistance and v.collidesBlockBottom then
					v.speedX = 0
					v.speedY = -config.noticeBounce
					data.hasLanded = false

					npcutils.faceNearestPlayer(v)
					data.chargeDir = v.direction
					SFX.play(Misc.resolveSoundFile("chuck-whistle"), 0.5)
					data.isCharging = true
				end
			end
		end

		if v.underwater then
			doStun(v, data, config, settings)
		end
    	else
        	for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
            		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
            		and (v:mem(0x12E,FIELD_WORD) <= 0 or v:mem(0x130,FIELD_WORD) ~= p.idx) then
                		kickStunned(v, data, config, p)
            		end
        	end
    	end

    	handleAnimation(v, data, config)
end

function strollinStu.onDrawNPC(v)
    	if v.despawnTimer <= 0 or v.isHidden then return end

    	local config = NPC.config[v.id]
    	local data = v.data
	local settings = v.data._settings

    	if not data.initialized then
		initialise(v, data, config, settings)
	end

    	local texture = Graphics.sprites.npc[v.id].img

    	if data.sprite == nil or data.sprite.texture ~= texture then
        	data.sprite = Sprite{texture = texture, frames = npcutils.getTotalFramesByFramestyle(v), pivot = Sprite.align.CENTRE}
    	end

	local lowPriorityStates = table.map{1, 3, 4}
    	local priority = (lowPriorityStates[v:mem(0x138, FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    	data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    	data.sprite.y = v.y + ((v.height - (config.gfxheight * data.spriteScale)*0.5) * -data.scale.y) + config.gfxoffsety + (v.height - ((config.gfxheight * data.spriteScale) - v.height)) -- Could definitely be optimized but it's fine so i'm gonna leave it

    	data.sprite.scale = data.scale * data.spriteScale
    	data.sprite.rotation = data.rotation

    	data.sprite:draw{frame = v.animationFrame + 1, priority = priority, sceneCoords = true}

	-- Colliders.getHitbox(v):draw()
    	npcutils.hideNPC(v)
end

local effectHarmTypes = table.map{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL}

function strollinStu.onPostNPCKill(v, reason)
    	if not strollinStu.idMap[v.id] or not effectHarmTypes[reason] then return end

    	local config = NPC.config[v.id]
    	local data = v.data

        local effectID = (reason == HARM_TYPE_JUMP and config.stompEffect) or config.deathEffect
        local e = Effect.spawn(effectID, v.x + v.width * 0.5, v.y + v.height * 0.5)

	e.xScale, e.yScale = data.spriteScale or 1, data.spriteScale or 1
        e.x = e.x - (e.width * e.xScale) * 0.5
        e.y = e.y - (e.height * e.yScale) * 0.5
    	e.direction = v.direction
	e.speedX = ((math.abs(v.speedX) * 3) * (e.xScale * 0.5)) * data.effectDir
	e.speedY = -10 * e.yScale

    	if reason == HARM_TYPE_JUMP then e.speedX, e.speedY = 0, 0 end
end

function strollinStu.onNPCHarm(eventObj, v, reason, culprit)
    	if not strollinStu.idMap[v.id] then return end

    	local config = NPC.config[v.id]
    	local data = v.data
	local settings = v.data._settings

    	if not data.initialized then initialise(v, data, config, settings) end

    	if reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
            	eventObj.cancelled = true

            	if v:mem(0x26,FIELD_WORD) == 0 then
                	if not config.isStunned then
                    		doStun(v, data, config, settings)
                	else
                    		data.timer = 0
                	end

                	SFX.play(9)

			if culprit then
				v.speedX = math.sign((culprit.x + (culprit.width / 2)) - (v.x + (v.width / 2))) * -6
			end
                	v.speedY = -6

			v:mem(0x136, FIELD_BOOL, true)
                	v:mem(0x26, FIELD_WORD, 10) 
            	end
    	end

	if culprit then
		data.effectDir = -math.sign((culprit.x + (culprit.width / 2)) - (v.x + (v.width / 2)))
	else
		data.effectDir = RNG.irandomEntry({-1, 1})
	end
end

function fludd.onNPCHarmByWater(eventObj, n, v, p)
    	if not strollinStu.idMap[n.id] then return end

    	local config = NPC.config[n.id]
    	local data = n.data
	local settings = n.data._settings

	eventObj.cancelled = true
	doStun(n, data, config, settings)
end

return strollinStu