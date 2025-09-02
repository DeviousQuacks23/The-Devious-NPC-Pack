local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bombRusher = {}
local npcID = NPC_ID

local bombRusherSettings = {
	id = npcID,

	gfxwidth = 44,
	gfxheight = 40,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 12,
	framestyle = 1,
	framespeed = 4, 

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

	nofireball = true,
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
}

npcManager.setNpcSettings(bombRusherSettings)

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

local bombRushingExplosion = Explosion.register(64, 763, 22, false, false)

local function explode(v, data, cfg)
	v:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN) 
        Explosion.spawn(v.x+(v.width/2), v.y+(v.height/2), bombRushingExplosion)
	Defines.earthquake = 6
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

function bombRusher.onInitAPI()
	npcManager.registerEvent(npcID, bombRusher, "onTickEndNPC")
end

function bombRusher.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = WANDER
                data.timer = 0
		data.animTimer = 0
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
                v.animationFrame = ((v.direction == 1 and cfg.frames) or 0)
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

        if data.state == WANDER then
		v.animationFrame = math.floor(data.animTimer / cfg.framespeed) % 8
                v.speedX = 2 * v.direction
                if shouldCliffturn(v,data,config) then v.direction = -v.direction end
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                data.state = CHARGE
                                data.timer = 0
                                v.speedX = 0
                        end
                end
        elseif data.state == CHARGE then
                v.animationFrame = math.floor(data.animTimer / cfg.framespeed) % 4 + 8
                if v.collidesBlockBottom then
		        if (data.timer % 4) == 0 then SFX.play(10) end
		        if (data.timer % RNG.randomInt(1, 3)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                e.speedX = -2 * v.direction
                                e.speedY = RNG.random(-3, 0)
                                if v.direction == -1 then
		                        e.x = v.x+v.width-e.width * 0.5
                                else
		                        e.x = v.x-e.width * 0.5
                                end
                        end
                end
                if data.timer >= 64 then
                        data.state = DASH
			v.speedX = 10 * v.direction
                        SFX.play(Misc.resolveSoundFile("sound/character/ub_lunge.wav"), 0.75) 
                        local e = Effect.spawn(10, v.x - v.width * v.direction, v.y + v.height * 0.5)
                        e.y = e.y - e.height * 0.5
                        e.speedX = -2 * v.direction
                end
        elseif data.state == DASH then
		v.animationFrame = math.floor(data.animTimer / cfg.framespeed) % 2 + 8
                if v.collidesBlockBottom then
		        if (data.timer % RNG.randomInt(1, 8)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                else
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)+v.width-8
                                end
                        end
                end
                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - 0.2)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + 0.2)
                else
                        v.speedX = 0
                end
                if v.speedX == 0 then
			npcutils.faceNearestPlayer(v)
                        data.state = WANDER
                        data.timer = 0
		end
		if (math.abs(v.speedX) >= 2) then
			if v.collidesBlockLeft or v.collidesBlockRight then explode(v, data, cfg) end
        		for _,p in ipairs(Player.getIntersecting(v.x - 2, v.y + 2, v.x + (v.width + 2), v.y + (v.height - 2))) do explode(v, data, cfg) end
			for _,n in ipairs(NPC.getIntersecting(v.x - 2, v.y + 2, v.x + (v.width + 2), v.y + (v.height - 2))) do 
				if n.idx ~= v.idx and not n.isProjectile and not n.isHidden and not n.friendly and NPC.HITTABLE_MAP[n.id] then
					explode(v, data, cfg) 
				end
			end
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

return bombRusher