/**
 * Hardlight laser cannon for Blood Brothers.
 */

/obj/item/gun/energy/laser/hardlight
	name = "hardlight laser cannon"
	desc = "A crude laser cannon that fires incredibly dense beams of hardlight. The beam is solid enough to be stopped by glass and grilles."
	icon_state = "hardlight_cannon"
	// Left null so the inhand state is built from the charge level (hardlight_cannon0 to hardlight_cannon4).
	inhand_icon_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/laser/hardlight)
	fire_delay = 10
	weapon_weight = WEAPON_HEAVY
	shaded_charge = TRUE

/obj/item/gun/energy/laser/hardlight/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/blood_brother_gun, \
		weapon_family = BB_GUN_ENERGY, \
		part_slots = list(BB_GUN_PART_RECEIVER, BB_GUN_PART_POWER_CELL, BB_GUN_PART_LENS, BB_GUN_PART_UNDERBARREL), \
		default_parts = list(/obj/item/blood_brother_gun_part/receiver/rifle), \
	)

/obj/item/ammo_casing/energy/laser/hardlight
	projectile_type = /obj/projectile/beam/laser/hardlight_cannon
	fire_sound = 'sound/weapons/lasercannonfire.ogg'
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/blue
	delay = 1 SECONDS

/obj/projectile/beam/laser/hardlight_cannon
	name = "hardlight laser"
	icon_state = "hardlight_cannon"
	pass_flags = PASSTABLE
	damage = 24
	damage_type = BURN
	range = 8
	eyeblur = 2 SECONDS
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = LIGHT_COLOR_BLUE

/obj/projectile/beam/laser/hardlight_cannon/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(iscarbon(target) && !blocked)
		var/mob/living/carbon/carbon_target = target
		carbon_target.adjustBruteLoss(8)
		carbon_target.adjustOrganLoss(ORGAN_SLOT_EYES, 2)
