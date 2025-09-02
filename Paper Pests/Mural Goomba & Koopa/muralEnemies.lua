local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local muralEnemies = {}

muralEnemies.idMap = {}

function muralEnemies.register(npcID)
	npcManager.registerEvent(npcID, muralEnemies, "onTickEndNPC")
	npcManager.registerEvent(npcID, muralEnemies, "onDrawNPC")
        muralEnemies.idMap[npcID] = true
end

function muralEnemies.onInitAPI()
    	registerEvent(muralEnemies,"onNPCHarm")
    	registerEvent(muralEnemies,"onPostNPCKill")
end

function muralEnemies.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0
		data.timer = 0
		data.hp = cfg.health
	end

       	data.rotation = math.sin((data.timer / 10) * math.pi) * 20

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end

	-- Movement logic

	data.timer = data.timer + 1

	v.speedX = RNG.random(1, 4) * v.direction
	if data.timer % RNG.randomInt(30, 90) == 0 then v.direction = -v.direction end
	if data.timer % RNG.randomInt(30, 90) == 0 then npcutils.faceNearestPlayer(v) end
	if data.timer % RNG.randomInt(10, 150) == 0 then 
		if v.collidesBlockBottom then v.speedY = RNG.random(-1, -6) end
	end
end

function muralEnemies.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
	local lowPriorityStates = table.map{1,3,4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,
		height = config.gfxheight,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
		centered = true,
                rotation = data.rotation,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

function muralEnemies.onNPCHarm(eventObj,v,reason,culprit)
	if not muralEnemies.idMap[v.id] then return end
	
	local data = v.data

	if data.hp > 1 then
		if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
			eventObj.cancelled = true
			data.hp = data.hp - 1
			SFX.play(9)
		end
	end
end

-- Fragments and stuff

local spike = require("npcs/ai/smmspike")

-- This function is just to fix   r e d i g i t   issues lol
local function gfxSize(config)
	local gfxwidth  = config.gfxwidth
	if gfxwidth  == 0 then gfxwidth  = config.width  end
	local gfxheight = config.gfxheight
	if gfxheight == 0 then gfxheight = config.height end

	return gfxwidth, gfxheight
end

local function createFragments(id,x,y,rotation)
	local config = NPC.config[id]
	local gfxwidth,gfxheight = gfxSize(config)

	for i=1,4 do
		local nX,nY
		local frameX,frameY

		if i == 1 or i == 3 then
			nX = -(gfxwidth / 4)
			frameX = 1
		else 
			nX = (gfxwidth / 4)
			frameX = 2
		end
		if i == 1 or i == 2 then
			nY = -(gfxheight / 4)
			frameY = 1
		else
			nY = (gfxheight / 4)
			frameY = 2
		end

		local position = vector(x,y) + vector(nX,nY):rotate(rotation)

		table.insert(
			spike.fragments,
			{
				id = id,groupIdx = i,
				x = position.x,y = position.y,
				rotation = rotation,
				speedX = RNG.random(-3,3),
				speedY = RNG.random(0,-7),
				frameX = frameX,
				frameY = frameY,
			}
		)
	end
end

function muralEnemies.onPostNPCKill(v,killReason)
	if not muralEnemies.idMap[v.id] then return end

	local config = NPC.config[v.id]
	local data = v.data

	if killReason ~= HARM_TYPE_OFFSCREEN and killReason ~= HARM_TYPE_LAVA then
		createFragments(
			v.id,
			v.x + (v.width / 2) + config.gfxoffsetx,
			v.y + (v.height / 2) + config.gfxoffsety,
			data.rotation or 0
		)
	end
end

return muralEnemies