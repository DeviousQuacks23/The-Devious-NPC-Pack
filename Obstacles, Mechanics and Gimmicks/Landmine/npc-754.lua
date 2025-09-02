local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local landmine = {}
local npcID = NPC_ID

local landmineExplosion = Explosion.register(48, 763, 37, false, false)

local landmineSettings = {
	id = npcID,

	gfxwidth = 28,
	gfxheight = 16,
	width = 24,
	height = 8,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = false,
	noiceball = true,
	noyoshi = true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	isstationary = true,
}

npcManager.setNpcSettings(landmineSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

local NORMAL = 0
local SQUASH = 1
local JUMP = 2

function landmine.onInitAPI()
	npcManager.registerEvent(npcID, landmine, "onTickEndNPC")
	npcManager.registerEvent(npcID, landmine, "onDrawNPC")
end

function landmine.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.scaleX = 1
		data.scaleY = 1
		data.state = NORMAL
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end
	
	-- Main AI

	if data.state == NORMAL then
        	for k,p in ipairs(Player.get()) do
                        if Colliders.collide(v, p) then
                                SFX.play(Misc.resolveSoundFile("landmine"))
                                data.state = SQUASH
                        end
                end
	elseif data.state == SQUASH then
        	if data.scaleX < 2 then data.scaleX = data.scaleX + 0.1 end
        	if data.scaleY > 0.25 then data.scaleY = data.scaleY - 0.1 end
		if data.scaleX >= 2 and data.scaleY <= 0.25 then
		        data.state = JUMP
			if v.collidesBlockBottom then v.speedY = -6 end
		end
	elseif data.state == JUMP then
        	if data.scaleX > 0.75 then data.scaleX = data.scaleX - 0.1 end
        	if data.scaleY < 2 then data.scaleY = data.scaleY + 0.1 end
		if v.speedY >= 0 then
       	        	v:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN) -- Kill the NPC in a slightly unorthodox way, to avoid points being given by the explosion
                	Explosion.spawn(v.x+(v.width/2), v.y+(v.height/2), landmineExplosion)
			Defines.earthquake = 3
			local e1 = Effect.spawn(131, v.x + (v.width / 2), v.y + (v.height / 2))
			e1.x = e1.x - (e1.width / 2) 
			e1.y = e1.y - (e1.height / 2) 
		        e1.speedX = -2
		        e1.speedY = -3
			local e2 = Effect.spawn(131, v.x + (v.width / 2), v.y + (v.height / 2))
			e2.x = e2.x - (e2.width / 2) 
			e2.y = e2.y - (e2.height / 2) 
		        e2.speedX = 2
		        e2.speedY = 3
			local e3 = Effect.spawn(131, v.x + (v.width / 2), v.y + (v.height / 2))
			e3.x = e3.x - (e3.width / 2) 
			e3.y = e3.y - (e3.height / 2) 
		        e3.speedX = -2
		        e3.speedY = 3
			local e4 = Effect.spawn(131, v.x + (v.width / 2), v.y + (v.height / 2))
			e4.x = e4.x - (e4.width / 2) 
			e4.y = e4.y - (e4.height / 2) 
		        e4.speedX = 2
		        e4.speedY = -3
		end
	end
end

function landmine.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
        local priority = -75

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth * data.scaleX,
		height = config.gfxheight * data.scaleY,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

return landmine