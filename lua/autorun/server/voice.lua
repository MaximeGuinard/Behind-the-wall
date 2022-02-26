local doorsClass = {
	["prop_door_rotating"] = true,
	["func_door_rotating"] = true,
	["func_door"] = true,
	["prop_dynamic"] = true,
}

local texturesExeptions = {
	["maps/rp_rockford_french_v4b/ocrp/urban/window3_-8033_-5783_40"] = true,
	["METAL/METALBAR001C"] = true,
	["TOOLS/TOOLSNODRAW"] = true,
}

local function DoorIsClose(ent)
	if ent:GetClass() == "prop_door_rotating" then
		if ent:GetSaveTable().m_eDoorState == 0 then
			return true
		else
			return false
		end	
	end	
	
	if ent:GetClass() == "func_door_rotating" or ent:GetClass() == "func_door" then
		if ent:GetSaveTable().m_toggle_state == 1 then
			return true
		else
			return false
		end	
	end

	if ent:GetClass() == "prop_dynamic" then
		if ent:GetParent() and  ent:GetParent():IsValid() then
			if ent:GetParent():GetSaveTable().m_toggle_state == 1 then
				return true
			else
				return false
			end		
		end	
	end
	return false
end

function calcPlyCanHearPlayerVoice(listener)
    if not IsValid(listener) then return end
	
    listener.DrpCanHear = listener.DrpCanHear or {}
    for _, talker in pairs(player.GetAll()) do
		if listener != talker then
			if listener:GetPos():Distance(talker:GetPos()) < 330 then
				local traceinfo = {}
				traceinfo.start = listener:GetPos() + Vector(0,0,50)
				traceinfo.endpos = talker:GetPos() + Vector(0,0,50)
				traceinfo.filter = listener
				local trace = util.TraceLine(traceinfo)
				
				if texturesExeptions[trace.HitTexture] then
					listener.DrpCanHear[talker] = true
					continue
				end
				if listener:IsLineOfSightClear(talker) then
					if trace.Entity then
						if trace.Entity:IsValid() and doorsClass[trace.Entity:GetClass()] then
							listener.DrpCanHear[talker] = !DoorIsClose(trace.Entity)
							continue
						end
						if string.find(string.lower(trace.HitTexture), "glass") or string.find(trace.HitTexture, "ocrp") then
							listener.DrpCanHear[talker] = false
							continue
						end
					end
					listener.DrpCanHear[talker] = true
				else
					if trace.Entity and trace.Entity:IsValid() and doorsClass[trace.Entity:GetClass()] then
						listener.DrpCanHear[talker] = !DoorIsClose(trace.Entity)
						continue
					end
					listener.DrpCanHear[talker] = false
				end	
			else
				listener.DrpCanHear[talker] = false
			end
		end
    end
end

hook.Add("PostGamemodeLoaded", "AdvancedDarkRPCanHearVoice", function()
	hook.Add("PlayerInitialSpawn", "DarkRPCanHearVoice", function(ply)
		timer.Create(ply:UserID().."DarkRPCanHearPlayersVoice", 0.5, 0,function() 
			
			local succ, err = pcall( function() calcPlyCanHearPlayerVoice(ply) end )
			if not succ then
				file.Append( "voipfail.txt", err.."\n")
			end
			
		end)
	end)
	hook.Add("PlayerDisconnected", "DarkRPCanHearVoice", function(ply)
		if not ply.DrpCanHear then return end
		for k,v in pairs(player.GetAll()) do
			if not v.DrpCanHear then continue end
			v.DrpCanHear[ply] = nil
		end
		timer.Remove(ply:UserID().."DarkRPCanHearPlayersVoice")
	end)