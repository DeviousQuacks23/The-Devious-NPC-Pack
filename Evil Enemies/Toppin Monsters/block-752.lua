local blockManager = require("blockManager")
local tJ = require("toppingJumpscare")

local alarmSFX = Misc.resolveFile("toppingJumpscare/alarm.ogg")
local canSoundAlarm = false
local alarmTimer = 0

local alarmSwitch = {}
local blockID = BLOCK_ID

-- No, I will not add the patrollers from DMAS.

local alarmSwitchSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8, 

	bumpable = true,
}

blockManager.setBlockSettings(alarmSwitchSettings)

function alarmSwitch.onInitAPI()
	blockManager.registerEvent(blockID, alarmSwitch, "onTickEndBlock")
	registerEvent(alarmSwitch, "onPostBlockHit")
        registerEvent(alarmSwitch, "onDraw") -- use onDraw to keep the timers going when paused
end

function alarmSwitch.onDraw()
        alarmTimer = alarmTimer - 1
        if alarmTimer <= 0 then
                canSoundAlarm = true
        else
                canSoundAlarm = false
        end
end

function alarmSwitch.onPostBlockHit(v, fromUpper)
	if v.id == BLOCK_ID then
                local data = v.data
                tJ.riseAndShine()
                SFX.play(2)
                if canSoundAlarm then
                        alarmTimer = 450
	                local alarm = SFX.create{
		        x = v.x + v.width*0.5,
		        y = v.y + v.height*0.5,
		        sound = alarmSFX,
                        play = true,
                        loops = 1,
		        parent = v,
		        type = typ,
		        volume = 1,
		        falloffRadius = 320,
		        falloffType = SFX.FALLOFF_LINEAR,
		        sourceRadius = 32,
		        sourceWidth = v.width,
		        sourceHeight = v.height,
		        sourceVector = vector.v2(64, 64)
	                }  
                end
	end
end

function alarmSwitch.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data

	if not data.initialized then
		data.initialized = true
	end
end

return alarmSwitch