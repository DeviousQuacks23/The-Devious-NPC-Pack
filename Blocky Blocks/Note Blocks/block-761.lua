local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

-- Code taken from Emral's Yoshi Wings

local noteBlock = {}
local blockID = BLOCK_ID

local noteBlockSettings = {
	id = blockID,

	frames = 4,
	framespeed = 8, 

	bumpable = true,

	bounceSFX = 24,
	playerBounceHeight = 0,

	flashFramespeed = 4,
	flashFrames = 2,
}

blockManager.setBlockSettings(noteBlockSettings)

local AI = require("noteBlocks")
AI.register(blockID)

function noteBlock.onInitAPI()
	blockManager.registerEvent(blockID, noteBlock, "onCameraDrawBlock")
	registerEvent(noteBlock, "onTick")
	registerEvent(noteBlock, "onBlockHit")
end

local warpingPlayers = {}
local playerShouldGoToWarpExit = {}

function noteBlock.onTick()
	for k,p in ipairs(warpingPlayers) do
		if playerShouldGoToWarpExit[p] then
			p.speedY = -14
                        p.speedX = 0

		        p.keys.left = nil
		        p.keys.right = nil
                        p.noblockcollision = true
                        p.nonpcinteraction = true
                        p.noplayerinteraction = true

			if p.y + p.height < p.sectionObj.boundary.top then
				local warp = Warp.get()[playerShouldGoToWarpExit[p]]

				if playerShouldGoToWarpExit[p] > 0 then 
					p:teleport(warp.exitX, warp.exitY, true) 
					p.speedY = -10
				else
					p.speedY = -4
				end

				playerShouldGoToWarpExit[p] = 0
			        table.remove(warpingPlayers, k)

                                p.noblockcollision = nil
                                p.nonpcinteraction = nil
                                p.noplayerinteraction = nil
			end
		end
	end
end

local function warpThePlayer(v, p)
	playerShouldGoToWarpExit[p] = v.data._settings.targetWarp
	table.insert(warpingPlayers, p)
end

function noteBlock.onBlockHit(event, v, fromUpper, p)
    	if v.id ~= blockID then return end

	if fromUpper and p and type(p) == "Player" then
		if (p.keys.jump or p.keys.altJump) and (p.mount ~= 2) then
                        warpThePlayer(v, p)
		end
	end
end

function noteBlock.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]

    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	local flash = math.floor((lunatime.drawtick() / config.flashFramespeed) % config.flashFrames)

    	local priority = -64

	Graphics.drawBox{
		texture = Graphics.sprites.block[v.id].img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + v:mem(0x56,FIELD_WORD),
		width = v.width,
		height = v.height,
		sourceX = flash * v.width,
		sourceY = frame * v.height,
		sourceWidth = v.width,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	blockutils.setBlockFrame(v.id, -1000)
end

return noteBlock