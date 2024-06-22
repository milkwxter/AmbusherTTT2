if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_ambush.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(174, 56, 1, 255)

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
  local nearbyPlyTable = {}
  -- call our hook when a player stops moving
  hook.Add("FinishMove", "TTT2AmbusherFinishedMoving", function()
    -- get all living players
    local plys = util.GetAlivePlayers()
    -- sort through players until we find the ambusher
    for i = 1, #plys do
      local currPly = plys[i]
      if currPly:GetSubRole() == ROLE_AMBUSHER then
        -- IF ambusher is moving
        if currPly:GetVelocity():LengthSqr() > 0 then
		  -- reset marker vision
			
          -- reset nearby player table
          nearbyPlyTable = {}
		  
        -- IF ambusher is still
        else
          -- iterate through players again
          for j = 1, #plys do
            target = plys[j]
            -- compare their distance to the ambusher
            if(currPly:GetPos():DistToSqr(target:GetPos()) < 500 * 500) then
                table.insert(nearbyPlyTable, target)
            end
          end
			-- print out all nearby players
			local plyString = ": "
			for k, v in pairs(nearbyPlyTable) do
				plyString = plyString .. v:Nick() .. ", "
			end
			PrintMessage(HUD_PRINTTALK, "NEAR THESE GUYS" .. plyString)
			-- empty table to prevent overflow and crashing the client
			nearbyPlyTable = {}
        end
      end
    end
  end)

-- end of if SERVER then
end