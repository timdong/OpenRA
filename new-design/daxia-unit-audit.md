# Daxia production audit

Scope: the 12 supplied `source-assets/reignition-units/large/nu_*.png`
unit designs, plus their corresponding icons. The six user screenshots match
`nu_mig`, `nu_htnk`, `nu_ftrk`, `nu_ttnk`, `nu_v3` and `nu_sub`.

The artwork had been installed globally, but the actors still used Soviet
prerequisites. `BADR` and `BADR.Bomber` were scripted support aircraft, not
player-buildable airships. The Daxia variants now have their own production
prerequisites without changing those original support actors.

| Source design | Daxia actor | Availability |
| --- | --- | --- |
| `nu_mig` | `MIG.DAXIA` | Added: Daxia airfield + research center |
| `nu_htnk` | `4TNK.DAXIA` | Human players: vehicle works, low technology; 25% shorter production time |
| `nu_ftrk` | `FTRK.DAXIA` | Added: vehicle works |
| `nu_ttnk` | `TTNK.DAXIA` | Added: vehicle works + radar + research center |
| `nu_v3` | `V2RL.DAXIA` | Added: vehicle works + radar |
| `nu_sub` | `SS.DAXIA` | Added: naval yard |
| `nu_ifv` | `APC.DAXIA` | Additional omission fixed: vehicle works |
| `nu_kirov` | `KIROV.DAXIA` | Additional omission fixed: helipad + research center |
| `nu_dest` | `DD` | Already available: naval yard + radar; includes depth charges |
| `nu_harv` | `HARV` | Already available: vehicle works; refinery also supplies a harvester |
| `nu_howz` | `ARTY` | Already available: vehicle works + radar |
| `nu_nhaw` → layered `reignition-nhaw` | `MH60` | Helipad; new body and counter-rotating dual rotors; currently a gunship, not a troop transport |

All 12 supplied designs are represented by producible Daxia units on the
bundled Conquest maps and Rift Outpost. High-tier units still require the
appropriate technology level; prerequisites are listed in the mod README.

## Design-document concepts that remain unimplemented

The detailed v2.0 design document describes a larger future roster than these
12 assets. Examples still lacking their own complete actor/ability implementation:

- Lin Lan hero with target designation and reinforcement abilities.
- Kunlun mobile fortress with area repair.
- Dedicated electronic-warfare infantry and decoy specialists.
- Kunpeng strategic transport and the high-altitude missile platform.
- Yanhuang command tank's infantry protection ability.

Existing RA proxies do not implement all of those proposed mechanics. In
particular, the supplied howitzer is still conventional artillery, the strike
fighter attacks ground targets, and the supplied transport design uses APC
transport behavior. The six screenshot requests and the two additional asset
omissions are addressed here; this does not claim that the entire concept
document has been implemented.
