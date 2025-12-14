local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Sprites by Eminus
-- Originally by Von Fahrenheit

-- Based on the Stretch Boo NPCs

local landBloopers = {}

local tableinsert = table.insert

landBloopers.TYPE = {
    ["FLOOR"] = 1,
    ["CEILING"] = 2,
    ["LEFTWALL"] = 3,
    ["RIGHTWALL"] = 4,
}

local ids = {}

function landBloopers.register(id, t)
    if t == nil or t <= 0 or t > 4 then
        error("Must provide valid landBloopers t. Types are landBloopers.TYPE.FLOOR/CEILING/LEFTWALL/RIGHTWALL.")
        return
    end

    ids[id] = t
	npcManager.registerEvent(id, landBloopers, "onTickEndNPC")
	npcManager.registerEvent(id, landBloopers, "onTickNPC")
end

-- let's be ambiguous about variables

local rightsideTerminology = {
    x = "x",
    y = "y",
    speedX = "speedX",
    speedY = "speedY",
    width = "width",
    height = "height",
}

local wallTerminology = {
    x = "y",
    y = "x",
    speedX = "speedY",
    speedY = "speedX",
    width = "height",
    height = "width",
}

local terms = {
    [landBloopers.TYPE.FLOOR] = rightsideTerminology,
    [landBloopers.TYPE.CEILING] = rightsideTerminology,
    [landBloopers.TYPE.LEFTWALL] = wallTerminology,
    [landBloopers.TYPE.RIGHTWALL] = wallTerminology,
}

local upSide = {
    [landBloopers.TYPE.FLOOR] = 1,
    [landBloopers.TYPE.CEILING] = -1,
    [landBloopers.TYPE.LEFTWALL] = -1,
    [landBloopers.TYPE.RIGHTWALL] = 1,
}

--blacklist functions

local function blckDefaultMap(v, npc)
	return Block.SOLID_MAP[v.id] or Block.HURT_MAP[v.id] or Block.SEMISOLID_MAP[v.id] or Block.PLAYER_MAP[v.id]
end

local function blckBlockSemisolid(v, npc)
	return not Block.SEMISOLID_MAP[v.id]
end

local function blckBlockTopLim(v, npc, t)
	return v[terms[t]["y"]] == npc[terms[t]["y"]] + npc[terms[t]["height"]]
end

local function blckBlockBotLim(v, npc, t)
	return v[terms[t]["y"]] + v[terms[t]["height"]] == npc[terms[t]["y"]]
end

local baseBlacklists = {
	[-1] = {
		blckDefaultMap,
		blckBlockBotLim
	},
	[1] = {
		blckDefaultMap,
		blckBlockTopLim
	}
}

local function makeIntersectingNPCAndBlockMap(npc, x1, y1, width, height, blockBlacklist)
	local entries = {}
	for k,v in Block.iterateIntersecting(x1, y1, x1 + width, y1 + height) do
		if not ((not v.layerObj or v.layerObj.isHidden) or v:mem(0x5A, FIELD_WORD) ~= 0) then
			local cancel = false
			for _, n in ipairs(blockBlacklist) do
				if not n(v, npc, ids[npc.id]) then
					cancel = true
					break
				end
			end
			if not cancel then
				tableinsert(entries, v)
			end
		end
	end
	for k,v in NPC.iterateIntersecting(x1, y1, x1 + width, y1 + height) do 
		if not (NPC.config[v.id].playerblocktop == false or v.isHidden or v == npc or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x64, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0) then
			tableinsert(entries, v)
		end
	end
	return entries
end

local function getDistanceX(k,p)
	return k.x - p.x, k.x < p.x
end

local function getDistanceY(k,p)
	return k.y - p.y, k.y < p.y
end

local getDistance = {
    [landBloopers.TYPE.FLOOR] = getDistanceX,
    [landBloopers.TYPE.CEILING] = getDistanceX,
    [landBloopers.TYPE.LEFTWALL] = getDistanceY,
    [landBloopers.TYPE.RIGHTWALL] = getDistanceY,
}

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function chasePlayers(v, t)
	local p1, dir1 = getDistance[t](v, npcutils.getNearestPlayer(v))
	setDir(dir1, v)
end

local function commonAI(v, vDir, t)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]
	
	data.timer = data.timer + 1
		
	if data.state == 0 then
		if not v.dontMove then
			v[terms[t]["speedX"]] = v[terms[t]["speedX"]] + cfg.walkspeed * v.direction

			if RNG.randomInt(1, cfg.turnchance) == 1 then
				chasePlayers(v, t)
			end
		end

		if data.timer >= cfg.movetime then
			data.timer = 0
			data.state = 1
		end
	else
		local layer = v.layerObj
		if layer and not layer:isPaused() then
			v[terms[t]["speedX"]] = layer[terms[t]["speedX"]]
		else
			v[terms[t]["speedX"]] = 0
		end

		chasePlayers(v, t)

		if data.timer >= cfg.spittime then
			data.timer = 0
			data.state = 0

	        	local pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5),
			(Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()

			if cfg.inkshot and cfg.inkshot > 0 then
				local n = NPC.spawn(cfg.inkshot, v.x + v.width * 0.5, v.y + v.height * 0.5)
                       		n.x = n.x - n.width * 0.5
                        	n.y = n.y - n.height * 0.5
	        		n.speedX = pos.x * cfg.shotspeed
	        		n.speedY = pos.y * cfg.shotspeed
				n.friendly = v.friendly
				n.layerName = "Spawned NPCs"

				SFX.play(18)
			end
		end
	end
end

function landBloopers.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	if not data.timer then return end
	
	local cfg = NPC.config[v.id]
			
	local framespeed = cfg.framespeed
	local spitframes = cfg.spitframes
	local frames = cfg.frames - spitframes

	if data.state == 0 then
		-- animation
		v.animationTimer = 500
		v.animationFrame = math.floor(data.timer / framespeed) % frames
	else
		v.animationTimer = 500
		v.animationFrame = math.floor(data.timer / framespeed) % spitframes + frames
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v)
end

function landBloopers.onTickNPC(v)
	if Defines.levelFreeze then return end
	
    	local t = ids[v.id]
	local rightsideUp = upSide[t]
	
	local lspdx = 0
    	local lspdy = 0
	local layer = v.layerObj
	if layer and not layer:isPaused() then
		lspdx = layer[terms[t]["speedX"]]
		lspdy = layer[terms[t]["speedY"]]
	end
	v[terms[t]["speedX"]] = lspdx
	v[terms[t]["speedY"]] = lspdy
	
	local data = v.data._basegame
	local cfg = NPC.config[v.id]
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x134, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.timer = 0
		data.state = 0
		return
	end
	
	if not data.timer then
		data.timer = 0
		data.state = 0
	end
	
	if not data.wallCollider then
		data.cliffCollider = Colliders.Box(v.x,v.y,2,2)
        	data.wallCollider = Colliders.Box(v.x, v.y, 4, v.height - 4)
        	if terms[t]["x"] == "y" then
            		data.cliffCollider.width, data.cliffCollider.height = data.cliffCollider.height, data.cliffCollider.width
            		data.wallCollider.width, data.wallCollider.height = data.wallCollider.height, data.wallCollider.width
        	end
	end
	
	commonAI(v, rightsideUp, t)
	
	if v.layerObj and v[terms[t]["speedX"]] == v.layerObj[terms[t]["speedX"]] or v[terms[t]["speedX"]] == 0 then return end

	-- Cliff turning

	data.wallCollider[terms[t]["x"]] = v[terms[t]["x"]] + 0.5 * v[terms[t]["width"]] - 0.5 * data.wallCollider[terms[t]["width"]] + v.direction * (0.5 * v[terms[t]["width"]] - 0.5 * data.wallCollider[terms[t]["width"]])
	data.wallCollider[terms[t]["y"]] = v[terms[t]["y"]] + 2
	local wallblocks = makeIntersectingNPCAndBlockMap(v, data.wallCollider.x, data.wallCollider.y, data.wallCollider.width, data.wallCollider.height, {blckDefaultMap})
	for _,q in ipairs(wallblocks) do
		if not Block.SEMISOLID_MAP[q.id] then
			v.direction = -v.direction;
			v[terms[t]["x"]] = v[terms[t]["x"]] + 2 * v.direction
			return
		end
	end
	
	data.cliffCollider[terms[t]["x"]] = v[terms[t]["x"]] + 0.5 * v[terms[t]["width"]] - 1 + v.direction * (0.5 * v[terms[t]["width"]] + 1)
	data.cliffCollider[terms[t]["y"]] = v[terms[t]["y"]] + 0.5 * v[terms[t]["height"]] - 1 + rightsideUp * (0.5 * v[terms[t]["height"]] + 1)
	local edgeBlocks = makeIntersectingNPCAndBlockMap(v, data.cliffCollider.x, data.cliffCollider.y, data.cliffCollider.width, data.cliffCollider.height, baseBlacklists[rightsideUp])
	if #edgeBlocks == 0 then v.direction = -v.direction end
end
	
return landBloopers