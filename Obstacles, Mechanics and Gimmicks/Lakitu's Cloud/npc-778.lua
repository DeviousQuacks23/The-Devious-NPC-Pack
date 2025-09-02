local npcManager = require("npcManager")
local yiYoshi
pcall(function() yiYoshi = require("yiYoshi/yiYoshi") end)

if not yiYoshi then
	local klonoa = require("characters/klonoa")
	klonoa.UngrabableNPCs[NPC_ID] = true
end

-- This is an edit of Lakithunder's cloud, made by Mal8rk, with multiplayer handling code taken from FNC's Koopa Troopa Car.

local lakituCloud = {}
local npcID = NPC_ID

local lakituCloudSettings = {
	id = npcID,

	gfxwidth = 52,
	gfxheight = 38,

	width = 48,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 1,
	framespeed = 6,

	foreground = true,

	speed = 1,
	luahandlesspeed = true,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = true,
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

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	lifetime = 1032,
}

npcManager.setNpcSettings(lakituCloudSettings)

function lakituCloud.onInitAPI()
	npcManager.registerEvent(npcID, lakituCloud, "onTickEndNPC")
end

local playerRiding = {}

function lakituCloud.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = config.lifetime
	end

	data.timer = data.timer - 1
        v.despawnTimer = 180

	for _,p in ipairs(Player.get()) do
		if Colliders.bounce(p,v) and p.deathTimer == 0 and p.mount == 0 then
			if playerRiding[v] == nil and not table.contains(playerRiding,p) then
				playerRiding[v] = p
			end
		end
	end

	if playerRiding[v] ~= nil and playerRiding[v] ~= 0 then
		local p = playerRiding[v]

		p.frame = 1
		p.direction = v.direction
		p:mem(0x04,FIELD_WORD, 1)
                p:mem(0x50, FIELD_BOOL, false)
		p.x = v.x + 10
                p.y = v.y - p.height

		if data.timer % 20 == 0 then
			Effect.spawn(131,v.x+8,v.y)
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = 0
		end

		if p.keys.left then
			v.speedX = v.speedX - 0.1
			v.direction = -1
		elseif p.keys.right then
			v.speedX = v.speedX + 0.1
			v.direction = 1
		else
			if v.speedX > 0 then
				v.speedX = v.speedX - 0.25
			else
				v.speedX = v.speedX + 0.25
			end
			
			if v.speedX >= -0.25 and v.speedX <= 0.25 then
				v.speedX = 0
			end
		end

		if p.keys.up then
			v.speedY = v.speedY - 0.1
		elseif p.keys.down then
			v.speedY = v.speedY + 0.1
		else
			if v.speedY > 0 then
				v.speedY = v.speedY - 0.25
			else
				v.speedY = v.speedY + 0.25
			end
			
			if v.speedY >= -0.25 and v.speedY <= 0.25 then
				v.speedY = 0
			end
		end

		v.speedX = math.clamp(v.speedX, -4, 4)
		v.speedY = math.clamp(v.speedY, -4, 4)

		if p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED then
			SFX.play(1)
			p.speedY = -8
			p.speedX = 0
			v.speedX = 0
			playerRiding[v] = nil
			p:mem(0x04,FIELD_WORD, 0)
		end
        else
		v.speedY = math.cos(data.timer / 32) * 0.2
	end

	if data.timer <= 160 then
		if data.timer % 7 <= 3 then
			v.animationFrame = -1
		end
	end

	if data.timer <= 0 then
		v:kill(HARM_TYPE_VANISH)

		if playerRiding[v] ~= nil and playerRiding[v] ~= 0 then
			playerRiding[v].speedX = 0
			playerRiding[v].speedY = 0
			playerRiding[v]:mem(0x04,FIELD_WORD,0)
		end
	end
end

return lakituCloud