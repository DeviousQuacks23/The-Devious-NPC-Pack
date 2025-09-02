local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local redirector = require("redirector")

local movingPlatform = {}

function movingPlatform.register(npcID)
	npcManager.registerEvent(npcID, movingPlatform, "onTickNPC")
	npcManager.registerEvent(npcID, movingPlatform, "onTickEndNPC")
	npcManager.registerEvent(npcID, movingPlatform, "onDrawNPC")
end

-- Custom platform skin sprites by Nitrox, SuperAlex, Askywalker, Crafink, SanS1m0n, FireSeraphim, Gate, Sednaiur, Murphmario, VannyArts

-- Movement behaviours (by MDA)
local MOVEMENT_STILL = 0
local MOVEMENT_STRAIGHT_HOR = 1
local MOVEMENT_STRAIGHT_VER = 2
local MOVEMENT_STRAIGHT_DIA = 3
local MOVEMENT_TURN_HOR = 4
local MOVEMENT_TURN_VER = 5
local MOVEMENT_TURN_DIA = 6
local MOVEMENT_REDIRECTOR = 7

local movementFuncs = {}
local movementIsVertical = {}
local movementIsDiagonal = {}

local function getCollidingBGO(v)
	local bgoPoint = Colliders.Point(0,0)
	local npcBox = Colliders.Box(0,0,1,1)

	for _,b in ipairs(BGO.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
		bgoPoint.x = b.x + 16
		bgoPoint.y = b.y + 16

		-- Collision box is a small square in the middle of the platform. Scales with speed
		local boxwidth = math.max(8,math.abs(v.speedX) + 4)
		local boxheight = math.max(8,math.abs(v.speedY) + 6)

		npcBox.x = v.x + (v.width/2) - (boxwidth/2)
		npcBox.y = v.y + (v.height/2) - (boxheight/2)
		npcBox.width = boxwidth
		npcBox.height = boxheight

		if not v.isHidden and not b.isHidden and Colliders.collide(bgoPoint,npcBox) then
			return b
		end
	end

	return nil
end

function setNewPlatformSize(v)
    	local settings = v.data._settings
    	local data = v.data

    	local newSpawnWidth = v.spawnWidth*settings.width
    	local newWidth = v.width*settings.width

    	v.spawnX = v.spawnX + (v.spawnWidth - newSpawnWidth)*0.5
    	v.spawnWidth = newSpawnWidth

    	v.x = v.x + (v.width - newWidth)*0.5
    	v.width = newWidth

    	data.hasChangedSize = true
end

-- Movement functions

local function getSettingSuffix(isVertical)
	if isVertical then
		return "v"
	else
		return "h"
	end
end

local function movementStill(v,data,config,settings,speed,isVertical)
	return 0
end

local function movementFlyStraight(v,data,config,settings,speed,isVertical)
	local settingSuffix = getSettingSuffix(isVertical)

	return (settings["straight_".. settingSuffix.. "_speed"] or 1)*v.direction
end

local function movementFlyAndTurn(v,data,config,settings,speed,isVertical)
	local settingSuffix = getSettingSuffix(isVertical)

	local distance = (settings["turn_".. settingSuffix.. "_distance"] or 128)*0.5*v.direction
	local time = (settings["turn_".. settingSuffix.. "_time"] or 320)/(math.pi*2)

	return math.sin(data.movementTimer/time)*(distance/time)
end

local function movementRedirector(v,data,config,settings,speed,isVertical)
	if getCollidingBGO(v) then
		local b = getCollidingBGO(v)

		if redirector.VECTORS[b.id] then
			local redirectorSpeed = redirector.VECTORS[b.id] * (settings.redirectorSpeed or 1)

			if isVertical then
				return redirectorSpeed.y
			else
				return redirectorSpeed.x
			end
		elseif b.id == redirector.TERMINUS then 
			return 0
		end
	end

	return speed
end

movementFuncs[MOVEMENT_STILL] = movementStill
movementIsVertical[MOVEMENT_STILL] = false
movementIsDiagonal[MOVEMENT_STILL] = false

movementFuncs[MOVEMENT_STRAIGHT_HOR] = movementFlyStraight
movementIsVertical[MOVEMENT_STRAIGHT_HOR] = false
movementIsDiagonal[MOVEMENT_STRAIGHT_HOR] = false

movementFuncs[MOVEMENT_STRAIGHT_VER] = movementFlyStraight
movementIsVertical[MOVEMENT_STRAIGHT_VER] = true
movementIsDiagonal[MOVEMENT_STRAIGHT_VER] = false

movementFuncs[MOVEMENT_STRAIGHT_DIA] = movementFlyStraight
movementIsVertical[MOVEMENT_STRAIGHT_DIA] = false
movementIsDiagonal[MOVEMENT_STRAIGHT_DIA] = true

movementFuncs[MOVEMENT_TURN_HOR] = movementFlyAndTurn
movementIsVertical[MOVEMENT_TURN_HOR] = false
movementIsDiagonal[MOVEMENT_TURN_HOR] = false

movementFuncs[MOVEMENT_TURN_VER] = movementFlyAndTurn
movementIsVertical[MOVEMENT_TURN_VER] = true
movementIsDiagonal[MOVEMENT_TURN_VER] = false

movementFuncs[MOVEMENT_TURN_DIA] = movementFlyAndTurn
movementIsVertical[MOVEMENT_TURN_DIA] = false
movementIsDiagonal[MOVEMENT_TURN_DIA] = true

movementFuncs[MOVEMENT_REDIRECTOR] = movementRedirector
movementIsVertical[MOVEMENT_REDIRECTOR] = false
movementIsDiagonal[MOVEMENT_REDIRECTOR] = true

-- Customizable widths! (taken from swinging platforms)
function movingPlatform.onTickNPC(v)	
    	if v.despawnTimer <= 0 then
		return
    	end

    	local data = v.data

    	if not data.hasChangedSize then
		setNewPlatformSize(v)
	end
end

-- Actual platform logic
function movingPlatform.onTickEndNPC(v)	
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

		data.movementTimer = 0

        	data.despawning = false
		data.despawnTimer = (settings.vanishTime or 95)

		data.isFalling = false
		data.fallTimer = 0
		data.isFallingViaTerminus = false

		data.isActive = settings.shouldStartActive
	end

	--[[Text.print(data.isActive, 0, 0)
	Text.print(data.movementTimer, 0, 16)
	Text.print(settings.movement, 0, 32)
	Text.print(movementIsVertical[settings.movement], 0, 48)
	Text.print(movementIsDiagonal[settings.movement], 0, 64)]]

	if v.heldIndex ~= 0  or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end

	-- Despawn behavior (by cold soup)

	if settings.vanishOnTerminus then
		if getCollidingBGO(v) then
			local b = getCollidingBGO(v)

			if b.id == redirector.TERMINUS then
				data.despawning = true
			end
		end
	end

	if data.despawning then
		data.despawnTimer = data.despawnTimer - 1

		-- Flash when despawning
		v.animationFrame = -1 + (data.despawnTimer % 2)

		if data.despawnTimer <= 0 then
                        local e = Effect.spawn(10, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
    			v:kill(HARM_TYPE_VANISH)
		end
	end

	-- Other things

	if settings.pleaseDontDespawn then
                v.despawnTimer = 180
        end

	npcutils.applyLayerMovement(v)

	-- Actual platform logic

	if data.isFalling then
		data.fallTimer = data.fallTimer + 1

		if data.fallTimer <= settings.fallDelay then
			v.speedY = settings.delaySpeed
		else
			v.speedY = math.min(settings.fallMaxSpeed, v.speedY + settings.fallAccel)
		end
	else
		if data.isActive then
			data.movementTimer = data.movementTimer + 1

			if movementIsDiagonal[settings.movement] then
				v.speedX = movementFuncs[settings.movement](v,data,config,settings,v.speedX,false)
				v.speedY = movementFuncs[settings.movement](v,data,config,settings,v.speedY,true)
			elseif movementIsVertical[settings.movement] then
				v.speedY = movementFuncs[settings.movement](v,data,config,settings,v.speedY,true)
			else
				v.speedX = movementFuncs[settings.movement](v,data,config,settings,v.speedX,false)
			end
		else
			v.speedX = 0
			v.speedY = 0
		end
	end

	-- Falling

	if settings.dontFallIfNothing and not data.isFallingViaTerminus then 
		data.isFalling = false 
	end

	for i, p in ipairs(Player.get()) do
		if p.standingNPC == v then
			if settings.fallWhenStoodOn then
				data.isFalling = true
				data.isActive = false
				v.speedX = 0
			else
				data.isActive = true
			end
			break
		end
	end

	if settings.fallOnTerminus then
		if getCollidingBGO(v) then
			local b = getCollidingBGO(v)

			if b.id == redirector.TERMINUS then
				data.isFallingViaTerminus = true
				data.isFalling = true
				data.isActive = false
				v.speedX = 0
			end
		end
	end
end

function movingPlatform.onDrawNPC(v) -- taken from swinging platforms
    	if v.despawnTimer <= 0 or v.isHidden then return end

    	local config = NPC.config[v.id]
    	local data = v.data

    	if not data.hasChangedSize then 
		setNewPlatformSize(v)
	end

    	local unitWidth = (config.gfxwidth / 3)
    	local totalWidth = v.width
    	local unitCount = math.max(2, math.ceil(totalWidth / unitWidth))
    	local actualUnitWidth = math.min(totalWidth * 0.5, unitWidth)

    	local image = Graphics.sprites.npc[v.id].img

	local lowPriorityStates = table.map{1, 3, 4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    	for i = 1, unitCount do
        	local x = v.x + v.width * 0.5 - totalWidth * 0.5 + config.gfxoffsetx
        	local y = v.y + v.height - config.gfxheight + config.gfxoffsety
        	local sourceX = 0
        	local sourceY = (v.animationFrame * config.gfxheight)

        	if i == unitCount then
            		x = x + totalWidth - actualUnitWidth
            		sourceX = config.gfxwidth - actualUnitWidth
        	elseif i > 1 then
            		x = x + (i - 1) * actualUnitWidth
            		sourceX = unitWidth
        	end

        	Graphics.drawImageToSceneWP(image, math.floor(x + 0.5), math.floor(y + 0.5), sourceX + (v.ai2 * config.gfxwidth), sourceY, actualUnitWidth, config.gfxheight, priority)
    	end

    	npcutils.hideNPC(v)
end

return movingPlatform