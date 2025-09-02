local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ai = require("toppingJumpscare")

local animatronic = {}
local npcID = NPC_ID

local heartbeat = Misc.resolveFile("toppingJumpscare/heartbeat.ogg")

local animatronicSettings = {
	id = npcID,

	gfxwidth = 170,
	gfxheight = 165,

	width = 48,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 19,
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

        image = Graphics.loadImageResolved("toppingJumpscare/butcher.png")
}

npcManager.setNpcSettings(animatronicSettings)

local deathEffectID = (833)

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
	        data.sound = SFX.create
	        {
		x = v.x + v.width*0.5,
		y = v.y + v.height,
		sound = heartbeat,
                play = false,
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
	elseif data.state == AWAKEN then
                v.animationFrame = math.floor(data.timer / 6) % 6 + 1
                if data.timer == 35 then
                        npcutils.faceNearestPlayer(v)
                        data.state = CHASE
                        data.timer = 0
                end
	elseif data.state == CHASE then
                v.animationFrame = math.floor(data.timer / 4) % 12 + 7	
	        local player = npcutils.getNearestPlayer(v)	
	        local dist = (player.x + 0.5 * player.width) - (v.x + 0.5 * v.width)	
	        if math.abs(dist) > 32 then
		        v.speedX = math.clamp(v.speedX + 0.05 * math.sign(dist), -4, 4)
	        end
                if not v.isHidden and v.section == player.section then
		        data.sound:play()
                else
		        data.sound:stop()
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