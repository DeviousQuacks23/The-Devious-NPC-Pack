local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local spikeZokTroop = {}
local npcID = NPC_ID

local spikeZokTroopSettings = {
	id = npcID,

	gfxwidth = 104,
	gfxheight = 70,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 11,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	-- Custom Properties
}

npcManager.setNpcSettings(spikeZokTroopSettings)

local deathEffectID = (npcID)

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

local WANDER = 0
local CHARGE = 1
local DASH = 2

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

function spikeZokTroop.onInitAPI()
	npcManager.registerEvent(npcID, spikeZokTroop, "onTickEndNPC")
	registerEvent(spikeZokTroop, "onNPCHarm")
end

function spikeZokTroop.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[npcID]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = WANDER
                data.timer = 0
                data.spiky = (RNG.randomInt(1, 2) == 1 and true) or false
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-175,-30},{-175,30}),
                        [1] = Colliders.Tri(0,0,{0,0},{175,-30},{175,30}),
                }
                end
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = 1
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if data.state == WANDER then
                if data.spiky then
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 6) % 4
                        else
                                v.animationFrame = 1
                        end
                else
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 6) % 4 + 7
                        else
                                v.animationFrame = 8
                        end
                end
                v.speedX = 1.4 * v.direction
                if shouldCliffturn(v,data,config) then v.direction = -v.direction end -- Custom cliffturning by MDA
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                SFX.play(Misc.resolveSoundFile("chuck-whistle"))
                                data.state = CHARGE
                                data.timer = 0
                                v.speedX = 0
                                v.speedY = -2
                        end
                end
        elseif data.state == CHARGE then
                v.animationFrame = math.floor(data.timer / 2) % 3 + 4
                if v.collidesBlockBottom then
		        if (data.timer % 4) == 0 then SFX.play(10) end
		        if (data.timer % RNG.randomInt(1, 3)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                e.speedX = -2 * v.direction
                                e.speedY = RNG.random(-3, 3)
                                if v.direction == -1 then
		                        e.x = v.x+v.width-e.width * 0.5
                                else
		                        e.x = v.x-e.width * 0.5
                                end
                        end
                end
                if data.timer%4 > 0 and data.timer%4 < 3 then
                        v.x = v.x - 2
                else
                        v.x = v.x + 2
                end
                if data.timer >= 64 then
                        data.state = DASH
                        data.spiky = (RNG.randomInt(1, 2) == 1 and true) or false
                        SFX.play(Misc.resolveSoundFile("sound/character/ub_lunge.wav"), 0.75) 
                        local e = Effect.spawn(10, v.x - v.width * v.direction, v.y + v.height * 0.5)
                        e.y = e.y - e.height * 0.5
                        e.speedX = -1 * v.direction
                end
        elseif data.state == DASH then
                if data.spiky then
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 2) % 4
                        else
                                v.animationFrame = 1
                        end
                else
                        if v.collidesBlockBottom then
                                v.animationFrame = math.floor(data.timer / 2) % 4 + 7
                        else
                                v.animationFrame = 8
                        end
                end
                v.speedX = 3.2 * v.direction
                if v.collidesBlockBottom then
		        if (data.timer % 12) == 0 then SFX.play(Misc.resolveSoundFile("sound/character/wario_footstep"..RNG.randomInt(1, 3)..".ogg"), 0.75) end
		        if (data.timer % RNG.randomInt(1, 8)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                else
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                end
                        end
                end
                local n = npcutils.getNearestPlayer(v)
		if ((n.x + n.width / 2) > (v.x + v.width * 8) and v.direction == -1) or ((n.x + n.width / 2) < (v.x - v.width * 8) and v.direction == 1) then
			npcutils.faceNearestPlayer(v)
                        data.spiky = (RNG.randomInt(1, 2) == 1 and true) or false
                        data.state = WANDER
                        data.timer = 0
                        v.speedY = -3
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

function spikeZokTroop.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        local data = v.data
	
        if data.spiky then
	        if reason == HARM_TYPE_JUMP then
		        if culprit then
			        if culprit.__type == "Player" then
				        eventObj.cancelled = true
                                        culprit:harm()
			        end
		        end
                elseif reason == HARM_TYPE_SPINJUMP then
		        if culprit then
			        if culprit.__type == "Player" then
				        eventObj.cancelled = true
			        end
		        end
	        end
	end	
end

return spikeZokTroop