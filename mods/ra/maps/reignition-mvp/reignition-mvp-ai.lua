--[[
   Copyright (c) The OpenRA Developers and Contributors
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

SovietsActivated = false
InfantryWave = 0
VehicleWave = 0
IdlingTanks = { tank1, tank2, tank3, tank4, tank5, tank6, tank7, tank8 }

InfantryDelays =
{
	easy = DateTime.Seconds(120),
	normal = DateTime.Seconds(90),
	hard = DateTime.Seconds(65)
}

VehicleDelays =
{
	easy = DateTime.Seconds(150),
	normal = DateTime.Seconds(110),
	hard = DateTime.Seconds(85)
}

InfantryWaves =
{
	{ "e1", "e1", "e2" },
	{ "e1", "e1", "e1", "e2" },
	{ "e1", "e2", "e2", "e4" }
}

VehicleWaves =
{
	{ "3tnk", "3tnk" },
	{ "3tnk", "v2rl" },
	{ "3tnk", "3tnk", "v2rl" }
}

SendAttack = function(units)
	Utils.Do(units, function(unit)
		unit.Patrol({ WeaponMeetPoint.Location, MCVStopLocation.Location }, false)
		IdleHunt(unit)
	end)
end

ProduceInfantry = function()
	if SovietBarracks.IsDead or SovietBarracks.Owner ~= USSR then
		return
	end

	InfantryWave = InfantryWave + 1
	local wave = InfantryWaves[((InfantryWave - 1) % #InfantryWaves) + 1]
	USSR.Build(wave, function(units)
		SendAttack(units)
	end)

	Trigger.AfterDelay(InfantryDelays[Difficulty], ProduceInfantry)
end

ProduceVehicles = function()
	if WeaponsFactory.IsDead or WeaponsFactory.Owner ~= USSR then
		return
	end

	VehicleWave = VehicleWave + 1
	local wave = VehicleWaves[((VehicleWave - 1) % #VehicleWaves) + 1]
	USSR.Build(wave, function(units)
		SendAttack(units)
	end)

	Trigger.AfterDelay(VehicleDelays[Difficulty], ProduceVehicles)
end

PrepareDefenders = function()
	Utils.Do({ TechLab1, TechLab2, TechLab3, WeaponsFactory, SovietConyard }, function(building)
		Trigger.OnDamaged(building, function()
			Utils.Do(IdlingTanks, function(unit)
				if not unit.IsDead then
					unit.Hunt()
				end
			end)

			if building.Owner == USSR and building.Health < building.MaxHealth * 3/4 then
				building.StartBuildingRepairs()
			end
		end)
	end)
end

ActivateAI = function()
	if SovietsActivated then
		return
	end

	SovietsActivated = true
	USSR.Cash = 6000
	WeaponsFactory.RallyPoint = WeaponMeetPoint.Location
	PrepareDefenders()
	ProduceInfantry()
	Trigger.AfterDelay(DateTime.Seconds(60), ProduceVehicles)
	Media.DisplayMessage(UserInterface.GetFluentMessage("reignition-enemy-activated"))
end
