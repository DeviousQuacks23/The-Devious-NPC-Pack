local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local paralx2 = require("paralx2")

-- Editor symbol based on sprites by Smuglutena
-- Some code by Marioman2007 and Radiance

local smokeAndMirrors = {}
local blockID = BLOCK_ID

blockManager.setBlockSettings({
	id = blockID,

	frames = 1,
	framespeed = 8,

	sizable = true, 
	passthrough = true, 

	exitWarpSizableID = (blockID + 1),
})

local bgPoses = {}

function smokeAndMirrors.onInitAPI()
	Graphics.sprites.block[blockID].img = Graphics.loadImageResolved("stock-0.png")
	blockManager.registerEvent(blockID, smokeAndMirrors, "onTickBlock")
    	registerEvent(smokeAndMirrors, "onCameraUpdate")
end

function smokeAndMirrors.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

	local config = Block.config[v.id]
	local settings = v.data._settings
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and p:mem(0x15C, FIELD_WORD) <= 0 then
    			for _,b in ipairs(Block.get({config.exitWarpSizableID})) do
				local pathSettings = b.data._settings
				
				if not b.isHidden and not v:mem(0x5A, FIELD_BOOL) and not b.layerObj.isHidden then
					if pathSettings.index and pathSettings.index > 0 then
						if settings.index and settings.index > 0 and settings.index == pathSettings.index then
							local diff = vector((p.x + p.width/2) - (v.x + v.width/2), (p.y + p.height/2) - (v.y + v.height/2))
							local i = vector((diff.x/(v.width/2 + p.width/2) + 1)/2, (diff.y/(v.height/2 + p.height/2) + 1)/2)
							local exitSection = blockutils.getBlockSection(b)

							if settings.doWarpCooldown then p:mem(0x15C, FIELD_WORD, 50) end
							p:teleport(math.lerp(b.x-p.width, b.x+b.width, i.x), math.lerp(b.y-p.height, b.y+b.height, i.y))
							if p.section ~= exitSection then p.section = exitSection end
							if settings.resetSpeed then p.speedX, p.speedY = 0, 0 end

							if settings.affectBG then
    								local bg = p.sectionObj.background
 
								if bg ~= nil then
    									for k, l in ipairs(bg:get()) do
										bgPoses[p.idx] = {}
        									bgPoses[p.idx][l.name] = {
            										layerX  = l.x,
											cameraX = (Camera.get()[p.idx].x or camera.x),
        									}
    									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function smokeAndMirrors.onCameraUpdate()
	for _,p in ipairs(Player.get()) do
    		if bgPoses[p.idx] then
        		local bg = p.sectionObj.background
        
        		for k, l in ipairs(bg:get()) do
            			local pos = bgPoses[p.idx][l.name]
            			local parallaxX = l.parallaxX

            			if parallaxX == nil and l.depth ~= nil then
                			local d = l.depth/paralx2.focus
               				d = d + 1
                			d = 1/(d*d)

					parallaxX = d
            			end

            			l.x = pos.layerX + ((Camera.get()[p.idx].x or camera.x) - pos.cameraX) * parallaxX
        		end

        		bgPoses[p.idx] = nil
		end
    	end
end

return smokeAndMirrors