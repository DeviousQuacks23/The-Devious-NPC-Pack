local npcManager = require("npcManager")

local boneHead = {}
local npcID = NPC_ID

-- Code taken from MegaDood's Piranha Pod with some help from Deltom

local boneHeadSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	luahandlessspeed = true,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	ignorethrownnpcs = true,
	staticdirection = true, 
}

npcManager.setNpcSettings(boneHeadSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN,
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0},
	}
);

function boneHead.onInitAPI()
	npcManager.registerEvent(npcID, boneHead, "onTickEndNPC")
end

function boneHead.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.gravity = false
                data.timer = 0
	end

        if data.timer >= 60 then data.gravity = true end

        if not data.gravity then
                v.speedY = -Defines.npc_grav
                data.timer = data.timer + 1
        end

        v.speedX = 3 * v.direction

        if v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockLeft then
                v:transform(189)
		Effect.spawn(796, v.x - v.width * 1.25, v.y - v.height * 0.5)
		SFX.play("Shoop.wav")
	end
end

return boneHead