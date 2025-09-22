local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local easing = require("ext/easing")

local flipswapPanels = {}

flipswapPanels.switchSFX = Misc.resolveFile("flipSwapPanel.ogg")
flipswapPanels.scaleSpeed = 0.05

flipswapPanels.blockMap = {}
local invertedMap = {}

function flipswapPanels.register(blockID, isInvert)
	blockManager.registerEvent(blockID, flipswapPanels, "onCameraDrawBlock")
	flipswapPanels.blockMap[blockID] = true
	invertedMap[blockID] = isInvert
end

function flipswapPanels.onInitAPI()
	registerEvent(flipswapPanels, "onTick")
end

local lerp = 1
local flipDir = 1

local function isOnGround(p) -- ripped straight from MrDoubleA's SMW Costume scripts
	return (
		p.speedY == 0 -- "on a block"
		or p:isGroundTouching() -- on a block (fallback if the former check fails)
		or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
		or (p.mount == MOUNT_BOOT and p:mem(0x10C, FIELD_WORD) ~= 0) -- hopping around while wearing a boot
	)
end

local function playerJumped(p)
	if isOnGround(p) then
		if p.forcedState == 0 and p.deathTimer == 0 then 
			if p.mount ~= MOUNT_CLOWNCAR and p:mem(0x26,FIELD_WORD) == 0 then
				if p.keys.jump == KEYS_PRESSED or (p.mount == 0 and p.keys.altJump == KEYS_PRESSED) then
					return true
				end
			end
		end
	end
	
	return false
end

function flipswapPanels.switch()
	flipDir = -flipDir
	lerp = 0

	for _,v in ipairs(Block.getByFilterMap(flipswapPanels.blockMap)) do
		if flipswapPanels.switchSFX then
			blockutils.playSound(v.id, flipswapPanels.switchSFX)
		end

		if flipDir == -1 then
			if invertedMap[v.id] then
				Block.config[v.id].passthrough = false
			else
				Block.config[v.id].passthrough = true
			end
		elseif flipDir == 1 then
			if invertedMap[v.id] then
				Block.config[v.id].passthrough = true
			else
				Block.config[v.id].passthrough = false
			end
		end
	end
end

function flipswapPanels.getFlipDirection() return flipDir end

function flipswapPanels.onTick()
	for _,p in ipairs(Player.get()) do	
		if playerJumped(p) and lerp >= 1 then
			flipswapPanels.switch()
		end
	end

	lerp = math.min(1, lerp + flipswapPanels.scaleSpeed)
end

local function getScale(v)
	local config = Block.config[v.id]

	local start = (config.passthrough and 1) or 0
	local endLerp = (config.passthrough and -1) or 1

	return easing.outQuart(lerp, start, endLerp, 1)
end

function flipswapPanels.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

    	local config = Block.config[v.id]
    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	local img = config.activateImg
    	local priority = -63.5

	if getScale(v) <= 0 then return end

	Graphics.drawBox{
		texture = img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5,
		width = img.width * getScale(v),
		height = img.height * getScale(v),
		sourceY = frame * img.height,
		sourceHeight = img.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}
end

return flipswapPanels