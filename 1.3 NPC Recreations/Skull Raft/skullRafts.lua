local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Sprites by Smuglutena

local skullRafts = {}

function skullRafts.register(npcID)
	npcManager.registerEvent(npcID, skullRafts, "onTickEndNPC")
	npcManager.registerEvent(npcID, skullRafts, "onDrawNPC")
end

Misc.groupsCollide["skullRafts"]["skullRafts"] = false

local function skullRide(v, data)
	local otherRafts = NPC.get(v.id, v.section)

	for _,n in ipairs(otherRafts) do
		if not n.data.active and not n.isHidden and not n.friendly then
			if Colliders.collide(data.hitbox, n) then
				n.data.active = true
				skullRide(n, n.data)
			end
		end
	end
end

function skullRafts.onTickEndNPC(v)
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
		data.hitbox = Colliders.Box()
		data.active = settings.shouldStartActive
		data.hasReset = false

		v.collisionGroup = "skullRafts"
	end

	data.hitbox.width = v.width + config.detectOffset
	data.hitbox.height = v.height
	data.hitbox.x = v.x + (v.width * 0.5) - (data.hitbox.width * 0.5)
	data.hitbox.y = v.y + (v.height * 0.5) - (data.hitbox.height * 0.5)
	-- data.hitbox:Debug(true)

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then 
		if v.isProjectile then
			npcutils.applyStationary(v)
		end
		return 
	end

	npcutils.applyLayerMovement(v)
	v:mem(0x120, FIELD_BOOL, false) 

	if data.active then
		v.speedX = config.raftSpeed * v.direction
	else
		v.speedX = 0
	end

	if v.underwater then
		v.speedY = v.speedY - Defines.npc_grav * config.floatMod

		if not data.hasReset then
			v.speedY = 0
			data.hasReset = true
		end
	else
		data.hasReset = false
	end

	if not data.active then
		for _,p in ipairs(Player.get()) do
			if p.standingNPC == v then
				skullRide(v, data)
			end
		end
	end
end

function skullRafts.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	if config.steppedOffset <= 0 then return end

	for _,p in ipairs(Player.get()) do
		if p.standingNPC == v then
			npcutils.drawNPC(v, {yOffset = config.steppedOffset})
			npcutils.hideNPC(v)
		end
	end
end

return skullRafts