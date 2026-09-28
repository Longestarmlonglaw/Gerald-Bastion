#define BB_GUN_PART_MAGAZINE "magazine"
#define BB_GUN_PART_FIRING_MECHANISM "firing mechanism"
#define BB_GUN_PART_BARREL "barrel"
#define BB_GUN_PART_POWER_CELL "power cell"
#define BB_GUN_PART_LENS "lens"
#define BB_GUN_PART_UNDERBARREL "underbarrel"

#define BB_GUN_BALLISTIC "ballistic"
#define BB_GUN_ENERGY "energy"

#define BB_GUN_FIRING_SEMI_AUTO "semi-auto"
#define BB_GUN_FIRING_FULL_AUTO "full auto"
#define BB_GUN_FIRING_BOLT_ACTION "bolt action"
#define BB_GUN_FIRING_PUMP_ACTION "pump action"

/**
 * Blood Brother gun parts.
 *
 * These are intentionally lightweight attachment objects. Their sprites are
 * placeholders borrowed from existing stock parts/items until dedicated art
 * exists.
 */

/obj/item/blood_brother_gun_part
	name = "Blood Brother gun part"
	desc = "An improvised component used to upgrade a Blood Brother weapon."
	w_class = WEIGHT_CLASS_SMALL
	var/bb_part_slot
	var/bb_weapon_family

/obj/item/blood_brother_gun_part/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isgun(interacting_with))
		return NONE

	var/obj/item/gun/targeted_gun = interacting_with
	if(!targeted_gun.bb_install_part(src, user))
		if(!bb_part_slot || !(bb_part_slot in targeted_gun.bb_part_slots))
			balloon_alert(user, "incompatible part!")
		else if(bb_weapon_family && bb_weapon_family != targeted_gun.bb_weapon_family)
			balloon_alert(user, "wrong weapon type!")
		else
			balloon_alert(user, "can't install part!")
		return ITEM_INTERACT_BLOCKING

	return ITEM_INTERACT_SUCCESS

/obj/item/blood_brother_gun_part/magazine
	name = "magazine"
	desc = "An improvised ballistic magazine component. Its capacity is determined by the matter bin used to build it."
	icon = /obj/item/stock_parts/matter_bin::icon
	icon_state = /obj/item/stock_parts/matter_bin::icon_state
	bb_part_slot = BB_GUN_PART_MAGAZINE
	bb_weapon_family = BB_GUN_BALLISTIC

/obj/item/blood_brother_gun_part/firing_mechanism
	name = "firing mechanism"
	desc = "An improvised firing mechanism that determines how a weapon cycles between shots."
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	bb_part_slot = BB_GUN_PART_FIRING_MECHANISM
	var/bb_firing_mode = BB_GUN_FIRING_SEMI_AUTO
	/// Multiplier applied to projectile damage when this mechanism is installed.
	var/bb_damage_multiplier = 1
	/// Multiplier applied to projectile speed when this mechanism is installed.
	var/bb_projectile_speed_multiplier = 1
	/// Delay used to cycle a manual-action mechanism. Only present on manual-action mechanisms.
	var/bb_rack_delay
	/// Delay between automatic shots. Only present on full-auto mechanisms.
	var/bb_fire_rate

/obj/item/blood_brother_gun_part/firing_mechanism/semi_auto
	name = "semi-auto firing mechanism"
	bb_firing_mode = BB_GUN_FIRING_SEMI_AUTO

/obj/item/blood_brother_gun_part/firing_mechanism/full_auto
	name = "full-auto firing mechanism"
	bb_firing_mode = BB_GUN_FIRING_FULL_AUTO
	bb_damage_multiplier = 1
	bb_projectile_speed_multiplier = 1
	bb_fire_rate = 0.2 SECONDS

/obj/item/blood_brother_gun_part/firing_mechanism/bolt_action
	name = "bolt-action firing mechanism"
	bb_firing_mode = BB_GUN_FIRING_BOLT_ACTION
	bb_damage_multiplier = 1.2
	bb_projectile_speed_multiplier = 1.2
	bb_rack_delay = 5

/obj/item/blood_brother_gun_part/firing_mechanism/pump_action
	name = "pump-action firing mechanism"
	bb_firing_mode = BB_GUN_FIRING_PUMP_ACTION
	bb_damage_multiplier = 1.1
	bb_projectile_speed_multiplier = 1.1
	bb_rack_delay = 3

/obj/item/blood_brother_gun_part/barrel
	name = "barrel"
	desc = "An improvised ballistic barrel used to modify a weapon's firing characteristics."
	icon = /obj/item/pipe::icon
	icon_state = /obj/item/pipe::icon_state
	bb_part_slot = BB_GUN_PART_BARREL
	bb_weapon_family = BB_GUN_BALLISTIC

/obj/item/blood_brother_gun_part/power_cell
	name = "power cell"
	desc = "An improvised energy weapon power cell."
	icon = /obj/item/stock_parts/power_store/cell::icon
	icon_state = /obj/item/stock_parts/power_store/cell::icon_state
	bb_part_slot = BB_GUN_PART_POWER_CELL
	bb_weapon_family = BB_GUN_ENERGY

/obj/item/blood_brother_gun_part/underbarrel
	name = "underbarrel"
	desc = "An improvised underbarrel component for a Blood Brother weapon."
	icon = /obj/item/stock_parts/micro_laser::icon
	icon_state = /obj/item/stock_parts/micro_laser::icon_state
	bb_part_slot = BB_GUN_PART_UNDERBARREL

/obj/item/blood_brother_gun_part/lens
	name = "lens"
	desc = "An improvised energy weapon lens used to modify its output."
	icon = /obj/item/stock_parts/scanning_module::icon
	icon_state = /obj/item/stock_parts/scanning_module::icon_state
	bb_part_slot = BB_GUN_PART_LENS
	bb_weapon_family = BB_GUN_ENERGY
