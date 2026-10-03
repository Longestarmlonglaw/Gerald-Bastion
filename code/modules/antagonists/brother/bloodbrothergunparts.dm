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

/// Using a part on a Blood Brother weapon installs it.
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
	/// Multiplier applied to projectile damage. Stacks with the receiver's.
	var/bb_damage_multiplier = 1
	/// Extra armour penetration added to each projectile.
	var/bb_armour_penetration = 0
	/// How many weight classes this barrel adds to the weapon. Negative makes it smaller.
	var/bb_weight_class_change = 0
	/// Extra spread added to the weapon, in degrees.
	var/bb_spread = 0
	/// Multiplier applied to the weapon's spread and to each round's inaccuracy, including buckshot pellet spread.
	var/bb_spread_multiplier = 1
	/// Multiplier applied to the extra spread from dual wielding.
	var/bb_dual_wield_spread_multiplier = 1
	/// Percent chance for a single-projectile round to crit for double damage. Rounds that fire several pellets are unaffected.
	var/bb_crit_chance = 0

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
	/// How many weight classes this underbarrel adds to the weapon. Negative makes it smaller.
	var/bb_weight_class_change = 0
	/// Multiplier applied to the weapon's spread.
	var/bb_spread_multiplier = 1
	/// Multiplier applied to the extra spread from dual wielding.
	var/bb_dual_wield_spread_multiplier = 1
	/// If set, replaces the weapon's melee damage, and makes its melee attacks cut.
	var/bb_melee_force = 0
	/// Whether right-clicking with the weapon fires this underbarrel, instead of bashing or holding someone up.
	var/bb_fires = FALSE
	/// The item loaded into this underbarrel, for underbarrels that fire things.
	var/obj/item/loaded_item

/obj/item/blood_brother_gun_part/underbarrel/Destroy()
	QDEL_NULL(loaded_item)
	return ..()

/obj/item/blood_brother_gun_part/underbarrel/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == loaded_item)
		loaded_item = null

/obj/item/blood_brother_gun_part/underbarrel/examine(mob/user)
	. = ..()
	if(bb_fires)
		. += span_notice("It's [loaded_item ? "loaded with [loaded_item]" : "empty"].")

/// Using a firing underbarrel in hand takes out whatever's loaded in it.
/obj/item/blood_brother_gun_part/underbarrel/attack_self(mob/user, modifiers)
	. = ..()
	if(. || !loaded_item)
		return
	var/obj/item/unloaded = loaded_item
	if(!user.put_in_hands(unloaded))
		unloaded.forceMove(user.drop_location())
	balloon_alert(user, "unloaded [unloaded]")
	return TRUE

/// Tries to load an item into this underbarrel. Returns TRUE if it was loaded.
/obj/item/blood_brother_gun_part/underbarrel/proc/try_load(obj/item/item, mob/living/user)
	if(loaded_item)
		balloon_alert(user, "already loaded!")
		return FALSE
	if(!can_load(item, user))
		return FALSE
	if(!user.transferItemToLoc(item, src))
		return FALSE
	loaded_item = item
	balloon_alert(user, "loaded [item]")
	return TRUE

/// Whether the given item can be loaded into this underbarrel. Shows the user why not if it can't.
/obj/item/blood_brother_gun_part/underbarrel/proc/can_load(obj/item/item, mob/living/user)
	return FALSE

/// Fires whatever is loaded at the target. Called when the user right-clicks with the weapon.
/obj/item/blood_brother_gun_part/underbarrel/proc/fire_at(atom/target, mob/living/user, obj/item/gun/gun)
	return

/obj/item/blood_brother_gun_part/lens
	name = "lens"
	desc = "Focuses absolutely nothing. If you can see through this, you're looking directly at a bug."
	icon_state = "BBlens_parent"
	bb_part_slot = BB_GUN_PART_LENS
	bb_weapon_family = BB_GUN_ENERGY
	/// Multiplier applied to projectile damage. Stacks with the receiver's.
	var/bb_damage_multiplier = 1
	/// Multiplier applied to projectile speed. Stacks with the receiver's.
	var/bb_projectile_speed_multiplier = 1
	/// Multiplier applied to the delay between shots. Above 1 fires slower, below 1 fires faster.
	var/bb_fire_delay_multiplier = 1
	/// Multiplier applied to how much charge each shot uses. Below 1 gets more shots out of a cell.
	var/bb_energy_cost_multiplier = 1
	/// Extra spread added to the weapon, in degrees.
	var/bb_spread = 0
	/// Extra armour penetration added to each shot.
	var/bb_armour_penetration = 0
	/// How long each shot knocks its target down for. 0 for no knockdown.
	var/bb_knockdown = 0
	/// Percent chance for each shot to teleport the mob it hits.
	var/bb_teleport_chance = 0

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
	icon_state = "upgraded_cell"
	desc = "An improvised high-capacity cell that lets an energy weapon hold a lot more charge."
	bb_capacity_multiplier = 2

/obj/item/blood_brother_gun_part/power_cell/emp_shielded
	name = "EMP shielded cell"
	icon_state = "emp_shielded_cell"
	desc = "An improvised cell wrapped in shielding. It holds less charge than an upgraded cell, but instead of being drained by an EMP, it soaks up the pulse and fully recharges the weapon."
	bb_capacity_multiplier = 1.5
	bb_emp_recharges = TRUE

/obj/item/blood_brother_gun_part/power_cell/self_recharging
	name = "self-recharging cell"
	icon_state = "self_recharging_cell"
	desc = "An improvised cell built around a yellow slime core. It slowly recharges the weapon on its own."
	bb_self_recharging = TRUE

/obj/item/blood_brother_gun_part/power_cell/unstable
	name = "unstable cell"
	icon_state = "unstable_cell"
	desc = "A crackling, barely contained cell with an enormous capacity. The weapon can be recharged by feeding it uranium sheets, but it sparks with every shot, leaks radiation, and an EMP will make it violently discharge into whoever is holding it."
	bb_capacity_multiplier = 4
	bb_unstable = TRUE

// Lenses

/obj/item/blood_brother_gun_part/lens/bluespace
	name = "bluespace lens"
	icon_state = "bluespace_lens"
	desc = "A lens laced with bluespace crystal. Shots hit harder, fly faster, and can teleport whoever they hit, but each one draws more power and the weapon fires more slowly."
	bb_damage_multiplier = 1.25
	bb_projectile_speed_multiplier = 1.5
	bb_fire_delay_multiplier = 1.25
	bb_energy_cost_multiplier = 1.5
	bb_teleport_chance = 20

/obj/item/blood_brother_gun_part/lens/spray
	name = "spray lens"
	icon_state = "spray_lens"
	desc = "A lens that splits the beam into a faster stream of weaker, armor-piercing shots. It sips power, but the shots spread out a lot more."
	bb_damage_multiplier = 0.7
	bb_fire_delay_multiplier = 0.6
	bb_energy_cost_multiplier = 0.75
	bb_spread = 20
	bb_armour_penetration = 20

/obj/item/blood_brother_gun_part/lens/densifying
	name = "densifying lens"
	icon_state = "densifying_lens"
	desc = "A lens that compresses each beam into a slow, heavy shot that hits harder and knocks its target down. The weapon fires more slowly, too."
	bb_damage_multiplier = 1.4
	bb_projectile_speed_multiplier = 0.6
	bb_fire_delay_multiplier = 1.5
	bb_knockdown = 1 SECONDS

/obj/item/blood_brother_gun_part/lens/efficiency
	name = "efficiency lens"
	icon_state = "efficiency_lens"
	desc = "A lens that focuses the beam more efficiently, getting a lot more shots out of each charge at the cost of some damage."
	bb_damage_multiplier = 0.75
	bb_energy_cost_multiplier = 0.5

// Barrels

/obj/item/blood_brother_gun_part/barrel/long
	name = "long barrel"
	icon_state = "long_barrel"
	desc = "A lengthened improvised barrel. Rounds leave it harder-hitting and better at punching through armor, but it makes the weapon one size bigger."
	bb_damage_multiplier = 1.25
	bb_armour_penetration = 15
	bb_weight_class_change = 1

/obj/item/blood_brother_gun_part/barrel/shortened
	name = "shortened barrel"
	icon_state = "shortened_barrel"
	desc = "A sawn-down improvised barrel. It makes the weapon one size smaller and easier to hide, but rounds spread out a lot more."
	bb_weight_class_change = -1
	bb_spread = 15

/obj/item/blood_brother_gun_part/barrel/lucky
	name = "lucky barrel"
	icon_state = "lucky_barrel"
	desc = "An improvised barrel with a pair of dice rattling around inside it for luck. Rounds that fire a single projectile have a chance to land a critical hit for double damage. Buckshot and other pellet rounds don't benefit."
	bb_crit_chance = 15

/obj/item/blood_brother_gun_part/barrel/choke
	name = "choke"
	icon_state = "choke_barrel"
	desc = "A narrowed improvised barrel that keeps rounds tightly grouped. It reduces buckshot pellet spread, the inaccuracy of single rounds, and the penalty for dual wielding."
	bb_spread_multiplier = 0.4
	bb_dual_wield_spread_multiplier = 0.5

// Underbarrels

/obj/item/blood_brother_gun_part/underbarrel/launcher
	name = "crude launcher"
	icon_state = "crude_launcher_underbarrel"
	desc = "A pneumatic tube bolted under a weapon. Right-click with the weapon to launch whatever is loaded in it at your target. It fits one item of normal size or smaller, like a knife or a bola. Right-click the weapon with an item to load it. Bullets just plink out harmlessly, and grenades don't fit."
	bb_fires = TRUE

/obj/item/blood_brother_gun_part/underbarrel/launcher/can_load(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/grenade))
		balloon_alert(user, "grenades don't fit!")
		return FALSE
	if(item.w_class > WEIGHT_CLASS_NORMAL)
		balloon_alert(user, "too big!")
		return FALSE
	return TRUE

/obj/item/blood_brother_gun_part/underbarrel/launcher/fire_at(atom/target, mob/living/user, obj/item/gun/gun)
	if(!loaded_item)
		gun.balloon_alert(user, "launcher empty!")
		return
	var/obj/item/launched = loaded_item
	launched.forceMove(get_turf(user))
	playsound(gun, 'sound/weapons/sonic_jackhammer.ogg', 50, TRUE)
	user.visible_message(span_warning("[user] launches [launched] from [gun]!"), span_notice("You launch [launched] from [gun]."))
	launched.throw_at(target, 7, 3, user)

/obj/item/blood_brother_gun_part/underbarrel/grenade_launcher
	name = "underbarrel grenade launcher"
	icon_state = "grenade_launcher_underbarrel"
	desc = "A single-shot grenade launcher bolted under a weapon. Right-click the weapon with any grenade to load it, then right-click with the weapon to fire it on a short fuse."
	bb_fires = TRUE

/obj/item/blood_brother_gun_part/underbarrel/grenade_launcher/can_load(obj/item/item, mob/living/user)
	if(!istype(item, /obj/item/grenade))
		balloon_alert(user, "only fits grenades!")
		return FALSE
	return TRUE

/obj/item/blood_brother_gun_part/underbarrel/grenade_launcher/fire_at(atom/target, mob/living/user, obj/item/gun/gun)
	if(!loaded_item)
		gun.balloon_alert(user, "launcher empty!")
		return
	var/obj/item/grenade/launched = loaded_item
	launched.forceMove(get_turf(user))
	playsound(gun, 'sound/weapons/gun/general/grenade_launch.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] fires [launched] from [gun]!"), span_notice("You fire [launched] from [gun]."))
	// Arming handles everything about the grenade itself, including chemical grenades that aren't assembled yet.
	launched.arm_grenade(user, 1.5 SECONDS, msg = FALSE)
	launched.throw_at(target, 10, 2, user)

/obj/item/blood_brother_gun_part/underbarrel/saw_blade
	name = "saw blade"
	icon_state = "saw_blade_underbarrel"
	desc = "A spinning saw blade bolted under a weapon, turning it into a nasty melee weapon. It makes the weapon one size bigger."
	bb_melee_force = 23
	bb_weight_class_change = 1

/obj/item/blood_brother_gun_part/underbarrel/foregrip
	name = "scrap foregrip"
	icon_state = "scrap_foregrip_underbarrel"
	desc = "A retractable handle bolted under a weapon. It steadies your aim and makes dual wielding much easier, and it folds away so it doesn't get in the way."
	bb_spread_multiplier = 0.5
	bb_dual_wield_spread_multiplier = 0.25
