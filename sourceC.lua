local sx,sy = guiGetScreenSize()
local oX, oY = 1920, 1080
local xF = 0.7


--if fileExists("sourceC.lua") then
	--fileDelete("sourceC.lua")
--end


local hudW, hudH = 256, 256
local speedoTarget = dxCreateRenderTarget(hudW, hudH, true)
local currentVehicle
local textures = {
	speedo = dxCreateTexture("files/speedo.png", "dxt5"),
	rpm = dxCreateTexture("files/rpm.png", "dxt5"),
	text = dxCreateTexture("files/text.png", "dxt5"),
	lines = dxCreateTexture("files/lines.png", "dxt5"),
	lamp = dxCreateTexture("files/lamp.png", "dxt5"),
	index_jobb = dxCreateTexture("files/index_jobb.png", "dxt5"),
	index_bal = dxCreateTexture("files/index_bal.png", "dxt5"),
	handbrake = dxCreateTexture("files/handbrake.png", "dxt5"),
	door = dxCreateTexture("files/door.png", "dxt5"),
	indicator = dxCreateTexture("files/indicator.png", "dxt5"),
	fuelindicator = dxCreateTexture("files/fuelindicator.png", "dxt5"),
	fuelbase = dxCreateTexture("files/fuelbase.png", "dxt5"),
	fuelnum = dxCreateTexture("files/fuelnum.png", "dxt5"),
	icon = dxCreateTexture("files/icon.png", "dxt5"),
	seatbelt0 = dxCreateTexture("files/seatbelt0.png", "dxt5"),
	seatbelt1 = dxCreateTexture("files/seatbelt1.png", "dxt5"),
	circle = dxCreateTexture("files/circle.png", "dxt5"),
}



function getVehicleSpeed()
    if currentVehicle then
        local vx, vy, vz = getElementVelocity(currentVehicle)
        return math.sqrt(vx^2 + vy^2 + vz^2) * 187.5
    end
    return 0
end


function getVehicleGear()
	if getElementData(currentVehicle, "veh:ManualGear") then
		local controller = getVehicleController(currentVehicle)
		if controller == localPlayer then
			return getPlayerGear()
		else
			return tonumber(getElementData(currentVehicle, "veh:Gear")) or 0
		end
    else
		return tonumber(getVehicleCurrentGear(currentVehicle))
    end
end

function getRPM(maxW)
	local gear = getVehicleGear()
	local speed = getVehicleSpeed()
	if gear == 0 then
		gear = 1
		maxW = maxW/2
	end
	local rpm = math.floor((speed/gear)*1.1)
	if rpm > maxW then
		rpm = maxW
	end
	return rpm, math.floor(speed)
end

function getFormattedVehicleGear()
	local gear = getVehicleGear()
	if (gear > 0) then
		return gear
	else
		return "R"
	end
end

local lastBlinkTick = 0
local fuelCache = -1
local speedoFont = dxCreateFont("files/bitsu.ttf", 8)
local speedoFontBig = dxCreateFont("files/bitsu.ttf", 20)
local rpmTemp = 0
local rpmMax = 115
local widget = nil
local lampR, lampG, lampB = 0,0,0


local drawP = 40
local canDraw = false
local tempomatText = ""
local seefont = dxCreateFont(":sas_hud/files/fonts/Roboto.ttf", 10)
local fuelR, fuelG, fuelB = 255,255,255
function drawSpeedo()
	if not isPedInVehicle(localPlayer) then hideSpeedo() end
	if not getElementData(localPlayer, "enableall") then return end
	if not currentVehicle then
		if isElement(beltSound) then
			stopSound(beltSound)
		end
		setElementData(localPlayer, "seatbelt", false)
		return
	end
	local lampR, lampG, lampB = getVehicleHeadLightColor(currentVehicle)
	local speedcolor = tocolor(lampR,lampG,lampB,255)
	if exports.sas_hud:getNode(13, "showing") or getElementData(localPlayer, "valaszto") then
		local fuelX, fuelY = exports.sas_hud:getNode(13, "x"), exports.sas_hud:getNode(13, "y")
		local vehicleFuelamount = tonumber(getElementData(currentVehicle, "fuel") or 0)
		if vehicleFuelamount < 20 then
			fuelR, fuelG, fuelB = 217, 83, 79
		else
			fuelR, fuelG, fuelB = 255, 255, 255
		end
		if lampR ~= 255 or lampG ~= 255 or lampB ~= 255 then
			fuelR, fuelG, fuelB = lampR, lampG, lampB
		end

		dxDrawImage(fuelX, fuelY, 256, 256, "files/fuelbase.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		dxDrawImage(fuelX, fuelY, 256, 256, textures.fuelnum, 0, 0, 0, tocolor(fuelR, fuelG, fuelB, 255))
		local fuelRotation = 1.8*vehicleFuelamount
		dxDrawImage(fuelX, fuelY, 256, 256, textures.fuelindicator, -90+fuelRotation-1.8, 0, 0, tocolor(255, 255, 255, 255))
	end
	if exports.sas_hud:getNode(16, "showing") or getElementData(localPlayer, "valaszto") then
		local nameX, nameY = exports.sas_hud:getNode(16, "x"), exports.sas_hud:getNode(16, "y")
		dxDrawImage(nameX, nameY, hudW, hudH, textures.circle, 0, 0, 0, tocolor(255, 255, 255, 255))
		local textmsg = exports["sas_vehicle"]:getVehicleNames(getElementModel(currentVehicle)) or "Ismeretlen"
		dxDrawText(textmsg.."#ff9933"..tempomatText, nameX+222, nameY+20-2, nameX+222, nameY+20, tocolor(255,255,255,255), 1, seefont, "right", "top", false,false,false,true)
	end

	dxSetRenderTarget(speedoTarget, true)

	if exports.sas_hud:getNode(12, "showing") or getElementData(localPlayer, "valaszto") then
		local kocsispeed = getVehicleSpeed()
		local rpm, speed = getRPM(rpmMax)
		if (isVehicleOnGround(currentVehicle)) then
			if(rpm~=rpmTemp and math.abs(rpm-rpmTemp)>2)then
				if(rpm > rpmTemp)then
					rpmTemp = rpmTemp + math.ceil((rpm - rpmTemp) * 0.1)
				else
					rpmTemp = rpmTemp - math.ceil((rpmTemp - rpm) * 0.1)
				end
			end
		else
			if(rpmTemp>0)then
				rpmTemp = rpmTemp - (rpmTemp*0.05)
			end
		end
			if(rpmTemp<1)then
				rpmTemp = 1
			end

			for i=0, kocsispeed*0.7 do
				dxDrawImage(0, 0, 256, 256, textures.rpm, i, 0, 0, speedcolor)
			end
			dxDrawImage(0, 0, hudW, hudH, textures.indicator, -131+kocsispeed*0.7, 0, 0, tocolor(255,255,255,255))

		dxDrawText(speed, hudW, 200, 0, 0, tocolor(255,255,255,240), 1*xF, speedoFontBig, "center")
		dxDrawText("km/h", hudW, 228, 0, 0, tocolor(255,255,255,240), 1.2*xF, speedoFont, "center")

		dxDrawText(getFormattedVehicleGear(), hudW+65, 158*xF+10, 0, 0, tocolor(255,255,255,240), 0.6*xF, speedoFontBig, "center")
	end

	dxSetRenderTarget()

	if exports.sas_hud:getNode(12, "showing") or getElementData(localPlayer, "valaszto") then
		local x,y = exports.sas_hud:getNode(12, "x"), exports.sas_hud:getNode(12,"y")
		dxDrawImage(x, y, hudW, hudH, textures.lines, 0, 0, 0, tocolor(0, 0, 0, 255))

		dxDrawImage(x, y, hudW, hudH, "files/speedo.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		dxDrawImage(x, y, hudW, hudH, textures.seatbelt0, 0, 0, 0, tocolor(255, 255, 255, 255))
		dxDrawImage(x, y, hudW, hudH, textures.text, 0, 0, 0, tocolor(lampR, lampG, lampB, 255))
		dxDrawImage(x, y, hudW, hudH, speedoTarget, 0)

		dxDrawText("8.5 km", x+110, y+80, hudW, hudH, tocolor(60,60,60,200), 1.3*xF, seefont)

		if not getElementData(localPlayer, "seatbelt") and canDraw then
			dxDrawImage(x, y, hudW, hudH, "files/seatbelt1.png", 0)
		end
	end
	if exports.sas_hud:getNode(14, "showing") or getElementData(localPlayer, "valaszto") then
		local x2,y2 = exports.sas_hud:getNode(14, "x"), exports.sas_hud:getNode(14,"y")
		dxDrawImage(x2, y2, hudW, hudH, "files/icon.png")
		if getVehicleOverrideLights(currentVehicle) == 2 then
			dxDrawImage(x2,y2,hudW,hudH, "files/lamp.png")
		end
		if isVehicleLocked(currentVehicle) then
			dxDrawImage(x2,y2,hudW,hudH, "files/door.png")
		end
		if isElementFrozen(currentVehicle) then
			dxDrawImage(x2,y2,hudW,hudH, "files/handbrake.png")
		end
		if getElementData(currentVehicle, "indexR") then
			dxDrawImage(x2,y2,hudW,hudH, "files/index_jobb.png")
		end
		if getElementData(currentVehicle, "indexL") then
			dxDrawImage(x2,y2,hudW,hudH, "files/index_bal.png")
		end
	end
end

function showSpeedo()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle then
		currentVehicle = vehicle
		local t = getVehicleType(vehicle)
		if t == "Automobile" or t == "Monster Truck" or t == "Quad" or t == "Bike" or t == "Helicopter" or t == "Boat" then
			addEventHandler("onClientRender", root, drawSpeedo)
		end
	end
end

function hideSpeedo()
	removeEventHandler("onClientRender", root, drawSpeedo)
	currentVehicle = nil
	lastBlinkTick = 0
	fuelCache = -1
end

addEventHandler("onClientPlayerVehicleEnter",localPlayer,function(veh, seat)
	showSpeedo()
	if seat == 0 and ccEnabled then
		removeEventHandler("onClientRender", getRootElement(), cc)
		ccEnabled = false
	end
	setElementData(localPlayer, "seatbelt", false)
	beltSound = playSound("files/seatbelt.mp3", true)
	canDraw = true
	if isTimer(timer) then killTimer(timer) end
	timer = setTimer(function()
		if canDraw then
			canDraw = false
		else
			canDraw = true
		end
	end, 600, 0)
	if getElementModel(veh) == 407 then return end
	toggleControl("vehicle_secondary_fire", false)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
	showSpeedo()
end)

addEventHandler("onClientPlayerVehicleExit",localPlayer,function(veh)
	hideSpeedo()
	if isTimer(timer) then killTimer(timer) end
	if isElement(beltSound) then
		stopSound(beltSound)
	end
	if getElementModel(veh) == 407 then return end
	toggleControl("vehicle_secondary_fire", true)
end)

local beltVehicles = {
	["Automobile"] = true,
	["Plane"] = true,
	["Helicopter"] = true,
	["Boat"] = true,
	["Train"] = true,
	["Monster Truck"] = true
}

addEventHandler("onClientKey", root, function(key, pressed)
	if key == "z" and pressed and currentVehicle and beltVehicles[getVehicleType(currentVehicle)] then
		if not getElementData(localPlayer, "seatbelt") then
			setElementData(localPlayer, "seatbelt", true)

			stopSound(beltSound)
			playSound("files/seatbelton.mp3", false)
			triggerServerEvent("sendMeMessageOn", localPlayer)
			if isTimer(timer) then killTimer(timer) end
		else
			triggerServerEvent("sendMeMessageOff", localPlayer)
			setElementData(localPlayer, "seatbelt", false)

			playSound("files/seatbeltoff.mp3", false)
			beltSound = playSound("files/seatbelt.mp3", true)
			canDraw = true
			if isTimer(timer) then killTimer(timer) end
			timer = setTimer(function()
				if canDraw then
					canDraw = false
				else
					canDraw = true
				end
			end, 600, 0)
		end
	end
end)

addEventHandler("onClientElementDestroy", getRootElement(), function()
	if getElementType(source) == "vehicle" then
		setElementData(localPlayer, "seatbelt", false)
	end
end)

addEventHandler("onClientVehicleCollision", root, function(collider, force, bodyPart, x, y, z, nx, ny, nz)
    if source == currentVehicle then
		local fDamageMultiplier = getVehicleHandling(source).collisionDamageMultiplier
		local realDamage = (force*fDamageMultiplier)*0.1

		if realDamage > 15 then
			realDamage = realDamage/3
			if getElementData(localPlayer, "seatbelt") then
				setElementHealth(localPlayer, getElementHealth(localPlayer) - realDamage/2)
			else
				setElementHealth(localPlayer, getElementHealth(localPlayer) - realDamage)
			end
		end
    end
end)


limit = true
key = "c"
allowedTypes = { "Automobile", "Bike", "Boat", "Train" }
local targetSpeedTmp = 0
local basicSpeed = 0

function getElementSpeed(element,unit)
	if (unit == nil) then unit = 0 end
	if (isElement(element)) then
		local x,y,z = getElementVelocity(element)
		if (unit=="mph" or unit==1 or unit =='1') then
			return (x^2 + y^2 + z^2) ^ 0.5 * 100
		else
			return (x^2 + y^2 + z^2) ^ 0.5 * 1.61 * 100
		end
	else
		return false
	end
end

function setElementSpeed(element, unit, speed)
	if (unit == nil) then unit = 0 end
	if (speed == nil) then speed = 0 end
	speed = tonumber(speed)
	local acSpeed = getVehicleSpeed(element, unit)
	if (acSpeed~=false) then
		local diff = speed/acSpeed
		local x,y,z = getElementVelocity(element)
		setElementVelocity(element,x*diff,y*diff,z*diff)
		return true
	else
		return false
	end
end

function in_array(e, t)
	for _,v in pairs(t) do
		if (v==e) then return true end
	end
	return false
end

function round2(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function angle(vehicle)
	local vx,vy,vz = getElementVelocity(vehicle)
	local modV = math.sqrt(vx*vx + vy*vy)

	if not isVehicleOnGround(vehicle) then return 0,modV end
	local rx,ry,rz = getElementRotation(vehicle)
	local sn,cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))
	local cosX = (sn*vx + cs*vy)/modV

	return math.deg(math.acos(cosX))*0.5, modV
end

function getMaxSpeed(vehicle)
	local handlign = getVehicleHandling(vehicle)
	speed = handlign["maxVelocity"]
	return speed
end

ccEnabled = false
targetSpeed = 1
multiplier = 1

local Speed = 0
function cc()
	if (not isElement(currentVehicle)) then
		removeEventHandler("onClientRender", getRootElement(), cc)
		ccEnabled=false
		--outputChatBox( "#EB9532[Tempomat] #ffffff A tempomat sikeresen #D24D57Kikapcsolva#ffffff.", 255,255,255,true)
		return false
	end
	local x,y = angle(currentVehicle)
	if (x<15) then
		local speed = getVehicleSpeed(currentVehicle)
		targetSpeedTmp = speed + multiplier
		if (targetSpeedTmp > targetSpeed) then
			targetSpeedTmp = targetSpeed
		end
		if (targetSpeedTmp > 3) then
			if (getMaxSpeed(currentVehicle) >= targetSpeedTmp) then
				setElementSpeed(currentVehicle, "k", targetSpeedTmp)
			end
		end
	end
end

bindKey(key, "up", function()
	if currentVehicle and localPlayer == getVehicleOccupant(currentVehicle) then
		if getElementHealth(currentVehicle) <= 450 then return end
		if (ccEnabled) then
			removeEventHandler("onClientRender", getRootElement(), cc)
			ccEnabled=false
			tempomatText = ""
		else
			targetSpeed = getVehicleSpeed(currentVehicle)
			if targetSpeed > 4 then
				if (limit) then
					if in_array(getVehicleType(currentVehicle), allowedTypes) then
						tempomatText = " (Tempomat: "..math.floor(targetSpeed).." km/h)"
						addEventHandler("onClientRender", getRootElement(), cc)
						basicSpeed = targetSpeed
						ccEnabled=true
					end
				else
					tempomatText = " (Tempomat: "..math.floor(targetSpeed).." km/h)"
					addEventHandler("onClientRender", getRootElement(), cc)
					ccEnabled=true
					basicSpeed = targetSpeed
				end
			end
		end
	end
end)

addEventHandler( "onClientKey", root, function(button,press)
  if button == "s" or button == "space" or button == "lalt" or button == "w" then
      if (ccEnabled) then
				removeEventHandler("onClientRender", getRootElement(), cc)
				ccEnabled=false
				tempomatText = ""
			end
        return true
	elseif button == "num_sub" and press then
		if (basicSpeed - 10 >= targetSpeed -1) then
			targetSpeed = targetSpeed - 1
			tempomatText = " (Tempomat: "..math.floor(targetSpeed).." km/h)"
		end
	elseif button == "num_add" and press then
		--if (basicSpeed + 10 <= targetSpeed +1) then
			targetSpeed = targetSpeed + 1
			tempomatText = " (Tempomat: "..math.floor(targetSpeed).." km/h)"
		--end
	end
    return false
end )
