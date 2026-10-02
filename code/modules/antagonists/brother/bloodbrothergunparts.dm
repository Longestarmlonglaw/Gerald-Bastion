/**
 * Blood Brother gun parts.
 *
 * These are intentionally lightweight attachment objects. Sprites live in bb_gun_parts.dmi.
 * The *_parent sprites are only for the slot parents below, so real attachments should set their own icon_state.
 */

/obj/item/blood_brother_gun_part
	name = "Blood Brother gun part"
	desc = "The platonic ideal of a gun part, and therefore useless. Unless an admin spawned this, somebody needs to go beat a coder's ass."
	icon = 'icons/obj/weapons/guns/bb_gun_parts.dmi'
	icon_state = "BBgunpart_parent"
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

// Slot parents. These set up each slot and aren't meant to be crafted themselves.
// Real attachments are subtypes of these, and should give themselves their own desc.

/obj/item/blood_brother_gun_part/magazine
	name = "magazine"
	desc = "Holds exactly zero rounds. The only thing it feeds is the issue tracker."
	icon_state = "BBmagazine_parent"
	bb_part_slot = BB_GUN_PART_MAGAZINE
	bb_weapon_family = BB_GUN_BALLISTIC

/obj/item/blood_brother_gun_part/receiver
	name = "receiver"
	desc = "The abstract concept of a receiver, poorly disguised as a firing pin. It receives nothing. If you're holding this, someone has made a terrible mistake, and I know who."
	icon_state = "BBreciever_parent"
	bb_part_slot = BB_GUN_PART_RECEIVER
	/// The receiver's firing type, as a BB_GUN_RECEIVER_* define.
	var/bb_receiver_type = BB_GUN_RECEIVER_SEMI_AUTO
	/// Multiplier applied to projectile damage when this receiver is installed.
	var/bb_damage_multiplier = 1
	/// Multiplier applied to projectile speed when this receiver is installed.
	var/bb_projectile_speed_multiplier = 1
	/// Firing interval for this receiver. Used as the gun's delay between shots.
	var/bb_fire_interval

/obj/item/blood_brother_gun_part/barrel
	name = "barrel"
	desc = "A barrel with no bore, no rifling, and no reason to exist. Please report this to a coder, then check on the coder's mental health."
	icon_state = "BBbarrel_parent"
	bb_part_slot = BB_GUN_PART_BARREL
	bb_weapon_family = BB_GUN_BALLISTIC

/obj/item/blood_brother_gun_part/power_cell
	name = "power cell"
	desc = "Contains zero joules and a lifetime supply of regret. This is a parent type. Do not use."
	icon_state = "BBcell_parent"
	bb_part_slot = BB_GUN_PART_POWER_CELL
	bb_weapon_family = BB_GUN_ENERGY

/obj/item/blood_brother_gun_part/underbarrel
	name = "underbarrel"
	desc = "Hangs from nothing, attaches to nothing, does nothing. A true monument to object-oriented design."
	icon_state = "BBunderbarrel_parent"
	bb_part_slot = BB_GUN_PART_UNDERBARREL

/obj/item/blood_brother_gun_part/lens
	name = "lens"
	desc = "Focuses absolutely nothing. If you can see through this, you're looking directly at a bug."
	icon_state = "BBlens_parent"
	bb_part_slot = BB_GUN_PART_LENS
	bb_weapon_family = BB_GUN_ENERGY

// Receivers

/obj/item/blood_brother_gun_part/receiver/semi_auto
	name = "semi-auto receiver"
	// Placeholder sprite until this receiver gets its own.
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	desc = "An improvised semi-automatic receiver. One shot per trigger pull, with no changes to the weapon's damage, projectile speed or rate of fire. When in doubt, use this one."
	bb_receiver_type = BB_GUN_RECEIVER_SEMI_AUTO

/obj/item/blood_brother_gun_part/receiver/automatic
	name = "automatic receiver"
	// Placeholder sprite until this receiver gets its own.
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	desc = "An improvised fully automatic receiver. Hold down the trigger to keep firing at a rapid rate."
	bb_receiver_type = BB_GUN_RECEIVER_AUTOMATIC
	bb_damage_multiplier = 1
	bb_projectile_speed_multiplier = 1
	bb_fire_interval = 0.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/rifle
	name = "rifle receiver"
	// Placeholder sprite until this receiver gets its own.
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	desc = "An improvised rifle receiver. Each shot hits harder and flies faster, but the weapon fires much more slowly."
	bb_receiver_type = BB_GUN_RECEIVER_RIFLE
	bb_damage_multiplier = 1.2
	bb_projectile_speed_multiplier = 1.2
	bb_fire_interval = 1.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/carbine
	name = "carbine receiver"
	// Placeholder sprite until this receiver gets its own.
	icon = /obj/item/firing_pin::icon
	icon_state = /obj/item/firing_pin::icon_state
	desc = "An improvised carbine receiver. A middle ground between semi-auto and rifle: shots hit a little harder and fly a little faster, at a somewhat slower rate of fire."
	bb_receiver_type = BB_GUN_RECEIVER_CARBINE
	bb_damage_multiplier = 1.1
	bb_projectile_speed_multiplier = 1.1
	bb_fire_interval = 1 SECONDS
