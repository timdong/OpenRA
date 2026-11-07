# Red Alert: Reignition

`mod.yaml` loads the Red Alert building, aircraft and ship rules, sequences and
content packages. Assets inherited from `mods/ra` and the installed RA content
do not need duplicate files in `reignition/bits`.

## Skirmish with Daxia Iron Fist

Start a Skirmish game, choose a map in the **Conquest** category, select
**Daxia Iron Fist**, and add an AI opponent to another player slot.
**Crimson Tide** and **Random** are also available; Random chooses between
the two Reignition factions.

Faction selection and names are registered globally in `rules/factions.yaml`
and `fluent/rules.ftl`: the lobby builds its dropdown from the default mod
rules, so map-only faction overrides cannot populate this menu.

All 80 lobby-only maps supplied by the bundled RA mod are included: 74 Conquest
maps and 6 special-mode maps (3 Minigame and 3 Drop Zone). The 3 previously
imported cooperative campaign maps remain available in the lobby too.
Special-mode maps retain their original locked factions, starting units,
construction restrictions and objectives.

Land maps to start with:

| Map | Players | Terrain |
| --- | --- | --- |
| Keep Off The Grass 2 | 2 | Temperate |
| Siberian Pass | 2 | Snow |
| Great Sahara 2 | 8 | Desert |
| Ore Gardens | 8 | Desert |

The imported maps load `rules/skirmish.yaml`, `sequences/skirmish.yaml` and
`fluent/skirmish.ftl` before their own overrides. These provide the existing
Daxia MCV and deployment animation, custom buildings and icons, Chidian rovers,
rocket infantry, deployment abilities and building proximity bonuses.
The standard skirmish victory conditions, AI, starting units and lobby options
remain available. Starting cash follows the lobby setting, not Rift Outpost's
fixed mission funds. The nuclear reactor still produces 500 power at full health.

These shared files apply to the bundled skirmish maps. Campaign scripts and
technology restrictions remain separate; newly downloaded maps would also need
these references to use the complete Daxia design.

## Campaign missions

The Missions menu includes Rift Outpost and all 60 missions listed in the
bundled RA mission catalog: Allied, Soviet, Counterstrike, Aftermath, OpenRA
Originals and Ant Missions. `mod.yaml` loads `ra|missions.yaml` after the
Reignition catalog to preserve the original campaign groups and ordering.
These are the missions supplied by this OpenRA checkout, not every mission
from the commercial Red Alert releases.

Each imported mission is a local copy in `reignition/maps` with
`RequiresMod: reignition`. Terrain, objectives, Lua scripts, starting resources,
playable slots and mission-specific technology restrictions are preserved.
Reignition's global unit and building overrides still apply; Rift Outpost's
unrestricted technology and starting funds do not apply to these missions.

For land battles, start with:

| Menu | Mission | Gameplay |
| --- | --- | --- |
| Allied Campaign | 02: Five to One (`allies-02`) | Snow terrain; deploy an MCV and clear the supply convoy route. The toughest difficulty replaces the MCV with a jeep. |
| Soviet Campaign | 04a: Behind the Lines (`soviet-04a`) | Snow terrain; build up and attack the Allied base and communications. |

Restart the mod to refresh the mission list, then select a campaign in the
Missions menu and start a new mission.

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
| Nuclear power | Nuclear reactor (`NUCLEAR`) | Nuclear reactor (`NUCLEAR`) | Research/tech center; high or unrestricted technology |
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

The nuclear reactor is available throughout the mod and uses the supplied
reference artwork. It costs 2500 credits and produces 500 power at full health;
damage reduces output through the inherited power-plant behavior, and its
destruction causes a fixed-radius damaging blast. It occupies 3 × 2 cells and
retains repair, sale and capture support. Rebuild its transparent world sprite
and separate production icon with
`new-design/build-nuclear-assets.ps1`.

## Naval and air production

On the 74 bundled Conquest maps and Rift Outpost, Daxia also loads
`rules/daxia-arsenal.yaml`. Its separate unit variants retain the supplied
artwork while using Daxia prerequisites; the original Soviet actors and
scripted campaign rosters are preserved.

| Added Daxia unit | Producer | Additional prerequisites |
| --- | --- | --- |
| Mobile flak (`FTRK.DAXIA`) | Vehicle works | Low technology |
| Armored transport (`APC.DAXIA`) | Vehicle works | Low technology |
| Missile launcher (`V2RL.DAXIA`) | Vehicle works | Radar; medium technology |
| Heavy tank (`4TNK.DAXIA`) | Vehicle works | Research center and repair depot; high technology |
| Tesla tank (`TTNK.DAXIA`) | Vehicle works | Research center and radar; high technology |
| Strike fighter (`MIG.DAXIA`) | Daxia airfield | Research center; high technology |
| Attack submarine (`SS.DAXIA`) | Naval yard | Low technology |
| Kirov airship (`KIROV.DAXIA`) | Helipad | Research center; high technology |

The Daxia airfield costs 500 credits and requires radar. Strike fighters attack
ground targets and return to this airfield to reload. The submarine uses the
naval yard's boat exits and retains its torpedoes and underwater detection.
The Kirov is a selectable, controllable bomber costing 2500 credits, with
100000 health, slow movement and a bomb every 75 ticks at close range. It has
no anti-air weapon. AI production lists and air/naval squad classifications
include these variants. Special-mode maps retain their original rosters.

The inherited naval and air roster remains available:

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
Other faction-specific production and country-exclusive units follow the
inherited RA rules.
The original Hind remains an editor/campaign unit, with the Black Hawk filling
the normal buildable helicopter role.

The Black Hawk (`MH60`) uses the layered `reignition-nhaw` design: both rotors
counter-rotate above a static body, with 24 fast airborne frames (40 ms/frame,
75 degrees per frame, five revolutions per loop) and motion trails
and 12 slow grounded frames (120 ms/frame). Both layers use the same alignment
and scale. Rebuild the body, rotor sheet and production icon using Pillow:
`python new-design/build-nhaw-animation.py`. Source layers are stored in
`new-design/source-assets/reignition-nhaw/large`; the script also writes
`new-design/nhaw-rotor-preview.gif`. The generic static-unit asset builder
excludes this helicopter so it cannot overwrite the animated version.

Previously disabled advanced ground units are also restored to their inherited
technology and faction prerequisites. Existing Reignition art overrides remain
in place; restored buildings and aircraft without custom artwork use RA assets.

Restart the mission to use the updated rules. Saved games may retain the older
mission rules.
