local koopa = {}
local npcManager = require("npcManager")
local npcID = NPC_ID

local normalID = (801)
local shellID = (802)

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 56,
	width = 32,
	height = 32,
	gfxoffsety = 2,
	framestyle = 1,
	frames = 4,
	framespeed = 4,
	jumphurt = false,
	isflying = true,
	nogravity = true,
	spinjumpsafe = false,
	score = 2,
})

local deathEffect = (789)

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
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_JUMP]            = stompEffect,
		[HARM_TYPE_FROMBELOW]       = deathEffect,
		[HARM_TYPE_NPC]             = deathEffect,
		[HARM_TYPE_PROJECTILE_USED] = deathEffect,
		[HARM_TYPE_HELD]            = deathEffect,
		[HARM_TYPE_TAIL]            = deathEffect,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

function koopa.onInitAPI()
	npcManager.registerEvent(npcID, koopa, "onTickNPC")
	registerEvent(koopa, "onNPCKill")
end

local utils = require("npcs/npcutils")

function koopa.onTickNPC(v)
	local data = v.data

	if v:mem(0x138, FIELD_WORD) == 5 then
		v:transform(shellID)
	end

        if not data.changedBehaviour then
            	local config = NPC.config[v.id]
            	data.changedBehaviour = true
            	if v.id >= 751 and v.id <= 1000 and config.isflying then
                	v.spawnAi1 = v.spawnAi2
                	v.spawnAi2 = 0

                	v.ai1 = v.spawnAi1
                	v.ai2 = v.spawnAi2
                	v.ai3 = 0
                	v.ai4 = 0
                	v.ai5 = 0
            	end
        end
end

function koopa.onNPCKill(eventObj, v, reason)
	if v.id == npcID and (reason == 1 or reason == 2 or reason == 7) then
		eventObj.cancelled = true
		if reason == 1 then
			v:transform(normalID)
		else
			v:transform(shellID)
		end
		if reason == 7 then -- Play a different sound when swiping with a tail, for parity to SMBX Koopas
			SFX.play(9)
		else
			SFX.play(2)	
		end
		v.ai4 = 1
		v.dontMove = false
		if reason == 2 or reason == 7 then
			v.speedY = -5
		end
		v.speedX = 0
	end
end

return koopa