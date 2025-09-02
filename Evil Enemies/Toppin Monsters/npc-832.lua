local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ai = require("toppingJumpscare")

local animatronic = {}
local npcID = NPC_ID

local animatronicSettings = {
	id = npcID,

	gfxwidth = 174,
	gfxheight = 76,

	width = 48,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 10,

	frames = 10,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false, 
	staticdirection = true, 

	npcblock = false, 
	npcblocktop = false,
	playerblock = false, 
	playerblocktop = false, 

	grabside = false,
	grabtop = false,

	nohurt = true, 
	nogravity = true,
	noblockcollision = true,
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

        image = Graphics.loadImageResolved("toppingJumpscare/tomato.png")
}

npcManager.setNpcSettings(animatronicSettings)

local deathEffectID = (832)

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
	
	-- Put main AI below here

        if data.state == IDLE then
                v.animationFrame = 0
                v.speedX = 0
                v.speedY = 0
	elseif data.state == AWAKEN then
                v.animationFrame = math.floor(data.timer / 6) % 6 + 1
                if data.timer == 35 then
                        npcutils.faceNearestPlayer(v)
                        data.state = CHASE
                        data.timer = 0
                end
	elseif data.state == CHASE then
                v.animationFrame = math.floor(data.timer / 4) % 3 + 7
                npcutils.faceNearestPlayer(v)
	        data.pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5), (Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()
	        v.speedX = data.pos.x*4
	        v.speedY = data.pos.y*4
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