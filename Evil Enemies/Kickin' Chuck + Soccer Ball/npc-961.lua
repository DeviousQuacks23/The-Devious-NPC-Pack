local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Sprites by Smuglutena

local soccerBall = {}
local npcID = NPC_ID

local soccerBallSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 1,
	framestyle = 0,

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 
	grabside = false,
	grabtop = false,

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = false,
	noiceball = true,
	noyoshi = true, 

	score = 2, 
	weight = 2,

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = false,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	-- Custom Properties

	slopeAccel = 0.05,
	deceleration = 0.075,

	maxSpeed = 24,

	fireIMG = Graphics.loadImageResolved("npc-"..npcID.."-fire.png"),
	fireFrames = 2,
	fireFrameSpeed = 4,
	fireFadeSpeed = 0.1,
}

npcManager.setNpcSettings(soccerBallSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function soccerBall.onInitAPI()
	npcManager.registerEvent(npcID, soccerBall, "onTickEndNPC")
	npcManager.registerEvent(npcID, soccerBall, "onDrawNPC")
	registerEvent(soccerBall, "onNPCHarm")

	-- This is here so that stuff like beach koopas and outmaways will kick the ball
	NPC.VEGETABLE_MAP[npcID] = true
end

-- Taken directly from basegame spike AI
local function getSlopeSteepness(v)
	local greatestSteepness = 0

	for _,b in Block.iterateIntersecting(v.x,v.y + v.height,v.x + v.width,v.y + v.height + 0.2) do
		if not b.isHidden and not b:mem(0x5A,FIELD_BOOL) then
			local config = Block.config[b.id]

			if config ~= nil and config.floorslope ~= 0 and not config.passthrough and config.npcfilter == 0 then
				local steepness = b.height/b.width

				if steepness > math.abs(greatestSteepness) then
					greatestSteepness = steepness*config.floorslope
				end
			end
		end
	end

	return greatestSteepness
end

function soccerBall.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local newX = (v.x + v.width*0.5) - v.speedX
	local newY = (v.y + v.height*0.5) - v.speedY

	if not data.initialized then
		data.initialized = true

		data.harmful = false
		data.oldSpeedY = 0
		data.sfxTimer = 0

		data.lastX = newX
		data.lastY = newY
		data.goalRotation = 0
		data.fireRotation = 0
		data.rotation = 0

		data.fireOpacity = 0
		data.ballFlash = 0
	end

	-- Forced state/held BS
	if v.forcedState > 0 or v.heldIndex ~= 0 then return end

	-- Make the ball harmful
	if v.isProjectile then
		data.harmful = true
		v.isProjectile = false
	end

	-- Move the ball around with physics
	local angle = getSlopeSteepness(v)

	if angle ~= 0 then
		v.speedX = v.speedX + (angle * config.slopeAccel)
	else
		if v.collidesBlockBottom then
                	if v.speedX > 0 then
                        	v.speedX = math.max(0, v.speedX - config.deceleration)
                	elseif v.speedX < 0 then
                        	v.speedX = math.min(0, v.speedX + config.deceleration)
                	else
                        	v.speedX = 0
                	end

			-- Make the ball bouncy
        		if data.oldSpeedY > 1 then
        			v.speedY = -data.oldSpeedY * 0.65
                	end
		end
	end

	v.speedX = math.clamp(v.speedX, -config.maxSpeed, config.maxSpeed)
	data.oldSpeedY = v.speedY

	-- Float in water
        if v.underwater then
        	v.speedY = v.speedY - 0.35

		v.speedX = math.clamp(v.speedX, -(config.maxSpeed * 0.25), (config.maxSpeed * 0.25))
		v.speedY = math.clamp(v.speedY, -3, 3)

                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - config.deceleration)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + config.deceleration)
                else
                        v.speedX = 0
                end
	end

	-- SFX
	if v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockLeft then SFX.play(3) end
	if not v.collidesBlockBottom then data.sfxTimer = data.sfxTimer + 1 end

	if data.sfxTimer >= 12 and v.collidesBlockBottom then
		data.sfxTimer = 0
		SFX.play(3)
	end

	-- Kick the ball around
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
        		local e = Effect.spawn(75, v.x + v.width * 0.5, v.y + v.height * 0.5)
        		e.x = e.x - e.width * 0.5
        		e.y = e.y - e.height * 0.5
			SFX.play(2)

			-- Avoid purple flames!
			if data.harmful then p:harm() end

			v.speedX = (math.sign((p.x + (p.width / 2)) - (v.x + (v.width / 2))) * -2) + p.speedX

			if p.keys.up then
				v.speedY = -10
			else
				v.speedY = -3
			end
			v.speedY = v.speedY - (math.abs(v.speedX) * 0.25)

			-- Flash if the ball is fast
			if (((math.abs(v.speedX) + math.abs(v.speedY)) / 2) >= (config.maxSpeed / 4)) and not data.harmful then data.ballFlash = 1 end
		end
	end

	-- Break blocks
	-- Yoinked from Beetroot code (by MrNameless)
	if (v.collidesBlockUp or v.collidesBlockLeft or v.collidesBlockRight) and not v.collidesBlockBottom and not v.friendly then
		for i,b in Block.iterateIntersecting(v.x - 2,v.y -4, v.x + v.width + 2, v.y + v.height + 4) do
			if not b.isHidden and not b:mem(0x5A, FIELD_BOOL) then
				if Block.MEGA_SMASH_MAP[b.id] then 
					if b.contentID > 0 then 
						b:hitWithoutPlayer(false)
					else
						b:remove(true)
					end
				elseif (Block.SOLID_MAP[b.id] or Block.PLAYERSOLID_MAP[b.id] or Block.MEGA_HIT_MAP[b.id]) then 
					b:hitWithoutPlayer(false)
				end
			end
		end
	end

	-- Damage NPCs
	if not v.collidesBlockBottom and not v.friendly and not data.harmful then
        	for _,n in ipairs(NPC.getIntersecting(v.x + (v.speedX * 0.5), v.y + (v.speedY * 0.5), v.x + v.width + (v.speedX * 0.5), v.y + v.height + (v.speedY * 0.5))) do
            		if n.idx ~= v.idx and n.isValid and not n.isGenerator and n.despawnTimer > 0 and not n.isHidden and not n.friendly and not n.isProjectile and NPC.HITTABLE_MAP[n.id] and not NPC.POWERUP_MAP[n.id] then
                    		n:harm(3)

				-- Bounce with other balls. Not perfect, but gets the job done
				if n.id == v.id then
					n.speedX = (math.sign((n.x + (n.width / 2)) - (v.x + (v.width / 2))) * 2)
					n.speedY = (math.sign((n.y + (n.height / 2)) - (v.y + (v.height / 2))) * 3)
				end

				v.speedX = -v.speedX
				v.speedY = (math.sign((n.y + (n.height / 2)) - (v.y + (v.height / 2))) * -3)
				SFX.play(3)
            		end
		end
	end

	-- Rotate the ball
	data.rotation = data.rotation + (v.speedX * 3)

	-- Fire rotation
	data.fireRotation = math.anglelerp(data.fireRotation, data.goalRotation, 0.5)
	if data.lastX ~= newX or data.lastY ~= newY then
		data.goalRotation = math.deg(math.atan2(newY - data.lastY, newX - data.lastX))
	end

	data.lastX = newX
	data.lastY = newY

	-- Fire opacity
	if ((math.abs(v.speedX) + math.abs(v.speedY)) / 2) >= 3 then
		data.fireOpacity = math.min(1, data.fireOpacity + config.fireFadeSpeed)
	else
		data.fireOpacity = math.max(0, data.fireOpacity - config.fireFadeSpeed)
	end

	-- Make the ball not harmful
	if data.harmful then
		if data.fireOpacity <= 0 then
			data.harmful = false
		end
	end

	-- Make the ball flash
	if (((math.abs(v.speedX) + math.abs(v.speedY)) / 2) >= (config.maxSpeed / 3)) and not data.harmful then
		data.ballFlash = math.min(1, data.ballFlash + config.fireFadeSpeed)
	else
		data.ballFlash = math.max(0, data.ballFlash - config.fireFadeSpeed)
	end
end

function soccerBall.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img

	local lowPriorityStates = table.map{1,3,4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	local prioffset = {0, 0.1}
	local opacity = {1, data.ballFlash}
	local xFrame = {0, config.gfxwidth}

	-- Draw the ball
	for j = 1,2 do
		Graphics.drawBox{
			texture = img,
			x = v.x+(v.width/2)+config.gfxoffsetx,
			y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
			width = config.gfxwidth,
			height = config.gfxheight,
			sourceX = xFrame[j],
			sourceY = v.animationFrame * config.gfxheight,
			sourceWidth = config.gfxwidth,
			sourceHeight = config.gfxheight,
			sceneCoords = true,
			centered = true,
                	rotation = data.rotation,
			color = Color.white .. opacity[j],
			priority = priority+prioffset[j],
		}
	end

	npcutils.hideNPC(v)

	local imgFire = config.fireIMG

	local height = ((imgFire.height / config.fireFrames) / 2)
	local frame = math.floor(lunatime.tick() / config.fireFrameSpeed) % config.fireFrames + ((data.harmful and config.fireFrames) or 0)

	-- Draw the fire
	Graphics.drawBox{
		texture = imgFire,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = imgFire.width,
		height = height,
		sourceY = frame * height,
		sourceHeight = height,
		sceneCoords = true,
		centered = true,
                rotation = data.fireRotation-90,
		color = Color.white .. data.fireOpacity,
		priority = priority-0.1,
	}
end

function soccerBall.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end

	-- from MegaDood
	local culpritIsPlayer = (culprit and culprit.__type == "Player") 
	local culpritIsNPC    = (culprit and culprit.__type == "NPC")

        if reason == HARM_TYPE_FROMBELOW then
        	v.speedY = -5
        	SFX.play(9)
	elseif reason == HARM_TYPE_TAIL or reason == HARM_TYPE_SWORD then
		if culpritIsPlayer or culpritIsNPC then
        		local e = Effect.spawn(75, v.x + v.width * 0.5, v.y + v.height * 0.5)
        		e.x = e.x - e.width * 0.5
        		e.y = e.y - e.height * 0.5
			SFX.play(2)

			v.speedX = (math.sign((culprit.x + (culprit.width / 2)) - (v.x + (v.width / 2))) * -1)
			v.speedY = -10
		end
	elseif reason == HARM_TYPE_NPC then
		if culpritIsPlayer or culpritIsNPC then
        		local e = Effect.spawn(75, v.x + v.width * 0.5, v.y + v.height * 0.5)
        		e.x = e.x - e.width * 0.5
        		e.y = e.y - e.height * 0.5
			SFX.play(2)

			v.speedX = (culprit.speedX * 0.85)
			v.speedY = -6
		end
	end

        if reason ~= HARM_TYPE_LAVA then
        	eventObj.cancelled = true
        end
end

return soccerBall