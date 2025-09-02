local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local zokkarangTroop = {}
local npcID = NPC_ID

local zokkarangTroopSettings = {
	id = npcID,

	gfxwidth = 104,
	gfxheight = 74,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 11,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	-- Custom Properties

        zokkarangID = npcID + 1,
}

npcManager.setNpcSettings(zokkarangTroopSettings)

local deathEffectID = (npcID)

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

local WANDER = 0
local THROW = 1
local UNARMED = 2

function zokkarangTroop.onInitAPI()
	npcManager.registerEvent(npcID, zokkarangTroop, "onTickEndNPC")
end

function zokkarangTroop.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[npcID]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = WANDER
                data.zokkarang = nil
                data.timer = 0
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-150,-50},{-150,50}),
                        [1] = Colliders.Tri(0,0,{0,0},{150,-50},{150,50}),
                }
                end
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = 8
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if data.state == WANDER then
                if v.collidesBlockBottom then
                        v.animationFrame = math.floor(data.timer / 6) % 4
                else
                        v.animationFrame = 1
                end
                v.speedX = 1.2 * v.direction
                if data.timer % 40 == 0 then npcutils.faceNearestPlayer(v) end
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                data.state = THROW
                                data.timer = 0
                                v.speedX = 0
                        end
                end
        elseif data.state == THROW then
                v.animationFrame = math.floor(data.timer / 12) % 3 + 4
                if data.timer == 24 then
	                SFX.play(25)
	                data.zokkarang = NPC.spawn(config.zokkarangID, v.x + (4 * v.direction), v.y - 30, v:mem(0x146, FIELD_WORD), false)
	                data.zokkarang.data._basegame.ownerBro = v
	                data.zokkarang.direction = v.direction
	                data.zokkarang.layerName = "Spawned NPCs"
	                data.zokkarang.speedX = 0
	                data.zokkarang.speedY = 0
	                data.zokkarang.friendly = v.friendly
                end
                if data.timer >= 36 then
                        npcutils.faceNearestPlayer(v)
                        data.state = UNARMED
                        data.timer = 0
                end
        elseif data.state == UNARMED then
                if v.collidesBlockBottom then
                        v.animationFrame = math.floor(data.timer / 6) % 4 + 7
                else
                        v.animationFrame = 8
                end
                v.speedX = 1.2 * v.direction
                if data.timer % 40 == 0 then npcutils.faceNearestPlayer(v) end       
                if data.zokkarang.isValid and data.zokkarang.despawnTimer <= 50 then
                        Effect.spawn(10, v.x, v.y)
                        SFX.play(73)
                        data.state = WANDER
                        data.timer = 0
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return zokkarangTroop