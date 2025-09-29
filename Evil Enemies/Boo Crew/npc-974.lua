local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local npcutils = require("npcs/npcutils")

local booCrewSpawner = {}

local npcID = NPC_ID

local fields = {
	"sound", "npc", "delay", "enabled"
}

local cams = {
	{enabled = false, timer = 0, spawncounter = 0},
	{enabled = false, timer = 0, spawncounter = 0}
}

local function onSpawnerTriggered(cam, settings, npcRef)
    	for k,v in ipairs(fields) do
        	cams[cam.idx][v] = settings[v]
    	end

    	cams[cam.idx].timer = 0
    	cams[cam.idx].spawncounter = 0
    	cams[cam.idx].direction = npcRef.direction
	cams[cam.idx].y = npcRef.y
end

spawner.register(npcID, onSpawnerTriggered)

function booCrewSpawner.onInitAPI()
    	registerEvent(booCrewSpawner, "onTickEnd")
end

function booCrewSpawner.onTickEnd()
    	if Defines.levelFreeze then return end

	for k,v in ipairs(Camera.get()) do
        	local c = cams[v.idx]
        	if c.enabled then
            		c.timer = c.timer + 1

            		if c.timer % c.delay == 0 then
                		local n = NPC.spawn(c.npc, RNG.random(v.x - 32, v.x + v.width + 32), c.y + RNG.random(64, 128))
                		n.layerName = "Spawned NPCs"
                		n.direction = RNG.irandomEntry({-1, 1})
                		if c.sound > 0 then
                    			SFX.play(c.sound)
                		end

                		c.spawncounter = c.spawncounter + 1
            		end
        	end
    	end
end

return booCrewSpawner;