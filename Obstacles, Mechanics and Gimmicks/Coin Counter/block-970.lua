local blockManager = require("blockManager")
local textplus = require("textplus")

local coinCounter = {}
local blockID = BLOCK_ID

coinCounter.hudSettings = {
	drawnBlock = Graphics.loadImageResolved("block-"..blockID..".png"),
	blockLandSFX = 36,

	hudImage = Graphics.loadImageResolved("block-"..blockID.."-hud.png"),
	hudOffset = vector(0, -2),

	font = textplus.loadFont("coinChallengeFont.ini"),
	fontScale = 1,
	maxTextWidth = 52,

	hudLocation = vector(0.065, 0.960),
	rewardScore = 12,
}

local coinCounterSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 

	bumpable = true, 

	--Define custom properties below

	hitSFX = Misc.resolveSoundFile("coinChallenge"),

	minCoins = 5,
	maxCoins = 15,
	coinID = 10,
	coinSFX = 59,
}

blockManager.setBlockSettings(coinCounterSettings)

function coinCounter.onInitAPI()
	registerEvent(coinCounter, "onBlockHit")
	registerEvent(coinCounter, "onDraw")
end

local drawnBlocks = {}

local shouldRender = false
local totalCoins = 0
local oldCoins = 0

local eventToTrigger

function coinCounter.onBlockHit(e, v, fromUpper, p)
	if v.id == BLOCK_ID then
		local cfg = Block.config[v.id]
		local blockSettings = v.data._settings
		local settings = coinCounter.hudSettings

		e.cancelled = true

		if not Misc.isPaused() then
			if shouldRender then
				if (cfg.minCoins > 0) and (cfg.maxCoins > 0) and (cfg.coinID > 0) then
                			for i = 1, RNG.randomInt(cfg.minCoins, cfg.maxCoins) do
                        			local coin = NPC.spawn(cfg.coinID, v.x + v.width * 0.5, v.y + v.height * 0.5)
                        			coin.x = coin.x - coin.width * 0.5
                        			coin.y = coin.y - coin.height * 0.5
                        			coin.speedX = RNG.random(-4, 4)
                        			coin.speedY = RNG.random(-3, -12)
						coin.layerName = "Spawned NPCs"

	  	                		if NPC.config[coin.id].iscoin then
		                        		coin.ai1 = 1
                                		end
					end

					for i = 1, 4 do
						local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.5)
						e.speedX = ({-2, -2, 2, 2})[i]
						e.speedY = ({-3, 3, -3, 3})[i]
                				e.x = e.x - e.width * 0.5
						e.y = e.y - e.height * 0.5
					end

					if cfg.coinSFX then SFX.play(cfg.coinSFX) end
				end
			else
				local distanceX = ((camera.width * settings.hudLocation.x) - (v.x - camera.x))
				local distanceY = ((camera.height * settings.hudLocation.y) - (v.y - camera.y))

				local speedX = (0.4/32)*distanceX
				local t = math.max(1,math.abs(distanceX/speedX))
				local speedY = (distanceY/t - Defines.npc_grav*t*0.5)

				table.insert(drawnBlocks, {
					x = v.x - camera.x, 
			        	y = v.y - camera.y,
					width = v.width,
					height = v.height,
					speedX = speedX,
					speedY = speedY,
					amount = (blockSettings.coinAmount or 30)
                        	})   

				if blockSettings.rewardEvent and blockSettings.rewardEvent ~= "" then
					eventToTrigger = tostring(blockSettings.rewardEvent)
				end

                     		if cfg.hitSFX then SFX.play(cfg.hitSFX) end
				Misc.pause()
			end

			SFX.play(3)
			v:delete()
		end
	end
end

function coinCounter.onDraw()
	local settings = coinCounter.hudSettings	

	if shouldRender then
		Graphics.drawBox{
			texture = settings.hudImage,
        		x = (camera.width * settings.hudLocation.x) + settings.hudOffset.x,
        		y = (camera.height * settings.hudLocation.y) + settings.hudOffset.y,
			sceneCoords = false,
			priority = 5,
			centered = true,
		}

		textplus.print{
        		x = (camera.width * settings.hudLocation.x),
        		y = (camera.height * settings.hudLocation.y),
        		text = tostring(totalCoins),
			maxWidth = settings.maxTextWidth,
			pivot = vector(0.5, 0.5),
			sceneCoords = false,
			priority = 5,
			font = settings.font,
			xscale = settings.fontScale,
			yscale = settings.fontScale
    		}
	end

	if totalCoins > 0 then
		if Misc.coins() ~= oldCoins then
			local coinsDiff = (Misc.coins() - oldCoins)
			totalCoins = totalCoins - coinsDiff
			oldCoins = Misc.coins()

			if totalCoins <= 0 then
				if settings.rewardScore > 0 then
					Misc.givePoints(settings.rewardScore, vector((player.x + player.width*0.5), player.y, true))
				end

				if eventToTrigger and eventToTrigger ~= "" then
					triggerEvent(eventToTrigger)
				end
				eventToTrigger = nil
			end
		end
	else
		if shouldRender then shouldRender = false end
		if totalCoins ~= 0 then totalCoins = 0 end
		if oldCoins ~= 0 then oldCoins = 0 end
	end

	-- Text.print(eventToTrigger, 0, 0)

	for k = #drawnBlocks, 1, -1 do
		local v = drawnBlocks[k]

		v.x = v.x + v.speedX
		v.y = v.y + v.speedY
		v.speedY = math.min(v.speedY + Defines.npc_grav, 8)

		if v.speedY > 0 and v.y >= ((camera.height * settings.hudLocation.y) - (settings.hudImage.height * 0.5)) then
			if settings.blockLandSFX then SFX.play(settings.blockLandSFX) end

			for i = 1, 4 do
				local e = Effect.spawn(10, (v.x + v.width * 0.5) + camera.x, (v.y + v.height * 0.5) + camera.y)
				e.speedX = ({-2, -2, 2, 2})[i]
				e.speedY = ({-3, 3, -3, 3})[i]
                		e.x = e.x - e.width * 0.5
				e.y = e.y - e.height * 0.5
			end

			shouldRender = true
			totalCoins = v.amount
			oldCoins = Misc.coins()

			table.remove(drawnBlocks, k)
			Misc.unpause()
		end

		Graphics.drawBox{
			texture = settings.drawnBlock,
			x = v.x + v.width*0.5,
			y = v.y + v.height*0.5,
			width = v.width,
			height = v.height,
			priority = 5,
			sceneCoords = false,
			centered = true,
		}
	end
end

return coinCounter