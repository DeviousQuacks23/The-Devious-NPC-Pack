local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")

-- Based on Marioman2007's Orbits code, and MDA's Swinging Platform code
-- Firebar base sprite by SuperSledgeBro, Spike Bar sprites by Smuglutena

local firebar = {}

function firebar.register(npcID)
	npcManager.registerEvent(npcID, firebar, "onTickEndNPC")
	lineguide.registerNpcs(npcID)
end

local function getPos(v, n, data, settings)
	local angle = data.rotation + ((data.npcRot[n] - 1) / (settings.count or 1)) * 360
	local posX = v.x + v.width / 2 + ((settings.segment or 16) * data.npcRadius[n]) * math.sin(math.rad(angle))
	local posY = v.y + v.height / 2 - ((settings.segment or 16) * data.npcRadius[n]) * math.cos(math.rad(angle))

	return posX, posY
end

local function spawnNPC(v, id, data, settings)
	local n = NPC.spawn(
		id,
		v.x + v.width / 2,
		v.y + v.height / 2,
		v.section,
		true, true
	)
	
	n.direction = v.direction
	n.friendly = v.friendly
	n.dontMove = v.dontMove
	n.noblockcollision = true

	n.layerName = v.layerName

	table.insert(data.npcList, n)
	return n
end

function firebar.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.rotation = (settings.rotation or 0)
		return
	end

	local spawnCentre = (settings.centre and 1) or 0

	if not data.initialized then
		data.initialized = true

		data.npcList = {}
		data.npcRot = {}
		data.npcRadius = {}

		data.speed = settings.speed or 3
		data.rotation = (settings.rotation or 0)

		if not settings.id or settings.id == 0 then
			settings.id = 260
		end

		for i = 1, (settings.count or 1) do
			for j = 1, ((settings.amount or 1) + spawnCentre) do
				local n = spawnNPC(v, settings.id, data, settings)

				data.npcRot[n] = i
				data.npcRadius[n] = j - spawnCentre
			end
		end
	end

	data.rotation = (data.rotation + data.speed) % 360

	for k, n in ipairs(data.npcList) do
		if n.isValid then
			local posX, posY = getPos(v, n, data, settings)
			local codeClusterfuck = ((data.npcRadius[n] + spawnCentre) / (data.npcRadius[n] + spawnCentre))

            		n.x = math.floor(math.lerp(v.x + v.width * 0.5, posX, codeClusterfuck) - n.width / 2)
            		n.y = math.floor(math.lerp(v.y + v.height * 0.5, posY, codeClusterfuck) - n.height / 2)
		end

		-- Text.print(data.npcRadius[n], 0, 16 * (k - 1))
		-- Text.print(data.npcRot[n], 32, 16 * (k - 1))
	end

	npcutils.applyLayerMovement(v)
    	local lineguideData = v.data._basegame.lineguide

    	if lineguideData ~= nil then
        	if lineguideData.state == lineguide.states.FALLING then
            		if v.underwater then
                		v.speedY = math.min(1.6, v.speedY + Defines.npc_grav * 0.2)
            		else
                		v.speedY = math.min(8, v.speedY + Defines.npc_grav)
            		end
        	end
    	end
end

return firebar