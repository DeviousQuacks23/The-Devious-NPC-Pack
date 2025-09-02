local npcManager = require("npcManager")
local playerStun = require("playerstun")

local klonoa = require("characters/klonoa")

-- Original Robirdo code by KateBulka, sprites by MarioFan5000

local robirdo = {}
robirdo.idMap = {}

local theDeathOfRoboBirdo = Explosion.register(72, nil, nil, true, false)

robirdo.sharedSettings = {	
	gfxwidth = 72,
	gfxheight = 144,

	gfxoffsety = 2,
	
	width = 72,
	height = 106,
	
	frames = 0,
	framespeed = 8,
        framestyle = 1,
	
        playerblock = false,
        playerblocktop = true,
        npcblock = false,
        npcblocktop = false,

        nofireball = true,
	noiceball = true,
	noyoshi = true,
	
        luahandlesspeed = true,
	score = 0,
	weight = 3,

        spawnOffsetX = 12,
	hurttime = 96,
	stunframes = 64,
        finalScore = 9,

	explosion = 753,
	smoke = 752,
	stunEffect = 754,

	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 668, 526},
        volley = 3,
	
	projectiles = {760},
	effect = 757,
	debris = 758,

	health = 5,
}

function robirdo.register(npcID)
	npcManager.registerEvent(npcID, robirdo, "onTickEndNPC")
        klonoa.UngrabableNPCs[npcID] = true -- Prevent Klonoa from grabbing the NPC
        robirdo.idMap[npcID] = true
        npcManager.registerHarmTypes(npcID,
	        {
		        HARM_TYPE_FROMBELOW,
		        HARM_TYPE_NPC,
		        HARM_TYPE_PROJECTILE_USED,
		        HARM_TYPE_LAVA,
		        HARM_TYPE_HELD,
		        HARM_TYPE_SWORD,
	        },
	        {
		        [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	        }
        );
end

function robirdo.onInitAPI()
    	registerEvent(robirdo, "onNPCHarm")
	registerEvent(robirdo, "onPostNPCKill")
end

local IDLE = -1
local WALKS_BACKWARDS = 0
local SHOOTS = 1
local RUNS = 2
local JUMPS = 3
local WALKS = 4
local HURT = 5

local function init(v, data)
	if not data.init then
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)

		data.frame = 0
		data.frametimer = 0		
		data.direction = nil

		data.state = WALKS
		data.time = 0
		data.time2 = 0

		data.boomtimer = 0
		
		data.hp = NPC.config[v.id].health
		
		data.init = true
	end
end

local function animation(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]
	
	data.frame = (data.direction == 1 and 8) or 0
	
	if data.state == WALKS or data.state == WALKS_BACKWARDS or data.state == RUNS then
		data.frametimer = (data.frametimer + 1) % config.framespeed

                if data.state == RUNS then
                        if data.hp < config.health * 0.5 then
		        data.frame = data.frame + 5
                        end
                end
		
		if data.frametimer >= config.framespeed / 2 then
			data.frame = data.frame + 1
		end
	elseif data.state == JUMPS then
		data.frame = (v.collidesBlockBottom and data.frame + 2) or data.frame + 3
	elseif data.state == SHOOTS then
		data.frame = data.frame + 4
	elseif data.state == HURT then
		data.frametimer = (data.frametimer + 1) % config.framespeed
		data.frame = data.frame + 6

		if data.frametimer >= config.framespeed / 2 then
			data.frame = data.frame + 1
		end	
	end
	
	v.animationFrame = data.frame
end

function robirdo.onTickEndNPC(v)	
	if Defines.levelFreeze or v.despawnTimer <= 0 then return end
	
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then	
		if v:mem(0x138, FIELD_WORD) ~= 8 then
			v.animationFrame = (v.direction == 1 and 8) or 0
		end	
		return
	end

	if v.despawnTimer > 1 and v.legacyBoss then
		v.despawnTimer = 100
		
		local section = Section(v.section)
		
		if section.musicID ~= 6 and section.musicID ~= 15 and section.musicID ~= 21 then
			Audio.MusicChange(v.section, 15) -- Change the music to the SMB2 boss theme
		end
	end
	
	local data = v.data._basegame
	local config = NPC.config[v.id]
	init(v, data)
	
	data.direction = v.direction
	data.time = data.time + 1

	data.attackCollider.x = v.x + 12 * v.direction
	data.attackCollider.y = v.y
   
         -- Behaviour
	
	if data.state == WALKS then
		local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
		
		if (data.time % 16) == 0 then
			if (v.x + v.width / 2) > (p.x + p.width / 2) then
				v.direction = -1
			else
				v.direction = 1
			end
		end
		
		v.speedX = 2 * v.direction

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = 0
		end
		
		if data.time >= 80 then
			data.state = (math.random(32) > 16 and JUMPS) or SHOOTS
			data.time = 0
		end
	elseif data.state == JUMPS then
		v.speedX = 0
		
		if data.time == 48 then
			if v.collidesBlockBottom then
				v.y = v.y - 1
				v.speedY = -6
			end                       
		elseif data.time > 48 then
			if v.collidesBlockBottom then
				if data.time2 == 0 then
					SFX.play(37)
					
					Defines.earthquake = 6

                			local e = Effect.spawn(config.stunEffect, v.x + v.width * 0.5, v.y + v.height)
                			e.x = e.x - e.width * 0.5
                			e.y = e.y - e.height
					
					if not v.friendly then
						for k, p in ipairs(Player.get()) do
							if p:isGroundTouching() and not playerStun.isStunned(k) and v.section == p.section then
								playerStun.stunPlayer(k, config.stunframes)
							end
						end
					end	
				end
				
				data.time2 = data.time2 + 1
			end
		end
		
		if data.time2 >= 48 or data.time >= 128 then
			data.state = RUNS
			data.time = 0
			data.time2 = 0
		end
	elseif data.state == RUNS then
                if v.collidesBlockBottom then
			SFX.play(3, 1, 1, 4)
                end

		v.speedX = 6 * v.direction

		-- Interact with blocks
		local list = Colliders.getColliding{
		a = data.attackCollider,
		b = config.destroyblocktable,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden and other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}

		for _,b in ipairs(list) do
			if b.id == 667 or b.id == 666 then
				b:hit()
			else
				b:remove(true)
			end
		end

                -- Handle killing NPCs
		for _,n in ipairs(NPC.getIntersecting(v.x - 6, v.y + 6, v.x + v.width + 6, v.y + v.height)) do
                        if n.idx ~= v.idx and (not n.isProjectile) and (not n.isHidden) and (not n.friendly) and NPC.HITTABLE_MAP[n.id] then
                                n:harm(3)
                        end
		end

                -- Effect spawning
                if v.collidesBlockBottom then
			local e = Effect.spawn(74,0,0)

                	if v.direction == -1 then
				e.x = v.x+RNG.random(-v.width/10,v.width/10)
                	else
				e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                	end
			e.y = v.y+v.height-e.height * 0.5
                end
		
		if v.collidesBlockLeft or v.collidesBlockRight or v.dontMove then
			if not v.dontMove then
                        	if not v.collidesBlockBottom then
					v.speedX = 5 * v.direction
                                	v.speedY = -5 
                        	end
                        	SFX.play(37)
		        	Defines.earthquake = 2
			end
			data.state = WALKS_BACKWARDS
			data.time = 0
		end
	elseif data.state == WALKS_BACKWARDS then
		v.speedX = 2 * v.direction	
		
		data.direction = -data.direction

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = 0
		end	
		
		if data.time >= 160 or v.dontMove then
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
		
			if (v.x + v.width / 2) > (p.x + p.width / 2) then
				v.direction = -1
			else
				v.direction = 1
			end
			data.time = 0
			data.state = IDLE
		end
	elseif data.state == IDLE then
		v.speedX = 0
		
		if data.time >= 48 then
			data.state = WALKS
			data.time = 0
		end
	elseif data.state == SHOOTS then
		v.speedX = 0
		
		if data.time >= (64 * config.volley) + 24 then
			data.state = JUMPS
			data.time = 0
			return
		end
		
		if (data.time % 64) == 0 then
			local egg = NPC.spawn(RNG.irandomEntry(config.projectiles), v.x + config.spawnOffsetX * v.direction, v.y, v.section)
			egg.x = (v.direction == 1 and egg.x + v.width + 4 - egg.width) or egg.x - 4
			egg.y = egg.y + (config.gfxheight - v.height) - (egg.height / 2) - (egg.height * 0.25) - 2
			egg.direction = v.direction
			egg.speedX = 4 * egg.direction
			egg.despawnTimer = 100
			egg.friendly = v.friendly
			egg.layerName = "Spawned NPCs"
				
			SFX.play(38)
		end
	elseif data.state == HURT then
	       if data.hp <= 0 then
                        if data.time == 1 then
	                	Misc.givePoints(config.finalScore,vector(v.x + (v.width/2),v.y),true) -- Give the player points
                        end
               end

	       if data.time >= config.hurttime then
			if data.hp > 0 then
				data.state = RUNS
				data.time = 0
				data.time2 = 0
	       		else
	       			v:kill(3)
                	end
		end
	end

         -- Smoke
        if data.hp < config.health * 0.5 or data.state == HURT then
	        if RNG.randomInt(1,15) == 1 then
			local e = Effect.spawn(config.smoke, v.x + RNG.randomInt(0, config.gfxwidth), v.y + RNG.random(config.height * -0.25, config.height * 0.25))
                	e.x = e.x - e.width * 0.5
                end
	end

        -- Spawn debris every few ticks
        if data.hp <= 0 then
        	data.boomtimer = data.boomtimer + 1

                if data.boomtimer >= 3 then
                	Effect.spawn(config.debris, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                	data.boomtimer = 0
	        	SFX.play(91, 0.5)
                end
        end

	animation(v) -- Handle the animation
end

function robirdo.onNPCHarm(eventObj,v,reason,culprit)
	if not robirdo.idMap[v.id] then return end
	
	local data = v.data._basegame
	local config = NPC.config[v.id]
	local hp = data.hp

        if reason == HARM_TYPE_FROMBELOW then -- Bump the NPC up if bonked from below
        	v.speedY = -3
        	SFX.play(9)
        end
	
	if hp >= 0 then		
		if reason == HARM_TYPE_NPC or reason == HARM_TYPE_PROJECTILE_USED or reason == HARM_TYPE_HELD or reason == HARM_TYPE_SWORD then
		        if v:mem(0x156,FIELD_WORD) == 0 and data.state ~= HURT then
			         data.time = 0
				 data.state = HURT
				 data.hp = data.hp - 1
                                 SFX.play(39)
				 v.speedX = 0
			         v:mem(0x156,FIELD_WORD,config.hurttime) -- Give the boss invincibility frames
		                 if type(culprit) == "NPC" then
			                 culprit:harm(HARM_TYPE_NPC) -- Kill the NPC to prevent cheesing
		                 end          
                        end
	        end		
	end

        if reason ~= HARM_TYPE_LAVA then
        	eventObj.cancelled = true
        end
end

function robirdo.onPostNPCKill(v, reason)
	if not robirdo.idMap[v.id] then return end
	if reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN then return end

        local config = NPC.config[v.id]

	Defines.earthquake = 8

        -- Spawn a bunch of debris
	for i = 1, 16 do
                local e = Effect.spawn(config.debris, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
		e.speedX = RNG.random(-10, 10)
		e.speedY = RNG.random(-12, -24)
	end  

        -- Spawn a bunch of smoke
	for j = 1, 32 do
                local e = Effect.spawn(131, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
		e.speedX = RNG.random(-8, 8)
		e.speedY = RNG.random(-10, 10)
	end  

        local e = Effect.spawn(config.effect, v.x + v.width * 0.5,v.y + v.height * 0.5)
        e.x = e.x - e.width * 0.5
        e.y = e.y - e.height * 0.5

        local e = Effect.spawn(config.explosion, v.x + v.width * 0.5,v.y + v.height * 0.5)
        --e.x = e.x - e.width * 0.5
        --e.y = e.y - e.height * 0.5

        Explosion.create(v.x + v.width*0.5, v.y + v.height*0.5, theDeathOfRoboBirdo, nil, false)
	SFX.play(43)
		
	if v.legacyBoss then -- Spawn a crystal ball if set to legacy boss
		local ball = NPC.spawn(41, v.x, v.y, v.section)
		ball.x = ball.x + ((v.width - ball.width) / 2)
		ball.y = ball.y + ((v.height - ball.height) / 2)
		ball.speedY = -6
		ball.despawnTimer = 100
			
		SFX.play(41)
	end
end

return robirdo