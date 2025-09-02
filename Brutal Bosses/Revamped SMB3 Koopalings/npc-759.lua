local ball = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 4,
	framespeed = 6,
	framestyle = 1,
	nogravity = false,
	nofireball=true,
	score = 0,
	stunDelay = 30
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 10,
	[HARM_TYPE_FROMBELOW] = 10,
	[HARM_TYPE_NPC] = 10,
	[HARM_TYPE_HELD] = 10,
	[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = 10,
	[HARM_TYPE_LAVA]={id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function ball.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then
		v.ai1 = 0
		return
	end
    v.ai2 = v.ai2 + 1
    if v.ai2 >= 480 then
    Effect.spawn(131, v.x, v.y)
    v:kill(9)
    end
    if v.ai1 > 0 then
        v.ai1 = v.ai1 - 1
        v.speedY = -Defines.npc_grav
        if v.ai1%4 > 0 and v.ai1%4 < 3 then
        v.x = v.x - 2
        else
        v.x = v.x + 2
        end
    else
    if not v.underwater then
    v.speedY = v.speedY - 0.1
    end
        if v.collidesBlockBottom then
            v.speedX = 2 * v.direction
            v.speedY = -7
        end
    end
end

function ball.onNPCHarm(eventObj, v, reason)
	if v.id == npcID and (reason == 1 or reason == 2 or reason == 7 or reason == 8) then
		eventObj.cancelled = true
		SFX.play(2)
        v.ai1 = NPC.config[v.id].stunDelay
		v.speedX = 0
	end
end

function ball.onInitAPI()
    npcManager.registerEvent(npcID, ball, "onTickNPC")
	registerEvent(ball, "onNPCHarm", "onNPCHarm")
end

return ball