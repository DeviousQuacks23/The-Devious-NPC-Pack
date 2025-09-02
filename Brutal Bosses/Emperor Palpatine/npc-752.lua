local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bobby = {}
local npcID = NPC_ID

local palpatineID = (npcID - 1)

local bobbySettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 2,
}

npcManager.setNpcSettings(bobbySettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function bobby.onInitAPI()
	npcManager.registerEvent(npcID, bobby, "onTickEndNPC")
	registerEvent(bobby, "onNPCHarm")
end

local NORMAL = 0
local PRIMED = 1

local function kickStunned(v,data,config, culprit)
    	if type(culprit) == "Player" then
        	if v.x+v.width*0.5 < culprit.x+culprit.width*0.5 then
            		v.direction = DIR_LEFT
        	else
            		v.direction = DIR_RIGHT
        	end

        	v:mem(0x12E,FIELD_WORD,10)
        	v:mem(0x130,FIELD_WORD,culprit.idx)
    	end

    	v.speedX = 5 * v.direction
    	v.speedY = -2.5

    	SFX.play(2)
end

local function solidFilter(v,solid)
    local solidType = type(solid)

    if solidType == "Block" then
        local solidConfig = Block.config[solid.id]

        if solid.isHidden or solid:mem(0x5A,FIELD_BOOL) then
            return false
        end

        if solidConfig.passthrough then
            return false
        end

        -- NPC filter
        if solidConfig.npcfilter < 0 or solidConfig.npcfilter == v.id then
            return false
        end

        return true
    elseif solidType == "NPC" then
        local solidConfig = NPC.config[solid.id]

        if solid.despawnTimer <= 0 or solid.isGenerator or solid.friendly or solid:mem(0x12C,FIELD_WORD) > 0 then
            return
        end

        if solidConfig.npcblock or solidConfig.playerblocktop then -- why do NPC's also use playerblocktop
            return true
        end

        return false
    end
end

local function shouldCliffturn(v,data,config)
    -- Making good cliffturning is surprisingly difficult
    if not v.collidesBlockBottom then
        return false
    end

    local width = v.width * 0.8
    local height = 24

    local x
    local y = v.y + v.height + 2

    if v.direction == DIR_LEFT then
        x = v.x + v.width*0.75 - width
    else
        x = v.x + v.width*0.25
    end


    --Colliders.Box(x,y,width,height):Draw(Color.purple.. 0.5)


    for _,block in Block.iterateIntersecting(x,y,x + width,y + height + 128) do
        if solidFilter(v,block) then
            local extraHeight = 0
            if Block.SLOPE_LR_FLOOR_MAP[block.id] or Block.SLOPE_RL_FLOOR_MAP[block.id] then
                extraHeight = (block.height / block.width) * 16
            end

            if (y + height + extraHeight) > block.y then
                --Colliders.getHitbox(block):Draw()
                return false
            end
        end
    end

    for _,npc in NPC.iterateIntersecting(x,y,x + width,y + height) do
        if solidFilter(v,npc) then
            return false
        end
    end

    return true
end

function bobby.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = NORMAL
		data.timer = 0
		data.animTimer = 0
		data.range = Colliders:Circle()
	end

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = 600

	if v.heldIndex ~= 0  or v.forcedState > 0 then v.animationFrame = ((v.direction == -1 and 2) or 6) return end
        if v.isProjectile then v.isProjectile = false end
	
	-- Main AI

	data.timer = data.timer - 1
	data.animTimer = data.animTimer + 1

        v.despawnTimer = 180

	if data.state == NORMAL then
		v.animationFrame = math.floor(data.animTimer / 8) % 2
		v.speedX = 1.2 * v.direction
                if shouldCliffturn(v,data,config) then v.direction = -v.direction end
		if data.animTimer % 64 == 0 then
			local p = npcutils.getNearestPlayer(v)
			v.direction = -math.sign((p.x + p.width/2) - (v.x - v.width/2)) -- turns the npc away from the player
		end
	elseif data.state == PRIMED then
		v.animationFrame = math.floor(data.animTimer / data.timer) % 2 + 2
        	if v:mem(0x12C,FIELD_WORD) == 0 then
            		if v.collidesBlockBottom then
                		if v.speedX > 0 then
                    			v.speedX = math.max(0,v.speedX - 0.35)
                		elseif v.speedX < 0 then
                    			v.speedX = math.min(0,v.speedX + 0.35)
                		end
            		else
                		if v.speedX > 0 then
                    			v.speedX = math.max(0,v.speedX - 0.05)
                		elseif v.speedX < 0 then
                    			v.speedX = math.min(0,v.speedX + 0.05)
                		end
            		end
       		end
        	for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
            		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
            		and (v:mem(0x12E,FIELD_WORD) <= 0 or v:mem(0x130,FIELD_WORD) ~= p.idx)
            		then
                		kickStunned(v,data,config,p)
            		end
        	end
		if data.timer <= 0 then
			v:kill(HARM_TYPE_OFFSCREEN)
			SFX.play("bobby.ogg")
			Defines.earthquake = 10
        		local e = Effect.spawn(272, v.x + v.width * 0.5,v.y + v.height * 0.5)
			e.xScale = 4
			e.yScale = 4
	        	for j = 1, 16 do
                        	local e = Effect.spawn(10, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
		        	e.speedX = RNG.random(-16, 16)
		        	e.speedY = RNG.random(-16, 16)
	       		end  
	        	for j = 1, 32 do
                        	local e = Effect.spawn(74, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
		        	e.speedX = RNG.random(-8, 8)
		        	e.speedY = RNG.random(-8, 8)
	        	end  
			for k,w in ipairs(Block.get()) do
                		if Colliders.collide(data.range, w) and Misc.canCollideWith(v, w) then
                			if not w.isHidden and not w.layerObj.isHidden and w.layerName ~= "Destroyed Blocks" and w:mem(0x5A, FIELD_WORD) ~= -1 then
						if Block.MEGA_SMASH_MAP[w.id] then 
							if w.contentID > 0 then 
								w:hitWithoutPlayer(false)
							else
								w:remove(true)
							end
						elseif (Block.SOLID_MAP[w.id] or Block.PLAYERSOLID_MAP[w.id] or Block.MEGA_HIT_MAP[w.id]) then 
							w:hitWithoutPlayer(false)
						end
					end
				end
			end
			for k,p in ipairs(Player.get()) do
                		if Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) then
					if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
						local distance = vector((p.x + p.width*0.5) - (v.x + v.width*0.5),(p.y + p.height*0.5) - (v.y + v.height*0.5))
			        		p.speedX = (distance.x / v.width ) * 4
			        		p.speedY = (distance.y / v.height) * 2
					end
				end
			end
        		for k,n in ipairs(NPC.get()) do
                		if Colliders.collide(data.range, n) and Misc.canCollideWith(v, n) then
					if not n.isHidden and not n.friendly and (NPC.HITTABLE_MAP[n.id] or (NPC.config[n.id].grabside and NPC.config[n.id].grabtop)) then
						if n.x + (n.width * 0.5) == v.x + (v.width * 0.5) then
							n.speedX = RNG.irandomEntry({-10, 10})
						else
							n.speedX = math.sign((n.x + (n.width / 2)) - (v.x + (v.width / 2))) * 8
						end
						n.speedY = -8
						n.isProjectile = true
						if palpatineID ~= nil then
							if n.id == palpatineID then
								n:kill()
							end
						end
					end
				end
			end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = NPC.config[v.id].frames
	});
end

function bobby.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        local data = v.data
	
        if reason ~= HARM_TYPE_LAVA then eventObj.cancelled = true end

        if reason == HARM_TYPE_FROMBELOW then -- Bump the NPC up if bonked from below
        	v.speedY = -3
        	SFX.play(9)
        end

	if reason == HARM_TYPE_JUMP then
    		if culprit then v.direction = -math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2))) end

    		v.speedX = v.direction*5
    		v.speedY = -3.5

    		SFX.play(2)

		if data.state ~= PRIMED then
			data.animTimer = 0
			data.timer = 500
			data.state = PRIMED
		end
	end
end

return bobby