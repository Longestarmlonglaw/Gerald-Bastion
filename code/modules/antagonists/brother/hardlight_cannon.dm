/**
 * Hardlight laser cannon for Blood Brothers.
 *
 * Uses the regular laser cannon sprites as a placeholder.
 */

/obj/item/gun/energy/laser/hardlight
	name = "hardlight laser cannon"
	desc = "A crude laser cannon that fires incredibly dense beams of hardlight. The beam is solid enough to be stopped by glass and grilles."
	icon_state = "lasercannon"
	inhand_icon_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/laser/hardlight)
	fire_delay = 10
	ammo_x_offset = 3
	weapon_weight = WEAPON_HEAVY
	shaded_charge = FALSE

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
	firing_effect_type = null
	delay = 1 SECONDS

/obj/projectile/beam/laser/hardlight_cannon
	name = "hardlight laser"
	pass_flags = PASSTABLE
	damage = 24
	damage_type = BURN
	range = 8
	eyeblur = 2 SECONDS

/obj/projectile/beam/laser/hardlight_cannon/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(iscarbon(target) && !blocked)
		var/mob/living/carbon/carbon_target = target
		carbon_target.adjustBruteLoss(8)
		carbon_target.adjustOrganLoss(ORGAN_SLOT_EYES, 2)
