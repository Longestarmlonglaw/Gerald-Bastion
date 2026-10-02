/**
 * Blood Brother modular gun.
 *
 * Tracks the upgrade slots a Blood Brother weapon exposes and the parts installed in them,
 * and applies the stats of the installed receiver to the gun.
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
	/// How many weight classes the current magazine part has added to the gun.
	var/applied_weight_class_increase = 0
	/// Whether someone is currently loading ammunition through a magazine with a load delay.
	var/loading = FALSE
	/// How much charge the energy gun's cell holds before any power cell part. Null if it isn't an energy gun.
	var/base_cell_maxcharge
	/// Whether the gun's self-charging was turned on by the current power cell part.
	var/added_selfcharge = FALSE

/datum/component/blood_brother_gun/Initialize(weapon_family, list/part_slots, list/default_parts)
	if(!isgun(parent))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/gun/gun = parent
	src.weapon_family = weapon_family
	src.part_slots = part_slots
	base_fire_delay = gun.fire_delay
	var/obj/item/ammo_box/magazine/internal/internal_magazine = get_internal_magazine()
	if(internal_magazine)
		base_capacity = internal_magazine.max_ammo
	var/obj/item/gun/energy/energy_gun = gun
	if(istype(energy_gun) && energy_gun.cell)
		base_cell_maxcharge = energy_gun.cell.maxcharge

	for(var/part_type in default_parts)
		var/obj/item/blood_brother_gun_part/part = new part_type(gun)
		LAZYSET(installed_parts, part.bb_part_slot, part)
	update_receiver()

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

/datum/component/blood_brother_gun/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_ATOM_EXITED,
		COMSIG_CLICK_ALT_SECONDARY,
		COMSIG_GUN_TRY_FIRE,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_EMP_ACT,
		COMSIG_GUN_FIRED,
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

/datum/component/blood_brother_gun/proc/can_modify_slot(slot, mob/living/user)
	// Energy guns can be modified at any time. Swapping their power cell drains them instead, see on_part_changed().
	if(istype(parent, /obj/item/gun/energy))
		return TRUE
	if(is_loaded())
		var/obj/item/gun/gun = parent
		gun.balloon_alert(user, "unload it first!")
		return FALSE
	return TRUE

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
	gun.update_appearance()

/// Returns the gun's internal magazine, if it has one. Magazine parts only work on internal magazines.
/datum/component/blood_brother_gun/proc/get_internal_magazine()
	var/obj/item/gun/ballistic/ballistic_gun = parent
	if(!istype(ballistic_gun) || !ballistic_gun.internal_magazine)
		return null
	return ballistic_gun.magazine

/// Sets how many rounds the internal magazine holds before any magazine part, such as when the scrap revolver changes caliber.
/datum/component/blood_brother_gun/proc/set_base_capacity(new_capacity)
	base_capacity = new_capacity
	update_magazine()

/// Applies the installed magazine part's capacity and weight to the gun, replacing those of the previous magazine.
/datum/component/blood_brother_gun/proc/update_magazine()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/magazine/magazine_part = get_part(BB_GUN_PART_MAGAZINE)

	var/new_weight_class_increase = magazine_part ? magazine_part.bb_weight_class_increase : 0
	if(new_weight_class_increase != applied_weight_class_increase)
		gun.update_weight_class(gun.w_class - applied_weight_class_increase + new_weight_class_increase)
		applied_weight_class_increase = new_weight_class_increase

	var/obj/item/ammo_box/magazine/internal/internal_magazine = get_internal_magazine()
	if(!internal_magazine || isnull(base_capacity))
		return
	internal_magazine.max_ammo = base_capacity + (magazine_part ? magazine_part.bb_extra_rounds : 0)
	resize_internal_magazine(internal_magazine)

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
	if(!energy_gun.cell)
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
	radiation_pulse(energy_gun, max_range = 2, threshold = RAD_LIGHT_INSULATION, chance = 20)

/// Applies the installed receiver's stats to the gun, replacing those of the previous receiver.
/datum/component/blood_brother_gun/proc/update_receiver()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/receiver/receiver = get_part(BB_GUN_PART_RECEIVER)

	gun.projectile_damage_multiplier /= applied_damage_multiplier
	gun.projectile_speed_multiplier /= applied_speed_multiplier
	applied_damage_multiplier = receiver ? receiver.bb_damage_multiplier : 1
	applied_speed_multiplier = receiver ? receiver.bb_projectile_speed_multiplier : 1
	gun.projectile_damage_multiplier *= applied_damage_multiplier
	gun.projectile_speed_multiplier *= applied_speed_multiplier

	update_fire_delay()

	if(added_autofire)
		qdel(gun.GetComponent(/datum/component/automatic_fire))
		added_autofire = FALSE
	if(receiver?.bb_receiver_type == BB_GUN_RECEIVER_AUTOMATIC)
		gun.AddComponent(/datum/component/automatic_fire, receiver.bb_fire_interval)
		added_autofire = TRUE

/datum/component/blood_brother_gun/proc/update_fire_delay()
	var/obj/item/gun/gun = parent
	var/obj/item/blood_brother_gun_part/receiver/receiver = get_part(BB_GUN_PART_RECEIVER)
	gun.fire_delay = receiver?.bb_fire_interval || get_base_fire_delay()

/datum/component/blood_brother_gun/proc/get_base_fire_delay()
	var/obj/item/gun/energy/energy_gun = parent
	if(istype(energy_gun))
		var/obj/item/ammo_casing/energy/shot = energy_gun.ammo_type[energy_gun.select]
		return shot.delay
	return base_fire_delay

/datum/component/blood_brother_gun/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("This is a modular Blood Brother weapon assembled from scavenged components.")
	examine_list += span_notice("<b>Alt-right-click</b> it while holding it to remove an installed upgrade.")
	for(var/slot in part_slots)
		var/obj/item/part = get_part(slot)
		examine_list += span_notice("[capitalize(slot)]: [part ? part.name : "empty"]")
	if(get_unstable_cell())
		examine_list += span_warning("Its unstable cell can be recharged by feeding it <b>uranium sheets</b>.")

/// Keeps the installed parts in sync if one leaves the gun by any means.
/datum/component/blood_brother_gun/proc/on_exited(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER

	for(var/slot in installed_parts)
		if(installed_parts[slot] != gone)
			continue
		LAZYREMOVE(installed_parts, slot)
		on_part_changed(slot)
		return

/datum/component/blood_brother_gun/proc/on_click_alt_secondary(datum/source, mob/user)
	SIGNAL_HANDLER

	if(!user.is_holding(parent))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(choose_part_to_remove), user)
	return COMPONENT_CANCEL_CLICK_ALT_SECONDARY

/datum/component/blood_brother_gun/proc/choose_part_to_remove(mob/living/user)
	var/obj/item/gun/gun = parent
	var/list/available_parts = list()
	for(var/slot in part_slots)
		var/obj/item/part = get_part(slot)
		if(part)
			available_parts["[part.name] ([slot])"] = slot

	if(!length(available_parts))
		gun.balloon_alert(user, "no upgrades installed!")
		return

	var/selected_part = tgui_input_list(user, "Choose an installed upgrade to remove.", "Blood Brother Upgrades", available_parts)
	if(isnull(selected_part) || QDELETED(src) || !user.is_holding(gun))
		return
	remove_part(user, available_parts[selected_part])

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

/// Unstable cells sometimes spark and leak radiation when the gun fires a shot.
/datum/component/blood_brother_gun/proc/on_fired(obj/item/gun/source, mob/living/user, atom/target, params, zone_override)
	SIGNAL_HANDLER

	if(!get_unstable_cell())
		return
	// This signal is sent on every trigger pull, even while the gun is cooling down or has nothing to fire, so ignore those.
	if(source.semicd || !source.chambered?.loaded_projectile)
		return
	if(prob(25))
		do_sparks(2, FALSE, source)
	if(prob(20))
		radiation_pulse(source, max_range = 1, threshold = RAD_LIGHT_INSULATION, chance = 100)

/datum/component/blood_brother_gun/proc/delayed_load(obj/item/ammo, mob/living/user, delay)
	if(loading)
		return
	var/obj/item/gun/ballistic/ballistic_gun = parent
	loading = TRUE
	ballistic_gun.balloon_alert(user, "loading...")
	if(do_after(user, delay, ballistic_gun) && !QDELETED(ammo))
		ballistic_gun.load_gun(ammo, user)
	loading = FALSE

/datum/component/blood_brother_gun/proc/on_try_fire(obj/item/gun/source, mob/living/user, atom/target, flag, params)
	SIGNAL_HANDLER

	if(!get_part(BB_GUN_PART_RECEIVER))
		source.balloon_alert(user, "no receiver!")
		return COMPONENT_CANCEL_GUN_FIRE
	// Energy guns reset their fire delay when switching firing modes, so reapply the receiver's before every shot.
	update_fire_delay()
	return NONE
