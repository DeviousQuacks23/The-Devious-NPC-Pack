local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ticker = require("npcs/ai/ticker")

-- Sprites by Darolac, modified by me

local bowserBlades = {}

bowserBlades.sharedSettings = {
	gfxoffsetx = 0,
	gfxoffsety = 0, 

	width = 48,
	height = 64,
	gfxwidth = 64,
	gfxheight = 64,

    	frames = 1,
    	framestyle = 1,

    	noiceball = true,
    	noyoshi = true,
	luahandlesspeed = true,
	notcointransformable = true,
	ignorethrownnpcs = true,
	noblockcollision = true,
    	nowaterphysics = true,
    	jumphurt = true,
    	spinjumpsafe = true,
    	nogravity = true,
	staticdirection = true,

	-- Custom:

	isHorizontal = false,

	expandSound = Misc.resolveSoundFile("bladeUp"),
	retractSound = Misc.resolveSoundFile("bladeDown"),
	scaleSpeed = 4,

	showMeDebugBS = false,
}

function bowserBlades.register(id)
    	npcManager.registerEvent(id, bowserBlades, "onTickNPC")
    	npcManager.registerEvent(id, bowserBlades, "onDrawNPC")
end

function bowserBlades.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
        local config = NPC.config[v.id]
	local settings = v.data._settings

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local moveTime = settings.moveTime or 100
	local stillTime = settings.stillTime or 50
	local bladeSpeed = settings.bladeSpeed or 2
	local retractedScale = settings.retractedScale or 0.5

	local speed = (config.isHorizontal and "speedY") or "speedX"
	local size = (config.isHorizontal and "width") or "height"
	local pos = (config.isHorizontal and "x") or "y"
	local retractedSize = (config[size] * retractedScale)

	if not data.initialized then
		data.initialized = true

    		data.timer = 0
		data.moving = false
		data.moveDir = 1
		data.playedSFX = false

		v[size] = retractedSize
		if v.direction == -1 then
			v[pos] = v[pos] + config[size] * (1 - retractedScale)

			-- Scuffed fix
			if config.isHorizontal and (retractedScale <= 0.5) then
				v[pos] = v[pos] + 1
			end
		end
	end

	if v.isProjectile then v.isProjectile = false end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

	ticker.shouldTick = ticker.shouldTick or not v:mem(0x128, FIELD_BOOL)
        npcutils.applyLayerMovement(v)
	data.timer = data.timer + 1

	if data.moving then
		v[speed] = (bladeSpeed * data.moveDir) 

		if data.timer >= (moveTime - ((v[size] - retractedSize) / config.scaleSpeed)) then
			if (v[size] > retractedSize) then
				v[size] = math.max(retractedSize, v[size] - config.scaleSpeed)
			
				if v.direction == -1 then
					v[pos] = v[pos] + config.scaleSpeed
				end
			end

			if not data.playedSFX then
				data.playedSFX = true

				if config.retractSound then
					SFX.play(config.retractSound)
				end
			end
		else
			local stupidBuffer = ((config.isHorizontal and config.scaleSpeed) or 0)
			
			if ((v[size] + stupidBuffer) < config[size]) then
				v[size] = math.min(config[size], v[size] + config.scaleSpeed)

				if v.direction == -1 then
					v[pos] = v[pos] - config.scaleSpeed
				end
			end
		end
		
		if data.timer >= moveTime then
			data.moving = false
			data.moveDir = -data.moveDir
			data.playedSFX = false
			data.timer = 0
		end
	else
		v[speed] = 0

		if data.timer >= stillTime then
			data.moving = true
			data.timer = 0

			if config.expandSound then
				SFX.play(config.expandSound)
			end
		end
	end
end

function bowserBlades.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
        local config = NPC.config[v.id]

	-- Debugging info

	if config.showMeDebugBS then
		Text.print(v.x, 0 + (48 * v.idx), 48)
		Text.print(v.y, 0 + (48 * v.idx), 64)
		Text.print(v.width, 0 + (48 * v.idx), 80)
		Text.print(v.height, 0 + (48 * v.idx), 96)
		Colliders.getHitbox(v):Draw()
	end

	-- Taken from the basegame piranha plants code

	local size = (config.isHorizontal and "width") or "height"
	local gfxSize = (config.isHorizontal and "gfxwidth") or "gfxheight"
	local sourcePosition = (config.isHorizontal and "sourceX") or "sourceY"
	local positionOffset = (config.isHorizontal and "xOffset") or "yOffset"

	local graphicsSize, offset, source = config[gfxSize], 0, 0
	local difference = (config[size] - v[size])

	if difference > 0 then
		graphicsSize = graphicsSize - difference

		if config.isHorizontal then
			offset = offset + difference * 0.5
		else
			offset = offset + difference
		end

		if v.direction == 1 then
			source = source + difference
		end
	end
	
	if graphicsSize > 0 then
		npcutils.drawNPC(v, {[positionOffset] = offset, [size] = math.floor(graphicsSize), [sourcePosition] = source})
	end

	npcutils.hideNPC(v)
end

return bowserBlades