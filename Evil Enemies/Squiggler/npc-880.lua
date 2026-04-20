local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local crawlerAI = require("wallcrawler")

-- Based on the Boo Cluster by S.Koopa0
-- Also uses wall crawler AI by S.Koopa0 & MegaDood

-- Sprites by Mariofan230

local squiggler = {}
local npcID = NPC_ID

local squigglerSettings = {
	id = npcID,
	gfxwidth = 28,
	gfxheight = 28,
	gfxoffsety = 2,
	width = 24,
	height = 24,
	frames = 1,
	framestyle = 1,
	framespeed = 8,
	speed = 1.25,
	luahandlesspeed = true,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	score = 2,
	jumphurt = false,
	spinjumpsafe = false,
	cliffturn = true,

	-- Devious is too lazy to change config names
	littlebooid = npcID + 1,
	littleboodistance = 9,
	littleboooffset = 6,
	nospecialanimation = false,
	nospecialrendering = false,

	rotationspeed = 15,
	collideswithnpcs = true,
}

npcManager.setNpcSettings(squigglerSettings)

local deathEffectID = npcID
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_VANISH,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = {id=deathEffectID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

crawlerAI.register(npcID, crawlerAI.ANIMATION.ROTATING_SMOOTH)

function squiggler.onInitAPI()
	npcManager.registerEvent(npcID, squiggler, "onTickNPC")
	npcManager.registerEvent(npcID, squiggler, "onTickEndNPC")
	npcManager.registerEvent(npcID, squiggler, "onDrawNPC")
	registerEvent(squiggler, "onNPCTransform")
	registerEvent(squiggler, "onPostNPCKill")
end

local function getChildSpawnPosition(v)
	local childcfg = NPC.config[NPC.config[v.id].littlebooid]
	local offset = vector(0, NPC.config[v.id].littleboooffset):rotate(math.deg(math.atan2(v.data.angle.y, v.data.angle.x)))

	return v.x + (v.width - childcfg.width) * 0.5 + (offset.x * v.data.direction),
	v.y + (v.height - childcfg.height) * 0.5 + (offset.y * v.data.direction)
end

local function initializeChildTables(v)
	local data = v.data._basegame

	data.children = {}
	data.childDistance = {}
	data.childX = {}
	data.childY = {}
	data.childSpeedX = {}
	data.childSpeedY = {}
end

local function spawnChildren(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	v.ai2 = v.spawnAi2

	for i = 1, v.ai2 do
		local child = NPC.spawn(cfg.littlebooid, getChildSpawnPosition(v))
		child.friendly = v.friendly
		child.layerName = v.layerName
		if cfg.littlebooid == npcID then child.data.spawnsWithNoLittleBoos = true end --this prevents the squigglers from spawning infinite segments
		table.insert(data.children, child)
		table.insert(data.childDistance, cfg.littleboodistance * i)
	end

	for i = 1, v.ai2 * cfg.littleboodistance do
		local x, y = getChildSpawnPosition(v)
		table.insert(data.childX, x)
		table.insert(data.childY, y)
		table.insert(data.childSpeedX, v.speedX)
		table.insert(data.childSpeedY, v.speedY)
	end
end

local function setChildPosition(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	for i = v.ai2 * cfg.littleboodistance, 2, -1 do
		data.childX[i] = data.childX[i - 1]
		data.childY[i] = data.childY[i - 1]
		data.childSpeedX[i] = data.childSpeedX[i - 1]
		data.childSpeedY[i] = data.childSpeedY[i - 1]
	end
	data.childX[1], data.childY[1] = getChildSpawnPosition(v)
	data.childSpeedX[1] = v.speedX
	data.childSpeedY[1] = v.speedY
end

local function resetChildPosition(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	for i = 1, v.ai2 * cfg.childdistance do
		data.childX[i], data.childY[i] = getChildSpawnPosition(v)
		data.childSpeedX[i] = 0
		data.childSpeedY[i] = 0
	end
end

local function isBeingGenerated(v)
	return v.forcedState == NPCFORCEDSTATE_BLOCK_RISE or v.forcedState == NPCFORCEDSTATE_BLOCK_FALL or v.forcedState == NPCFORCEDSTATE_WARP
end

local function setChildDistance(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	for i = 2, #data.childDistance do
		if data.childDistance[i] - data.childDistance[i - 1] > cfg.littleboodistance * i then data.childDistance[i] = data.childDistance[i] - 1 end
	end
end

local function isOnScreen(v)
	for i,c in ipairs(Camera.get()) do
		if v.x >= c.x - v.width and v.x < c.x + c.width + v.width and v.y >= c.y - v.height and v.y < c.y + c.height + v.height then return true end
	end
	return false
end

local function isChild(v)
	for _,parent in NPC.iterate(npcID) do
		if table.icontains(parent.data._basegame.children, v) then return true, parent end
	end
	return false, nil
end

local function hasChildren(v)
	return v.data._basegame.children and #v.data._basegame.children > 0
end

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

local function drawNPC(v)
	if v.isValid and v.despawnTimer >= 0 and not v.isHidden and v.forcedState ~= NPCFORCEDSTATE_DROPPED_ITEM and v.forcedState ~= NPCFORCEDSTATE_INVISIBLE then
		npcutils.drawNPC(v, {priority = getRenderPriority(v) - 1})
		npcutils.hideNPC(v)
	end
end

function squiggler.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		initializeChildTables(v)
		if not data.spawnsWithNoLittleBoos then spawnChildren(v) end
		data.initialized = true
	end

	if not isBeingGenerated(v) then
		if v.speedX ~= 0 or v.speedY ~= 0 then setChildPosition(v) end
		setChildDistance(v)
	end
end

function squiggler.onTickEndNPC(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]

	if hasChildren(v) then
		for i,child in ipairs(data.children) do
			if child.isValid then
				local distance = data.childDistance[i]
				child.x = data.childX[distance]
				child.y = data.childY[distance]
				child.speedX = data.childSpeedX[distance]
				child.speedY = data.childSpeedY[distance]
				child:mem(0x18, FIELD_FLOAT, child.speedX)
				child.isHidden = v.isHidden

				child.isProjectile = v.isProjectile
				child:mem(0x12E, FIELD_WORD, v:mem(0x12E, FIELD_WORD))
				child:mem(0x130, FIELD_WORD, v:mem(0x130, FIELD_WORD))
				child:mem(0x132, FIELD_WORD, v:mem(0x132, FIELD_WORD))

				child.despawnTimer = v.despawnTimer
				if not isOnScreen(v) and isOnScreen(child) then
					if v.despawnTimer >= 10 then
						v.despawnTimer = math.max(100, v.despawnTimer)
					end
				end

				if v.forcedState ~= NPCFORCEDSTATE_DROPPED_ITEM and v.forcedState ~= NPCFORCEDSTATE_YOSHI_TONGUE and v.forcedState ~= NPCFORCEDSTATE_YOSHI_MOUTH then
					child.forcedState = v.forcedState
					child.forcedCounter1 = v.forcedCounter1
					child.forcedCounter2 = v.forcedCounter2
				end

				if not cfg.nospecialanimation then child.animationFrame = v.animationFrame end
			else
				table.remove(data.children, i)
			end
		end
	end

	if isBeingGenerated(v) then resetChildPosition(v) end

	-- Squiggler exclusive code: make it wiggle

	data.timer = (data.timer or 0) + 1
	local s = 6 * math.pi/65
	v.data.speedMultiplier = 1 + (1.15 * s * math.cos(s * data.timer))

	-- Text.print(v.data.speedMultiplier,0,0)
end

function squiggler.onDrawNPC(v)
	local data = v.data._basegame
	if not hasChildren(v) then return end
	if NPC.config[v.id].nospecialrendering then return end

	for _,w in ipairs(table.reverse(data.children)) do drawNPC(w) end
end

function squiggler.onNPCTransform(v, oldID, harmtype)
	if v.id ~= 263 then return end

	if npcID == oldID then
		for _,w in ipairs(v.data._basegame.children) do
			w:toIce()
		end
	else
		local child, parent = isChild(v)
		if child and parent then table.remove(parent.data._basegame.children, table.ifind(parent.data._basegame.children, v)) end
	end
end

function squiggler.onPostNPCKill(v, harmtype)
	if v.id == NPC.config[npcID].littlebooid then
		local child, parent = isChild(v)
		if parent and v.despawnTimer > 0 then parent:kill(harmtype) end

		return
	end

	if v.id ~= npcID or not hasChildren(v) then return end

	--if the head is defeated, the segments are also defeated
	for _,w in ipairs(v.data._basegame.children) do
		if w.isValid then w:kill(harmtype) end
	end
end

return squiggler