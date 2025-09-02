local npcManager = require("npcManager")

local leggshell = {}
local npcID = NPC_ID

local leggshellSettings = {
	id = npcID,
	gfxheight = 36,
	gfxwidth = 32,
	width = 32,
	height = 36,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 0,
	framespeed = 4,

	speed = 1,
        score = 0,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn = true,

	iswalker = true,
	isbot = true,
}

npcManager.setNpcSettings(leggshellSettings)

local deathEffectID = (759)

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
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

function leggshell.onInitAPI()
        registerEvent(leggshell, "onNPCHarm")
end

function leggshell.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        if reason == HARM_TYPE_OFFSCREEN then return end

        -- I guess this is one way to prevent the Zelda effect from spawning

        eventObj.cancelled = true
        if reason ~= HARM_TYPE_LAVA then Misc.givePoints(2,vector(v.x + (v.width/2),v.y),true) end
        local e = Effect.spawn(deathEffectID, v.x + v.width * 0.5,v.y + v.height * 0.5)
        e.x = e.x - e.width * 0.5
        e.y = e.y - e.height * 0.5
        SFX.play(9)
        v:kill(9)

        if reason ~= HARM_TYPE_JUMP and reason ~= HARM_TYPE_SPINJUMP and reason ~= HARM_TYPE_TAIL and culprit ~= nil then Effect.spawn(75, culprit.x, culprit.y) end

        -- Spawn Contained NPC

        if reason == HARM_TYPE_LAVA then return end

        if v.data._settings.storedNPC ~= nil and v.data._settings.storedNPC > 0 then
	        n = NPC.spawn(v.data._settings.storedNPC, v.x + v.width/2, v.y + v.height/2, v.section,false,true)
	        n.direction = v.direction
		n.friendly = v.friendly
		n.layerName = "Spawned NPCs"
        end
end

return leggshell