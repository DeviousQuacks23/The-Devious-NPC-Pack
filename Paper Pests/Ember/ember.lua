local npcManager = require("npcManager")
local redirector = require("redirector")
local npcutils = require("npcs/npcutils")

-- Code taken from MegaDood's Flitter, thanks to Marioman2007 for help with the animation and sprites by Neopolis

local ember = {}

function ember.register(npcID)
	npcManager.registerEvent(npcID, ember, "onTickEndNPC")
end

local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

local function variant1(v, data, settings)
local myplayer=Player.getNearest(v.x,v.y)
	data.w = 11 * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	if math.abs(v.y-myplayer.y) < 512 and math.abs(v.x-myplayer.x) < 470 then
		if v.x < myplayer.x then
			v.direction = 1
		else
			v.direction = -1
		end
	end
		if data.timer % 10 == 0 then
			v.speedY = data.w * sin(data.w*data.timer)
		end
end

local function variant2(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * data.w * cos(data.w*data.timer)
end

local function variant3(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * data.w * cos(data.w*data.timer)
end

local function variant4(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant5(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer - 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end


local function variant6(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer / 2)
	v.speedY = settings.aamplitude * data.w * sin(data.w*data.timer)
end

local function variant7(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * data.w * cos(data.w*data.timer / 2)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant8(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * -data.w * cos(data.w*data.timer / 2)
	v.speedX = settings.aamplitude * data.w * sin(data.w*data.timer)
end

local function variant9(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * data.w * cos(data.w*data.timer / 2)
	v.speedX = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant10(v, data, settings)
	for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
		if redirector.VECTORS[bgo.id] then -- If this is a redirector and has a speed associated with it
			local redirectorSpeed = redirector.VECTORS[bgo.id]*settings.aspeed -- Get the redirector's speed and make it match the speed in the NPC's settings		
			-- Now, just put that speed from earlier onto the NPC
			v.speedX = redirectorSpeed.x
			v.speedY = redirectorSpeed.y
			if settings.aspeed <= -0.1 then
			v.speedX = -redirectorSpeed.x
			v.speedY = -redirectorSpeed.y
			end
		elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
			-- Simply make the NPC stop moving
			v.speedX = 0
			v.speedY = 0
		end
	end
end

function ember.onTickEndNPC(v)
	local data = v.data
	local settings = v.data._settings
	data.algorithm = settings.algorithm
	data.movetimer = data.movetimer or 0
	
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		if v.despawnTimer <= 0 then
			data.movetimer = 0
		end
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.shoottimer = data.shoottimer or 0
	end

	--Makes it so the NPC begins moving if you come back to it on variant 6 and 7 and data.timer is set to its original postion for some settings.
	if math.abs((player.x + 0.5 * player.width) - (v.x + 0.5 * v.width))<436 then
		data.movetimer = data.movetimer + 1
		if data.movetimer == 1 then
				if settings.algorithm ==5 then
					v.speedX = settings.aspeed * v.direction
				elseif settings.algorithm ==6 then
					v.speedY = settings.aspeed
				end
			end
		end	
		
	if settings.algorithm == 0 then
		variant1(v, data, settings)
	elseif settings.algorithm == 1 then
		variant2(v, data, settings)
	elseif settings.algorithm == 2 then
		variant3(v, data, settings)
	elseif settings.algorithm == 3 then
		variant4(v, data, settings)
	elseif settings.algorithm == 4 then
		variant5(v, data, settings)
	elseif settings.algorithm == 7 then
		variant6(v, data, settings)
	elseif settings.algorithm == 8 then
		variant7(v, data, settings)
	elseif settings.algorithm == 9 then
		variant8(v, data, settings)
	elseif settings.algorithm == 10 then
		variant9(v, data, settings)
	elseif settings.algorithm == 5 or settings.algorithm == 6 then
		variant10(v, data, settings)
	end

        data.shoottimer = data.shoottimer + 1
        local shootAnimTime = 32
        local animFrame = math.floor(data.timer / NPC.config[v.id].framespeed) % (NPC.config[v.id].frames/2)

        if data.shoottimer >= NPC.config[v.id].shootTime - shootAnimTime then
        	animFrame = animFrame + NPC.config[v.id].frames/2
        end

	if data.shoottimer >= NPC.config[v.id].shootTime then
		local n = NPC.spawn(NPC.config[v.id].fireballID, v.x, v.y)			
		SFX.play(18)
		data.shoottimer = 0
        end

        v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = animFrame})
end

return ember