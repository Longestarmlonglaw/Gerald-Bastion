/datum/antagonist/arcfiend
	name = "\improper Arcfiend"
	roundend_category = "arcfiends"
	antagpanel_category = "Arcfiend"
	job_rank = ROLE_ARCFIEND
	antag_moodlet = /datum/mood_event/focused
	hijack_speed = 0.5 //same as traitors, 10 seconds per hijack stage
	show_name_in_check_antagonists = TRUE
	ui_name = "AntagInfoArcfiend"
	can_assign_self_objectives = TRUE
	default_custom_objective = "Drain the station dry."

	/// Power currently stored. Spent on both abilities and upgrades.
	var/power = 0
	/// The most power we can hold at once
	var/power_cap = 2500
	/// Everything we have ever absorbed into our pool, checked by the drain objective
	var/total_drained = 0
	/// Whether we generate objectives on gain. Admins/other code can turn this off to hand out custom ones.
	var/give_objectives = TRUE
	/// Set if we rolled a hijack ending objective instead of escape
	var/hijacker = FALSE

	/// Every power we have unlocked. Everyone starts with the free ones.
	var/list/unlocked_powers = list(
		/datum/action/cooldown/arcfiend/sap_power,
		/datum/action/cooldown/arcfiend/ride_lightning,
		/datum/action/cooldown/arcfiend/charge,
		/datum/action/cooldown/arcfiend/shock_prod,
	)
	/// Assoc list of power type to the upgrade level we bought it to. Anything missing is level 1.
	var/list/power_levels = list()
	/// The passive powers we have. They have no button, so they never end up in the mob's list of actions, and we keep track of them here instead.
	var/list/datum/action/cooldown/arcfiend/passive/passive_powers = list()

	/// Unique minds that we've drained enough from to count towards unlocking higher tiers
	var/list/datum/mind/drained_minds = list()
	/// Assoc list of mind to how much we've drained from them so far, until they cross the threshold and are moved into drained_minds
	var/list/mind_drain_progress = list()
	/// Minds counted towards unlocks that an admin handed out, for testing
	var/bonus_minds_drained = 0
	/// Unique minds that must be drained before each shop tier unlocks. Index is the tier.
	var/static/list/tier_mind_requirements = list(0, 1, 3)

	/// Set while we are casting our own EMP, so that it doesn't hurt us
	var/emitting_emp = FALSE
	/// Multiplier to burn damage taken, a small natural resistance
	var/burn_resistance = 0.85
	/// Multiplier to stamina damage taken, a small natural resistance to batons and the like
	var/stamina_resistance = 0.85

/datum/antagonist/arcfiend/New(give_objectives = TRUE)
	. = ..()
	src.give_objectives = give_objectives

/datum/antagonist/arcfiend/on_gain()
	owner.special_role = job_rank
	if(give_objectives)
		forge_objectives()
	START_PROCESSING(SSprocessing, src)
	return ..()

/datum/antagonist/arcfiend/on_removal()
	STOP_PROCESSING(SSprocessing, src)
	owner.special_role = null
	return ..()

/datum/antagonist/arcfiend/process(seconds_per_tick)
	var/mob/living/current_mob = owner?.current
	if(current_mob && current_mob.stat != DEAD)
		reveal_cables(current_mob)
		for(var/datum/action/cooldown/arcfiend/passive/passive_power as anything in passive_powers)
			passive_power.passive_tick(current_mob, seconds_per_tick)

/// Briefly shows every hidden cable around us, like a built-in T-ray scanner that only shows cables
/datum/antagonist/arcfiend/proc/reveal_cables(mob/living/viewer)
	if(!viewer.client)
		return
	var/list/cable_images = list()
	for(var/obj/structure/cable/cable in range(ARCFIEND_CABLE_SIGHT_RANGE, get_turf(viewer)))
		if(!HAS_TRAIT(cable, TRAIT_T_RAY_VISIBLE))
			continue
		var/image/cable_image = new(loc = get_turf(cable))
		var/mutable_appearance/cable_appearance = new(cable)
		cable_appearance.alpha = 128
		cable_appearance.dir = cable.dir
		cable_image.appearance = cable_appearance
		cable_images += cable_image
	if(length(cable_images))
		flick_overlay_global(cable_images, list(viewer.client), 12)

/datum/antagonist/arcfiend/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current_mob = mob_override || owner.current
	if(!current_mob)
		return
	handle_clown_mutation(current_mob, mob_override ? null : "Your power allows you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	// Full body insulation. An arcfiend can never be hurt by electric shocks.
	current_mob.add_traits(list(TRAIT_SHOCKIMMUNE, TRAIT_TESLA_SHOCKIMMUNE, TRAIT_AIRLOCK_SHOCKIMMUNE), ARCFIEND_TRAIT)
	// Their heart can't be stopped, but they still need it: if it takes enough damage to fail, it stops like anyone's would
	ADD_TRAIT(current_mob, TRAIT_HEART_ATTACK_IMMUNE, ARCFIEND_TRAIT)
	// Being so attuned to machines, an arcfiend sees how they work, and can feel every cable nearby (see reveal_cables)
	current_mob.add_traits(list(TRAIT_KNOW_ALL_WIRES, TRAIT_DIAGNOSTIC_HUD), ARCFIEND_TRAIT)
	var/datum/atom_hud/diagnostic_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
	diagnostic_hud.show_to(current_mob)
	// A small resistance to burns and stamina damage
	if(ishuman(current_mob))
		var/mob/living/carbon/human/human_mob = current_mob
		human_mob.physiology.burn_mod *= burn_resistance
		human_mob.physiology.stamina_mod *= stamina_resistance
	// We act as a faraday cage for everything we carry, but not for ourselves
	RegisterSignal(current_mob, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp_act))
	// Pressing the drop key dispels the things we grow, instead of trying to drop them
	RegisterSignal(current_mob, COMSIG_KB_MOB_DROPITEM_DOWN, PROC_REF(on_drop_key))

	if(current_mob.hud_used?.arcfiend_counter)
		current_mob.hud_used.arcfiend_counter.SetInvisibility(INVISIBILITY_NONE, id = type)
		update_power_hud()

	grant_powers(current_mob)

/datum/antagonist/arcfiend/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current_mob = mob_override || owner.current
	if(!current_mob)
		return
	handle_clown_mutation(current_mob, removing = FALSE)
	current_mob.remove_traits(list(TRAIT_SHOCKIMMUNE, TRAIT_TESLA_SHOCKIMMUNE, TRAIT_AIRLOCK_SHOCKIMMUNE, TRAIT_KNOW_ALL_WIRES, TRAIT_DIAGNOSTIC_HUD, TRAIT_HEART_ATTACK_IMMUNE), ARCFIEND_TRAIT)
	var/datum/atom_hud/diagnostic_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_BASIC]
	diagnostic_hud.hide_from(current_mob)
	if(ishuman(current_mob))
		var/mob/living/carbon/human/human_mob = current_mob
		human_mob.physiology.burn_mod /= burn_resistance
		human_mob.physiology.stamina_mod /= stamina_resistance
	UnregisterSignal(current_mob, list(COMSIG_ATOM_EMP_ACT, COMSIG_KB_MOB_DROPITEM_DOWN))
	if(current_mob.hud_used?.arcfiend_counter)
		current_mob.hud_used.arcfiend_counter.RemoveInvisibility(type)
		current_mob.hud_used.arcfiend_counter.maptext = ""
	for(var/datum/action/cooldown/arcfiend/power in current_mob.actions)
		qdel(power)
	// The passives have no button, so they aren't in the list above
	for(var/datum/action/cooldown/arcfiend/passive/passive_power as anything in passive_powers.Copy())
		qdel(passive_power)

/datum/antagonist/arcfiend/greet()
	. = ..()
	to_chat(owner.current, span_boldannounce("You are an arcfiend. You live off the station's electricity."))
	to_chat(owner.current, span_notice("Electric shocks can't hurt you, but everything else can, and outside EMPs will hurt you too. Whatever you carry is safe from them."))
	owner.announce_objectives()

/// The power of this type that we have, if any. Passives are kept in their own list since they have no button.
/datum/antagonist/arcfiend/proc/get_power_instance(power_type, mob/living/current_mob = owner?.current)
	var/datum/action/cooldown/arcfiend/found = locate(power_type) in current_mob?.actions
	return found || (locate(power_type) in passive_powers)

/// Hands out every power we have unlocked that we don't already have
/datum/antagonist/arcfiend/proc/grant_powers(mob/living/current_mob)
	for(var/power_type in unlocked_powers)
		var/datum/action/cooldown/arcfiend/power_action = get_power_instance(power_type, current_mob)
		if(!power_action)
			power_action = new power_type(owner)
		// Granting something already ours would just register its signals a second time
		if(power_action.owner != current_mob)
			power_action.Grant(current_mob)

/// How far we've upgraded a power
/datum/antagonist/arcfiend/proc/get_power_level(power_type)
	return power_levels[power_type] || 1

/// Gives power to the arcfiend, up to the cap. Returns how much was actually gained.
/datum/antagonist/arcfiend/proc/add_power(amount)
	if(amount <= 0)
		return 0
	var/gained = min(amount, power_cap - power)
	if(gained <= 0)
		return 0
	power += gained
	total_drained += gained
	update_power_hud()
	nourish(gained)
	return gained

/**
 * Sapping power feeds an arcfiend. It fills them up, but never so far that they get fat.
 * An ethereal's food is their charge, and they are fed up to full charge but never into overcharge.
 */
/datum/antagonist/arcfiend/proc/nourish(power_gained)
	var/mob/living/carbon/human/user = owner?.current
	if(!istype(user) || user.stat == DEAD)
		return
	var/amount = power_gained * ARCFIEND_NUTRITION_PER_POWER
	if(isethereal(user))
		var/obj/item/organ/internal/stomach/ethereal/battery = user.get_organ_slot(ORGAN_SLOT_STOMACH)
		if(!istype(battery))
			return
		var/room_for_charge = ETHEREAL_BLOOD_CHARGE_FULL - user.blood_volume
		if(room_for_charge > 0)
			battery.adjust_charge(min(amount, room_for_charge))
		return
	var/room_for_food = NUTRITION_LEVEL_FULL - user.nutrition
	if(room_for_food > 0)
		user.adjust_nutrition(min(amount, room_for_food))

/// Returns TRUE if we have at least this much power
/datum/antagonist/arcfiend/proc/has_power(amount)
	return power >= amount

/// Spends power if we have enough of it. Returns TRUE if the power was spent.
/datum/antagonist/arcfiend/proc/spend_power(amount)
	if(!has_power(amount))
		return FALSE
	power -= amount
	update_power_hud()
	return TRUE

/datum/antagonist/arcfiend/proc/update_power_hud()
	var/atom/movable/screen/counter = owner?.current?.hud_used?.arcfiend_counter
	if(!counter)
		return
	counter.maptext = ANTAG_MAPTEXT(power, COLOR_YELLOW)

/// Counts power drained from a living player towards unlocking higher tiers. Each mind only counts once.
/datum/antagonist/arcfiend/proc/credit_mind_drain(mob/living/victim, amount)
	var/datum/mind/victim_mind = victim.mind
	if(!victim_mind || !victim.client || victim_mind == owner || (victim_mind in drained_minds))
		return
	mind_drain_progress[victim_mind] += amount
	if(mind_drain_progress[victim_mind] < ARCFIEND_MIND_DRAIN_REQUIRED)
		return
	mind_drain_progress -= victim_mind
	drained_minds += victim_mind
	to_chat(owner.current, span_notice("You've drained enough from [victim] for it to count. Players drained: [length(drained_minds)]."))

/// How many unique minds we have drained
/datum/antagonist/arcfiend/proc/get_minds_drained()
	return length(drained_minds) + bonus_minds_drained

/datum/antagonist/arcfiend/get_admin_commands()
	. = ..()
	.["Give Power"] = CALLBACK(src, PROC_REF(admin_give_power))
	.["Add Drained Minds"] = CALLBACK(src, PROC_REF(admin_add_minds))

/datum/antagonist/arcfiend/proc/admin_give_power(mob/admin)
	if(!check_rights(R_ADMIN|R_DEBUG))
		return
	var/amount = input(admin, "How much power should [owner.current] be given? Negative takes it away.", "Give power", 500) as null|num
	if(isnull(amount))
		return
	if(amount >= 0)
		power = min(power + amount, power_cap)
	else
		power = max(power + amount, 0)
	update_power_hud()
	message_admins("[key_name_admin(admin)] changed the power of [key_name_admin(owner)] by [amount] (now [power]).")
	log_admin("[key_name(admin)] changed the power of [key_name(owner)] by [amount] (now [power]).")

/datum/antagonist/arcfiend/proc/admin_add_minds(mob/admin)
	if(!check_rights(R_ADMIN|R_DEBUG))
		return
	var/amount = input(admin, "How many drained minds should [owner.current] be credited with? Negative takes them away.", "Add drained minds", 1) as null|num
	if(isnull(amount))
		return
	bonus_minds_drained += round(amount)
	message_admins("[key_name_admin(admin)] changed the drained minds of [key_name_admin(owner)] by [round(amount)] (now [get_minds_drained()]).")
	log_admin("[key_name(admin)] changed the drained minds of [key_name(owner)] by [round(amount)] (now [get_minds_drained()]).")

/// Whether we have drained enough minds to buy things from a shop tier. Tier 1 is the lowest.
/datum/antagonist/arcfiend/proc/can_access_tier(tier)
	var/required = tier_mind_requirements[clamp(tier, 1, length(tier_mind_requirements))]
	return get_minds_drained() >= required

/// Signal proc for COMSIG_ATOM_EMP_ACT on our mob.
/// Everything we carry is protected, including cybernetics and guns. We aren't, unless the EMP is our own.
/datum/antagonist/arcfiend/proc/on_emp_act(mob/living/source, severity)
	SIGNAL_HANDLER
	if(emitting_emp)
		return EMP_PROTECT_ALL
	// An EMP throws us out of the cables and stuns us
	var/obj/effect/dummy/phased_mob/arcfiend_lightning/ride = source.loc
	if(istype(ride))
		ride.cut_out("An electromagnetic pulse throws you out of the wires!", ARCFIEND_RIDE_EMP_STUN)
	var/heavy = (severity == EMP_HEAVY)
	source.apply_damage(heavy ? ARCFIEND_EMP_HEAVY_DAMAGE : ARCFIEND_EMP_LIGHT_DAMAGE, BURN, spread_damage = TRUE)
	source.set_jitter_if_lower(10 SECONDS)
	// The pulse also scatters part of our stored power
	var/power_lost = round(power * (heavy ? ARCFIEND_EMP_HEAVY_POWER_LOSS : ARCFIEND_EMP_LIGHT_POWER_LOSS))
	if(power_lost > 0)
		spend_power(power_lost)
	to_chat(source, span_userdanger("An electromagnetic pulse sears through your body[power_lost > 0 ? ", scattering [power_lost] of your stored power" : ""]!"))
	return EMP_PROTECT_CONTENTS | EMP_PROTECT_WIRES

/// Signal proc for COMSIG_KB_MOB_DROPITEM_DOWN. Returning COMSIG_KB_ACTIVATED stops the item from being dropped.
/datum/antagonist/arcfiend/proc/on_drop_key(mob/living/source)
	SIGNAL_HANDLER
	var/obj/item/held = source.get_active_held_item()
	if(!held)
		return NONE
	for(var/datum/action/cooldown/arcfiend/power in source.actions)
		if(power.on_drop_key(source, held))
			return COMSIG_KB_ACTIVATED
	return NONE

/// Gives the arcfiend a drain objective, some standard traitor objectives, and an ending objective
/datum/antagonist/arcfiend/forge_objectives()
	var/datum/objective/arcfiend_drain/drain = new
	drain.owner = owner
	objectives += drain

	var/objective_count = 0
	if((GLOB.joined_player_list.len >= HIJACK_MIN_PLAYERS) && prob(HIJACK_PROB))
		hijacker = TRUE
		objective_count++

	// Same count as a traitor gets, minus the drain objective we already handed out
	var/objective_limit = max(CONFIG_GET(number/traitor_objectives_amount) - 1, 1)
	for(var/i in objective_count to objective_limit - 1)
		objectives += forge_single_generic_objective()

	var/datum/objective/ending
	if(hijacker)
		ending = new /datum/objective/hijack
	else
		ending = new /datum/objective/escape
	ending.owner = owner
	objectives += ending

/// Mirrors the traitor's choice of assassinate/maroon/steal
/datum/antagonist/arcfiend/proc/forge_single_generic_objective()
	if(prob(MAROON_PROB))
		var/datum/objective/target_objective
		if(prob(KILL_PROB))
			target_objective = new /datum/objective/assassinate
		else
			target_objective = new /datum/objective/maroon
		target_objective.owner = owner
		target_objective.find_target()
		return target_objective

	var/datum/objective/steal/steal_objective = new
	steal_objective.owner = owner
	steal_objective.find_target()
	return steal_objective

/datum/antagonist/arcfiend/roundend_report()
	var/list/report = list()
	report += ..()
	report += "<br>They drained a total of <b>[round(total_drained)]</b> units of power."
	return report.Join()

/// Goon's arcfiends were asked to drain 3500-4000 power, in increments of 10
/datum/objective/arcfiend_drain
	name = "drain power"
	admin_grantable = TRUE

/datum/objective/arcfiend_drain/New(text)
	. = ..()
	target_amount = rand(350, 400) * 10
	update_explanation_text()

/datum/objective/arcfiend_drain/update_explanation_text()
	..()
	explanation_text = "Drain a total of [target_amount] units of power from the station."

/datum/objective/arcfiend_drain/check_completion()
	var/datum/antagonist/arcfiend/arcfiend = owner?.has_antag_datum(/datum/antagonist/arcfiend)
	if(arcfiend && arcfiend.total_drained >= target_amount)
		return TRUE
	return ..()

/datum/objective/arcfiend_drain/admin_edit(mob/admin)
	var/new_amount = input(admin, "Select the amount of power to drain:", "Objective target", target_amount) as null|num
	if(isnull(new_amount))
		return
	target_amount = max(round(new_amount), 10)
	update_explanation_text()

/atom/movable/screen/arcfiend_power
	name = "power"
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "psi_counter"
	screen_loc = ui_lingchemdisplay
	invisibility = INVISIBILITY_ABSTRACT

/datum/hud
	var/atom/movable/screen/arcfiend_power/arcfiend_counter

/datum/hud/New(mob/owner, ui_style = 'icons/hud/screen_midnight.dmi')
	. = ..()
	arcfiend_counter = new /atom/movable/screen/arcfiend_power(src)

/datum/hud/human/New(mob/living/carbon/human/owner, ui_style = 'icons/hud/screen_midnight.dmi')
	. = ..()
	arcfiend_counter = new /atom/movable/screen/arcfiend_power(src)
	infodisplay += arcfiend_counter

/datum/hud/Destroy()
	. = ..()
	arcfiend_counter = null

/// An injector of the nanites and retrovirus that make an arcfiend. Offered through the OPFOR menu.
/// Using it on yourself turns you into an arcfiend, and it is used up.
/obj/item/antag_granter/arcfiend
	name = "unmarked injector"
	desc = "An injector of shimmering fluid that crackles faintly when shaken. It has no markings."
	icon_state = "changeling_injector"
	color = ARCFIEND_YELLOW_TINT
	antag_datum = /datum/antagonist/arcfiend
	user_message = "You inject the fluid. Your skin starts to crackle, and you can feel the wires in the walls humming."

/// Throwaway datum that prototype powers are linked to, since actions need a target
/datum/arcfiend_prototype_holder

/// Every power that can appear in the shop, as an assoc list of power type to a prototype instance of it.
/// Lists on a type can't be read with initial(), so the shop reads costs and descriptions from these instead.
/// The prototypes are never granted to anyone, and the list is sorted by tier and then by name.
/proc/get_arcfiend_shop_powers()
	var/static/list/shop_powers
	if(isnull(shop_powers))
		var/datum/arcfiend_prototype_holder/holder = new
		var/list/prototypes = list()
		for(var/datum/action/cooldown/arcfiend/power_type as anything in subtypesof(/datum/action/cooldown/arcfiend))
			if(!initial(power_type.shop_listed))
				continue
			prototypes += new power_type(holder)
		sortTim(prototypes, GLOBAL_PROC_REF(cmp_arcfiend_shop_powers))
		shop_powers = list()
		for(var/datum/action/cooldown/arcfiend/prototype as anything in prototypes)
			shop_powers[prototype.type] = prototype
	return shop_powers

/proc/cmp_arcfiend_shop_powers(datum/action/cooldown/arcfiend/a, datum/action/cooldown/arcfiend/b)
	var/tier_diff = a.shop_tier - b.shop_tier
	if(tier_diff)
		return tier_diff
	return sorttext(b.name, a.name)

/// The prototype for a power, or null if it isn't sold in the shop
/proc/get_arcfiend_power_prototype(power_type)
	var/list/shop_powers = get_arcfiend_shop_powers()
	return shop_powers[power_type]

/// Whether we own a power
/datum/antagonist/arcfiend/proc/has_power_unlocked(power_type)
	return (power_type in unlocked_powers)

/// The most levels a power can be upgraded to
/datum/antagonist/arcfiend/proc/get_max_power_level(power_type)
	var/datum/action/cooldown/arcfiend/prototype = get_arcfiend_power_prototype(power_type)
	return length(prototype?.upgrade_costs) + 1

/// Buys a power from the shop. Returns TRUE if it was bought.
/datum/antagonist/arcfiend/proc/purchase_power(power_type)
	var/datum/action/cooldown/arcfiend/prototype = get_arcfiend_power_prototype(power_type)
	if(!prototype)
		return FALSE
	if(has_power_unlocked(power_type))
		return FALSE
	if(!can_access_tier(prototype.shop_tier))
		to_chat(owner.current, span_warning("You haven't drained enough players to learn that yet."))
		return FALSE
	if(!spend_power(prototype.unlock_cost))
		to_chat(owner.current, span_warning("You don't have enough power."))
		return FALSE
	unlocked_powers += power_type
	if(owner.current)
		grant_powers(owner.current)
		to_chat(owner.current, span_notice("You learn [prototype.name]."))
	return TRUE

/// Upgrades a power we own by one level. Returns TRUE if it was upgraded.
/datum/antagonist/arcfiend/proc/upgrade_power(power_type)
	var/datum/action/cooldown/arcfiend/prototype = get_arcfiend_power_prototype(power_type)
	if(!prototype || !has_power_unlocked(power_type))
		return FALSE
	var/current_level = get_power_level(power_type)
	if(current_level >= get_max_power_level(power_type))
		return FALSE
	// Upgrading to level N needs the minds of shop tier N
	if(!can_access_tier(current_level + 1))
		to_chat(owner.current, span_warning("You haven't drained enough players to improve that yet."))
		return FALSE
	if(!spend_power(prototype.upgrade_costs[current_level]))
		to_chat(owner.current, span_warning("You don't have enough power."))
		return FALSE
	power_levels[power_type] = current_level + 1
	var/datum/action/cooldown/arcfiend/owned_power = get_power_instance(power_type)
	owned_power?.on_upgraded()
	to_chat(owner.current, span_notice("You improve [prototype.name] to level [current_level + 1]."))
	return TRUE

/datum/antagonist/arcfiend/ui_status(mob/user, datum/ui_state/state)
	if(user.stat == DEAD)
		return UI_CLOSE
	return ..()

/datum/antagonist/arcfiend/ui_static_data(mob/user)
	var/list/data = ..()
	data["antag_name"] = name
	data["tier_requirements"] = tier_mind_requirements
	return data

/datum/antagonist/arcfiend/ui_data(mob/user)
	var/list/data = list()
	data["power"] = round(power)
	data["power_cap"] = power_cap
	data["total_drained"] = round(total_drained)
	data["minds_drained"] = get_minds_drained()
	data["objectives"] = get_objectives()

	var/list/powers_data = list()
	var/list/shop_powers = get_arcfiend_shop_powers()
	for(var/power_type in shop_powers)
		var/datum/action/cooldown/arcfiend/prototype = shop_powers[power_type]
		var/list/power_data = list()
		var/owned = has_power_unlocked(power_type)
		var/level = get_power_level(power_type)
		var/max_level = get_max_power_level(power_type)
		power_data["path"] = "[power_type]"
		power_data["name"] = prototype.name
		power_data["desc"] = prototype.desc
		power_data["tier"] = prototype.shop_tier
		power_data["passive"] = prototype.is_passive
		power_data["owned"] = owned
		power_data["level"] = level
		power_data["max_level"] = max_level
		power_data["upgrade_descriptions"] = prototype.upgrade_descriptions
		var/cost
		var/tier_needed
		if(!owned)
			cost = prototype.unlock_cost
			tier_needed = prototype.shop_tier
		else if(level < max_level)
			cost = prototype.upgrade_costs[level]
			tier_needed = level + 1
		power_data["cost"] = cost
		power_data["locked"] = !isnull(tier_needed) && !can_access_tier(tier_needed)
		power_data["minds_needed"] = isnull(tier_needed) ? 0 : tier_mind_requirements[clamp(tier_needed, 1, length(tier_mind_requirements))]
		power_data["can_afford"] = !isnull(cost) && has_power(cost)
		powers_data += list(power_data)
	data["powers"] = powers_data
	return data

/datum/antagonist/arcfiend/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	switch(action)
		if("purchase")
			var/power_type = text2path(params["path"])
			if(purchase_power(power_type))
				ui.send_update()
			return TRUE
		if("upgrade")
			var/power_type = text2path(params["path"])
			if(upgrade_power(power_type))
				ui.send_update()
			return TRUE
