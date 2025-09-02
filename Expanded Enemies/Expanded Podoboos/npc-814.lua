local npcManager = require("npcManager")
local rng = require("rng")
local waterleaper = require("npcs/AI/waterleaper")

local trouter = {}

--***********************************
--  DEFAULTS AND NPC CONFIGURATION  *
--***********************************

local npcID = NPC_ID;

function trouter.onInitAPI()
	waterleaper.register(npcID)

	npcManager.registerEvent(npcID, trouter, "onTickNPC");
end
local trouterData = {}

trouterData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 18, 
	gfxheight = 16, 
	width = 16, 
	height = 18, 
	frames = 4,
	framespeed = 8, 
	framestyle = 0,
	score = 2,
	jumphurt = 1,
	spinjumpsafe=true,
	noblockcollision = 1,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	nowaterphysics=true,
	speed=0,
	--lua only
	--death stuff
	resttime=120,
	type=waterleaper.TYPE.LAVA,
	sound=16,
	effect=13,
	down=waterleaper.DIR.RIGHT,
	lightradius=64,
    lightbrightness=1,
    lightcolor=Color.orange,
	ishot = true,
	durability = -1,
    gravitymultiplier = 1,
    jumpspeed = 8,
    friendlyrest = false
})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL}, 
{[HARM_TYPE_PROJECTILE_USED]=10,
[HARM_TYPE_NPC]=10,
[HARM_TYPE_TAIL]=10,
[HARM_TYPE_HELD]=10});



--************
--  TROUTER  *
--************

function trouter.onNPCHarm(ev,v,rsn,p)
	if v.id ~= npcID or p == nil then return end
	if rsn == 8 and p:mem(0x50, FIELD_BOOL) then
		ev.cancelled = true
	end
end

function trouter.onTickNPC(self)
	if Defines.levelFreeze then
		return
	end

	if self:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end

	local data = self.data._basegame

	-- Manage animation
	local framespeed = npcManager.getNpcSettings(self.id).framespeed

	self.animationTimer = 500
	if data.animTimer == nil then
		data.animTimer = 0
		data.mirror = false
	end
	data.animTimer = data.animTimer + 1
	if  data.animTimer >= framespeed  then
		data.animTimer = 0
		data.mirror = not data.mirror
		if data.state ~= waterleaper.STATE.RESTING then
			local offsetX = 0
			if self.speedX < 0 then
				offsetX = self.width
			end
			local e = Effect.spawn(265, self.x + offsetX, self.y + rng.random(4, self.height - 4))
			e.speedX = self.speedX * 0.15
		end
	end

	local animFrame = 1
	if  self.speedX > 0  and  not isHeld  and  not isThrown  then
		animFrame = animFrame + 2
	end
	if  data.mirror  then
		animFrame = animFrame + 1
	end
	if  self.direction == DIR_RIGHT  then
		animFrame = animFrame - 2
	end

	self.animationFrame = animFrame
end

return trouter;