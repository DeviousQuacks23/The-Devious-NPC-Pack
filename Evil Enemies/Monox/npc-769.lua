local npcManager = require("npcManager")

local monox = {}
local npcID = NPC_ID

local monoxSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = true,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = true,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = true, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	
	ishot = true,
	durability = -1,
	staticdirection = true, 

	lightradius = 64,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,

	-- Custom Properties

        delay = 48,
        moveSpeed = 3,
        deceleration = 0.1,
}

npcManager.setNpcSettings(monoxSettings)

local deathEffectID = (762)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

function monox.onInitAPI()
	npcManager.registerEvent(npcID, monox, "onTickEndNPC")
end

function monox.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if data.timer >= (config.delay * 0.5) then
                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - config.deceleration)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + config.deceleration)
                else
                        v.speedX = 0
                end
                if v.speedY > 0 then
                        v.speedY = math.max(0, v.speedY - config.deceleration)
                elseif v.speedY < 0 then
                        v.speedY = math.min(0, v.speedY + config.deceleration)
                else
                        v.speedY = 0
                end
        end

	data.pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5), (Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()

        if data.timer >= config.delay then
                local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                if p.x + 0.5 * p.width > v.x + 0.5 * v.width then
                        v.direction = 1
                else
                        v.direction = -1
                end
	        v.speedX = data.pos.x * config.moveSpeed
	        v.speedY = data.pos.y * config.moveSpeed
                SFX.play(16)
                data.timer = 0
	        for j = 1, RNG.randomInt(4, 16) do
                        local e = Effect.spawn(265, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
		        e.speedX = RNG.random(-4, 4)
		        e.speedY = RNG.random(-4, 4)
	        end  
        end
end

return monox