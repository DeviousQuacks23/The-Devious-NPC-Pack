local npcManager = require("npcManager")

local egg = {}
local deathEffectID = (755)

local npcID = NPC_ID

npcManager.setNpcSettings({
	id=npcID,
	
	width=64,
	
	height=48,
	gfxheight=48,
	
	gfxwidth=64,
	
	frames=1,
	
	jumphurt=true,
	npcblock=false,
	
	playerblocktop = true,
	npcblocktop = true,
	
	grabtop = true,
	nogravity = false,

	noblockcollision=true,
	nowalldeath = true,
	
	nofireball=true,
	noiceball = true,
	noyoshi = true,
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SWORD]=10,
	}
);

function egg.onInitAPI()
	npcManager.registerEvent(npcID, egg, "onTickEndNPC")
end	

function egg.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if not data.initialized then
		data.initialized = true
                data.gravity = false
	end

	if v.forcedState > 0 then return end

	if v.heldIndex ~= 0 or v.isProjectile then data.gravity = true end

        if data.gravity then
		-- Apply stationary movement

		if v.speedX > 0 then
			v.speedX = v.speedX - 0.05
		elseif v.speedX < 0 then
			v.speedX = v.speedX + 0.05
		end
		
		if v.speedX >= -0.05 and v.speedX <= 0.05 then
			v.speedX = 0
		end

		if v.speedY >= -Defines.npc_grav and v.speedY <= Defines.npc_grav then
			if v.speedX > 0 then
				v.speedX = v.speedX - 0.3
			elseif v.speedX < 0 then
				v.speedX = v.speedX + 0.3
			end
			
			if v.speedX >= -0.3 and v.speedX <= 0.3 then
				v.speedX = 0
			end
		end

		if v.isProjectile then 
			v.collisionGroup = "customBirdoEggs"
			Misc.groupsCollide["customBirdoEggs"][""] = false -- Disable collision

			-- Since we disabled collision, we'll have to re-add projectile logic
            		for _,n in ipairs(NPC.getIntersecting(v.x + 8, v.y + 8, v.x + v.width - 8, v.y + v.height - 8)) do
            			if n.idx ~= v.idx and not n.isHidden and not n.friendly and not v.friendly and NPC.HITTABLE_MAP[n.id] then
                    			n:harm(3)
		    			v:harm(4)
            			end
	    		end
		end
	else
        	v.speedX = 4 * v.direction
        	v.speedY = -Defines.npc_grav
        end

	if v.heldIndex ~= 0 or v.isProjectile then return end

	-- Collide with walls

        local hit = false

	local function solidNPCFilter(v) -- Filter for Colliders.getColliding to only return NPCs that are solid to NPCs
    		return (not v.isGenerator and not v.isHidden and not v.friendly and (NPC.config[v.id] and NPC.config[v.id].npcblock))
	end

        -- Account for blocks
        for _,w in ipairs(Colliders.getColliding{a = v, b = Block.SOLID.. Block.PLAYER, btype = Colliders.BLOCK}) do
		if not w.isHidden and not w:mem(0x5A, FIELD_BOOL) then
            		hit = true
		end
        end
        
        -- Account for NPCs
        hit = hit or (#Colliders.getColliding{a = v, btype = Colliders.NPC, filter = solidNPCFilter} > 0)

        if hit then
        	v:kill(HARM_TYPE_OFFSCREEN)
                local e = Effect.spawn(deathEffectID, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
        	e.speedX = -2.75 * v.direction
        	e.speedY = -5.5
        end
end

return egg