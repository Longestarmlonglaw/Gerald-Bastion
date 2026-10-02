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
	/// Extra rounds this magazine adds to a weapon's internal magazine.
	var/bb_extra_rounds = 0
	/// How many weight classes this magazine adds to the weapon.
	var/bb_weight_class_increase = 0
	/// How long loading ammunition into the weapon takes with this magazine installed. 0 for instant.
	var/bb_load_delay = 0

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
	/// Multiplier applied to the weapon's cell capacity.
	var/bb_capacity_multiplier = 1
	/// Whether an EMP fully recharges the weapon instead of draining it.
	var/bb_emp_recharges = FALSE
	/// Whether the weapon slowly recharges itself over time.
	var/bb_self_recharging = FALSE
	/// Whether the cell is unstable: it can be fed uranium, but sparks when fired and is wrecked by EMPs.
	var/bb_unstable = FALSE

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
	icon_state = "semi_auto_receiver"
	desc = "An improvised semi-automatic receiver. One shot per trigger pull, with no changes to the weapon's damage, projectile speed or rate of fire. When in doubt, use this one."
	bb_receiver_type = BB_GUN_RECEIVER_SEMI_AUTO

/obj/item/blood_brother_gun_part/receiver/automatic
	name = "automatic receiver"
	icon_state = "full_auto_receiver"
	desc = "An improvised fully automatic receiver. Hold down the trigger to keep firing at a rapid rate."
	bb_receiver_type = BB_GUN_RECEIVER_AUTOMATIC
	bb_damage_multiplier = 1
	bb_projectile_speed_multiplier = 1
	bb_fire_interval = 0.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/rifle
	name = "rifle receiver"
	icon_state = "rifle_receiver"
	desc = "An improvised rifle receiver. Each shot hits harder and flies faster, but the weapon fires much more slowly."
	bb_receiver_type = BB_GUN_RECEIVER_RIFLE
	bb_damage_multiplier = 1.2
	bb_projectile_speed_multiplier = 1.2
	bb_fire_interval = 1.2 SECONDS

/obj/item/blood_brother_gun_part/receiver/carbine
	name = "carbine receiver"
	icon_state = "carbine_receiver"
	desc = "An improvised carbine receiver. A middle ground between semi-auto and rifle: shots hit a little harder and fly a little faster, at a somewhat slower rate of fire."
	bb_receiver_type = BB_GUN_RECEIVER_CARBINE
	bb_damage_multiplier = 1.1
	bb_projectile_speed_multiplier = 1.1
	bb_fire_interval = 1 SECONDS

// Magazines. These only work on weapons with internal magazines, like revolvers.

/obj/item/blood_brother_gun_part/magazine/extended
	name = "extended magazine"
	icon_state = "extended_magazine"
	desc = "An improvised magazine extension that lets a weapon's internal magazine hold a couple of extra rounds."
	bb_extra_rounds = 2

/obj/item/blood_brother_gun_part/magazine/big
	name = "big magazine"
	icon_state = "big_magazine"
	desc = "A bulky improvised magazine that lets a weapon's internal magazine hold a lot more rounds, at the cost of making the weapon noticeably larger."
	bb_extra_rounds = 4
	bb_weight_class_increase = 1

/obj/item/blood_brother_gun_part/magazine/bluespace
	name = "bluespace magazine"
	icon_state = "bluespace_magazine"
	desc = "A magazine that folds space around a weapon's internal magazine, letting it hold an absurd number of rounds. Squeezing ammunition into a pocket dimension takes a moment, though."
	bb_extra_rounds = 18
	bb_load_delay = 1.5 SECONDS

// Power cells

/obj/item/blood_brother_gun_part/power_cell/upgraded
	name = "upgraded cell"
	desc = "An improvised high-capacity cell that lets an energy weapon hold a lot more charge."
	bb_capacity_multiplier = 2

/obj/item/blood_brother_gun_part/power_cell/emp_shielded
	name = "EMP shielded cell"
	desc = "An improvised cell wrapped in shielding. It holds less charge than an upgraded cell, but instead of being drained by an EMP, it soaks up the pulse and fully recharges the weapon."
	bb_capacity_multiplier = 1.5
	bb_emp_recharges = TRUE

/obj/item/blood_brother_gun_part/power_cell/self_recharging
	name = "self-recharging cell"
	desc = "An improvised cell built around a yellow slime core. It slowly recharges the weapon on its own."
	bb_self_recharging = TRUE

/obj/item/blood_brother_gun_part/power_cell/unstable
	name = "unstable cell"
	desc = "A crackling, barely contained cell with an enormous capacity. The weapon can be recharged by feeding it uranium sheets, but it sparks with every shot, leaks radiation, and an EMP will make it violently discharge into whoever is holding it."
	bb_capacity_multiplier = 4
	bb_unstable = TRUE
