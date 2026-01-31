local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local waterfallZone = {}
local blockID = BLOCK_ID

-- Settings
local sprayImage = Graphics.loadImageResolved("waterfallSpray.png")
local sprayFrames = 3
local sprayFrameSpeed = 2
local sprayLoopSFX = Misc.resolveFile("waterfallLoop.ogg")
local sprayVolume = 0.75

blockManager.setBlockSettings({
	id = blockID,

	frames = 1,
	framespeed = 8,

	sizable = true, 
	passthrough = true, 
})

function waterfallZone.onInitAPI()
	Graphics.sprites.block[blockID].img = Graphics.loadImageResolved("stock-0.png")
	blockManager.registerEvent(blockID, waterfallZone, "onTickEndBlock")
	blockManager.registerEvent(blockID, waterfallZone, "onDrawBlock")
	registerEvent(waterfallZone, "onTick")
end

local playSound = true
local idleSoundObj

function waterfallZone.onTick()
    	if playSound then
        	if idleSoundObj == nil then
			idleSoundObj = SFX.play{sound = sprayLoopSFX, volume = sprayVolume, loops = 0}
        	end
   	elseif idleSoundObj ~= nil then 
        	idleSoundObj:stop()
        	idleSoundObj = nil
    	end
    
    	playSound = false
end

function waterfallZone.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and (p.y > v.y) then
			if not p:isOnGround() and p:isUnderwater() and p:mem(0x06,FIELD_WORD) <= 0 then p.speedY = p.speedY + 0.075 end
			if blockutils.isOnScreen(v) then playSound = true end
		end
	end
end

function waterfallZone.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and (p.y > v.y) then
        		Graphics.drawBox{
        			texture = sprayImage,
				sceneCoords = true,
		        	centered = true,
				priority = -25,
                		x = p.x + (p.width / 2),
				y = p.y + (p.height * 0.1),
				width = sprayImage.width,
				height = (sprayImage.height / sprayFrames),
                		sourceY = (math.floor(lunatime.tick() / sprayFrameSpeed) % sprayFrames) * (sprayImage.height / sprayFrames),
				sourceHeight = (sprayImage.height / sprayFrames),
        		}
		end
	end
end

return waterfallZone