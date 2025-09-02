local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local eepCheep = {}
local npcID = NPC_ID

local eepCheepSettings = {
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

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = true,

	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi = false, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 

	-- Custom Properties

        visionlength = 135,
        visionwidth = 150,

        swimspeed = 2,
	swimacceleration = 0.035,

	rotateSprite = true,
}

npcManager.setNpcSettings(eepCheepSettings)

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

function eepCheep.onInitAPI()
	npcManager.registerEvent(npcID, eepCheep, "onTickEndNPC")
	npcManager.registerEvent(npcID, eepCheep, "onDrawNPC")
	registerEvent(eepCheep, "onNPCHarm")
end

function eepCheep.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local newX = (v.x + v.width*0.5) - v.speedX
	local newY = (v.y + v.height*0.5) - v.speedY

	if not data.initialized then
		data.initialized = true
                data.timer = 0
		data.animTimer = 0
                data.hasBeenUnderwater = false
                data.moving = false

		data.lastX = newX
		data.lastY = newY
		data.goalRotation = 0
		data.rotation = 0

                data.swimTimer = 0
		data.swimSpeed = 0
		data.swimSpeed2 = 1.2
		data.sineSpeed = 0.8
	
                if data.visionCollider == nil then
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-cfg.visionlength,-cfg.visionwidth},{-cfg.visionlength,cfg.visionwidth}),
                        [1] = Colliders.Tri(0,0,{0,0},{cfg.visionlength,-cfg.visionwidth},{cfg.visionlength,cfg.visionwidth}),
                }
                end
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

        data.swimTimer = data.swimTimer - 1

        if v.underwater then -- If the NPC is underwater then...
                data.hasBeenUnderwater = true
                v.noblockcollision = false

                v.speedX = data.swimSpeed2 * v.direction
                v.speedY = data.sineSpeed * -math.sin(data.timer * 0.04)

                if not v.friendly and not v.isProjectile then
                        data.visionCollider[v.direction].x = v.x + (v.width * ((v.direction == -1 and 0.8) or 0.2))
                        data.visionCollider[v.direction].y = v.y + 0.5 * v.height
                end

                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) and Misc.canCollideWith(v, p) and p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
                                data.swimTimer = 20
                        end
                end

                if data.swimTimer > 0 then
                        data.moving = true

	                data.pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5),
			(Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()

			v.speedX = data.pos.x * 1.2

			local plr = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                        if plr then
                                if plr.y + plr.height / 2 < v.y + v.height / 2 then
                                        v.speedY = data.swimSpeed
                                else
                                        v.speedY = -data.swimSpeed
                                end
                        end
                else
                        data.moving = false
                end
        else
                data.moving = false
                v.noblockcollision = true
                v.speedY = v.speedY + Defines.npc_grav -- Emulate gravity, since nogravity is enabled.

                if data.hasBeenUnderwater then
                        v.speedX = 1 * v.direction
                else
                        v.speedX = 0
                end
        end

        if data.moving then
                v.animationFrame = math.floor(data.animTimer / (cfg.framespeed / 2)) % cfg.frames

		data.swimSpeed = math.min(cfg.swimspeed, data.swimSpeed + cfg.swimacceleration)
		data.swimSpeed2 = v.speedX * v.direction
		data.sineSpeed = 0
		data.timer = 0

		data.rotation = math.anglelerp(data.rotation,data.goalRotation,0.35)
	        if data.lastX ~= newX or data.lastY ~= newY then
		        data.goalRotation = math.deg(math.atan2(newY - data.lastY,(newX - data.lastX)*v.direction))*v.direction*0.8
	        end
        else
                v.animationFrame = math.floor(data.animTimer / cfg.framespeed) % cfg.frames

		data.swimSpeed = math.max(data.swimSpeed - cfg.swimacceleration, 0)
		data.swimSpeed2 = math.min(1.2, data.swimSpeed2 + (cfg.swimacceleration * 0.25))
		data.sineSpeed = math.min(0.8, data.sineSpeed + cfg.swimacceleration)

		data.goalRotation = 0

                if data.rotation > 0 then
                        data.rotation = math.max(0,data.rotation - 2)
                elseif data.rotation < 0 then
                        data.rotation = math.min(0,data.rotation + 2)
                else
                        data.rotation = 0
                end
        end

	data.lastX = newX
	data.lastY = newY

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

--[[************************
Rotation code by MrDoubleA
**************************]]

local sprite

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function eepCheep.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end
	if not config.rotateSprite then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

function eepCheep.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end
	
	if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		if culprit then
			if culprit.__type == "Player" and v.underwater then
				culprit:harm()
			end
		end
	end	
end

return eepCheep