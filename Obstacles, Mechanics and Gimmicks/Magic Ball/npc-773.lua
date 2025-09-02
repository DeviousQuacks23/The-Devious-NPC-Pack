local npcManager = require("npcManager")
local AI = require("magicBall_ai")

local ball = {}
local npcID = NPC_ID

local ballSettings = table.join({
	id = npcID,

	gfxwidth = 36,
	gfxheight = 56,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 12,

	frames = 4,
	framestyle = 1,
	framespeed = 4, 

        isExplosive = true,
},AI.sharedSettings)

npcManager.setNpcSettings(ballSettings)
AI.register(npcID)

function ball.onInitAPI()
	Cheats.register("rainingballs",{
		isCheat = true,
		activateSFX = 63,
		aliases = {"lemmyfight","bombderby"},
		onActivate = (function() 
                        for k,l in ipairs(Player.get()) do
                                for i = 1, 10 do
                                        lakitu = NPC.spawn(284, l.x - (32 * i), l.y - (64 * i), l.section, false)
                                        lakitu.ai1 = npcID
                                end
                        end
			return true
		end)
	})
end

return ball