/**
 * Blood Brother modular gun.
 *
 * Tracks the upgrade slots a Blood Brother weapon exposes and the parts installed in them,
 * and applies their effects to the gun: receivers change damage, speed and fire rate,
 * magazines change an internal magazine's capacity, power cells change an energy gun's cell,
 * lenses change an energy gun's shots, and barrels change a ballistic gun's shots.
 *
 * Add it to a gun with AddComponent(), listing its weapon family, slots and any default parts.
 * The part types and their stats live in bloodbrothergunparts.dm.
 */
/datum/component/blood_brother_gun
	/// Upgrade slots this gun exposes, as BB_GUN_PART_* defines.
	var/list/part_slots
	/// Installed parts, keyed by BB_GUN_PART_* slot define.
	var/list/installed_parts
	/// Weapon family used for part compatibility, as a BB_GUN_* define.
	var/weapon_family
	/// The gun's fire delay before any receiver was applied. Energy guns use their selected shot's delay instead.
	var/base_fire_delay
	/// Projectile damage multiplier the current receiver has applied to the gun.
	var/applied_damage_multiplier = 1
	/// Projectile speed multiplier the current receiver has applied to the gun.
	var/applied_speed_multiplier = 1
	/// Whether the gun's automatic fire component was added by the current receiver.
	var/added_autofire = FALSE
	/// How many rounds the gun's internal magazine holds before any magazine part. Null if it has no internal magazine.
	var/base_capacity
	/// Multiplier applied to the internal magazine's total capacity, after the magazine part's extra rounds. Used by the scrap revolver's shotgun mode.
	var/capacity_multiplier = 1
	/// How many weight classes the current magazine and barrel have added to the gun. Can be negative.
	var/applied_weight_class_change = 0
	/// Whether someone is currently loading ammunition through a magazine with a load delay.
	var/loading = FALSE
	/// How much charge the energy gun's cell holds before any power cell part. Null if it isn't an energy gun.
	var/base_cell_maxcharge
	/// Whether the gun's self-charging was turned on by the current power cell part.
	var/added_selfcharge = FALSE
	/// The gun's spread before any parts.
	var/base_spread
	/// The gun's extra dual wielding spread before any parts.
	var/base_dual_wield_spread
	/// The gun's melee damage before any underbarrel.
	var/base_force
	/// The gun's melee sharpness before any underbarrel.
	var/base_sharpness
	/// The gun's melee hit sound before any underbarrel.
	var/base_hitsound

/datum/component/blood_brother_gun/Initialize(weapon_family, list/part_slots, list/default_parts)
	if(!isgun(parent))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/gun/gun = parent
	src.weapon_family = weapon_family
	src.part_slots = part_slots
	base_fire_delay = gun.fire_delay
	base_spread = gun.spread
	base_dual_wield_spread = gun.dual_wield_spread
	base_force = gun.force
	base_sharpness = gun.sharpness
	base_hitsound = gun.hitsound
	var/obj/item/ammo_box/magazine/internal/internal_magazine = get_internal_magazine()
	if(internal_magazine)
		base_capacity = internal_magazine.max_ammo
	var/obj/item/gun/energy/energy_gun = gun
	if(istype(energy_gun) && energy_gun.cell)
		base_cell_maxcharge = energy_gun.cell.maxcharge

	for(var/part_type in default_parts)
		var/obj/item/blood_brother_gun_part/part = new part_type(gun)
		LAZYSET(installed_parts, part.bb_part_slot, part)
	// Apply every default part's effects. Unlike on_part_changed(), this doesn't drain the gun's cell.
	// update_lens() and update_barrel() both reapply the receiver.
	update_lens()
	update_barrel()
	update_underbarrel()
	update_magazine()
	update_power_cell()

/datum/component/blood_brother_gun/Destroy(force)
	installed_parts = null
	return ..()

/datum/component/blood_brother_gun/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(on_exited))
	RegisterSignal(parent, COMSIG_CLICK_ALT_SECONDARY, PROC_REF(on_click_alt_secondary))
	RegisterSignal(parent, COMSIG_GUN_TRY_FIRE, PROC_REF(on_try_fire))
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp))
	RegisterSignal(parent, COMSIG_GUN_FIRED, PROC_REF(on_fired))
	RegisterSignal(parent, COMSIG_PROJECTILE_BEFORE_FIRE, PROC_REF(on_projectile_before_fire))
	// Right-clicking with the gun fires a firing underbarrel, both up close and at range.
	RegisterSignals(parent, list(COMSIG_ITEM_INTERACTING_WITH_ATOM_SECONDARY, COMSIG_RANGED_ITEM_INTERACTING_WITH_ATOM_SECONDARY), PROC_REF(on_secondary_fire))
	// Right-clicking the gun with an item loads it into a firing underbarrel.
	RegisterSignal(parent, COMSIG_ATOM_ITEM_INTERACTION_SECONDARY, PROC_REF(on_secondary_item_interaction))
	// Each energy firing mode readies a fresh projectile every shot, which is where the lens's per-shot effects get added.
	var/obj/item/gun/energy/energy_gun = parent
	if(istype(energy_gun))
		for(var/obj/item/ammo_casing/energy/shot in energy_gun.ammo_type)
			RegisterSignal(shot, COMSIG_CASING_READY_PROJECTILE, PROC_REF(on_ready_projectile))

/datum/component/blood_brother_gun/UnregisterFromParent()
	var/obj/item/gun/energy/energy_gun = parent
	if(istype(energy_gun))
		for(var/obj/item/ammo_casing/energy/shot in energy_gun.ammo_type)
			UnregisterSignal(shot, COMSIG_CASING_READY_PROJECTILE)
	UnregisterSignal(parent, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_ATOM_EXITED,
		COMSIG_CLICK_ALT_SECONDARY,
		COMSIG_GUN_TRY_FIRE,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_EMP_ACT,
		COMSIG_GUN_FIRED,
		COMSIG_PROJECTILE_BEFORE_FIRE,
		COMSIG_ITEM_INTERACTING_WITH_ATOM_SECONDARY,
		COMSIG_RANGED_ITEM_INTERACTING_WITH_ATOM_SECONDARY,
		COMSIG_ATOM_ITEM_INTERACTION_SECONDARY,
	))

/// Returns the part installed in the given slot, if any.
/datum/component/blood_brother_gun/proc/get_part(slot)
	return LAZYACCESS(installed_parts, slot)

/// Whether the gun is loaded in a way that makes swapping parts unsafe.
/datum/component/blood_brother_gun/proc/is_loaded()
	var/obj/item/gun/gun = parent
	if(gun.chambered?.loaded_projectile)
		return TRUE
	if(istype(gun, /obj/item/gun/ballistic))
		var/obj/item/gun/ballistic/ballistic_gun = gun
		if(ballistic_gun.get_ammo(FALSE, FALSE))
			return TRUE
	return FALSE

/// Whether parts can be swapped in the given slot right now. Ballistic guns must be unloaded first.
/datum/component/blood_brother_gun/proc/can_modify_slot(slot, mob/living/user)
	// Energy guns can be modified at any time. Swapping their power cell drains them instead, see on_part_changed().
	if(istype(parent, /obj/item/gun/energy))
		return TRUE
	if(is_loaded())
		var/obj/item/gun/gun = parent
		gun.balloon_alert(user, "unload it first!")
		return FALSE
	return TRUE

/// Installs a part from the user's hands, swapping out whatever was in that slot before. Returns TRUE on success.
/datum/component/blood_brother_gun/proc/try_install_part(obj/item/blood_brother_gun_part/part, mob/living/user)
	var/obj/item/gun/gun = parent
	var/slot = part.bb_part_slot
	if(!slot || !(slot in part_slots))
		gun.balloon_alert(user, "incompatible part!")
		return FALSE
	if(part.bb_weapon_family && part.bb_weapon_family != weapon_family)
		gun.balloon_alert(user, "wrong weapon type!")
		return FALSE
	if(!can_modify_slot(slot, user))
		return FALSE

	var/obj/item/old_part = get_part(slot)
	if(!user.transferItemToLoc(part, gun))
		return FALSE
	LAZYSET(installed_parts, slot, part)
	if(old_part && !user.put_in_hands(old_part))
		old_part.forceMove(gun.drop_location())

	on_part_changed(slot)
	to_chat(user, span_notice("You install [part] into [gun]."))
	return TRUE

/// Takes the part out of the given slot and puts it in the user's hands. Returns TRUE on success.
/datum/component/blood_brother_gun/proc/remove_part(mob/living/user, slot)
	if(!can_modify_slot(slot, user))
		return FALSE
	var/obj/item/part = get_part(slot)
	if(!part)
		return FALSE

	var/obj/item/gun/gun = parent
	LAZYREMOVE(installed_parts, slot)
	if(!user.put_in_hands(part))
		part.forceMove(gun.drop_location())

	on_part_changed(slot)
	to_chat(user, span_notice("You remove [part] from [gun]."))
	return TRUE

/// Applies the effects of a part being added to or removed from the given slot.
/datum/component/blood_brother_gun/proc/on_part_changed(slot)
	var/obj/item/gun/gun = parent
	switch(slot)
		if(BB_GUN_PART_POWER_CELL)
			update_power_cell()
			drain_cell()
		if(BB_GUN_PART_RECEIVER)
			update_receiver()
		if(BB_GUN_PART_MAGAZINE)
			update_magazine()
		if(BB_GUN_PART_LENS)
			update_lens()
		if(BB_GUN_PART_BARREL)
			update_barrel()
		if(BB_GUN_PART_UNDERBARREL)
			update_underbarrel()
	gun.update_appearance()

/// Returns the gun's internal magazine, if it has one. Magazine parts only work on internal magazines.
/datum/component/blood_brother_gun/proc/get_internal_magazine()
	var/obj/item/gun/ballistic/ballistic_gun = parent
	if(!istype(ballistic_gun) || !ballistic_gun.internal_magazine)
		return null
	return ballistic_gun.magazine

/// Sets how many rounds the internal magazine holds before any magazine part.
/datum/component/blood_brother_gun/proc/set_base_capacity(new_capacity)
	base_capacity = new_capacity
	update_magazine()

/// Sets the multiplier applied to the internal magazine's total capacity, such as when the scrap revolver switches to shotgun shells.
/datum/component/blood_brother_gun/proc/set_capacity_multiplier(new_multiplier)
	capacity_multiplier = new_multiplier
	update_magazine()

/// Applies the installed magazine part's capacity and weight to the gun, replacing those of the previous magazine.
/datum/component/blood_brother_gun/proc/update_magazine()
	var/obj/item/blood_brother_gun_part/magazine/magazine_part = get_part(BB_GUN_PART_MAGAZINE)

	update_weight_class()

	var/obj/item/ammo_box/magazine/internal/internal_magazine = get_internal_magazine()
	if(!internal_magazine || isnull(base_capacity))
		return
	var/total_capacity = (base_capacity + (magazine_part ? magazine_part.bb_extra_rounds : 0)) * capacity_multiplier
	internal_magazine.max_ammo = max(round(total_capacity), 1)
	resize_internal_magazine(internal_magazine)

/// Applies the combined size change of the installed magazine, barrel and underbarrel, replacing the previous change.
/datum/component/blood_brother_gun/proc/update_weight_class()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/magazine/magazine_part = get_part(BB_GUN_PART_MAGAZINE)
	var/obj/item/blood_brother_gun_part/barrel/barrel = get_part(BB_GUN_PART_BARREL)
	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)

	var/new_change = (magazine_part ? magazine_part.bb_weight_class_increase : 0) \
		+ (barrel ? barrel.bb_weight_class_change : 0) \
		+ (underbarrel ? underbarrel.bb_weight_class_change : 0)
	if(new_change == applied_weight_class_change)
		return
	var/base_w_class = gun.w_class - applied_weight_class_change
	// Never shrink the gun below tiny or grow it past huge.
	var/new_w_class = clamp(base_w_class + new_change, WEIGHT_CLASS_TINY, WEIGHT_CLASS_HUGE)
	gun.update_weight_class(new_w_class)
	applied_weight_class_change = new_w_class - base_w_class

/// Makes the internal magazine's stored rounds fit its current capacity, dropping anything that no longer fits.
/datum/component/blood_brother_gun/proc/resize_internal_magazine(obj/item/ammo_box/magazine/internal/internal_magazine)
	var/obj/item/gun/gun = parent
	var/list/overflow = list()
	while(length(internal_magazine.stored_ammo) > internal_magazine.max_ammo)
		var/obj/item/ammo_casing/casing = internal_magazine.stored_ammo[length(internal_magazine.stored_ammo)]
		internal_magazine.stored_ammo.len--
		if(istype(casing))
			overflow += casing
	// Cylinders keep one entry per chamber, empty or not.
	if(istype(internal_magazine, /obj/item/ammo_box/magazine/internal/cylinder))
		while(length(internal_magazine.stored_ammo) < internal_magazine.max_ammo)
			internal_magazine.stored_ammo += null
	for(var/obj/item/ammo_casing/casing as anything in overflow)
		casing.forceMove(gun.drop_location())
	internal_magazine.update_appearance()

/// Empties an energy gun's cell. Done whenever its power cell part is added or removed.
/datum/component/blood_brother_gun/proc/drain_cell()
	var/obj/item/gun/energy/energy_gun = parent
	if(!istype(energy_gun) || !energy_gun.cell)
		return
	energy_gun.cell.charge = 0

/// Applies the installed power cell part's capacity and self-charging to the gun, replacing those of the previous cell.
/datum/component/blood_brother_gun/proc/update_power_cell()
	var/obj/item/gun/energy/energy_gun = parent
	if(!istype(energy_gun) || !energy_gun.cell || isnull(base_cell_maxcharge))
		return
	var/obj/item/blood_brother_gun_part/power_cell/cell_part = get_part(BB_GUN_PART_POWER_CELL)

	energy_gun.cell.maxcharge = base_cell_maxcharge * (cell_part ? cell_part.bb_capacity_multiplier : 1)
	energy_gun.cell.charge = min(energy_gun.cell.charge, energy_gun.cell.maxcharge)

	if(added_selfcharge)
		energy_gun.selfcharge = initial(energy_gun.selfcharge)
		if(!energy_gun.selfcharge)
			STOP_PROCESSING(SSobj, energy_gun)
		added_selfcharge = FALSE
	if(cell_part?.bb_self_recharging && !energy_gun.selfcharge)
		energy_gun.selfcharge = TRUE
		START_PROCESSING(SSobj, energy_gun)
		added_selfcharge = TRUE

/// Returns the installed power cell part if it's unstable, otherwise null.
/datum/component/blood_brother_gun/proc/get_unstable_cell()
	var/obj/item/blood_brother_gun_part/power_cell/cell_part = get_part(BB_GUN_PART_POWER_CELL)
	return cell_part?.bb_unstable ? cell_part : null

/// Recharges an unstable cell with a uranium sheet. Radiation leaks out each time.
/datum/component/blood_brother_gun/proc/feed_uranium(obj/item/stack/sheet/mineral/uranium/uranium, mob/living/user)
	var/obj/item/gun/energy/energy_gun = parent
	if(!istype(energy_gun) || !energy_gun.cell)
		return
	if(energy_gun.cell.charge >= energy_gun.cell.maxcharge)
		energy_gun.balloon_alert(user, "already fully charged!")
		return
	if(!uranium.use(1))
		return
	energy_gun.cell.give(energy_gun.cell.maxcharge * 0.25)
	energy_gun.recharge_newshot(TRUE)
	energy_gun.update_appearance()
	energy_gun.balloon_alert(user, "fed uranium")
	do_sparks(2, FALSE, energy_gun)
	// Pulse from the turf rather than the gun, so it still works while the gun is held or worn.
	radiation_pulse(get_turf(energy_gun), max_range = 2, threshold = RAD_LIGHT_INSULATION, chance = 20)

/// Applies the installed receiver's, lens's and barrel's damage, speed and fire rate to the gun, replacing those of the previous parts.
/datum/component/blood_brother_gun/proc/update_receiver()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/receiver/receiver = get_part(BB_GUN_PART_RECEIVER)
	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)
	var/obj/item/blood_brother_gun_part/barrel/barrel = get_part(BB_GUN_PART_BARREL)

	// The receiver's, lens's and barrel's multipliers all stack.
	gun.projectile_damage_multiplier /= applied_damage_multiplier
	gun.projectile_speed_multiplier /= applied_speed_multiplier
	applied_damage_multiplier = (receiver ? receiver.bb_damage_multiplier : 1) * (lens ? lens.bb_damage_multiplier : 1) * (barrel ? barrel.bb_damage_multiplier : 1)
	applied_speed_multiplier = (receiver ? receiver.bb_projectile_speed_multiplier : 1) * (lens ? lens.bb_projectile_speed_multiplier : 1)
	gun.projectile_damage_multiplier *= applied_damage_multiplier
	gun.projectile_speed_multiplier *= applied_speed_multiplier

	update_fire_delay()

	if(added_autofire)
		qdel(gun.GetComponent(/datum/component/automatic_fire))
		added_autofire = FALSE
	if(receiver?.bb_receiver_type == BB_GUN_RECEIVER_AUTOMATIC)
		gun.AddComponent(/datum/component/automatic_fire, receiver.bb_fire_interval * get_fire_delay_multiplier())
		added_autofire = TRUE

/// Sets the gun's delay between shots from the receiver (or the gun's own delay), adjusted by the lens.
/datum/component/blood_brother_gun/proc/update_fire_delay()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/receiver/receiver = get_part(BB_GUN_PART_RECEIVER)
	gun.fire_delay = (receiver?.bb_fire_interval || get_base_fire_delay()) * get_fire_delay_multiplier()

/// Returns how much the installed lens slows down or speeds up the gun's firing.
/datum/component/blood_brother_gun/proc/get_fire_delay_multiplier()
	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)
	return lens ? lens.bb_fire_delay_multiplier : 1

/// Applies the installed lens's effects to the gun, replacing those of the previous lens.
/// Damage, speed and fire rate are handled with the receiver, armour penetration, knockdown and teleporting in on_ready_projectile().
/datum/component/blood_brother_gun/proc/update_lens()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)

	update_receiver()
	update_spread()

	// Each firing mode's shot cost is reset from its original value, so lenses never stack.
	var/obj/item/gun/energy/energy_gun = gun
	if(!istype(energy_gun))
		return
	var/cost_multiplier = lens ? lens.bb_energy_cost_multiplier : 1
	for(var/obj/item/ammo_casing/energy/shot in energy_gun.ammo_type)
		shot.e_cost = initial(shot.e_cost) * cost_multiplier
	energy_gun.update_appearance()

/// Applies the installed barrel's effects to the gun, replacing those of the previous barrel.
/// Armour penetration and crits are added to each projectile in on_projectile_before_fire(), and the choke's tighter grouping in on_fired().
/datum/component/blood_brother_gun/proc/update_barrel()
	update_receiver()
	update_weight_class()
	update_spread()

/// Sets the gun's spread and dual wielding spread from its own values, adjusted by the installed lens, barrel and underbarrel.
/datum/component/blood_brother_gun/proc/update_spread()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)
	var/obj/item/blood_brother_gun_part/barrel/barrel = get_part(BB_GUN_PART_BARREL)
	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)

	var/extra_spread = (lens ? lens.bb_spread : 0) + (barrel ? barrel.bb_spread : 0)
	var/spread_multiplier = (barrel ? barrel.bb_spread_multiplier : 1) * (underbarrel ? underbarrel.bb_spread_multiplier : 1)
	var/dual_wield_multiplier = (barrel ? barrel.bb_dual_wield_spread_multiplier : 1) * (underbarrel ? underbarrel.bb_dual_wield_spread_multiplier : 1)
	gun.spread = (base_spread + extra_spread) * spread_multiplier
	gun.dual_wield_spread = base_dual_wield_spread * dual_wield_multiplier

/// Applies the installed underbarrel's effects to the gun, replacing those of the previous underbarrel.
/// Firing and loading are handled in on_secondary_fire() and on_secondary_item_interaction().
/datum/component/blood_brother_gun/proc/update_underbarrel()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)

	update_weight_class()
	update_spread()

	if(underbarrel?.bb_melee_force)
		gun.force = underbarrel.bb_melee_force
		gun.sharpness = SHARP_EDGED
		gun.hitsound = 'sound/weapons/bladeslice.ogg'
	else
		gun.force = base_force
		gun.sharpness = base_sharpness
		gun.hitsound = base_hitsound

/// Right-clicking with the gun fires a firing underbarrel, instead of bashing or holding someone up.
/datum/component/blood_brother_gun/proc/on_secondary_fire(obj/item/gun/source, mob/living/user, atom/target, list/modifiers)
	SIGNAL_HANDLER

	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)
	if(!underbarrel?.bb_fires || target == user)
		return NONE
	// Only fire at things out in the world, not at items in someone's inventory.
	if(!isturf(target) && !isturf(target.loc))
		return NONE
	INVOKE_ASYNC(underbarrel, TYPE_PROC_REF(/obj/item/blood_brother_gun_part/underbarrel, fire_at), target, user, source)
	return ITEM_INTERACT_SUCCESS

/// Right-clicking the gun with an item loads it into a firing underbarrel.
/datum/component/blood_brother_gun/proc/on_secondary_item_interaction(obj/item/gun/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER

	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)
	if(!underbarrel?.bb_fires)
		return NONE
	underbarrel.try_load(tool, user)
	return ITEM_INTERACT_BLOCKING

/// Adds the barrel's armour penetration and crits to each projectile the gun fires, including every buckshot pellet.
/datum/component/blood_brother_gun/proc/on_projectile_before_fire(obj/item/gun/source, obj/projectile/projectile, atom/original_target)
	SIGNAL_HANDLER

	var/obj/item/blood_brother_gun_part/barrel/barrel = get_part(BB_GUN_PART_BARREL)
	if(!barrel)
		return
	projectile.armour_penetration += barrel.bb_armour_penetration
	// Crits only apply to rounds that fire a single projectile, so buckshot can't crit, but slugs and revolver rounds can.
	// The round being fired is still chambered while its projectiles launch.
	if(barrel.bb_crit_chance && source.chambered?.pellets == 1 && prob(barrel.bb_crit_chance))
		projectile.damage *= 2
		RegisterSignal(projectile, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_crit_hit))

/// Lets the shooter know when one of their crits lands.
/datum/component/blood_brother_gun/proc/on_crit_hit(obj/projectile/source, atom/movable/firer, atom/target, angle, hit_limb, blocked)
	SIGNAL_HANDLER

	if(ismob(firer) && isliving(target))
		target.balloon_alert(firer, "critical hit!")

/// Adds the lens's armour penetration, knockdown and teleporting to each shot as it's fired.
/datum/component/blood_brother_gun/proc/on_ready_projectile(obj/item/ammo_casing/source, atom/target, mob/living/user, quiet, zone_override, atom/fired_from)
	SIGNAL_HANDLER

	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)
	var/obj/projectile/shot = source.loaded_projectile
	if(!lens || !shot)
		return
	shot.armour_penetration += lens.bb_armour_penetration
	if(lens.bb_knockdown)
		shot.knockdown = max(shot.knockdown, lens.bb_knockdown)
	if(lens.bb_teleport_chance)
		RegisterSignal(shot, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_teleporting_shot_hit))

/// Bluespace lens shots have a chance to teleport the mob they hit a short distance.
/datum/component/blood_brother_gun/proc/on_teleporting_shot_hit(obj/projectile/source, atom/movable/firer, atom/target, angle, hit_limb, blocked)
	SIGNAL_HANDLER

	var/obj/item/blood_brother_gun_part/lens/lens = get_part(BB_GUN_PART_LENS)
	if(!isliving(target) || !lens || !prob(lens.bb_teleport_chance))
		return
	do_teleport(target, get_turf(target), 4, channel = TELEPORT_CHANNEL_BLUESPACE)

/// Returns the gun's own delay between shots, ignoring any receiver.
/datum/component/blood_brother_gun/proc/get_base_fire_delay()
	var/obj/item/gun/energy/energy_gun = parent
	if(istype(energy_gun))
		var/obj/item/ammo_casing/energy/shot = energy_gun.ammo_type[energy_gun.select]
		return shot.delay
	return base_fire_delay

/// Lists the gun's upgrade slots and what's installed in them.
/datum/component/blood_brother_gun/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("This is a modular Blood Brother weapon assembled from scavenged components.")
	examine_list += span_notice("<b>Alt-right-click</b> it while holding it to remove an installed upgrade.")
	for(var/slot in part_slots)
		var/obj/item/part = get_part(slot)
		examine_list += span_notice("[capitalize(slot)]: [part ? part.name : "empty"]")
	if(get_unstable_cell())
		examine_list += span_warning("Its unstable cell can be recharged by feeding it <b>uranium sheets</b>.")
	var/obj/item/blood_brother_gun_part/underbarrel/underbarrel = get_part(BB_GUN_PART_UNDERBARREL)
	if(underbarrel?.bb_fires)
		examine_list += span_notice("<b>Right-click</b> the weapon with an item to load its [underbarrel.name], and <b>right-click</b> with it to fire. It's [underbarrel.loaded_item ? "loaded with [underbarrel.loaded_item]" : "empty"].")

/// Keeps the installed parts in sync if one leaves the gun by any means.
/datum/component/blood_brother_gun/proc/on_exited(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER

	for(var/slot in installed_parts)
		if(installed_parts[slot] != gone)
			continue
		LAZYREMOVE(installed_parts, slot)
		on_part_changed(slot)
		return

/// Alt-right-clicking the gun while holding it opens a menu to remove an installed part.
/datum/component/blood_brother_gun/proc/on_click_alt_secondary(datum/source, mob/user)
	SIGNAL_HANDLER

	if(!user.is_holding(parent))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(choose_part_to_remove), user)
	return COMPONENT_CANCEL_CLICK_ALT_SECONDARY

/// Shows a radial menu of the installed parts, then removes the one the user picks.
/datum/component/blood_brother_gun/proc/choose_part_to_remove(mob/living/user)
	var/obj/item/gun/gun = parent
	// Keyed by slot, so the menu returns the slot to remove.
	var/list/choices = list()
	for(var/slot in part_slots)
		var/obj/item/part = get_part(slot)
		if(!part)
			continue
		var/datum/radial_menu_choice/choice = new
		choice.name = "[part.name] ([slot])"
		choice.image = image(icon = part.icon, icon_state = part.icon_state)
		choices[slot] = choice

	if(!length(choices))
		gun.balloon_alert(user, "no upgrades installed!")
		return

	var/selected_slot = show_radial_menu(user, gun, choices, custom_check = CALLBACK(src, PROC_REF(can_use_part_menu), user), require_near = TRUE, tooltips = TRUE, autopick_single_option = FALSE)
	if(isnull(selected_slot) || QDELETED(src) || !can_use_part_menu(user))
		return
	remove_part(user, selected_slot)

/// Whether the user can still use the part removal menu. They have to keep holding the gun.
/datum/component/blood_brother_gun/proc/can_use_part_menu(mob/living/user)
	return !QDELETED(user) && user.is_holding(parent)

/// Handles feeding uranium to an unstable cell, and makes loading ammunition take time when the installed magazine has a load delay.
/datum/component/blood_brother_gun/proc/on_attackby(datum/source, obj/item/tool, mob/living/user, list/modifiers)
	SIGNAL_HANDLER

	if(istype(tool, /obj/item/stack/sheet/mineral/uranium) && get_unstable_cell())
		feed_uranium(tool, user)
		return COMPONENT_NO_AFTERATTACK

	var/obj/item/blood_brother_gun_part/magazine/magazine_part = get_part(BB_GUN_PART_MAGAZINE)
	if(!magazine_part?.bb_load_delay || !get_internal_magazine())
		return NONE
	if(!isammocasing(tool) && !istype(tool, /obj/item/ammo_box))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(delayed_load), tool, user, magazine_part.bb_load_delay)
	return COMPONENT_NO_AFTERATTACK

/// EMP shielded cells soak up the pulse and recharge the gun, while unstable cells violently discharge into whoever is holding it.
/datum/component/blood_brother_gun/proc/on_emp(datum/source, severity)
	SIGNAL_HANDLER

	var/obj/item/gun/energy/energy_gun = parent
	var/obj/item/blood_brother_gun_part/power_cell/cell_part = get_part(BB_GUN_PART_POWER_CELL)
	if(!istype(energy_gun) || !energy_gun.cell || !cell_part)
		return NONE

	if(cell_part.bb_emp_recharges)
		energy_gun.cell.give(energy_gun.cell.maxcharge)
		energy_gun.recharge_newshot(TRUE)
		energy_gun.update_appearance()
		energy_gun.visible_message(span_notice("[energy_gun] crackles as it soaks up the pulse!"))
		// Stops the gun from draining its cell, and protects the parts inside it.
		return EMP_PROTECT_CONTENTS

	if(cell_part.bb_unstable)
		energy_gun.cell.use(energy_gun.cell.charge)
		do_sparks(5, TRUE, energy_gun)
		var/mob/living/holder = energy_gun.loc
		if(istype(holder))
			holder.electrocute_act(20, energy_gun)
		energy_gun.visible_message(span_danger("[energy_gun]'s unstable cell violently discharges!"))
	return NONE

/// Applies the barrel's tighter grouping to the round about to be fired, and makes unstable cells sometimes spark and leak radiation.
/datum/component/blood_brother_gun/proc/on_fired(obj/item/gun/source, mob/living/user, atom/target, params, zone_override)
	SIGNAL_HANDLER

	// This signal is sent on every trigger pull, even while the gun is cooling down or has nothing to fire, so ignore those.
	if(source.semicd || !source.chambered?.loaded_projectile)
		return

	// A round's inaccuracy, including buckshot pellet spread, comes from its variance.
	// It's always set from the round's original value, so it can't stack.
	var/obj/item/blood_brother_gun_part/barrel/barrel = get_part(BB_GUN_PART_BARREL)
	if(barrel)
		source.chambered.variance = initial(source.chambered.variance) * barrel.bb_spread_multiplier

	if(!get_unstable_cell())
		return
	if(prob(25))
		do_sparks(2, FALSE, source)
	if(prob(20))
		// Pulse from the turf rather than the gun, so it still works while the gun is held.
		radiation_pulse(get_turf(source), max_range = 1, threshold = RAD_LIGHT_INSULATION, chance = 100)

/// Loads the ammo into the gun after a delay, for magazines with a load delay like the bluespace magazine.
/datum/component/blood_brother_gun/proc/delayed_load(obj/item/ammo, mob/living/user, delay)
	if(loading)
		return
	var/obj/item/gun/ballistic/ballistic_gun = parent
	loading = TRUE
	ballistic_gun.balloon_alert(user, "loading...")
	// The ammo has to still be in their hands, so they can't put it away mid-load and have it load anyway.
	if(do_after(user, delay, ballistic_gun) && !QDELETED(ammo) && user.is_holding(ammo))
		ballistic_gun.load_gun(ammo, user)
	loading = FALSE

/// Stops the gun from firing without a receiver.
/datum/component/blood_brother_gun/proc/on_try_fire(obj/item/gun/source, mob/living/user, atom/target, flag, params)
	SIGNAL_HANDLER

	if(!get_part(BB_GUN_PART_RECEIVER))
		source.balloon_alert(user, "no receiver!")
		return COMPONENT_CANCEL_GUN_FIRE
	// Energy guns reset their fire delay when switching firing modes, so reapply the receiver's before every shot.
	update_fire_delay()
	return NONE
