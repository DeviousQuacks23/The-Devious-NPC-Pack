local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local coffer = {}
local npcID = NPC_ID

local cofferSettings = {
	id = npcID,
	gfxheight = 44,
	gfxwidth = 42,
	width = 40,
	height = 40,
	gfxoffsetx = -1,
	gfxoffsety = 2,
	frames = 2,
	framestyle = 1,
	framespeed = 8, 
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false, 
        nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	grabside=false,
	grabtop=false,
}

npcManager.setNpcSettings(cofferSettings)

local deathEffectID = (761)
local stompEffectID = (760)

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
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=stompEffectID,
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=deathEffectID,
	}
);

function coffer.onInitAPI()
	npcManager.registerEvent(npcID, coffer, "onTickEndNPC")
        registerEvent(coffer, "onPostNPCKill") 
end

function coffer.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	local isHeld = v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x130, FIELD_WORD) > 0
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or isHeld then
		data.jumpTimer = nil
		return
	end

	if data.jumpTimer == nil  then
		data.jumpTimer = 40
	end

	data.jumpTimer = data.jumpTimer - 1

	if v.collidesBlockBottom then
	        v.speedX = 0
	end

	if v.collidesBlockBottom then
	        v.animationFrame = 0
        else
	        v.animationFrame = 1
	end

        v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = v.animationFrame})

        local p = npcutils.getNearestPlayer(v)
        local sign = math.sign(p.x + p.width/2 - v.x - v.width/2)

	if data.jumpTimer <= 0  then
		data.jumpTimer = 40
		if v.collidesBlockBottom then
                        if sign == 0 then sign = 1 end
                        v.speedX = -sign * 3
			v.speedY = -4
		end
	end
end

function coffer.onPostNPCKill(v,harm,y) 
        if v.id ~= npcID then return end
	if y == HARM_TYPE_OFFSCREEN then return end
        for i = 1, v.data._settings.coins do
                local coin = NPC.spawn(10, v.x  + v.height * 0.25, v.y + v.height * 0.25, player.section, false)
                coin.speedX = RNG.random(-1.5,1.5)
                coin.speedY = RNG.random(-2,-8)
                coin.ai1 = 1
        end
end

return coffer