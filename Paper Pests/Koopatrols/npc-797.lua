local shell = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local npcID = NPC_ID

local THROWN_NPC_COOLDOWN    = 0x00B2C85C
local SHELL_HORIZONTAL_SPEED = 0x00B2C860
local SHELL_VERTICAL_SPEED   = 0x00B2C864

-- Shell code taken from MegaDood's Snortise

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 38,
	width = 32,
	height = 32,
	gfxoffsety = 2,
	speed = 1,
	frames = 4,
	framespeed = 4,
	framestyle = 0,
	score = 2,
	jumphurt = true,
	spinjumpsafe = true,
	nohurt = false,
	noyoshi=false,
	grabside = false,
	harmlessthrown=false,
	noiceball=false,
	nofireball=false,
	isshell = true,
	restingframes = 4,
	nospecialanimation = false
})

local effectID = (783)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=effectID,
		[HARM_TYPE_FROMBELOW]=effectID,
		[HARM_TYPE_NPC]=effectID,
		[HARM_TYPE_PROJECTILE_USED]=effectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=effectID,
		[HARM_TYPE_TAIL]=effectID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

function shell.onTickNPC(npc)
	if Defines.levelFreeze then return end

	--If despawned
	if npc.despawnTimer <= 0 then
		if npc.ai4 ~= 0 then
			npc:transform(npcID - 1)
		end
		return
	end

	if npc:mem(0x12A, FIELD_WORD) <= 0 then
		npc.ai3 = 0
		return
	end

	if npc.direction == 0 then
		npc.direction = 1
	end
	if not npc.friendly then
		npc.ai3 = npc.ai3 + 1
	end
end

function shell.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	npc.ai5 = 1
	if not config.nospecialanimation then

		local frames = config.restingframes
		local offset = 0
		local gap = config.frames - config.restingframes
		npcutils.restoreAnimation(npc)
		npc.animationFrame = npcutils.getFrameByFramestyle(npc, {
			frames = frames,
			offset = offset,
			gap = gap
		})
		if npc.speedX == 0 then
			npc.animationFrame = 0
		end
	end
end

function shell.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and npc.ai5 == 1 then
		if reason == 1 or reason == 2 or reason == 7 then
			eventObj.cancelled = true
			npc.speedX = 0
			npc.speedY = -5
		end
	end
end

-- big thanks to Mr.DoubleA
function shell.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

	local culpritIsPlayer = (culprit and culprit.__type == "Player")
	local culpritIsNPC    = (culprit and culprit.__type == "NPC"   )

	if reason == HARM_TYPE_JUMP then
		if v:mem(0x138,FIELD_WORD) == 2 then
			v:mem(0x138,FIELD_WORD,0)
		end

		if culpritIsPlayer and culprit:mem(0xBC,FIELD_WORD) <= 0 and culprit.mount ~= 2 then
			if v.speedX == 0 and (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx)  then
				SFX.play(9)
				v.speedX = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT)*culprit.direction
				v.speedY = 0

				v:mem(0x12E,FIELD_WORD,mem(THROWN_NPC_COOLDOWN,FIELD_WORD))
				v:mem(0x130,FIELD_WORD,culprit.idx)
				v:mem(0x132,FIELD_BOOL,true)
			elseif (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx) or (v:mem(0x22,FIELD_WORD) == 0 and (culpritIsPlayer and culprit:mem(0x40,FIELD_WORD) == 0)) then
				SFX.play(2)
				v.speedX = 0
				v.speedY = 0

				if v:mem(0x1C,FIELD_WORD) > 0 then
					v:mem(0x18,FIELD_FLOAT,0)
					v:mem(0x132,FIELD_BOOL,true)
				end
			end
		end
	elseif reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
		SFX.play(9)

		v:mem(0x132,FIELD_BOOL,true)
		v.speedY = -5
		v.speedX = 0
	elseif reason == HARM_TYPE_LAVA then
		v:mem(0x122,FIELD_WORD,reason)
	elseif reason ~= HARM_TYPE_PROJECTILE_USED and v:mem(0x138, FIELD_WORD) ~= 4 then
		if reason == HARM_TYPE_NPC then
			if not (v.id == 24 and culpritIsNPC and (culprit.id == 13 or culprit.id == 108)) then
				v:mem(0x122,FIELD_WORD,reason)
			end
		else
			v:mem(0x122,FIELD_WORD,reason)
		end
	elseif reason == HARM_TYPE_PROJECTILE_USED then
		if culpritIsNPC and culprit:mem(0x132,FIELD_BOOL) and (culprit.id < 117 or culprit.id > 120) then
			v:mem(0x122,FIELD_WORD,reason)
		end
	end

	eventObj.cancelled = true
end

function shell.onInitAPI()
	npcManager.registerEvent(npcID, shell, "onTickNPC")
	npcManager.registerEvent(npcID, shell, "onDrawNPC")
	registerEvent(shell, "onNPCHarm", "onNPCHarm")
	registerEvent(shell, "onNPCKill", "onNPCKill")
end

return shell
