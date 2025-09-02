local npcManager = require("npcManager")
local AI = require("angrySun_ai")

local happyMoonNPC = {}
local npcID = NPC_ID

local happyMoonNPCSettings = table.join({
	id = npcID,

	iscold = true,

	frames = 3,
	angryFrames = 2,

	spawnSparkles = true,
	afterimageColour = Color.yellow,

	projectileNPC = 0,
	nohurt=true,

	preSwoopSFX = Misc.resolveFile("happy-moon.ogg"),
	swoopSFX = Misc.resolveFile("happy-moon-swoop.ogg"),

	killNPCs = false,

	-- Moon-exclusive configs

	enemyEffect = 935,
	clearSFX = Misc.resolveFile("happy-moon-clear.ogg"),

	moonFunction = (function(v, p, data, cfg)
		local cam = Camera.get()[p.idx]
		if cam == nil then
			cam = camera
		end

		for _,n in ipairs(NPC.get()) do
			if n.x + n.width > cam.x and n.x - n.width < cam.x + cam.width and n.y + n.height > cam.y and n.y - n.height < cam.x + cam.height then -- If onscreen
				if not n.isHidden and not n.friendly and NPC.HITTABLE_MAP[n.id] and not NPC.POWERUP_MAP[n.id] and not NPC.COLLECTIBLE_MAP[n.id] then
                        		local e = Effect.spawn(cfg.enemyEffect, n.x + n.width * 0.5, n.y + n.height * 0.5)
                        		e.x = e.x - e.width * 0.5
                        		e.y = e.y - e.height * 0.5

					n:kill(9)
				end
			end
		end

		if cfg.clearSFX then SFX.play(cfg.clearSFX) end
                local e = Effect.spawn(cfg.enemyEffect, v.x + v.width * 0.5, v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
		v:kill(9)
	end),
}, AI.sharedSettings)

npcManager.setNpcSettings(happyMoonNPCSettings)

AI.register(npcID, false)

return happyMoonNPC