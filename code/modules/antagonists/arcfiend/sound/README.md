# Arcfiend sound effects

Put the .ogg files here. Not wired into the code yet: when they exist, tell Claude and the `playsound` calls will be pointed at them.
Format: .ogg Vorbis, mono, 44.1 kHz, normalized to about -3 dB, no clipping, trim silence at the start, under ~100 KB each.
Lowercase snake_case names.

## Core
- `sap_loop.ogg` (looping crackle while sapping), `sap_finish.ogg`
- `ride_enter.ogg`, `ride_hum_loop.ogg`, `ride_exit.ogg`, `ride_ejected.ogg` (cable cut or EMP)
- `charge.ogg`
- `toggle_on.ogg`, `toggle_off.ogg` (shared by every toggle power)
- `power_gain.ogg`, `power_spend.ogg`, `not_enough_power.ogg` (small UI cues)

## Actives
- `thunderclap_windup.ogg` (about 1.5 s), `thunderclap_boom.ogg`
- `arc_discharge.ogg`
- `brain_scramble.ogg`
- `jolt_windup.ogg`, `jolt_restart.ogg`
- `emp_burst.ogg`
- `emag_hack.ogg`
- `surge_reflex.ogg`
- `jamming_on.ogg`, `jamming_off.ogg` (optional, toggle sounds also work)

## Weapons
- `coilgun_fire.ogg`, `coilgun_reload.ogg`, `coilgun_dry.ogg`
- `lateral_laser_fire.ogg`, `lateral_laser_mode.ogg`
- `tether_fire.ogg`, `tether_pull.ogg`
- `prod_hit.ogg`, `prod_zap.ogg`, `prod_ready.ogg`
