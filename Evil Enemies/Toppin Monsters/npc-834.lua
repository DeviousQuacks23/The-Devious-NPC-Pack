local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ai = require("toppingJumpscare")

local animatronic = {}
local npcID = NPC_ID

local goop = Misc.resolveFile("toppingJumpscare/cheese_monster.ogg")

local animatronicSettings = {
	id = npcID,

	gfxwidth = 202,
	gfxheight = 160,

	width = 64,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 48,

	frames = 41,
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
	nogravity = true,
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

        image = Graphics.loadImageResolved("toppingJumpscare/cheese.png")
}

npcManager.setNpcSettings(animatronicSettings)

local deathEffectID = (834)

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

local NORMAL = 0
local JUMPUP = 1
local UPSIDEDOWN = 2
local JUMPDOWN = 3

function animatronic.onInitAPI()
	npcManager.registerEvent(npcID, animatronic, "onTickEndNPC")
end

local function init(v,data)
	if not data.init then
		data.init = true
                data.subState = NORMAL
	        data.sound = SFX.create
	        {
		x = v.x + v.width*0.5,
		y = v.y + v.height,
		sound = goop,
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
                v.speedY = v.speedY + Defines.npc_grav
	elseif data.state == AWAKEN then
                v.animationFrame = math.floor(data.timer / 6) % 7 + 1
                v.speedY = v.speedY + Defines.npc_grav
                if data.timer == 41 then
                        npcutils.faceNearestPlayer(v)
                        data.state = CHASE
                        data.subState = NORMAL
                        data.timer = 0
                end
	elseif data.state == CHASE then
                if data.subState == NORMAL then
		        v.speedX = 4.5 * v.direction
                        v.speedY = v.speedY + Defines.npc_grav
                        v.animationFrame = math.floor(data.timer / 4) % 10 + 9
                        if (data.timer % 10) == 0 then
                                npcutils.faceNearestPlayer(v)
                        end
                        if v.collidesBlockLeft or v.collidesBlockRight then
                                npcutils.faceNearestPlayer(v)
		                v.speedX = 0
                                data.subState = JUMPUP
                                data.timer = 0
                        end
                        for k, p in ipairs(Player.getIntersecting(v.x, v.y - 512, v.x + v.width, v.y + v.height)) do
                                data.subState = JUMPUP
                                data.timer = 0
                        end
                elseif data.subState == JUMPUP then
	                v.speedY = v.speedY - Defines.npc_grav -- Inverted gravity
                        if data.timer >= 48 then
                                v.animationFrame = 24
                        else
                                v.animationFrame = math.floor(data.timer / 8) % 6 + 19
                        end
                        if v.collidesBlockUp then
                                npcutils.faceNearestPlayer(v)
                                data.subState = UPSIDEDOWN
                                data.timer = 0
                        end
                        for _, w in Block.iterateIntersecting(v.x + 8, v.y - 2, v.x + (v.width - 8), v.y + (v.height / 2)) do
                                if Block.SLOPE_LR_CEIL_MAP[w.id] or Block.SLOPE_RL_CEIL_MAP[w.id] then
                                        npcutils.faceNearestPlayer(v)
                                        data.subState = UPSIDEDOWN
                                        data.timer = 0
                                end
                        end
                elseif data.subState == UPSIDEDOWN then
                        if v.collidesBlockUp then
		                v.x = v.x + (4.5 * v.direction) -- Janky alternative to speedX because that wouldn't work
	                        v.speedY = v.speedY - Defines.npc_grav
                                v.animationFrame = math.floor(data.timer / 4) % 10 + 25
                                if (data.timer % 10) == 0 then
                                        npcutils.faceNearestPlayer(v)
                                end
                                if v.collidesBlockLeft or v.collidesBlockRight then
                                        npcutils.faceNearestPlayer(v)
		                        v.speedX = 0
                                        data.subState = JUMPDOWN
                                        data.timer = 0
                                end
                        else
                                data.subState = JUMPDOWN
                                data.timer = 0
                        end
                        for k, p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height + 512)) do
                                data.subState = JUMPDOWN
                                data.timer = 0
                        end
                elseif data.subState == JUMPDOWN then
                        v.speedY = v.speedY + Defines.npc_grav
                        if data.timer >= 48 then
                                v.animationFrame = 40
                        else
                                v.animationFrame = math.floor(data.timer / 8) % 6 + 35
                        end
                        if v.collidesBlockBottom then
                                npcutils.faceNearestPlayer(v)
                                data.subState = NORMAL
                                data.timer = 0
                        end
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