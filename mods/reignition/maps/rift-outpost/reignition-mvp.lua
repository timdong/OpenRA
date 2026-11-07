--[[
   Copyright (c) The OpenRA Developers and Contributors
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

SovietTechLabs = { TechLab1, TechLab2, TechLab3 }
OpeningAttackers = { BadGuy1, BadGuy2, BadGuy3 }
MissionActive = false
BaseEstablished = false

InitialAlliedReinforcements = function()
	local camera = Actor.Create("Camera", true, { Owner = Greece, Location = DefaultCameraPosition.Location })
	Trigger.AfterDelay(DateTime.Seconds(30), camera.Destroy)

	Reinforcements.Reinforce(Greece, { "jeep", "jeep", "e1", "e1", "e1" }, { AlliedEntry1.Location, UnitBStopLocation.Location }, 2)
	Reinforcements.Reinforce(Greece, { "2tnk", "2tnk", "e3", "e3", "e3" }, { AlliedEntry2.Location, UnitAStopLocation.Location }, 2)
	Trigger.AfterDelay(DateTime.Seconds(3), function()
		Reinforcements.Reinforce(Greece, { "mcv" }, { AlliedEntry3.Location, MCVStopLocation.Location })
		MissionActive = true
	end)

	Trigger.AfterDelay(DateTime.Seconds(20), function()
		Utils.Do(OpeningAttackers, function(unit)
			if not unit.IsDead then
				unit.AttackMove(MCVStopLocation.Location)
			end
		end)
	end)
end

EstablishBase = function()
	if BaseEstablished or not Greece.HasPrerequisites({ "fact", "proc" }) then
		return
	end

	BaseEstablished = true
	Greece.MarkCompletedObjective(EstablishBaseObjective)
	Media.PlaySpeechNotification(Greece, "FirstObjectiveMet")
	Media.DisplayMessage(UserInterface.GetFluentMessage("reignition-base-established"))
	ActivateAI()
end

SetupRadarObjective = function()
	Trigger.OnCapture(RadarDome, function()
		if Greece.IsObjectiveCompleted(CaptureRadarObjective) then
			return
		end

		Greece.MarkCompletedObjective(CaptureRadarObjective)
		Media.DisplayMessage(UserInterface.GetFluentMessage("reignition-labs-marked"))
		Utils.Do(SovietTechLabs, function(lab)
			if not lab.IsDead then
				Beacon.New(Greece, lab.CenterPosition)
				Actor.Create("TECH.CAM", true, { Owner = Greece, Location = lab.Location + CVec.New(1, 1) })
			end
		end)
	end)

	Trigger.OnKilled(RadarDome, function()
		if not Greece.IsObjectiveCompleted(CaptureRadarObjective) then
			Greece.MarkFailedObjective(CaptureRadarObjective)
		end
	end)
end

SetupMissionObjectives = function()
	Trigger.OnAllKilledOrCaptured(SovietTechLabs, function()
		if not MissionActive then
			return
		end

		MissionActive = false
		Greece.MarkCompletedObjective(DestroyLabsObjective)
		Media.DisplayMessage(UserInterface.GetFluentMessage("reignition-mission-complete"))
	end)
end

Tick = function()
	if not MissionActive then
		return
	end

	EstablishBase()

	if Greece.HasNoRequiredUnits() then
		MissionActive = false
		Greece.MarkFailedObjective(EstablishBaseObjective)
		Greece.MarkFailedObjective(DestroyLabsObjective)
		USSR.MarkCompletedObjective(EnemyObjective)
	end
end

WorldLoaded = function()
	Greece = Player.GetPlayer("Greece")
	USSR = Player.GetPlayer("USSR")

	InitObjectives(Greece)
	EstablishBaseObjective = AddPrimaryObjective(Greece, "reignition-establish-base")
	DestroyLabsObjective = AddPrimaryObjective(Greece, "reignition-destroy-labs")
	CaptureRadarObjective = AddSecondaryObjective(Greece, "reignition-capture-radar")
	EnemyObjective = AddPrimaryObjective(USSR, "")

	Camera.Position = DefaultCameraPosition.CenterPosition
	SetupRadarObjective()
	SetupMissionObjectives()
	Trigger.AfterDelay(DateTime.Seconds(1), InitialAlliedReinforcements)
	Trigger.AfterDelay(DateTime.Seconds(90), ActivateAI)
end
