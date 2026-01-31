local npcManager = require("npcManager")
local berries = require("npcs/ai/berries")
local timer = require("timer")
local utils = require("npcs/npcutils")

local berry = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	jumphurt = -1,
	nogravity = 0,
	nohurt=-1,
	noblockcollision = 0,
	ignorethrownnpcs = false,
	noiceball=1,
	noyoshi=0,
	harmlessgrab=true,
	harmlessthrown=true,
	notcointransformable = true,
	limit=1,
	npcblock = true,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.
})

local function rewardFunc(p)
	if timer.isActive() then
		timer.add(10)
	end
end

function berry.onInitAPI()
	berries.register(npcID, rewardFunc)
	npcManager.registerEvent(npcID, berry, "onTickEndNPC")
end

function berry.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then return end
	
	utils.applyLayerMovement(v)
end
	
return berry
