local blockManager = require("blockManager")

-- Editor symbol based on sprites by Smuglutena

local smokeAndMirrors = {}
local blockID = BLOCK_ID

blockManager.setBlockSettings({
	id = blockID,

	frames = 1,
	framespeed = 8,

	sizable = true, 
	passthrough = true, 
})

function smokeAndMirrors.onInitAPI()
	Graphics.sprites.block[blockID].img = Graphics.loadImageResolved("stock-0.png")
end

return smokeAndMirrors