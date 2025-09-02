local spiny = {}
local npcManager = require("npcManager")

local npcID = NPC_ID
npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	framestyle = 1,
	frames = 2,
	framespeed = 8,
	jumphurt = true,
	iswalker = true,
	spinjumpsafe = true,
	cliffturn = true
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA},
	{[HARM_TYPE_FROMBELOW] = 792,
	[HARM_TYPE_NPC] = 792,
	[HARM_TYPE_HELD] = 792,
	[HARM_TYPE_TAIL] = 792,
	[HARM_TYPE_PROJECTILE_USED] = 792,
	[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
})

function spiny.onInitAPI()
	npcManager.registerEvent(npcID, spiny, "onTickNPC")
end

local utils = require("npcs/npcutils")

function spiny.onTickNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.turnTimer = 0
		return
	end
	
	if data.turnTimer == nil then
		data.turnTimer = 0
	end
	data.turnTimer = data.turnTimer + 1
	if data.turnTimer >= 65 then
		utils.faceNearestPlayer(v)
		data.turnTimer = 0
	end
end

return spiny