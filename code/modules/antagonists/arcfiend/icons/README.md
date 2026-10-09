# Arcfiend sprites

Put the .dmi files here. Not wired into the code yet: when they exist, tell Claude (or edit the `button_icon` / `icon` / `icon_state` vars) and point them at these files.
All icons are 32x32 unless noted. Use lowercase snake_case state names.

## arcfiend_actions.dmi (power button icons)
One state per power that has a button, named after the power. Passives (Nanite Regeneration, Organ Resonance, Ampullary Sense, Capacitive Soles) have no button and no icon. Toggle powers also get a `_on` state with a brighter glow.

Starters: `sap_power`, `ride_the_lightning`, `charge`, `galvanic_prod`
Actives: `surge_reflex`, `overdrive_sprint` (+`_on`), `brain_scramble`, `arc_discharge`, `thunderclap`,
`electrokinetic_smash` (+`_on`), `myoelectric_stimulation` (+`_on`), `jamming_field` (+`_on`),
`electric_emag`, `emp_burst`, `jolt`
Weapons: `manifest_coilgun`, `biometal_tether`, `lateral_laser`
Optional: `bg` and `bg_on` for a custom button background (set `background_icon_state` on the base power).

## arcfiend_items.dmi (item icons and in-hands)
Each item needs its item icon state plus in-hand states `<name>_lefthand` and `<name>_righthand` (32x32, 4 directions).
- `arcfiend_hand` (touch hand, used by Sap / Brain Scramble)
- `galvanic_prod`
- `manifest_coilgun`
- `lateral_laser`
- `electric_emag` (item icon only)
- `jamming_device` (item icon only)
- `nanite_injector` (item icon only; also used in the OPFOR menu)

## arcfiend_effects.dmi
- `lightning_ball` (animated; the Ride the Lightning orb. Frame count and delay up to you)
- `spark` (small spark that trails the rider)
- `glow` (yellow body glow overlay for toggle powers)
- `jamming_aura` (aura around the arcfiend while Jamming Field is on)
- `thunderclap` (animated shockwave, ideally 96x96 or larger)
- `tether_hook`, `tether_chain` (Biometal Tether)
- Lateral Laser beam: `lateral_beam` (optional, it currently uses the stock laser tinted)

## arcfiend_hud.dmi
- `power_counter` (HUD power counter; currently stock `psi_counter`)
- `antag_hud` (the arcfiend marker shown on their head; also needs to be added to icons/mob/huds/antag_hud.dmi or wired separately)
- `preview` (antagonist selection menu preview icon)
