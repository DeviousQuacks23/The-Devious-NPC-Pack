local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local brickman = {}
local npcID = NPC_ID

local brickmanSettings = {
	id = npcID,

	gfxwidth = 128,
	gfxheight = 64,
	gfxoffsety = 2,
	width = 64,
	height = 48,
	frames = 3,
	framestyle = 0,
	framespeed = 12, 

	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 2,
	weight = 2,
	isstationary = true,

        delay = 120,
        brickInterval = 5,
        volleyMin = 3,
        volleyMax = 10,
        brickSpawn = 825,

	deathEffectID = 51,
	deathSFX = 4,
}

npcManager.setNpcSettings(brickmanSettings)
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
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_OFFSCREEN]=10,
	}
);

function brickman.onInitAPI()
	npcManager.registerEvent(npcID, brickman, "onTickEndNPC")
        npcManager.registerEvent(npcID, brickman, "onDrawNPC")
	registerEvent(brickman, "onPostNPCKill")
end

function brickman.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.animationTimer = 1
                data.brickTimer = 0
                data.shakeTimer = 0
                data.offset = 0
                data.brickVolleyCount = 0
                data.isDroppingBricks = false
	end

        if data.isDroppingBricks then
        	data.animationTimer = data.animationTimer + 1
        	data.shakeTimer = data.shakeTimer + 1
        else
        	data.animationTimer = data.animationTimer - 1
        	data.shakeTimer = 0
        	data.offset = 0
        end

	v.animationFrame = math.floor(data.animationTimer / cfg.framespeed) % cfg.frames
	data.animationTimer = math.clamp(data.animationTimer, 1, (cfg.frames * cfg.framespeed) - 2)

        if data.shakeTimer ~= 0 then
        	if data.shakeTimer%4 > 0 and data.shakeTimer%4 < 3 then
               		data.offset = data.offset - 2
               	else
               		data.offset = data.offset + 2
               	end
        end

	if v.heldIndex ~= 0
	or v.isProjectile  
	or v.forcedState > 0
	then
	     return
	end

        data.brickTimer = data.brickTimer + 1

        if data.brickTimer >= cfg.delay then
               	data.isDroppingBricks = true
               	if data.brickTimer == (cfg.delay + cfg.brickInterval) then
               		brick = NPC.spawn(cfg.brickSpawn, v.x + RNG.randomInt(0,v.width), v.y + v.height, v.section)
	       		brick.friendly = v.friendly
	       		brick.layerName = "Spawned NPCs"
               		data.brickVolleyCount = data.brickVolleyCount + 1
               		SFX.play(25)
               	end
               
               	if data.brickTimer == (cfg.delay + (cfg.brickInterval * 2)) then
                	if data.brickVolleyCount < RNG.randomInt(cfg.volleyMin, cfg.volleyMax) then
                        	data.brickTimer = cfg.delay - (cfg.brickInterval * 3)
                      	else
                      		data.brickTimer = 0
                          	data.brickVolleyCount = 0
                          	data.isDroppingBricks = false
                      	end
               	end
        end
end

function brickman.onDrawNPC(v)
    	if v:mem(0x12A, FIELD_WORD) <= 0 or v.isHidden then
        	return
    	end

    	if not v.data.offset or v.data.offset == 0 then return end

    	npcutils.drawNPC(v, {
        	xOffset = v.data.offset
    	})

    	npcutils.hideNPC(v)
end

-- Taken from MDA's Bullet Bills
local function spawnEffects(effectID,x,y,width,height)
        local effectConfig = Effect.config[effectID][1]
    
        local effectWidth = effectConfig.width
        local effectHeight = effectConfig.height
    
        local effectCountX = math.floor(width /effectWidth  + 0.5)
        local effectCountY = math.floor(height/effectHeight + 0.5)
    
	for idxX = 1,effectCountX do
            	for idxY = 1,effectCountY do
                	local effectX = x - effectCountX*effectWidth *0.5 + (idxX - 1)*effectWidth
                	local effectY = y - effectCountY*effectHeight*0.5 + (idxY - 1)*effectHeight
    
                	Effect.spawn(effectID,effectX,effectY)
            	end
        end
end

function brickman.onPostNPCKill(v,reason)
	if v.id ~= npcID then
		return
	end

	if reason ~= HARM_TYPE_OFFSCREEN and reason ~= HARM_TYPE_LAVA then
		local config = NPC.config[v.id]

		spawnEffects(131,v.x + v.width*0.5,v.y + v.height*0.5,v.width,v.height)
		if config.deathSFX then SFX.play(config.deathSFX) end
		if config.deathEffectID and config.deathEffectID > 0 then
			spawnEffects(config.deathEffectID,v.x + v.width*0.5,v.y + v.height*0.5,v.width,v.height)
		end
	end
end

return brickman