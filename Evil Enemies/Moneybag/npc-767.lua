local npcManager = require("npcManager")

local susCoin = {}

local npcID = NPC_ID
local transformID = (npcID + 1)

local susCoinSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 0,
	framespeed = 8, 

	nowaterphysics = false,
	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = true,
	nowalldeath = false, 

	iscoin = true,
	isstationary = true,

	-- Custom Properties

	radius = 160,
	transformID = transformID,
}

npcManager.setNpcSettings(susCoinSettings)

function susCoin.onInitAPI()
	npcManager.registerEvent(npcID, susCoin, "onTickNPC")
end

function susCoin.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.range = Colliders:Circle()
	end

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = config.radius

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        for k,p in ipairs(Player.get()) do
                if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) then
			local ID = v.ai1
			if v.ai1 == 0 then
				ID = config.transformID
			end

			data.initialized = nil
                        v:transform(ID)
			v.speedX = 0
                        v.speedY = -5

		        Animation.spawn(10, v)
                        SFX.play(41)
                end
        end
end

return susCoin