local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local friendlyNPC = require("npcs/ai/friendlies")

local toad = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	
	frames = 3, 
	framestyle = 1, 
	gfxoffsety = 2,
	jumphurt = 1,
	ignorethrownnpcs = 1,
	nofireball=1,
	noiceball=1,
	noyoshi=1,
	grabside=0,
	grabtop=0,
	isshoe=0,
	isyoshi=0,
	isstationary = true,
	nowalldeath = true,
	nohurt=1,
	score = 0,
	spinjumpsafe=0,
	
	width = 38,
	gfxwidth = 38,
	height = 54,
	gfxheight = 58,
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

friendlyNPC.register(npcID)

function toad.onInitAPI()
	npcManager.registerEvent(npcID, toad, "onTickEndNPC")
    	npcManager.registerEvent(npcID, toad, "onDrawNPC")  
end

function toad.onTickEndNPC(v)
	if not v.friendly then for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do NPC.spawn(9,p.x,p.y):collect() end end
	if Defines.levelFreeze then return end

	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
                data.animTimer = 0
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        if v.collidesBlockBottom then
		v.animationFrame = 0
		data.animTimer = 0
        	data.timer = data.timer + 1
		if data.timer > 9 then
			v.speedY = -4.6
		end
        else
		data.timer = 0
        	data.animTimer = data.animTimer + 1
        	if data.animTimer > 10 then
            		v.animationFrame = 2
		else
            		v.animationFrame = 1
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
end

local lowPriorityStates = table.map{1,3,4}

function toad.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

        local config = NPC.config[v.id]
	local img = Graphics.sprites.npc[v.id].img
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45
        local colour = v.data._settings.color or 0

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,
		height = config.gfxheight,
		sourceX = colour * config.gfxwidth,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

return toad