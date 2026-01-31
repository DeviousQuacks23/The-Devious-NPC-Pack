local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ghostBlock = {}
local npcID = NPC_ID

local effect = npcID

local ghostBlockSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 64,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 16,
	frames = 4,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = false, 
	nowaterphysics = false,
	cliffturn = false, 
	staticdirection = false,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, 
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	ignorethrownnpcs = true,

	score = 0, 

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false, 
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
}

npcManager.setNpcSettings(ghostBlockSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

local IDLE = 0
local ASCEND = 1
local FLOAT = 2
local CHARGE = 3
local THORW = 4

function ghostBlock.onInitAPI()
	npcManager.registerEvent(npcID, ghostBlock, "onTickNPC")
	npcManager.registerEvent(npcID, ghostBlock, "onDrawNPC")
end

local function homeIn(v)
	local localeX = 0
	local localeY = 0
	local localeSqrd = 0
	local targetPlayer
	for i=1,Player.count() do
		if not Player(i):mem(0x13C, FIELD_BOOL) and Player(i).section == v.section then
			if localeX == 0 or math.abs(v.x + v.width * 0.5 - (Player(i).x + Player(i).width * 0.5)) < localeX then
				localeX = math.abs(v.x + v.width * 0.5 - (Player(i).x + Player(i).width * 0.5))
				targetPlayer = Player(i)
			end
		end
	end
	if targetPlayer == nil then return end
	localeX = (v.x + v.width * 0.5) - (targetPlayer.x + targetPlayer.width * 0.5)
	localeY = (v.y + v.height * 0.5) - (targetPlayer.y + targetPlayer.height * 0.5)
	localeSqrd = math.sqrt(localeX^2 + localeY^2)
	localeX = -localeX / localeSqrd
	localeY = -localeY / localeSqrd
	v.speedX = localeX * 7
	v.speedY = localeY * 7
end

function ghostBlock.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = IDLE
                data.timer = 0
                data.isHoming = false
		data.rotation = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile 
	or v.forcedState > 0
	then
		return
	end

        data.timer = data.timer + 1
	
        if data.state == IDLE then
		for _, k in ipairs(Player.getIntersecting(v.x - 64, v.y - 48, v.x + v.width + 48, v.y + v.height + 64)) do
		        data.state = ASCEND
                        data.timer = 0
			Animation.spawn(10, v.x, v.y)
                        SFX.play(41)
                end
	elseif data.state == ASCEND then
                v.speedX = 2.6*math.sin(data.timer * 0.3)
                v.speedY = -6
	        data.rotation = ((data.rotation or 0) + math.deg((1.25)/((v.width+v.height)/4)))
                if data.timer == 30 then
                        v.speedY = 0
                        data.state = FLOAT
                        data.timer = 0
                end
	elseif data.state == FLOAT then
                v.speedY = 2.6*math.sin(data.timer * 0.1)
	        data.rotation = ((data.rotation or 0) + math.deg((v.speedX*0.85)/((v.width+v.height)/4)))
	        local player = npcutils.getNearestPlayer(v)	
	        local dist = (player.x + 0.5 * player.width) - (v.x + 0.5 * v.width)
	
	        if math.abs(dist)>32 then
		        v.speedX = math.clamp(v.speedX + 0.1*math.sign(dist),-5,5)
	        end

                if data.timer == 200 then
                        v.speedX = 0
                        v.speedY = 0
                        npcutils.faceNearestPlayer(v)	
                        data.state = CHARGE
                        data.timer = 0
                        SFX.play(35)
                end
	elseif data.state == CHARGE then
	        data.rotation = ((data.rotation or 0) + math.deg((7*v.direction)/((v.width+v.height)/4)))
                if data.timer == 80 then
	        	for j = 1, RNG.randomInt(6, 16) do
                        	local e = Effect.spawn(80, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
		        	e.speedX = RNG.random(-4, 4)
		        	e.speedY = RNG.random(-4, 4)
	        	end  
                        data.state = THROW
                        SFX.play(59)
                end
	elseif data.state == THROW then
	        data.rotation = ((data.rotation or 0) + math.deg((7*v.direction)/((v.width+v.height)/4)))
                if not data.isHoming then
		        local playerObj = npcutils.getNearestPlayer(v)
		        if playerObj ~= nil then
			        data.isHoming = true
			        homeIn(v)
		        end
                end
                for _, intersectingBlock in Block.iterateIntersecting(v.x - 2, v.y - 2, v.x + v.width + 2, v.y + v.height + 2) do
                        if intersectingBlock.isHidden == false and not intersectingBlock:mem(0x5A, FIELD_BOOL) then
				if Block.MEGA_SMASH_MAP[intersectingBlock.id] then intersectingBlock:remove(true) end
                                v:kill(HARM_TYPE_OFFSCREEN)
                        	local e = Effect.spawn(effect, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
	                        Animation.spawn(75, v.x, v.y)
                                SFX.play(4)
                                SFX.play(3)
                                if v.ai1 ~= 0 then
	                                local n = NPC.spawn(v.ai1, v.x, v.y, v.section)
                     	                n.layerName = "Spawned NPCs"
	                                n.speedX = 1.5 * v.direction
	                                n.speedY = RNG.random(-6,-2)
        	                        n.friendly = v.friendly
	  	                        if NPC.config[n.id].iscoin then
		                                n.ai1 = 1
                                        end
	                        end
                                break
                        end
                end
        end

        if data.state == IDLE then
                v.animationFrame = 0 + (2 * v.data._settings.look)
        else
                v.animationFrame = 1 + (2 * v.data._settings.look)
                if RNG.randomInt(1,15) == 1 then
                        local e = Effect.spawn(80, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        e.speedX = RNG.random(-2, 2)
                        e.speedY = RNG.random(-2, 2)
                        e.x = e.x - e.width *0.5
                        e.y = e.y - e.height*0.5
                end
        end

        v.animationTimer = 0
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

function ghostBlock.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

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

return ghostBlock