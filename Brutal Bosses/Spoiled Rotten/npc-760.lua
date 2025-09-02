local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local spoiledRottenBoss = {}
local npcID = NPC_ID

-- Some code taken from Mal8rk's Cuckoo Condor, adapted by me with help from MegaDood

local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true

local wariodashattacking
pcall(function() wariodashattacking = require("wariodashattacking") end)

local wariodashing
pcall(function() wariodashing = require("wariodashing") end)

local spoiledRottenBossSettings = {
	id = npcID,

	gfxwidth = 240,
	gfxheight = 134,
	width = 80,
	height = 96,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 19,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = true, 
	staticdirection = false,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false, 

	nohurt=false, 
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 
	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 0,

	jumphurt = false,
	spinjumpsafe = false, 
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	weight = 2,

        bossHP = 10,
        criticalHP = 3,
        finalScore = 7,

        smallSmoke = 759,
        mediumSmoke = 760,
        largeSmoke = 761,
        eggplantEffect = 762,
}

npcManager.setNpcSettings(spoiledRottenBossSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_LAVA,
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

local IDLE = 0
local WALK = 1
local TURN = 2
local HURT = 3
local STUN = 4

function spoiledRottenBoss.onInitAPI()
	npcManager.registerEvent(npcID, spoiledRottenBoss, "onTickEndNPC")
	registerEvent(spoiledRottenBoss, "onNPCHarm")
end

function spoiledRottenBoss.onTickEndNPC(v)	
	local data = v.data
        local cfg = NPC.config[npcID]
        local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.state = IDLE
                data.hp = cfg.bossHP
                data.timer = 0
		data.animTimer = 0
                data.turnInterval = 0
                data.immunity = 0
                data.critical = false
                data.hurtDirection = 0

                data.leftHitboxEnabled = true
                data.rightHitboxEnabled = true

		data.buttonTimer = 0

		data.initialized = true
	end

	if v.heldIndex ~= 0 
	or v.isProjectile 
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1
        data.turnInterval = data.turnInterval + 1
        data.immunity = data.immunity - 1

	if player.character == CHARACTER_WARIO then
		if player.keys.altRun then
			data.buttonTimer = data.buttonTimer + 1
		else
			data.buttonTimer = 0
		end
	end

        if cfg.criticalHP >= data.hp then
                data.critical = true
        end

        if data.critical and (data.state == IDLE or data.state == WALK) then
                if v.direction == -1 then
                        data.leftHitboxEnabled = false
                        data.rightHitboxEnabled = true
                elseif v.direction == 1 then
                        data.leftHitboxEnabled = true
                        data.rightHitboxEnabled = false
                end
        end

        for _, k in ipairs(Player.getIntersecting(v.x - 10, v.y, v.x + 24, v.y + v.height)) do
                if data.leftHitboxEnabled then
                        SFX.play(3)
			k.speedX = -3
			k.speedY = -3
                        k:mem(0x40, FIELD_WORD, 0)
                        if data.critical == false and data.state ~= HURT then
	                data.state = STUN
                        data.timer = 0
                        end
                end
        end

        for _, j in ipairs(Player.getIntersecting(v.x + v.width - 24, v.y, v.x + v.width + 10, v.y + v.height)) do
                if data.rightHitboxEnabled then
                        SFX.play(3)
			j.speedX = 3
			j.speedY = -3
                        j:mem(0x40, FIELD_WORD, 0)
                        if data.critical == false and data.state ~= HURT then
	                data.state = STUN
                        data.timer = 0
                        end
                end
        end

	for _,n in ipairs(NPC.getIntersecting(v.x - 6, v.y + 6, v.x + v.width + 6, v.y + v.height - 6)) do
		if n.isProjectile and not n.friendly then
                        if 0 >= data.immunity and (((n.x > v.x and v.direction == -1) or (n.x < v.x + v.width and v.direction == 1)) or data.hp > cfg.criticalHP) then
                                data.hp = data.hp - 1
                                SFX.play(39)
                                data.state = HURT
                                data.timer = 0
                                data.immunity = 50
	                        if n.x + n.width / 2 < v.x + v.width / 2 then
		                        data.hurtDirection = 1
	                        else
		                        data.hurtDirection = 2
	                        end
                        end
		end
		n:harm(HARM_TYPE_NPC)
	end
        if 0 >= data.immunity then
        for _, q in ipairs(Player.getIntersecting(v.x - 12, v.y + 4, v.x + v.width + 12, v.y + v.height - 4)) do
	        if q.character == CHARACTER_WARIO and q.keys.altRun and q.powerup > 1 and data.buttonTimer > 22 then
                        if (((q.x > v.x and v.direction == -1) or (q.x < v.x + v.width and v.direction == 1)) or data.hp > cfg.criticalHP) then 
                                data.hp = data.hp - 1
                                SFX.play(39)
                                data.state = HURT
                                data.timer = 0
                                data.immunity = 50
	                        if q.x + q.width / 2 < v.x + v.width / 2 then
		                        data.hurtDirection = 1
	                        else
		                        data.hurtDirection = 2
	                        end
                        else
                                q:harm()
                                data.immunity = 50
                        end
                        q.speedX = 10 * -q.direction
			q.speedY = -8
	        end
        end
	if (wariodashattacking and wariodashattacking.dashstate > 0) or (wariodashing and wariodashing.dash) then
                if (wariodashing and Colliders.collide(wariodashing.dashingColliderNPC,v)) or (wariodashattacking and Colliders.collide(wariodashattacking.dashingColliderNPC,v)) then
		        if (((player.x > v.x and v.direction == -1) or (player.x < v.x + v.width and v.direction == 1)) or data.hp > cfg.criticalHP) then
				wariodashattacking.cancelDashAttack(true)
				wariodashing.cancelDash(true)
					data.hp = data.hp - 1
					SFX.play(39)
					data.state = HURT
					data.timer = 0
					data.immunity = 50
				if player.x + player.width / 2 < v.x + v.width / 2 then
					data.hurtDirection = 1
				else
					data.hurtDirection = 2
				end
                        else
                                player:harm()
			        wariodashattacking.cancelDashAttack(true)
			        wariodashing.cancelDash(true)
			end
		end
	end
        end

	if data.state == IDLE then
        	v.speedX = 0
        	if data.critical == false then
			v.animationFrame = 0
        	else
	        	if data.timer >= 5 then
	                	v.animationFrame = 9
                	else
	                	v.animationFrame = 8
                	end
       		end
                if data.timer == 10 then
	        	data.state = WALK
			data.animTimer = 0
                	data.timer = 0
                	data.turnInterval = 0
                end
	elseif data.state == WALK then
        	if data.critical == false then
			v.animationFrame = math.floor(data.animTimer / 6) % 6 + 1
        		v.speedX = 0.9 * v.direction
       		else
			v.animationFrame = math.floor(data.animTimer / 12) % 6 + 9
        		v.speedX = 0.5 * v.direction
        	end
                if data.turnInterval == 120 then
                        if (p.x + 0.5 * p.width > v.x + 0.5 * v.width and v.direction == -1) or (p.x + 0.5 * p.width < v.x + 0.5 * v.width and v.direction == 1) then
	                	data.state = TURN
                        end
                	data.turnInterval = 0
                end
	elseif data.state == TURN then
        	v.speedX = 0
        	if data.critical == false then
			v.animationFrame = 7 
        	else
			v.animationFrame = 16
        	end
                if data.turnInterval == 3 then
                        if p.x + 0.5 * p.width > v.x + 0.5 * v.width then
                        	v.direction = 1
                        else
                        	v.direction = -1
                        end
                elseif data.turnInterval == 6 then
	        	data.state = WALK
			data.animTimer = 0
                	data.turnInterval = 0
                end
	elseif data.state == HURT then
        	if data.hurtDirection == 1 then
                	if not v.collidesBlockRight then
                 		v.x = v.x + 3.5
                 	end
        	elseif data.hurtDirection == 2 then
                 	if not v.collidesBlockLeft then
                 		v.x = v.x - 3.5
                 	end
       		end
		v.animationFrame = 17
                if data.timer >= 30 then
			if data.hp > 0 then
                        	data.state = STUN
                        	data.timer = 0
                        else
                        	v.speedX = 0
                        	data.immunity = 9999
	                	if RNG.randomInt(1,9) == 1 then
		        		Effect.spawn(cfg.smallSmoke, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        		SFX.play(64)
                        	end
	                	if RNG.randomInt(1,7) == 1 then
		        		Effect.spawn(cfg.mediumSmoke, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        		SFX.play(64)
                        	end
	                	if RNG.randomInt(1,5) == 1 then
		        		Effect.spawn(cfg.largeSmoke, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        		SFX.play(64)
                        	end
	                	if RNG.randomInt(1,3) == 1 then
		        		Effect.spawn(cfg.eggplantEffect, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        		SFX.play(64)
                        	end
                               	if data.timer >= 60 then
		               		v:kill(HARM_TYPE_OFFSCREEN)
	                       		Misc.givePoints(cfg.finalScore,vector(v.x + (v.width/2),v.y),true)

		                      	if v.legacyBoss then
			                	local ball = NPC.spawn(354, v.x, v.y, v.section)
			                   	ball.x = ball.x + ((v.width - ball.width) / 2)
			                   	ball.y = ball.y + ((v.height - ball.height) / 2)
			                   	ball.speedY = -6
			                   	ball.despawnTimer = 100
			
			                   	SFX.play(20)
                                      end
                               end
                        end
                 end
	elseif data.state == STUN then
        	v.speedX = 0
		v.animationFrame = 18
        	data.hurtDirection = 0
                if data.timer == 20 then
	        	data.state = IDLE
                	data.timer = 0
			data.animTimer = 0
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

function spoiledRottenBoss.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

	local data = v.data

	if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		if culprit.x + culprit.width / 2 < v.x + v.width / 2 then
			culprit.speedX = -3
		else
			culprit.speedX = 3
		end
                SFX.play(3)
        elseif reason == HARM_TYPE_FROMBELOW then
        	v.speedY = -5
        	SFX.play(9)
	end

        if reason ~= HARM_TYPE_LAVA then
        	eventObj.cancelled = true
        end
end

return spoiledRottenBoss