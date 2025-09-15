local npcManager = require("npcManager")

-- Originally written by MrDoubleA
-- Sprites by Sednaiur

local shroom = {}

function shroom.register(npcID)
	npcManager.registerEvent(npcID, shroom, "onTickEndNPC")
end

local function canCollectMushroom(p)
	return (
		p.forcedState == FORCEDSTATE_NONE
		and p.deathTimer == 0
		and not p:mem(0x13C,FIELD_BOOL)
	)
end

function shroom.onTickEndNPC(v)
	if v:mem(0x12C,FIELD_WORD) > 0 then
		local p = Player(v:mem(0x12C,FIELD_WORD))

		if p.isValid and canCollectMushroom(p) then
			-- There's not really a convenient way to just give the player a mushroom so this'll do
			local mushroom = NPC.spawn(NPC.config[v.id].shroomID, p.x + p.width * 0.5, p.y + p.height * 0.5, p.section, false, false)

			mushroom.width = 1
			mushroom.height = 1

			mushroom.animationFrame = -9999

			if v.data.effectLocate then
                        	local e = Effect.spawn(NPC.config[v.id].puffID, v.data.effectLocate.x + v.width * 0.5, v.data.effectLocate.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
			end

			v:kill(HARM_TYPE_VANISH)
			v.animationFrame = -9999
		end
	elseif v:mem(0x12C,FIELD_WORD) == 0 and v:mem(0x138,FIELD_WORD) == 0 and v.collidesBlockBottom and not Defines.levelFreeze then
        	if v.data.oldSpeedY and v.data.oldSpeedY > 1 then
        		v.speedY = -v.data.oldSpeedY * 0.5
                end

		v.speedX = 0
	end

	v.data.effectLocate = vector(v.x, v.y)
	v.data.oldSpeedY = v.speedY
end

return shroom