local npcManager = require("npcManager")

local bombshell = {}
local npcID = NPC_ID

local bombshellSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 28,
	width = 32,
	height = 28,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 2,
	framestyle = 1,
	framespeed = 2,

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = true,
	staticdirection = true,

	npcblock = false, 
	npcblocktop = false,
	playerblock = false, 
	playerblocktop = false, 

	nohurt=false, 
	nogravity = true,
	noblockcollision = false,
	notcointransformable = false, 
	nofireball = true,
	noiceball = false,
	noyoshi= false, 

	score = 2,

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false,
	harmlessthrown = false, 
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
}

npcManager.setNpcSettings(bombshellSettings)

local deathEffectID = (766)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]={id=deathEffectID, speedX=0, speedY=0},
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

function bombshell.onInitAPI()
	npcManager.registerEvent(npcID, bombshell, "onTickEndNPC")
end

function bombshell.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	if v.heldIndex ~= 0 
	or v.isProjectile
	or v.forcedState > 0
	then
		return
	end
	
	if math.abs(v.speedX) < 4 then -- Taken from The Bullet Bill Pack
	        v.ai5 = v.ai5 + 1
		if v.ai5 == 2 then
			SFX.play(22)
			v.speedX = 4 * v.direction
		end
	else
		v.speedX = 4 * v.direction
	end

        if v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockLeft or #Player.getIntersecting(v.x, v.y, v.x+v.width, v.y+v.height) > 0 or #Colliders.getColliding{a = v, b = NPC.HITTABLE, btype = Colliders.NPC, filter = Colliders.FILTER_COL_NPC_DEF} > 0 then
	        v:kill(HARM_TYPE_OFFSCREEN)
	        Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
                Defines.earthquake = 5
        end
end

return bombshell