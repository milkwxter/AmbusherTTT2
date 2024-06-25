if CLIENT then
	hook.Add("TTT2FinishedLoading", "ambusher_init_icon", function()
	STATUS:RegisterStatus("ambusher_damageIncrease", {
		hud = Material("vgui/ttt/dynamic/roles/icon_ambush.vtf"),
		type = "good",
		name = "Ambusher Ability",
		sidebarDescription = "You deal extra damage while standing still and can see players through walls."
	})
	end)
end