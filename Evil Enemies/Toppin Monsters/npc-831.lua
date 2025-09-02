local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ai = require("toppingJumpscare")

local animatronic = {}
local npcID = NPC_ID

local footstep = Misc.resolveFile("toppingJumpscare/monster_footstep.ogg")

local animatronicSettings = {
	id = npcID,

	gfxwidth = 146,
	gfxheight = 161,

	width = 32,
	height = 112,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 16,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false, 
	staticdirection = false, 

	npcblock = false, 
	npcblocktop = false,
	playerblock = false, 
	playerblocktop = false, 

	grabside = false,
	grabtop = false,

	nohurt = true, 
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 
        nopowblock = true,

	score = 0,

	ignorethrownnpcs = false,
	harmlessgrab = true, 
	harmlessthrown = true, 
	nowalldeath = true, 

	jumphurt = true, 
	spinjumpsafe = false, 

        image = Graphics.loadImageResolved("toppingJumpscare/mushroom.png")
}

npcManager.setNpcSettings(animatronicSettings)

local deathEffectID = (831)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

local IDLE = 0
local AWAKEN = 1
local CHASE = 2

function animatronic.onInitAPI()
	npcManager.registerEvent(npcID, animatronic, "onTickEndNPC")
end

local function init(v,data)
	if not data.init then
		data.init = true
		data.collider = data.collider or Colliders.Box(v.x, v.y, v.width, v.height)
	end
end

function animatronic.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.init = false
		return
	end

        init(v,data)

	data.collider.x = v.x + 4 * v.direction
	data.collider.y = v.y

	local block = Colliders.getColliding{
	a = data.collider,
	btype = Colliders.BLOCK,
	filter = function(other)
		if other.isHidden or other.layerObj.isHidden or other.layerName == "Destroyed Blocks" or other:mem(0x5A, FIELD_WORD) == -1 then
			return false
		end
		return true
	end
	}
	
	-- Put main AI below here

        if data.state == IDLE then
                v.animationFrame = 0
                v.speedX = 0
	elseif data.state == AWAKEN then
                v.animationFrame = math.floor(data.timer / 6) % 7 + 1
                if data.timer == 41 then
                        npcutils.faceNearestPlayer(v)
                        data.state = CHASE
                        data.timer = 0
                end
	elseif data.state == CHASE then
                if (data.timer % 30) == 0 then
                        npcutils.faceNearestPlayer(v)
                end
                if v.collidesBlockLeft or v.collidesBlockRight then
                        v.speedX = 0
                else
		        v.speedX = 5 * v.direction
                end
                if #block ~= 0 then
                        v.animationFrame = math.floor(data.timer / 8) % 3 + 5
                else
                        v.animationFrame = math.floor(data.timer / 4) % 8 + 8
                end
                if #block == 0 and v.collidesBlockBottom and data.timer % 16 == 0 then 
	                local step = SFX.create
	                {
		        x = v.x + v.width*0.5,
		        y = v.y + v.height,
		        sound = footstep,
                        play = true,
                        loops = 1,
		        parent = v,
		        type = typ,
		        volume = 1,
		        falloffRadius = 320,
		        falloffType = SFX.FALLOFF_LINEAR,
		        sourceRadius = 32,
		        sourceWidth = v.width,
		        sourceHeight = v.height,
		        sourceVector = vector.v2(64, 0)
	                }
                end
        end

        -- Animation handling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
        v.animationTimer = 0
end

ai.register(npcID)

return animatronic