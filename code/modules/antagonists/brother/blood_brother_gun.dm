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

/datum/component/blood_brother_gun/Initialize(weapon_family, list/part_slots, list/default_parts)
	if(!isgun(parent))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/gun/gun = parent
	src.weapon_family = weapon_family
	src.part_slots = part_slots
	base_fire_delay = gun.fire_delay

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

/datum/component/blood_brother_gun/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_ATOM_EXITED,
		COMSIG_CLICK_ALT_SECONDARY,
		COMSIG_GUN_TRY_FIRE,
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
			drain_cell()
		if(BB_GUN_PART_RECEIVER)
			update_receiver()
	gun.update_appearance()

/datum/component/blood_brother_gun/proc/drain_cell()
	var/obj/item/gun/energy/energy_gun = parent
	if(!istype(energy_gun) || !energy_gun.cell)
		return
	energy_gun.cell.charge = 0

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

/datum/component/blood_brother_gun/proc/on_try_fire(obj/item/gun/source, mob/living/user, atom/target, flag, params)
	SIGNAL_HANDLER

	if(!get_part(BB_GUN_PART_RECEIVER))
		source.balloon_alert(user, "no receiver!")
		return COMPONENT_CANCEL_GUN_FIRE
	// Energy guns reset their fire delay when switching firing modes, so reapply the receiver's before every shot.
	update_fire_delay()
	return NONE
