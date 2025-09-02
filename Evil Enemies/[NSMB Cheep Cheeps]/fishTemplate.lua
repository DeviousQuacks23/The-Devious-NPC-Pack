local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- This is a template for making custom cheep cheeps. Enjoy!

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,

	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi = false, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
}

npcManager.setNpcSettings(sampleNPCSettings)

local deathEffectID = (752)

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
		[HARM_TYPE_JUMP]            = {id=deathEffectID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
                data.hasBeenUnderwater = false
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if v.underwater then -- If the NPC is underwater then...
                data.hasBeenUnderwater = true
                v.noblockcollision = false
                v.speedX = 2.4 * v.direction
                v.speedY = 0.8 * -math.sin(data.timer * 0.04)
        else
                v.noblockcollision = true
                v.speedY = v.speedY + Defines.npc_grav -- Emulate gravity, since nogravity is enabled.
                if data.hasBeenUnderwater then
                        v.speedX = 1 * v.direction
                else
                        v.speedX = 0
                end
        end
end

function sampleNPC.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end
	
	if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		if culprit then
			if culprit.__type == "Player" and v.underwater then
				culprit:harm()
			end
		end
	end	
end

return sampleNPC