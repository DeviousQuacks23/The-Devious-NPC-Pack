local koopa = {}
local npcManager = require("npcManager")
local npcID = NPC_ID

local shellID = (805)

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 54,
	width = 32,
	height = 32,
	gfxoffsety = 2,
	framestyle = 1,
	frames = 2,
	framespeed = 8,
	jumphurt = false,
	iswalker = true,
	spinjumpsafe = false,
	score = 2,
	cliffturn = true
})

local deathEffect = (790)

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

	if v:mem(0x138, FIELD_WORD) == 5 then
		v:transform(shellID)
	end
end

function koopa.onNPCKill(eventObj, v, reason)
	if v.id == npcID and (reason == 1 or reason == 2 or reason == 7) then
		eventObj.cancelled = true
		v:transform(shellID)
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