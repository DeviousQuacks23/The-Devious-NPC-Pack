local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local greenSpinyEgg = {}

function greenSpinyEgg.register(npcID)
	npcManager.registerEvent(npcID, greenSpinyEgg, "onTickEndNPC")
end

Misc.groupsCollide["greenSpinyEggs"]["greenSpinyEggs"] = false

function greenSpinyEgg.onTickEndNPC(v)
	if Defines.levelFreeze then return end
        local config = NPC.config[v.id]

	if not v.data.setCollideGroup then
		v.data.setCollideGroup = true
		v.collisionGroup = "greenSpinyEggs"
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then return end

	npcutils.faceNearestPlayer(v)
	v.speedX = math.clamp(v.speedX + (config.accel * v.direction), -config.maxSpeed, config.maxSpeed)

	if v.collidesBlockBottom and v.data.oldSpeedY then
        	if v.data.oldSpeedY > config.bounceLimit then
        		v.speedY = -v.data.oldSpeedY * config.bounceLossMod
		end
	end

	v.data.oldSpeedY = v.speedY

       	if v.underwater then
		v.speedY = math.min(1.6, v.speedY - Defines.npc_grav * 0.8)
	end
end

return greenSpinyEgg