local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local easing = require("ext/easing")

local checkeredBlock = {}

function checkeredBlock.register(blockID)
	blockManager.registerEvent(blockID, checkeredBlock, "onTickBlock")
	blockManager.registerEvent(blockID, checkeredBlock, "onCameraDrawBlock")
end

function checkeredBlock.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local settings = data._settings
	
	if not data.initialized then
		data.occupied = false
		data.oldAngle = 0
		data.angle = 0
		data.lerp = 0

		data.initialized = true
	end
	
	-- Important
	local rotDir = settings.rotationDirection or 0
	local clockwise = rotDir == 0
	local delay = settings.rotationDelay or 100
	local rotSpeed = settings.rotationSpeed or 8
	
	if data.occupied then	
		-- Push things off
		for _,p in ipairs(Player.getIntersecting(v.x - 4, v.y - 4, v.x + v.width + 4, v.y)) do
			if clockwise then
				p.speedX = math.min(4, p.speedX + 0.5)
			else
				p.speedX = math.max(-4, p.speedX - 0.5)
			end
		end
		for _,n in ipairs(NPC.getIntersecting(v.x - 4, v.y - 4, v.x + v.width + 4, v.y)) do
			if n.collidesBlockBottom then
				if clockwise and not n.collidesBlockRight then
					n.x = n.x + 2
				elseif not clockwise and not n.collidesBlockLeft then
					n.y = n.y - 2
				end
			end
		end

		data.lerp = math.min(1, data.lerp + (rotSpeed / 360))
		data.angle = easing.outBack(data.lerp, data.oldAngle, ((clockwise and 90) or -90), 1)

		if data.lerp >= 1 then
			data.occupied = false
		end
	else
		data.oldAngle = data.angle
		data.lerp = 0

		if lunatime.tick() % delay == 0 then
			blockutils.playSound(v.id, "checkeredSpin.ogg")
			data.occupied = true
		end
	end

	data.angle = data.angle % 360
end

function checkeredBlock.onCameraDrawBlock(v, camIdx)
	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end
	
	local data = v.data
	local config = Block.config[v.id]
	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	
	Graphics.drawBox{
		texture = Graphics.sprites.block[v.id].img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + v:mem(0x56, FIELD_WORD),
		width = v.width,
		height = v.height,
		sourceY = frame * v.height,
		sourceHeight = v.height,
		priority = -64,
		rotation = data.angle,
		centered = true,
		sceneCoords = true
	}

	blockutils.setBlockFrame(v.id, -100)
end

return checkeredBlock