local npcManager = require("npcManager")

local bananaPeel = {}
local npcID = NPC_ID

local bananaPeelSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 30,
	width = 16,
	height = 16,
	gfxoffsetx = 0,
	gfxoffsety = 10,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = false,
	noiceball = true,
	noyoshi= false, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = false,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	
	isstationary = true,
}

npcManager.setNpcSettings(bananaPeelSettings)

local deathEffectID = (838)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
	},
	{
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

function bananaPeel.onInitAPI()
	npcManager.registerEvent(npcID, bananaPeel, "onTickEndNPC")
end

function bananaPeel.onTickEndNPC(v)
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end
	
	-- Main AI

	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p,v) and p.deathTimer == 0 then
			if p:isGroundTouching() or p.speedY >= 0 then
    				if p.x + 0.5 * p.width > v.x + 0.5 * v.width then
        				p.speedX = -8
    				else
       					p.speedX = 8
    				end
				SFX.play("cartoon-fling.ogg")
				p:mem(0x3C, FIELD_BOOL, true)
				p.speedY = -4
			end
			v:kill(3)
		end
	end

	if Defines.levelFreeze then return end

	for _,n in ipairs(NPC.getIntersecting(v.x - 32, v.y - 32, v.x + v.width + 32, v.y + v.height + 32)) do
		if Colliders.collide(n,v) and n.idx ~= v.idx and not n.isHidden and not n.friendly then
			if n.collidesBlockBottom or n.speedY >= 0 then
    				if n.x + 0.5 * n.width > v.x + 0.5 * v.width then
        				n.speedX = -4
    				else
       					n.speedX = 4
    				end
				SFX.play("cartoon-fling.ogg")
				n.isProjectile = true
				n.speedY = -3
			end
			v:kill(3)
		end
	end
end

return bananaPeel