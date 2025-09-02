local npcManager = require("npcManager")

local projectileThing = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	
	width = 32,
	gfxwidth = 32,	
	height = 28,
	gfxheight = 28,
	
	frames = 3,
	framestyle = 1,
	framespeed = 6,	

	linkshieldable = true,
	noshieldfireeffect = true,
	score = 0,

	jumphurt = false,
	noblockcollision = true,	
	nogravity = true,
	
	nofireball = true,
	noiceball = true,
	noyoshi = true,
})

local deathEffectID = (828)
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
		[HARM_TYPE_SPINJUMP]        = deathEffectID,
		[HARM_TYPE_SWORD]           = deathEffectID,
	}
);

function projectileThing.onInitAPI()
	npcManager.registerEvent(npcID, projectileThing, "onTickEndNPC")
end	

function projectileThing.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end

        v.speedX = 2.5 * v.direction  

	for _, w in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
                if w.isHidden or w.layerObj.isHidden or w.layerName == "Destroyed Blocks" or w:mem(0x5A, FIELD_WORD) == -1 then return end
			if Block.MEGA_SMASH_MAP[w.id] then 
				if w.contentID > 0 then 
					w:hitWithoutPlayer(false)
				else
					w:remove(true)
				end
			elseif (Block.SOLID_MAP[w.id] or Block.PLAYERSOLID_MAP[w.id] or Block.MEGA_HIT_MAP[w.id]) then 
				w:hitWithoutPlayer(false)
			end
                v:kill(3)
        end
end

return projectileThing