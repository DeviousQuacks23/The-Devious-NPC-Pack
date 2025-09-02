local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--A bit of code used by MrDoubleA, please credit him too

local tipsyTurtleShell = {}
local npcID = NPC_ID

local tipsyTurtleShellSettings = {
	id = npcID, 
	gfxwidth = 384, 
	gfxheight = 320, 
	width = 384, 
	height = 32, 
	gfxoffsety = 288,
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = 1, 
	nogravity = 1, 
	noiceball = 1, 
	noblockcollision = 1, 
	ignorethrownnpcs = true,
	noyoshi = 1,
	notcointransformable = true,

	leftSlopeID = 846,
	rightSlopeID = 847,
	solidBlockID = 1007,
}

npcManager.setNpcSettings(tipsyTurtleShellSettings); 

function tipsyTurtleShell.onInitAPI()
	npcManager.registerEvent(npcID, tipsyTurtleShell, "onTickNPC")
	npcManager.registerEvent(npcID, tipsyTurtleShell, "onDrawNPC")
end

function tipsyTurtleShell.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
    	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
        	if data.block and data.block.isValid then
            		data.block:delete()
        	end
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0
		data.state = (v.direction == -1 and 3) or 1
		data.timer = 0
	end
	
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		v.speedY = 0
		v.speedX = 0
		return
	end

	-- Seesaw logic

    	-- Spawn a new block if we don't have one
    	if not data.block or not data.block.isValid then
        	data.block = Block.spawn(1,0,0) -- This gets changed after this, so the details don't really matter
   	end

    	-- Get the right ID for the block
    	local id = config.solidBlockID -- Straight, with no slope
    	if data.rotation < 0 then
        	id = config.leftSlopeID -- To the left
    	elseif data.rotation > 0 then
        	id = config.rightSlopeID -- To the right
    	else
        	data.block.isHidden = false -- Prevent it from being hidden if straight
    	end

    	if data.block.id ~= id then
        	data.block:transform(id)
    	end

    	-- Determine how large the left side and right side of the platform are
    	local leftWidth  = (v.width*(0.5))
    	local rightWidth = (v.width*(1-0.5))

    	-- Get the leftmost and rightmost points on the platform, relative to the centre
    	local left  = vector(leftWidth, 0):rotate(data.rotation+180)
    	local right = vector(rightWidth,0):rotate(data.rotation)

    	-- See the size of the block
    	data.block.width  = math.abs(right.x-left.x)
    	data.block.height = math.abs(right.y-left.y)

    	if data.rotation == 0 then -- Prevent the block being too small
        	data.block.height = v.height
    	end

    	local x = math.min(v.x+leftWidth+left.x,v.x+leftWidth+right.x)
    	local y = math.min(v.y+left.y,v.y+right.y)+0.25

    	if data.block.x ~= x or data.block.y ~= y then
        	data.block:translate(x-data.block.x,y-data.block.y)
    	end

	-- The actual rotation stuff

	data.timer = data.timer + 1

	if data.state == 0 then
		if data.timer >= 75 then
			data.state = 1
			data.timer = 0
		end
	elseif data.state == 1 then
		data.rotation = data.rotation + 0.5
		if data.rotation >= 22.5 then
			data.state = 2
			data.timer = 0
		end
	elseif data.state == 2 then
		if data.timer >= 75 then
			data.state = 3
			data.timer = 0
		end
	elseif data.state == 3 then
		data.rotation = data.rotation - 0.5
		if data.rotation <= -22.5 then
			data.state = 0
			data.timer = 0
		end
	end
end

--[[************************
Rotation code by MrDoubleA
**************************]]

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

function tipsyTurtleShell.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -76

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

return tipsyTurtleShell;