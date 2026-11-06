# Red Alert: Reignition

`mod.yaml` loads the Red Alert building, aircraft and ship rules, sequences and
content packages. Assets inherited from `mods/ra` and the installed RA content
do not need duplicate files in `reignition/bits`.

## Rift Outpost construction

The mission uses the unrestricted technology level. Buildings still require
their normal prerequisites, sufficient credits, power for their supported
abilities, and valid placement terrain. The former MVP construction blacklist
has been removed.

| Category | Daxia (`allies`) | Crimson Tide (`soviet`) | Unlock |
| --- | --- | --- | --- |
| Basic economy | Power plant, ore refinery, ore silo | Power plant, ore refinery, ore silo | Construction yard; power for refinery, refinery for silo |
| Infantry | Field barracks | Barracks, kennel | Power |
| Vehicles | Vehicle works, logistics/repair depot | War factory, repair depot | Refinery; factory for repair depot |
| Radar and power | Radar, advanced power plant | Radar, advanced power plant | Refinery for radar; radar for advanced power |
| Naval base | Naval yard (`SYRD`) | Sub pen (`SPEN`) | Power; place in water within building range |
| Air base | Helipad (`HPAD`) | Airfield (`AFLD`) | Radar |
| Research | Research center (`ATEK`) | Tech center (`STEK`) | Factory and radar |
| Ground defense | Pillboxes, camouflaged pillboxes, sentry guns | Flame towers, Tesla coils | Barracks; additional technology for advanced defenses |
| Air defense | AA gun | SAM site | Radar |
| Walls | Sandbags, concrete wall | Wire fence, concrete wall | Construction yard |
| Special defense | Gap generator | — | Research center |
| Superweapons | Chrono terminal, missile silo | Iron curtain, missile silo | Appropriate research/tech center |

The construction yard is deployed from an MCV. Additional MCVs require a vehicle
factory and repair depot. Superweapons are built explicitly; establishing the
base does not spawn a free Chrono terminal.

## Naval and air production

| Producer | Units | Additional prerequisite |
| --- | --- | --- |
| Naval yard | Transport, gunboat | None |
| Naval yard | Destroyer | Radar |
| Naval yard | Cruiser | Allied research center |
| Sub pen | Transport, submarine | None |
| Sub pen | Missile submarine | Soviet tech center |
| Helipad | Transport helicopter, Black Hawk | None |
| Helipad | Longbow | Allied research center |
| Airfield | Yak | None |
| Airfield | MiG | Soviet tech center |

Ships retain their water movement, production exits and repair behavior.
Aircraft retain their native landing, ammunition and rearming behavior.
Faction-specific production and country-exclusive units follow the inherited
RA rules; the two mission factions do not receive every other faction's units.
The original Hind remains an editor/campaign unit, with the Black Hawk filling
the normal buildable helicopter role.

Previously disabled advanced ground units are also restored to their inherited
technology and faction prerequisites. Existing Reignition art overrides remain
in place; restored buildings and aircraft without custom artwork use RA assets.

Restart the mission to use the updated rules. Saved games may retain the older
mission rules.
