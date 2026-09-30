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
	/// The slot this part is installed into, as a BB_GUN_PART_* define.
	var/bb_part_slot
	/// The weapon family this part is restricted to, as a BB_GUN_* define. Null if it fits any family.
	var/bb_weapon_family

/obj/item/blood_brother_gun_part/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isgun(interacting_with))
		return NONE

	var/datum/component/blood_brother_gun/modular_gun = interacting_with.GetComponent(/datum/component/blood_brother_gun)
	if(!modular_gun)
		interacting_with.balloon_alert(user, "incompatible part!")
		return ITEM_INTERACT_BLOCKING
	if(!modular_gun.try_install_part(src, user))
		return ITEM_INTERACT_BLOCKING
	return ITEM_INTERACT_SUCCESS

/obj/item/blood_brother_gun_part/magazine
	name = "magazine"
	desc = "An improvised ballistic magazine component. Its capacity is determined by the matter bin used to build it."
	icon = /obj/item/stock_parts/matter_bin::icon
	icon_state = /obj/item/stock_parts/matter_bin::icon_state
	bb_part_slot = BB_GUN_PART_MAGAZINE
	bb_weapon_family = BB_GUN_BALLISTIC

/obj/item/blood_brother_gun_part/receiver
	name = "receiver"
	desc = "An improvised receiver that determines a weapon's firing characteristics."
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	bb_part_slot = BB_GUN_PART_RECEIVER
	/// The receiver's firing type, as a BB_GUN_RECEIVER_* define.
	var/bb_receiver_type = BB_GUN_RECEIVER_SEMI_AUTO
	/// Multiplier applied to projectile damage when this receiver is installed.
	var/bb_damage_multiplier = 1
	/// Multiplier applied to projectile speed when this receiver is installed.
	var/bb_projectile_speed_multiplier = 1
	/// Firing interval for this receiver. Used as the gun's delay between shots.
	var/bb_fire_interval

/obj/item/blood_brother_gun_part/receiver/semi_auto
	name = "semi-auto receiver"
	bb_receiver_type = BB_GUN_RECEIVER_SEMI_AUTO

/obj/item/blood_brother_gun_part/receiver/automatic
	name = "automatic receiver"
	bb_receiver_type = BB_GUN_RECEIVER_AUTOMATIC
	bb_damage_multiplier = 1
	bb_projectile_speed_multiplier = 1
	bb_fire_interval = 0.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/rifle
	name = "rifle receiver"
	bb_receiver_type = BB_GUN_RECEIVER_RIFLE
	bb_damage_multiplier = 1.2
	bb_projectile_speed_multiplier = 1.2
	bb_fire_interval = 1.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/carbine
	name = "carbine receiver"
	bb_receiver_type = BB_GUN_RECEIVER_CARBINE
	bb_damage_multiplier = 1.1
	bb_projectile_speed_multiplier = 1.1
	bb_fire_interval = 1 SECONDS

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
