if SERVER then
    AddCSLuaFile()
    resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_ambush.vmt")
end

function ROLE:PreInitialize()
    self.color = Color(70, 6, 60, 255)

    self.abbr = "ambush" -- abbreviation
    self.surviveBonus = 0.5 -- bonus multiplier for every survive while another player was killed
    self.scoreKillsMultiplier = 5 -- multiplier for kill of player of another team
    self.scoreTeamKillsMultiplier = -16 -- multiplier for teamkill
    self.preventFindCredits = false
    self.preventKillCredits = false
    self.preventTraitorAloneCredits = false
    
    self.isOmniscientRole = true

    self.defaultEquipment = SPECIAL_EQUIPMENT -- here you can set up your own default equipment
    self.defaultTeam = TEAM_TRAITOR

    self.conVarData = {
        pct = 0.17, -- necessary: percentage of getting this role selected (per player)
        maximum = 1, -- maximum amount of roles in a round
        minPlayers = 6, -- minimum amount of players until this role is able to get selected
        credits = 1, -- the starting credits of a specific role
        togglable = true, -- option to toggle a role for a client if possible (F1 menu)
        random = 33,
        traitorButton = 1, -- can use traitor buttons
        shopFallback = SHOP_FALLBACK_TRAITOR
  }
end

-- now link this subrole with its baserole
function ROLE:Initialize()
    roles.SetBaseRole(self, ROLE_TRAITOR)
end

-- start super special coding
if SERVER then
    -- call our hook when a player starts to move
    hook.Add("StartMove", "TTT2AmbusherStartedMoving", function()
		print("retard alert")
        -- get all players
        local plys = player.GetAll()

        -- iterate through all players
        for i = 1, #plys do
            -- make sure we only do this for the ambusher role
            if plys[i]:GetSubRole() ~= ROLE_AMBUSHER then continue end

            -- remove damage bonus
            STATUS:RemoveStatus(plys[i], "ambusher_damageIncrease")

            -- iterate through living players
            for j = 1, #plys do
                -- remove marker vision from all players when you start moving 
                plys[j]:RemoveMarkerVision("ambusher_target")
            end
        end
    end)

    -- call our hook when a player stops moving
    hook.Add("FinishMove", "TTT2AmbusherFinishedMoving", function()
        -- get all living players
        local plys = util.GetActivePlayers()
        -- sort through players until we find the ambusher
        for i = 1, #plys do
            -- save current player in for loop
            local currPly = plys[i]

            -- make sure the ply is an ambusher
            if currPly:GetSubRole() ~= ROLE_AMBUSHER then continue end
			
			if currPly:GetVelocity():LengthSqr() > 0 then
				-- iterate through all players
				for i = 1, #plys do
					-- make sure we only do this for the ambusher role
					if plys[i]:GetSubRole() ~= ROLE_AMBUSHER then continue end

					-- remove damage bonus
					STATUS:RemoveStatus(plys[i], "ambusher_damageIncrease")

					-- iterate through living players
					for j = 1, #plys do
						-- remove marker vision from all players when you start moving 
						plys[j]:RemoveMarkerVision("ambusher_target")
					end
				end
			
				-- stop doing math
				return
			end

            -- give him a damage buff
			STATUS:AddStatus(currPly, "ambusher_damageIncrease")

            -- iterate through players again
            for j = 1, #plys do
                -- save plys[j] as a variable to mess with
                local target = plys[j]

                -- compare their distance to the ambusher
                if(currPly:GetPos():DistToSqr(target:GetPos()) > 500 * 500) then
                    -- remove marker vision from players not in range (i.e. they run away from you)
                    target:RemoveMarkerVision("ambusher_target")
                    -- move to next player in the loop
                    continue
                end

                -- add marker vision to nearby players if they are not traitors/jesters or dead
                if target:GetRealTeam() == TEAM_TRAITOR or target:GetRealTeam() == TEAM_JESTER or not target:IsActive() then
                    -- remove marker vision from traitors (they never got it) and dead players (they might have it)
					target:RemoveMarkerVision("ambusher_target")
                    -- move to next player in the loop
                    continue
                end
				
                -- do marker vision
				local mvData, numOfAmbusherMV = target:GetMarkerVision("ambusher_target")
				if(numOfAmbusherMV == -1) then
					local mvObject = target:AddMarkerVision("ambusher_target")
					mvObject:SetOwner(ROLE_AMBUSHER)
					mvObject:SetVisibleFor(VISIBLE_FOR_ROLE)
					mvObject:SyncToClients()
				end
            end
        end
    end)
end

-- actual wallhacks part DONT TOUCH!!!!!!!!!
if CLIENT then
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local materialAmbush = Material("vgui/ttt/dynamic/roles/icon_ambush")

	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionAmbusherTargets", function(mvData)
		local client = LocalPlayer()
		local ent = mvData:GetEntity()
		local mvObject = mvData:GetMarkerVisionObject()

		if not client:IsTerror() or not mvObject:IsObjectFor(ent, "ambusher_target") then return end

		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:AddIcon(materialAmbush)
		mvData:SetTitle(ent:Nick() .. " is nearby.")

		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))
		mvData:AddDescriptionLine(TryT(mvObject:GetVisibleForTranslationKey()), COLOR_SLATEGRAY)
	end)
end

-- change amount of damage for the ambusher when he stands still
hook.Add("EntityTakeDamage", "ttt2_ambusher_standing_damage", function(target, dmginfo)
	-- get the attacker
	local attacker = dmginfo:GetAttacker()

	-- make sure the attacker is valid and also the attacker must be an ambusher
	if not IsValid(target) or not target:IsPlayer() then return end
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if not (attacker:GetRoleString() == "ambusher") then return end
	
	if attacker:GetVelocity():LengthSqr() <= 0 then
		dmginfo:SetDamage(dmginfo:GetDamage() * GetConVar("ttt2_ambusher_standing_dmg_multi"):GetFloat())
	end
end)

-- beautiful convar
CreateConVar("ttt2_ambusher_standing_dmg_multi", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
function ROLE:AddToSettingsMenu(parent)
	local form = vgui.CreateTTT2Form(parent, "header_roles_additional")
	form:MakeSlider({
		serverConvar = "ttt2_ambusher_standing_dmg_multi",
		label = "Damage multiplier when standing still: ",
		min = 1.0,
		max = 2.0,
		decimal = 2
	})
end