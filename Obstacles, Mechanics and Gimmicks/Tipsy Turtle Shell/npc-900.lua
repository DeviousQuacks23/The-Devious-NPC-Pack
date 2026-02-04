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

-- Taken directly from seesaw AI

local function getObjectsOnPlatform(v) -- Get any objects standing on this platform
    local data = v.data

    local objects = {}

    if data.block and data.block.isValid then -- Only do this if we have a block
        if Block.config[data.block.id].floorslope == 0 then -- Platform does not have a slope
            local x1,y1,x2,y2 = (data.block.x),(data.block.y-1),(data.block.x+data.block.width),(data.block.y)

            for _,w in ipairs(table.append(Player.getIntersecting(x1,y1,x2,y2),NPC.getIntersecting(x1,y1,x2,y2))) do
                if (w.__type == "Player" and w:mem(0x146,FIELD_WORD) > 0) or (w.__type == "NPC" and w.collidesBlockBottom) then -- The object is probably standing on that block
                    table.insert(objects,w)
                end
            end
        else -- Platform has a slope
            for _,w in ipairs(table.append(Player.get(),NPC.get())) do
                if (w.__type == "Player" and w:mem(0x48,FIELD_WORD) == data.block.idx) or (w.__type == "NPC" and w:mem(0x22,FIELD_WORD) == data.block.idx) then -- The object is standing on the slope
                    table.insert(objects,w)
                end
            end
        end
    end

    return objects
end

local function rotateTo(v,angle)
    local data = v.data

    -- Apply rotation to any objects on the platform
    local difference = (angle-data.rotation)

    for _,w in ipairs(getObjectsOnPlatform(v)) do
        local distance = vector((v.x+(v.width*0.5))-(w.x+(w.width/2)),(v.y)-(w.y+w.height))

        if math.abs(angle) > 60 then -- yeet everything off
            w.speedX = (math.sign(distance.x)*-3)
            w.soeedY = -4
        else
            -- Keep track of the original position for later
            local originalPosition = vector(w.x,w.y)

            -- Rotate the object with the platform
            distance = distance:rotate(difference)

            w.x = v.x+v.speedX+(v.width*0.5)-distance.x-(w.width/2)
            w.y = v.y+v.speedY                         -distance.y-(w.height )

            if w.__type == "NPC" then
                w.speedY = 0
            else
                --w:mem(0x146,FIELD_WORD,0)
            end

            -- If this new position would cause the object to collide with something
            local idList = Block.SOLID
            if w.__type == "Player" then
                idList = idList.. Block.PLAYERSOLID
            else
                idList = idList.. Block.PLAYER
            end

            if #Colliders.getColliding{a = w,b = idList,btype = Colliders.BLOCK} > 0 then
                -- Go back to the original position
                w.x = originalPosition.x-w.speedX
                w.y = originalPosition.y-w.speedY
            end
        end
    end

    data.rotation = angle
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

    	local x = math.min(v.x+leftWidth+left.x,v.x+leftWidth+right.x) + (data.rotation * 2.5)
    	local y = (math.min(v.y+left.y,v.y+right.y)+0.25) + (math.abs(data.rotation) * 0.5)

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
		rotateTo(v, math.min(22.5, data.rotation + 0.5))
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
		rotateTo(v, math.max(-22.5, data.rotation - 0.5))
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

	local x,y,w,h = v.x, v.y, v.width, v.height

	if data.block then
		-- Colliders.getHitbox(data.block):Draw()
	end

	if v:mem(0x12A,FIELD_WORD) <= 0 or v.isHidden then return end

	local priority = -76

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = x+(w/2)+config.gfxoffsetx,y = y+h-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation or 0,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

return tipsyTurtleShell;