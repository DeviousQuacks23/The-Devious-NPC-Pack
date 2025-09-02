local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

local list = {
	390,
	511,
	526,
}

function npc.onTickEndNPC(v)
	local random = math.random(1, #list)
	v:transform(list[random])
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc