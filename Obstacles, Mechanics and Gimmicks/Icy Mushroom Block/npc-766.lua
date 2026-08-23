local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

npcManager.setNpcSettings({
	id = id,
	
	frames = 1,
	framestyle = 0,
	
	jumphurt = true,
	nohurt = true,
	
	grabside = true,
	grabtop = true,
	
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = true,
	
	harmlessgrab=true,
	score = 0,
	
	noiceball = true,
	slippery = true,
	notcointransformable = true,
})

function npc.onTickNPC(v)
	v:mem(0x134, FIELD_WORD, 0)
	
	if v:mem(0x12E, FIELD_WORD) == 29 then
		SFX.play(75)
	end

	if v.collidesBlockLeft or v.collidesBlockRight then
		v.speedX = (v.speedX * 0.35)
	end

        if v.collidesBlockBottom then
                if v.speedX > 0 then
               		v.speedX = math.max(0,v.speedX - 0.35)
                elseif v.speedX < 0 then
                    	v.speedX = math.min(0,v.speedX + 0.35)
                end

        	if v.data.oldSpeedY and v.data.oldSpeedY > 1 then
        		v.speedY = -v.data.oldSpeedY * 0.65
		end
        else
                if v.speedX > 0 then
                    	v.speedX = math.max(0,v.speedX - 0.05)
                elseif v.speedX < 0 then
                    	v.speedX = math.min(0,v.speedX + 0.05)
                end
        end

	v.data.oldSpeedY = v.speedY

        if RNG.randomInt(1, 24) == 1 and not v.isHidden then
                local e = Effect.spawn(80, v.x + RNG.randomInt(0, v.width), v.y + RNG.randomInt(0, v.height))
		e.speedX = RNG.random() * 0.5 - 0.25
		e.speedY = RNG.random() * 0.5 - 0.25
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
        end
end

function npc.onNPCHarm(e, v, r, c)
	if v.id ~= id then return end
	
	if r == HARM_TYPE_SWORD then
		if v:mem(0x12E, FIELD_WORD) <= 0 then
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
			
			v:mem(0x08,	FIELD_BOOL, true)
			v:mem(0x12E, FIELD_WORD, 30)
			v:mem(0x136, FIELD_BOOL, true)
			
			v.speedX = 3 * p.direction
			v.speedY = -5
		end
		
		e.cancelled = true
	elseif r == HARM_TYPE_LAVA then
		Effect.spawn(10, v.x, v.y)
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickNPC')
	registerEvent(npc, 'onNPCHarm')
	registerEvent(npc, 'onPostNPCKill')
	
	npcManager.registerHarmTypes(id,
		{
			HARM_TYPE_SWORD,
			HARM_TYPE_LAVA,
			HARM_TYPE_NPC,
			HARM_TYPE_PROJECTILE_USED,
			HARM_TYPE_HELD,
		}, 
		{
			[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		}
	);
end

-- Fragments and stuff

local spike = require("npcs/ai/smmspike")

-- This function is just to fix   r e d i g i t   issues lol
local function gfxSize(config)
	local gfxwidth  = config.gfxwidth
	if gfxwidth  == 0 then gfxwidth  = config.width  end
	local gfxheight = config.gfxheight
	if gfxheight == 0 then gfxheight = config.height end

	return gfxwidth, gfxheight
end

local function createFragments(id,x,y,rotation)
	local config = NPC.config[id]
	local gfxwidth,gfxheight = gfxSize(config)

	for i=1,4 do
		local nX,nY
		local frameX,frameY

		if i == 1 or i == 3 then
			nX = -(gfxwidth / 4)
			frameX = 1
		else 
			nX = (gfxwidth / 4)
			frameX = 2
		end
		if i == 1 or i == 2 then
			nY = -(gfxheight / 4)
			frameY = 1
		else
			nY = (gfxheight / 4)
			frameY = 2
		end

		local position = vector(x,y) + vector(nX,nY):rotate(rotation)

		table.insert(
			spike.fragments,
			{
				id = id,groupIdx = i,
				x = position.x,y = position.y,
				rotation = rotation,
				speedX = RNG.random(-9,9),
				speedY = RNG.random(-0,-12),
				frameX = frameX,
				frameY = frameY,
			}
		)
	end
end

function npc.onPostNPCKill(v,killReason)
	if v.id ~= id then return end

	local config = NPC.config[v.id]
	local data = v.data

	if killReason ~= HARM_TYPE_OFFSCREEN and killReason ~= HARM_TYPE_LAVA then
		for i=1,RNG.randomInt(1, 4) do
			createFragments(
				v.id,
				v.x + (v.width / 2) + config.gfxoffsetx,
				v.y + (v.height / 2) + config.gfxoffsety,
				data.rotation or 0
			)
		end

		for j = 1, RNG.randomInt(4, 12) do
                	local e = Effect.spawn(80, v.x + v.width * 0.5, v.y + v.height * 0.5)
                	e.x = e.x - e.width * 0.5
                	e.y = e.y - e.height * 0.5
			e.speedX = RNG.random(-8, 8)
			e.speedY = RNG.random(-8, 8)
		end  

		for i = 1, 4 do
			local e = Effect.spawn(74, v.x + v.width * 0.5, v.y + v.height * 0.5)
			e.speedX = ({-3, -3, 3, 3})[i]
			e.speedY = ({-3, 3, -3, 3})[i]
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
		end

		SFX.play("yi_icebreak.ogg")
	end
end

return npc