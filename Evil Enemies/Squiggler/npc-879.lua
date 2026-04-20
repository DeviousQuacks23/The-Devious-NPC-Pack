local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local hidingSquiggler = {}
local npcID = NPC_ID

local hidingSquigglerSettings = {
	id = npcID,
	gfxwidth = 28,
	gfxheight = 28,
	width = 24,
	height = 24,
	gfxoffsety = 2,
	frames = 3,
	framestyle = 1,
	framespeed = 6,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	score = 2,
	jumphurt = false,
	spinjumpsafe = false,
	nogravity = true,
	noblockcollision = true,
	luahandlesspeed = true,

	detectSize = 96,
	peekTime = 150,
	peekSpeed = 1.5,
	transformID = (npcID + 1),

	renderPriority = -66,
	hideAnim = {0},
	peekAnim = {0,1,1,1,0,2,2,2},
}

npcManager.setNpcSettings(hidingSquigglerSettings)

local deathEffectID = (npcID + 1)
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
		HARM_TYPE_VANISH,
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

function hidingSquiggler.onInitAPI()
    	npcManager.registerEvent(npcID, hidingSquiggler, "onTickEndNPC")
    	npcManager.registerEvent(npcID, hidingSquiggler, "onDrawNPC")
end

function hidingSquiggler.onTickEndNPC(v)
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
		data.animTimer = 0
		data.resetAnimTimer = false
		data.animDir = 1

		v.y = v.y - (v.height * v.direction)
	end

	if v.isProjectile then v.isProjectile = false end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        npcutils.applyLayerMovement(v)
	v.speedX, v.speedY = 0, 0

        local p = npcutils.getNearestPlayer(v)
        local distX = (p.x + p.width * 0.5) - (v.x + v.width * 0.5)
	local distY = (p.y + p.height * 0.5) - (v.y + v.height * 0.5)
	local dist = (math.abs(distX) + math.abs(distY)) / 2

	if data.timer <= 0 then
		if math.abs(dist) <= config.detectSize then 
			data.timer = 1 
			SFX.play(7, 0.5)
		end
	else
		data.timer = data.timer + 1

                if v.y > v.spawnY then
                        v.y = math.max(v.spawnY, v.y - config.peekSpeed)
                elseif v.y < v.spawnY then
                        v.y = math.min(v.spawnY, v.y + config.peekSpeed)
                else
                        v.y = v.spawnY
                end

		if data.timer >= (config.peekTime * 0.75) then
	        	if data.timer%8 > 0 and data.timer%8 < 5 then
		    		v.x = v.x + 1
	        	else
		    		v.x = v.x - 1
	        	end
		end

		if data.timer > config.peekTime then 
			v:transform(config.transformID)

			-- Reset a bunch of values
			v.data.initialized = false
			v.data._basegame.initialized = false
			v.spawnAi2 = v.spawnAi2

			-- Other stuff
			if v.direction == 1 then 
				v.y = v.y + 2 
			end
			npcutils.faceNearestPlayer(v)
		end
	end

	-- Animation

	data.animTimer = data.animTimer + 1

	local frame = 0
	local hide, peek = config.hideAnim, config.peekAnim

	if data.timer > 0 and v.y == v.spawnY then
		data.animDir = math.sign(distX)

		if not data.resetAnimTimer then 
			data.animTimer = 0 
			data.resetAnimTimer = true 

			if data.animDir == -1 then
				data.animTimer = (config.framespeed * #peek) - 1
			end
		end

		frame = (peek)[1 + math.floor((data.animDir * data.animTimer) / config.framespeed) % #peek]
	else
		frame = (hide)[1 + math.floor(data.animTimer / config.framespeed) % #hide]
		if data.resetAnimTimer then data.resetAnimTimer = false end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function hidingSquiggler.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then npcutils.hideNPC(v) return end
        local config = NPC.config[v.id]

	-- Render at a different priority

	npcutils.drawNPC(v, {priority = config.renderPriority})
	npcutils.hideNPC(v)
end

return hidingSquiggler