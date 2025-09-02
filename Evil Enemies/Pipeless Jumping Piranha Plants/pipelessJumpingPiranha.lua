local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local jumpingPiranha = {}

jumpingPiranha.idMap  = {}
jumpingPiranha.idList = {}

-- All of these functions are taken directly from piranhaPlant.lua
local function getInfo(v)
	local config = NPC.config[v.id]
	local data = v.data._basegame

	local settings = v.data._settings

	return config,data,settings
end

local function getDirectionInfo(v)
	if NPC.config[v.id].isHorizontal then
		return "x","spawnX","width" ,"speedX"
	else
		return "y","spawnY","height","speedY"
	end
end

local function doFireSpurt(v,spurtNumber)
	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)


	local fireID = settings.fireID
	if fireID == 0 then
		fireID = config.defaultFireID
	end

	if fireID == 0 then
		return
	end


	for i = 1,settings.firePerSpurt do
		local spawnPosition = vector(v.x + v.width*0.5,v.y + v.height*0.5)
		spawnPosition[position] = spawnPosition[position] + v[size]*0.25*data.direction


		--local totalIndex = (spurtNumber - 1)*math.ceil(settings.firePerSpurt*0.5) + math.abs(index)
		--local angle = (settings.fireAngle*totalIndex)*math.sign(index)

		local angle
		if settings.firePerSpurt > 1 then
			local align = (i - 1) - (settings.firePerSpurt - 1)*0.5

			angle = settings.fireAngle*(align + (spurtNumber - 1)*math.sign(align))
		else
			local n = Player.getNearest(spawnPosition.x,spawnPosition.y)

			if (n.x + n.width*0.5) < spawnPosition.x then
				angle = -settings.fireAngle
			else
				angle = settings.fireAngle
			end
		end

		local speed = vector(0,0)
		speed[position] = (settings.fireSpeed*data.direction)
		speed = speed:rotate(angle)


		local fire = NPC.spawn(fireID,spawnPosition.x,spawnPosition.y,v.section,false,true)

		if speed.x ~= 0 then
			fire.direction = math.sign(speed.x)
		else
			npcutils.faceNearestPlayer(fire)
		end

		fire.speedX = speed.x
		fire.speedY = speed.y

		fire.layerName = "Spawned NPCs"
		fire.friendly = data.originallyFriendly
	end

	if config.fireSound ~= nil and config.fireSound ~= 0 then
		SFX.play(config.fireSound)
	end
end

function jumpingPiranha.register(id)
    	npcManager.registerEvent(id,jumpingPiranha,"onTickEndNPC")
    	npcManager.registerEvent(id,jumpingPiranha,"onDrawNPC")

    	jumpingPiranha.idMap[id] = true
    	table.insert(jumpingPiranha.idList,id)
end

local STATE_BOUNCE  = 0
local STATE_JUMP  = 1
local STATE_REST  = 2
local STATE_LOWER  = 3

local NORMAL = 0
local WIDE = 1
local SLIM = 2

local function initialise(v)
	local data = v.data._basegame

    	data.state = STATE_BOUNCE
    	data.bounces = 0
    	data.timer = 0

	data.direction = v.direction

	data.bounceState = NORMAL
	data.hasChangedState = false
	data.hasCounted = false
	data.scale = vector(1, 1)

	v.collisionGroup = "pipelessJumpingPiranhaPlants"
end

-- takes start and makes it get closer to goal, at speed change
-- taken from SMATRS
local function approach(start,goal,change)
    	if start > goal then
        	return math.max(goal,start - change)
    	elseif start < goal then
        	return math.min(goal,start + change)
    	else
        	return goal
    	end
end

local function collidesBlockDir(v, data, config)
	if config.isHorizontal then
		if data.direction == -1 and v.collidesBlockRight then
			return true
		elseif data.direction == 1 and v.collidesBlockLeft then
			return true
		end
	else
		if data.direction == -1 and v.collidesBlockBottom then
			return true
		elseif data.direction == 1 and v.collidesBlockUp then
			return true
		end
	end

	return false
end

local function customGravity(data, speed, maxSpeed, gravity)
	if data.direction == -1 then
		return math.min(maxSpeed, speed + gravity)
	elseif data.direction == 1 then	
		return math.max(-maxSpeed, speed - gravity)
	end
end

function jumpingPiranha.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
		initialise(v)
	end

	if v:mem(0x136,FIELD_BOOL) then -- If in a projectile state, PANIC!
		v:kill(HARM_TYPE_NPC)
		return
	elseif v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- Held or in a forced state
		return
	end

	if data.bounceState == NORMAL then
		data.scale.x = approach(data.scale.x, 1, config.scaleStretchSpeed)
		data.scale.y = approach(data.scale.y, 1, config.scaleStretchSpeed)
	elseif data.bounceState == WIDE then
		data.scale.x = approach(data.scale.x, config.scaleX, config.scaleStretchSpeed)
		data.scale.y = approach(data.scale.y, config.scaleY, config.scaleStretchSpeed)
		if data.scale.x == config.scaleX and data.scale.y == config.scaleY then data.bounceState = SLIM end
	elseif data.bounceState == SLIM then
		data.scale.x = approach(data.scale.x, config.scaleY, config.scaleStretchSpeed)
		data.scale.y = approach(data.scale.y, config.scaleX, config.scaleStretchSpeed)
		if data.scale.x == config.scaleY and data.scale.y == config.scaleX then data.bounceState = NORMAL end
	end

	if config.isHorizontal then 
		v:mem(0x120, FIELD_BOOL, false) 
		v.speedY = 0
	end

	if data.state == STATE_BOUNCE then
                v[speed] = customGravity(data, v[speed], config.jumpMaxSpeed, config.jumpRisingGravity)
                if collidesBlockDir(v, data, config) then 
			if not data.hasChangedState then
				data.bounceState = WIDE
				data.hasChangedState = true
				data.hasCounted = false
			end
                end

		if data.bounceState == SLIM then
			if not data.hasCounted then
                        	data.bounces = data.bounces + 1
				data.hasChangedState = false
				data.hasCounted = true
				SFX.play(72, 0.6)

                        	if data.bounces > config.smallBounces then
                                	data.state = STATE_JUMP
                                	v[speed] = config.jumpStartSpeed * -data.direction
                        	else
                                	v[speed] = config.smallBounceHeight * -data.direction
                        	end
			end
		end
	elseif data.state == STATE_JUMP then
                v[speed] = customGravity(data, v[speed], config.jumpMaxSpeed, config.jumpRisingGravity)
                if (data.direction == -1 and v[speed] >= 0) or (data.direction == 1 and v[speed] <= 0) then
			data.state = STATE_REST
                end
	elseif data.state == STATE_REST then
		data.timer = data.timer + 1

		local restTime = 3
                v[speed] = 0

		if config.defaultFireID ~= nil and (config.defaultFireID ~= 0 or settings.fireID ~= 0) then
			local currentSpurt = math.floor(data.timer - restTime*0.5 + 0.5)/math.max(1,settings.fireSpurtDelay) + 1

			if currentSpurt == math.floor(currentSpurt) and currentSpurt >= 1 and currentSpurt <= settings.fireSpurts then
				doFireSpurt(v,currentSpurt)
			end

			restTime = restTime + settings.fireSpurts*settings.fireSpurtDelay
		end

		if data.timer > restTime then
			data.state = STATE_LOWER
			data.timer = 0
		end
	elseif data.state == STATE_LOWER then
		v[speed] = customGravity(data, v[speed], config.jumpMaxSpeed, config.jumpFallingGravity)
                if collidesBlockDir(v, data, config) then 
                        data.state = STATE_BOUNCE
                        data.bounces = 0
			data.hasChangedState = false
			data.hasCounted = false
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames,
		direction = data.direction
	});
end

function jumpingPiranha.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data._basegame
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
	local lowPriorityStates = table.map{1,3,4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	local scaleX, scaleY
	if config.isHorizontal then
		scaleX, scaleY = (data.scale.y or 1), (data.scale.x or 1)
	else
		scaleX, scaleY = (data.scale.x or 1), (data.scale.y or 1)
	end

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth*scaleX,
		height = config.gfxheight*scaleY,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

function jumpingPiranha.onNPCHarm(eventObj,v,reason,culprit)
	if not jumpingPiranha.idMap[v.id] then
		return
	end

	if reason == HARM_TYPE_SPINJUMP and type(culprit) == "Player" then
		-- Piranha plants can be killed by boot stomps/statue stomps, but not by spin jumps/yoshi stomps
		if culprit:mem(0x50,FIELD_BOOL) or culprit.mount == MOUNT_YOSHI then
			eventObj.cancelled = true
			return
		end
	end
end

function jumpingPiranha.onInitAPI()
	registerEvent(jumpingPiranha,"onNPCHarm")
	Misc.groupsCollide["pipelessJumpingPiranhaPlants"]["pipelessJumpingPiranhaPlants"] = false
end

return jumpingPiranha