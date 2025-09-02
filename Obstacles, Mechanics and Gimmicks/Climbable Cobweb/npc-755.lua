local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local climbableCobweb = {}
local npcID = NPC_ID

local climbableCobwebSettings = {
	id = npcID,

	gfxwidth = 96,
	gfxheight = 96,
	width = 96,
	height = 96,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 0,
	luahandlesspeed = false, 
	nowaterphysics = true,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, 

	nofireball = false,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	isvine = true,
	isstationary = true
}

npcManager.setNpcSettings(climbableCobwebSettings)

function climbableCobweb.onInitAPI()
	npcManager.registerEvent(npcID, climbableCobweb, "onTickEndNPC")
	npcManager.registerEvent(npcID, climbableCobweb, "onDrawNPC")
end

local NORMAL = 0
local CLIMBED = 1
local INVIS = 2

function climbableCobweb.onTickEndNPC(v)	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.scale = 1
		data.opacity = 1
		data.state = NORMAL
		data.timer = 0
	end

        if data.scale > 1 then data.scale = data.scale - 0.05 end
	
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end
	
	-- Main AI

	if data.state == NORMAL then
		for _,p in ipairs(Player.get()) do
			if p:isClimbing() and p.climbingNPC ~= nil and p.climbingNPC == v then
				data.state = CLIMBED
				data.scale = 1.5
				data.timer = 0
				SFX.play(2)
			end
		end
	elseif data.state == CLIMBED then
		data.timer = data.timer + 1
		if data.timer >= 40 then
			data.opacity = math.max(data.opacity - 0.1, 0) 
			if data.opacity <= 0 then 
				for _,p in ipairs(Player.get()) do
					if p:isClimbing() and p.climbingNPC ~= nil and p.climbingNPC == v then
    						p:mem(0x2C, FIELD_DFLOAT, 0)
    						p:mem(0x40, FIELD_WORD, 0)
					end
				end
				data.state = INVIS
				data.timer = 0
			end
		end
	elseif data.state == INVIS then
		data.timer = data.timer + 1
		if data.timer >= 60 then
			data.opacity = math.min(data.opacity + 0.1, 1) 
			if data.opacity >= 1 then 
				data.state = NORMAL
				data.timer = 0
			end
		end
		for _,p in ipairs(Player.get()) do
			if p:isClimbing() and p.climbingNPC ~= nil and p.climbingNPC == v then
    				p:mem(0x2C, FIELD_DFLOAT, 0)
    				p:mem(0x40, FIELD_WORD, 0)
			end
		end
	end
end

function climbableCobweb.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
	
	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth * data.scale,
		height = config.gfxheight * data.scale,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
                color = Color.white .. data.opacity,
		centered = true,
		priority = -76,
	}
	npcutils.hideNPC(v)
end

return climbableCobweb