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
    -- call our hook when a player stops moving
    hook.Add("FinishMove", "TTT2AmbusherFinishedMoving", function()
        -- get all living players
        local plys = util.GetActivePlayers()
        -- sort through players until we find the ambusher
        for i = 1, #plys do
            -- check if the current player, i, is an ambusher
            local currPly = plys[i]
            if currPly:GetSubRole() == ROLE_AMBUSHER then
                -- IFF ambusher is moving
                if currPly:GetVelocity():LengthSqr() > 0 then
                    for j = 1, #plys do
                        -- remove marker vision from all players when you start moving
                        plys[j]:RemoveMarkerVision("ambusher_target")
                    end
                -- IFF ambusher is still
                else
                    -- iterate through players again
                    for j = 1, #plys do
                        local target = plys[j]
                        -- compare their distance to the ambusher
                        if(currPly:GetPos():DistToSqr(target:GetPos()) < 500 * 500) then
                            -- add marker vision to nearby players if they are not traitors.
							if not (target:GetTeam() == "traitors") and (target:Alive()) then
								local mvObject = target:AddMarkerVision("ambusher_target")
								mvObject:SetOwner(ROLE_AMBUSHER)
								mvObject:SetVisibleFor(VISIBLE_FOR_ROLE)
								mvObject:SyncToClients()
							else
								-- remove marker vision from traitors (they never got it) and dead players (they might have it)
								target:RemoveMarkerVision("ambusher_target")
							end
                        else
                            -- remove marker vision from players not in range (i.e. they run away from you)
                            target:RemoveMarkerVision("ambusher_target")
                        end
                    end
                end
            end
        end
    end)
-- end of if SERVER then
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