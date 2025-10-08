local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local redirector = require("redirector")

local flipPanel = {}
local blockID = BLOCK_ID

local flipPanelSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 
	passthrough = false, 
	bumpable = true, 

	-- Custom

	pathID = (blockID + 1),
	outputBlockID = (blockID + 1),

	panelSFX = Misc.resolveSoundFile("flip-panel"),
	switchSFX = 32,
}

blockManager.setBlockSettings(flipPanelSettings)

function flipPanel.onInitAPI()
	blockManager.registerEvent(blockID, flipPanel, "onTickBlock")
	blockManager.registerEvent(blockID, flipPanel, "onCameraDrawBlock")
	registerEvent(flipPanel, "onBlockHit")
end

local function getRedirector(w, id)
	for _,b in ipairs(BGO.getIntersecting(w.x, w.y, w.x + w.width, w.y + w.height)) do
		if b.id ~= id then
        		if b.id == redirector.TERMINUS then
            			return -1
        		else
            			return redirector.VECTORS[b.id]
        		end
		end
	end

	return nil
end

local function spawnPanel(v, b, data, config)
	local w = Block.spawn(config.outputBlockID, b.x + (b.width / 2), b.y + (b.height / 2))
	w.x = w.x - (w.width / 2)
	w.y = w.y - (w.height / 2)

	if data.dir then
		w.x = w.x + (w.width * data.dir.x)
		w.y = w.y + (w.height * data.dir.y)
	end

	local settings = v.data._settings

	w.data.lerp = 0
	w.data.flipPlaced = true
	w.data.timer = (settings.panelLifetime or 400)

        w.layerName = v.layerName
	data.path = w
	table.insert(data.panels, w)

	local redir = getRedirector(w, config.pathID)
	if redir then
		if redir == -1 then
			data.path = nil
		else
			data.dir = redir
		end
	end

	if not blockutils.isInActiveSection(w) then
		data.path = nil
	end

	if config.panelSFX then
		SFX.play(config.panelSFX)
	end
end

function flipPanel.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local config = Block.config[v.id]
	local settings = v.data._settings

	data.activated = data.activated or false
	data.timer = data.timer or 0
	data.panels = data.panels or {}

	local flipTime = (settings.panelFlipTime or 25)

	if data.activated then
		data.timer = data.timer + 1
		if data.path and data.path.isValid then
			if data.timer % flipTime == 0 then
				spawnPanel(v, data.path, data, config)
			end
		else
			if #data.panels <= 0 then
				data.activated = false
				blockutils.bump(v)

				if config.switchSFX then
					blockutils.playSound(v.id, config.switchSFX)
				end
			end
		end
	else
		data.timer = 0
		data.timer2 = 0
		data.dir = nil
		data.path = nil
	end

        for k,b in ipairs(data.panels) do
		if not b.isValid then 
			table.remove(data.panels, k)
		end
	end

	-- Text.print(#data.panels, 0, 0)
end

function flipPanel.onBlockHit(event, v, fromUpper, p)
	local data = v.data
	local config = Block.config[v.id]
	local settings = v.data._settings

	if v.id == BLOCK_ID then
		if not data.activated then
			data.activated = true
			if config.switchSFX then
				blockutils.playSound(v.id, config.switchSFX)
			end

    			for _,b in ipairs(BGO.get({config.pathID})) do
				local pathSettings = b.data._settings
				
				if not b.isHidden and not b.layerObj.isHidden then
					if pathSettings.index and pathSettings.index > 0 then
						if settings.index and settings.index > 0 and settings.index == pathSettings.index then
							spawnPanel(v, b, data, config)
						end
					end
				end
			end
		end
	end
end

function flipPanel.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height) or not blockutils.hiddenFilter(v) then return end

	local data = v.data
    	local config = Block.config[v.id]

    	local frame = math.floor((lunatime.drawtick() / config.framespeed) % config.frames)
	local img = Graphics.sprites.block[v.id].img
    	local priority = -64

	Graphics.drawBox{
		texture = img,
		x = v.x + v.width * 0.5,
		y = v.y + v.height * 0.5 + v:mem(0x56,FIELD_WORD),
		width = v.width,
		height = v.height,
		sourceX = ((data.activated and 1) or 0) * v.width,
		sourceY = frame * v.height,
		sourceWidth = v.width,
		sourceHeight = v.height,
		sceneCoords = true,
		centered = true,
		priority = priority,
	}

	blockutils.setBlockFrame(v.id, -1000)
end

return flipPanel