/// Trait source for what Overdrive Sprint gives, so it can be taken away without touching anything else
#define ARCFIEND_OVERDRIVE_TRAIT "arcfiend_overdrive"

//////////////////////////////////////////////////////////////////////////
//------------------------------Toggled powers--------------------------//
//////////////////////////////////////////////////////////////////////////
/**
 * A power that is switched on and off, and drains power every second while it is on.
 * Switching it off is always possible. It switches itself off when the power runs out.
 */
/datum/action/cooldown/arcfiend/toggle
	shop_listed = FALSE
	cooldown_time = 1 SECONDS
	/// The least power we need to have to switch this on
	var/minimum_power_to_start = 20
	/// Whether we are on
	var/active = FALSE
	/// Timer that drains power each second while we are on
	var/upkeep_timer

/// How much power this costs every second while on. Override this.
/datum/action/cooldown/arcfiend/toggle/proc/get_upkeep()
	return 1

/// Applies our effects to the owner. Override this.
/datum/action/cooldown/arcfiend/toggle/proc/apply_effect(mob/living/user)
	return

/// Removes everything apply_effect did. Override this.
/datum/action/cooldown/arcfiend/toggle/proc/remove_effect(mob/living/user)
	return

/// What everyone nearby sees when this is switched on, if anything. Override this.
/datum/action/cooldown/arcfiend/toggle/proc/get_on_message(mob/living/user)
	return null

/// What everyone nearby sees when this is switched off, if anything. Override this.
/datum/action/cooldown/arcfiend/toggle/proc/get_off_message(mob/living/user)
	return null

/// A faint pulsing yellow glow around the user, so people can see that they are charged up
/datum/action/cooldown/arcfiend/toggle/proc/add_glow(mob/living/user, glow_name)
	user.add_filter(glow_name, 2, list("type" = "outline", "color" = "#ffe94d", "alpha" = 30, "size" = 1))
	var/filter = user.get_filter(glow_name)
	animate(filter, alpha = 120, time = 0.6 SECONDS, loop = -1)
	animate(alpha = 30, time = 0.6 SECONDS)

/datum/action/cooldown/arcfiend/toggle/proc/remove_glow(mob/living/user, glow_name)
	var/filter = user.get_filter(glow_name)
	if(filter)
		animate(filter)
		user.remove_filter(glow_name)

/datum/action/cooldown/arcfiend/toggle/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return active

/datum/action/cooldown/arcfiend/toggle/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(owner))
		return FALSE
	if(active)
		switch_off()
		StartCooldown()
		return TRUE
	if(!arcfiend.has_power(minimum_power_to_start))
		owner.balloon_alert(owner, "not enough power!")
		to_chat(owner, span_warning("You need at least [minimum_power_to_start] power to switch on [name]."))
		return FALSE
	switch_on()
	StartCooldown()
	return TRUE

/datum/action/cooldown/arcfiend/toggle/proc/switch_on()
	active = TRUE
	owner.balloon_alert(owner, "[name] on")
	to_chat(owner, span_notice("You switch on [name]. It drains [get_upkeep()] power every second."))
	var/on_message = get_on_message(owner)
	if(on_message)
		owner.visible_message(span_warning(on_message), ignored_mobs = list(owner))
	do_sparks(2, FALSE, owner)
	playsound(owner, SFX_SPARKS, 30, TRUE)
	apply_effect(owner)
	upkeep_timer = addtimer(CALLBACK(src, PROC_REF(upkeep_tick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/arcfiend/toggle/proc/switch_off()
	active = FALSE
	deltimer(upkeep_timer)
	upkeep_timer = null
	if(owner)
		owner.balloon_alert(owner, "[name] off")
		to_chat(owner, span_notice("You switch off [name]."))
		var/off_message = get_off_message(owner)
		if(off_message)
			owner.visible_message(span_notice(off_message), ignored_mobs = list(owner))
		remove_effect(owner)
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/arcfiend/toggle/proc/upkeep_tick()
	if(!active)
		return
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!owner || owner.stat == DEAD || !arcfiend)
		switch_off()
		return
	if(!arcfiend.spend_power(get_upkeep()))
		to_chat(owner, span_warning("You run out of power and [name] shuts off."))
		switch_off()

/datum/action/cooldown/arcfiend/toggle/on_upgraded()
	// Reapply at the new level
	if(active && owner)
		remove_effect(owner)
		apply_effect(owner)

/datum/action/cooldown/arcfiend/toggle/Remove(mob/remove_from)
	if(active)
		switch_off()
	return ..()

/datum/action/cooldown/arcfiend/toggle/Destroy()
	if(upkeep_timer)
		deltimer(upkeep_timer)
		upkeep_timer = null
	return ..()

//////////////////////////////////////////////////////////////////////////
//----------------------------Overdrive Sprint--------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/movespeed_modifier/arcfiend_overdrive
	variable = TRUE

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint
	name = "Overdrive Sprint"
	desc = "Move much faster and don't slip on wet floors. Drains power every second."
	button_icon_state = "lightning"
	shop_listed = TRUE
	shop_tier = 1
	unlock_cost = 250
	upgrade_costs = list(250, 500)
	upgrade_descriptions = list(
		"Faster, and cheaper to run.",
		"Faster again, and cheaper again.",
	)

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint/get_upkeep()
	return list(3, 2.5, 2)[clamp(get_level(), 1, 3)]

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint/apply_effect(mob/living/user)
	var/speed_bonus = list(0.35, 0.5, 0.65)[clamp(get_level(), 1, 3)]
	user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/arcfiend_overdrive, multiplicative_slowdown = -speed_bonus)
	ADD_TRAIT(user, TRAIT_NO_SLIP_ALL, ARCFIEND_OVERDRIVE_TRAIT)
	add_glow(user, "arcfiend_overdrive_glow")

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint/remove_effect(mob/living/user)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/arcfiend_overdrive)
	REMOVE_TRAIT(user, TRAIT_NO_SLIP_ALL, ARCFIEND_OVERDRIVE_TRAIT)
	remove_glow(user, "arcfiend_overdrive_glow")

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint/get_on_message(mob/living/user)
	return "[user] crackles with energy, sparks trailing behind [user.p_them()]!"

/datum/action/cooldown/arcfiend/toggle/overdrive_sprint/get_off_message(mob/living/user)
	return "The energy around [user] dies down."

//////////////////////////////////////////////////////////////////////////
//-----------------------------Brain Scramble---------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/brain_scramble
	name = "Brain Scramble"
	desc = "Touch someone to scramble their nerves. It burns a little and drains some stamina, and for 8 seconds their screen shakes and they're confused, dizzy and slurring."
	button_icon_state = "lightning"
	click_to_activate = TRUE
	shows_hand = TRUE
	hand_message = "Your hand is charged. Touch someone next to you, or use the power again to cancel."
	cooldown_time = 12 SECONDS
	power_cost = 40
	shop_tier = 1
	unlock_cost = 250
	upgrade_costs = list(200, 450)
	upgrade_descriptions = list(
		"Lasts 12 seconds, with a bit more burn and stamina damage.",
		"Lasts 16 seconds, with a bit more burn and stamina damage.",
	)

/datum/action/cooldown/arcfiend/brain_scramble/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(target) || target == owner)
		return FALSE
	if(!owner.Adjacent(target))
		owner.balloon_alert(owner, "too far away!")
		return FALSE
	if(!arcfiend.spend_power(power_cost))
		return FALSE
	var/mob/living/victim = target
	var/duration = list(8 SECONDS, 12 SECONDS, 16 SECONDS)[clamp(get_level(), 1, 3)]
	victim.adjust_confusion(duration)
	victim.adjust_slurring(duration)
	victim.set_dizzy_if_lower(duration)
	// A little burn and a fair amount of stamina damage, more with upgrades
	if(!HAS_TRAIT(victim, TRAIT_SHOCKIMMUNE))
		var/level = clamp(get_level(), 1, 3)
		victim.apply_damage(list(3, 4, 5)[level], BURN)
		victim.apply_damage(list(25, 30, 35)[level], STAMINA)
	if(victim.client)
		shake_camera(victim, duration, 3)
	do_sparks(2, FALSE, victim)
	playsound(victim, SFX_SPARKS, 60, TRUE)
	owner.visible_message(
		span_danger("[owner] touches [victim], and [victim.p_their()] whole body jolts with static!"),
		span_notice("You scramble [victim]'s nerves."),
	)
	to_chat(victim, span_userdanger("Static roars through your head and you can't think straight!"))
	StartCooldown()
	return TRUE

//////////////////////////////////////////////////////////////////////////
//-----------------------------Arc Discharge----------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/arc_discharge
	name = "Arc Discharge"
	desc = "Fire a bolt of lightning at someone. It burns, drains stamina, briefly blinds, and arcs to others nearby. Anyone shock immune takes nothing."
	button_icon_state = "lightning"
	click_to_activate = TRUE
	shows_hand = TRUE
	hand_message = "Your hand is charged. Click someone you can see to fire, or use the power again to cancel."
	cooldown_time = 8 SECONDS
	power_cost = 60
	shop_tier = 1
	unlock_cost = 300
	upgrade_costs = list(300, 600)
	upgrade_descriptions = list(
		"More damage, and arcs to a second target.",
		"More damage again, and arcs to a third target.",
	)
	/// How far away we can fire
	var/bolt_range = 7
	/// How far each arc can jump to a new target
	var/chain_range = 3

/datum/action/cooldown/arcfiend/arc_discharge/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || target == owner)
		return FALSE
	if(!can_see(owner, target, bolt_range))
		owner.balloon_alert(owner, "can't reach that!")
		return FALSE
	if(!arcfiend.spend_power(power_cost))
		return FALSE

	var/level = clamp(get_level(), 1, 3)
	var/damage = list(15, 20, 25)[level]
	var/arcs_left = level
	var/mob/living/victim = isliving(target) ? target : locate(/mob/living) in get_turf(target)
	if(victim == owner)
		victim = null

	playsound(owner, 'sound/magic/lightningbolt.ogg', 50, TRUE)
	owner.Beam(victim || target, icon_state = "lightning[rand(1, 12)]", time = 5)
	owner.visible_message(
		span_danger("[owner] flings a bolt of lightning at [victim || target]!"),
		span_notice("You fling a bolt of lightning at [victim || target]."),
	)
	if(!victim)
		StartCooldown()
		return TRUE

	var/list/already_hit = list(owner)
	var/atom/source = owner
	while(victim)
		already_hit += victim
		zap(source, victim, damage)
		damage = round(damage * 0.6)
		source = victim
		victim = (arcs_left-- > 0) ? find_next_victim(source, already_hit) : null
		if(victim)
			source.Beam(victim, icon_state = "lightning[rand(1, 12)]", time = 5)
	StartCooldown()
	return TRUE

/// The nearest living thing the arc can jump to from this one
/datum/action/cooldown/arcfiend/arc_discharge/proc/find_next_victim(atom/source, list/already_hit)
	var/mob/living/closest
	var/closest_dist = INFINITY
	for(var/mob/living/candidate in oview(chain_range, source))
		if(candidate in already_hit)
			continue
		if(candidate.stat == DEAD || !can_see(source, candidate, chain_range))
			continue
		var/candidate_dist = get_dist(source, candidate)
		if(candidate_dist < closest_dist)
			closest = candidate
			closest_dist = candidate_dist
	return closest

/// Hits someone with the arc
/datum/action/cooldown/arcfiend/arc_discharge/proc/zap(atom/source, mob/living/victim, damage)
	if(HAS_TRAIT(victim, TRAIT_SHOCKIMMUNE))
		victim.visible_message(span_warning("The lightning washes harmlessly over [victim]!"))
		return
	victim.apply_damage(damage, BURN, spread_damage = TRUE)
	victim.apply_damage(damage, STAMINA)
	victim.adjust_temp_blindness(3 SECONDS)
	victim.flash_act(1, visual = TRUE)
	to_chat(victim, span_userdanger("A bolt of lightning slams into you!"))
	do_sparks(2, FALSE, victim)

#undef ARCFIEND_OVERDRIVE_TRAIT

//////////////////////////////////////////////////////////////////////////
//-------------------------------Thunderclap----------------------------//
//////////////////////////////////////////////////////////////////////////
/// The name of the glow an arcfiend has while charging a thunderclap
#define ARCFIEND_THUNDERCLAP_GLOW "arcfiend_thunderclap_glow"

/**
 * A burst of electricity around the arcfiend, after a short and very obvious windup.
 * Everyone in range takes a little burn, some stamina damage and a flash, and the further they are the weaker
 * all of it is. Anyone within 2 tiles is also thrown away.
 * It has no hand, using the power just starts it.
 */
/datum/action/cooldown/arcfiend/thunderclap
	name = "Thunderclap"
	desc = "After a short windup that everyone around you will notice, release a burst of electricity. Everyone near you takes a little burn damage and some stamina damage, and is flashed. The further away they are, the weaker it is. Anyone within 2 tiles is also thrown away."
	button_icon_state = "lightning"
	cooldown_time = 30 SECONDS
	power_cost = 120
	shop_tier = 2
	unlock_cost = 550
	upgrade_costs = list(450, 850)
	upgrade_descriptions = list(
		"Throws 4 tiles and reaches 8. More damage, shorter windup, and recharges in 25 seconds.",
		"Throws 5 tiles and reaches 9. More damage, shorter windup, and recharges in 20 seconds.",
	)
	/// Whether we are in the middle of the windup, so it can't be started twice
	var/winding_up = FALSE

/// How long the windup takes
/datum/action/cooldown/arcfiend/thunderclap/proc/get_windup()
	return list(1.5 SECONDS, 1.25 SECONDS, 1 SECONDS)[clamp(get_level(), 1, 3)]

/// How far people within 2 tiles are thrown
/datum/action/cooldown/arcfiend/thunderclap/proc/get_throw_distance()
	return list(3, 4, 5)[clamp(get_level(), 1, 3)]

/// How far away the burn, stamina damage and flash reach
/datum/action/cooldown/arcfiend/thunderclap/proc/get_outer_range()
	return list(7, 8, 9)[clamp(get_level(), 1, 3)]

/// The burn damage right next to the edge of the throwing range, before falloff
/datum/action/cooldown/arcfiend/thunderclap/proc/get_burn()
	return list(4, 5, 6)[clamp(get_level(), 1, 3)]

/// The stamina damage right next to the edge of the throwing range, before falloff
/datum/action/cooldown/arcfiend/thunderclap/proc/get_stamina()
	return list(30, 40, 50)[clamp(get_level(), 1, 3)]

/// How long it takes to recharge
/datum/action/cooldown/arcfiend/thunderclap/proc/get_recharge_time()
	return list(30 SECONDS, 25 SECONDS, 20 SECONDS)[clamp(get_level(), 1, 3)]

/// How much of the full effect someone this many tiles away gets. It never drops to nothing within range.
/datum/action/cooldown/arcfiend/thunderclap/proc/get_falloff(distance)
	return max(1 - (distance - 1) / get_outer_range(), 0.15)

/datum/action/cooldown/arcfiend/thunderclap/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(owner) || winding_up)
		return FALSE
	var/mob/living/user = owner
	winding_up = TRUE
	user.visible_message(
		span_danger("[user] starts glowing brighter and brighter, the air around [user.p_them()] crackling and tightening!"),
		span_notice("You gather the charge in your body. Anyone close will be thrown, and everyone nearby will feel it."),
	)
	user.balloon_alert_to_viewers("charging!")
	playsound(user, 'sound/magic/lightning_chargeup.ogg', 80, TRUE, extrarange = 8)
	user.add_filter(ARCFIEND_THUNDERCLAP_GLOW, 2, list("type" = "outline", "color" = "#ffe94d", "alpha" = 100, "size" = 3))
	var/filter = user.get_filter(ARCFIEND_THUNDERCLAP_GLOW)
	animate(filter, alpha = 255, time = 0.2 SECONDS, loop = -1)
	animate(alpha = 100, time = 0.2 SECONDS)
	// Moving doesn't interrupt it, being stunned or knocked out does
	var/finished = do_after(user, get_windup(), progress = FALSE, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM, interaction_key = "arcfiend_thunderclap")
	filter = user.get_filter(ARCFIEND_THUNDERCLAP_GLOW)
	if(filter)
		animate(filter)
		user.remove_filter(ARCFIEND_THUNDERCLAP_GLOW)
	winding_up = FALSE
	if(!finished)
		user.balloon_alert(user, "interrupted!")
		return FALSE
	if(!arcfiend.spend_power(power_cost))
		return FALSE
	burst(user)
	StartCooldown(get_recharge_time())
	return TRUE

/// The burst itself
/datum/action/cooldown/arcfiend/thunderclap/proc/burst(mob/living/user)
	new /obj/effect/temp_visual/emp/pulse(get_turf(user))
	do_sparks(6, FALSE, user)
	playsound(user, 'sound/magic/lightningshock.ogg', 100, TRUE, extrarange = 15)
	user.flash_lighting_fx(7, 5, "#ffe94d", 1 SECONDS)
	user.visible_message(span_danger("[user] releases a burst of electricity!"), span_notice("You release the charge."))
	var/outer_range = get_outer_range()
	for(var/mob/living/victim in view(outer_range, user))
		if(victim == user || victim.stat == DEAD)
			continue
		hit_victim(user, victim, get_dist(user, victim))
	for(var/obj/machinery/light/nearby_light in view(outer_range, user))
		if(prob(50))
			INVOKE_ASYNC(nearby_light, TYPE_PROC_REF(/obj/machinery/light, flicker), rand(2, 4))

/// What the burst does to one person, depending on how far away they are
/datum/action/cooldown/arcfiend/thunderclap/proc/hit_victim(mob/living/user, mob/living/victim, distance)
	// Everyone in range is hurt and flashed, and the further away they are the weaker it is
	var/falloff = get_falloff(distance)
	if(!HAS_TRAIT(victim, TRAIT_SHOCKIMMUNE))
		victim.apply_damage(get_burn() * falloff, BURN)
		victim.apply_damage(get_stamina() * falloff, STAMINA)
	victim.flash_act(1, visual = TRUE, length = 2.5 SECONDS * falloff)
	if(victim.client)
		shake_camera(victim, 3, 1)
	if(distance > 2)
		to_chat(victim, span_userdanger("A burst of electricity from [user] washes over you!"))
		return
	// Anyone close enough is also thrown away
	to_chat(victim, span_userdanger("A shockwave of electricity throws you away from [user]!"))
	if(!victim.anchored)
		var/turf/away = get_edge_target_turf(victim, get_dir(user, victim) || victim.dir)
		victim.throw_at(away, get_throw_distance(), 2, user, spin = FALSE)

#undef ARCFIEND_THUNDERCLAP_GLOW

//////////////////////////////////////////////////////////////////////////
//---------------------------Electrokinetic Smash-----------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash
	name = "Electrokinetic Smash"
	desc = "Your punches and the weapons you swing hit harder. In combat mode every hit also burns for extra damage and can arc to others nearby. Costs power every second, and a little more per hit."
	button_icon_state = "lightning"
	shop_listed = TRUE
	shop_tier = 2
	unlock_cost = 500
	upgrade_costs = list(400, 800)
	upgrade_descriptions = list(
		"Hits 30% harder, more burn damage, and arcs more often.",
		"Hits 40% harder, more burn damage, and arcs can reach two others.",
	)
	/// Power each hit costs, on top of the upkeep
	var/hit_cost = 8
	/// How far an arc can jump
	var/chain_range = 2
	/// The arms we have boosted, each with how much we added to its low and high punch damage, so we can take exactly that away again
	var/list/boosted_arms = list()

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/get_upkeep()
	return 1

/// How much harder the weapons we swing and our punches hit
/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/proc/get_hit_multiplier()
	return list(1.2, 1.3, 1.4)[clamp(get_level(), 1, 3)]

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/apply_effect(mob/living/user)
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	add_glow(user, "arcfiend_smash_glow")
	// Punch damage is rolled from the damage range of the arm doing the punching, so that is what gets boosted
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		for(var/obj/item/bodypart/arm/arm in carbon_user.bodyparts)
			var/low_bonus = round(arm.unarmed_damage_low * (get_hit_multiplier() - 1), 1)
			var/high_bonus = round(arm.unarmed_damage_high * (get_hit_multiplier() - 1), 1)
			arm.unarmed_damage_low += low_bonus
			arm.unarmed_damage_high += high_bonus
			boosted_arms[arm] = list(low_bonus, high_bonus)

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/remove_effect(mob/living/user)
	UnregisterSignal(user, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK))
	remove_glow(user, "arcfiend_smash_glow")
	for(var/obj/item/bodypart/arm/arm as anything in boosted_arms)
		if(QDELETED(arm))
			continue
		arm.unarmed_damage_low -= boosted_arms[arm][1]
		arm.unarmed_damage_high -= boosted_arms[arm][2]
	boosted_arms.Cut()

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/get_on_message(mob/living/user)
	return "[user]'s hands start crackling with electricity!"

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/get_off_message(mob/living/user)
	return "The electricity around [user]'s hands fades."

/// Signal proc for COMSIG_MOB_ITEM_ATTACK. Returning anything here would cancel the attack, so we never do.
/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user, list/modifiers, list/attack_modifiers, obj/item/weapon)
	SIGNAL_HANDLER
	if((source.istate & ISTATE_HARM) && isliving(target))
		// The weapon hits harder, on top of the burn from discharge()
		MODIFY_ATTACK_FORCE_MULTIPLIER(attack_modifiers, get_hit_multiplier())
		discharge(target)
	return NONE

/// Signal proc for COMSIG_HUMAN_MELEE_UNARMED_ATTACK
/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/proc/on_unarmed_attack(mob/living/source, atom/target, proximity)
	SIGNAL_HANDLER
	if(proximity && (source.istate & ISTATE_HARM) && isliving(target))
		discharge(target)

/// Burns whoever we hit, and maybe arcs on to others
/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/proc/discharge(mob/living/victim)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || victim == owner || victim.stat == DEAD)
		return
	if(!arcfiend.spend_power(hit_cost))
		return
	var/level = clamp(get_level(), 1, 3)
	var/damage = list(8, 12, 16)[level]
	shock(victim, damage, "[owner]'s electrified blow shocks you!")
	if(!prob(list(25, 40, 55)[level]))
		return
	var/arcs_left = (level == 3) ? 2 : 1
	var/list/already_hit = list(owner, victim)
	var/atom/source = victim
	while(arcs_left-- > 0)
		var/list/candidates = list()
		for(var/mob/living/candidate in oview(chain_range, source))
			if(!(candidate in already_hit) && candidate.stat != DEAD)
				candidates += candidate
		if(!length(candidates))
			return
		var/mob/living/next_victim = pick(candidates)
		already_hit += next_victim
		source.Beam(next_victim, icon_state = "lightning[rand(1, 12)]", time = 5)
		damage = round(damage * 0.6)
		shock(next_victim, damage, "A stray arc of electricity shocks you!")
		source = next_victim

/datum/action/cooldown/arcfiend/toggle/electrokinetic_smash/proc/shock(mob/living/victim, damage, victim_message)
	if(HAS_TRAIT(victim, TRAIT_SHOCKIMMUNE))
		return
	victim.apply_damage(damage, BURN, spread_damage = TRUE)
	do_sparks(2, FALSE, victim)
	playsound(victim, SFX_SPARKS, 40, TRUE)
	to_chat(victim, span_userdanger(victim_message))

//////////////////////////////////////////////////////////////////////////
//--------------------------Myoelectric Stimulation---------------------//
//////////////////////////////////////////////////////////////////////////
/// Makes everything done with the hands take less time
/datum/actionspeed_modifier/arcfiend_stimulation
	variable = TRUE

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation
	name = "Myoelectric Stimulation"
	desc = "Stimulate the muscles in your arms. Do-afters take less time, and you hit, shoot and click faster. Drains power every second."
	button_icon_state = "lightning"
	shop_listed = TRUE
	shop_tier = 2
	unlock_cost = 500
	upgrade_costs = list(400, 800)
	upgrade_descriptions = list(
		"Do-afters take 35% less time and attacks are 30% faster. Cheaper to run.",
		"Do-afters take 45% less time and attacks are 40% faster. Cheaper again.",
	)
	/// What the click and gun delay multipliers were multiplied by when this was switched on, so we can divide it out exactly
	var/applied_speed_factor = 1

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation/get_upkeep()
	return list(2, 1.5, 1)[clamp(get_level(), 1, 3)]

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation/apply_effect(mob/living/user)
	var/level = clamp(get_level(), 1, 3)
	user.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/arcfiend_stimulation, multiplicative_slowdown = -list(0.25, 0.35, 0.45)[level])
	applied_speed_factor = list(0.8, 0.7, 0.6)[level]
	user.next_move_modifier *= applied_speed_factor
	user.gun_fire_delay_modifier *= applied_speed_factor
	add_glow(user, "arcfiend_stimulation_glow")

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation/remove_effect(mob/living/user)
	user.remove_actionspeed_modifier(/datum/actionspeed_modifier/arcfiend_stimulation)
	user.next_move_modifier /= applied_speed_factor
	user.gun_fire_delay_modifier /= applied_speed_factor
	applied_speed_factor = 1
	remove_glow(user, "arcfiend_stimulation_glow")

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation/get_on_message(mob/living/user)
	return "[user]'s arms start twitching with electricity!"

/datum/action/cooldown/arcfiend/toggle/myoelectric_stimulation/get_off_message(mob/living/user)
	return "The electricity in [user]'s arms dies down."

//////////////////////////////////////////////////////////////////////////
//------------------------------Jamming Field---------------------------//
//////////////////////////////////////////////////////////////////////////
/// The jammer an arcfiend carries inside of themselves while their jamming field is on
/obj/item/jammer/arcfiend
	name = "jamming field"
	item_flags = ABSTRACT
	range = 6

/datum/action/cooldown/arcfiend/toggle/jamming_field
	name = "Jamming Field"
	desc = "Radios, PDAs, GPS and suit sensors near you stop working. You glow while it's on, so everyone can tell it's you. Drains power every second."
	button_icon_state = "lightning"
	shop_listed = TRUE
	shop_tier = 2
	unlock_cost = 450
	upgrade_costs = list(300, 600)
	upgrade_descriptions = list(
		"Reaches 9 tiles, and cheaper to run.",
		"Reaches 12 tiles, and cheaper again.",
	)
	/// The jammer we carry while on
	var/obj/item/jammer/arcfiend/field
	/// The aura filter's name
	var/aura_name = "arcfiend_jamming_aura"

/datum/action/cooldown/arcfiend/toggle/jamming_field/get_upkeep()
	return list(2, 1.5, 1)[clamp(get_level(), 1, 3)]

/datum/action/cooldown/arcfiend/toggle/jamming_field/get_on_message(mob/living/user)
	return "[user] is wrapped in a pulsing field of static!"

/datum/action/cooldown/arcfiend/toggle/jamming_field/get_off_message(mob/living/user)
	return "The field of static around [user] collapses."

/datum/action/cooldown/arcfiend/toggle/jamming_field/apply_effect(mob/living/user)
	field = new(user)
	field.range = list(6, 9, 12)[clamp(get_level(), 1, 3)]
	field.active = TRUE
	GLOB.active_jammers |= field
	user.add_filter(aura_name, 2, list("type" = "outline", "color" = "#ffe94d", "alpha" = 60, "size" = 2))
	var/filter = user.get_filter(aura_name)
	animate(filter, alpha = 230, time = 0.4 SECONDS, loop = -1)
	animate(alpha = 60, time = 0.4 SECONDS)
	user.set_light_range_power_color(3, 1.5, "#ffe94d")
	user.set_light_on(TRUE)

/datum/action/cooldown/arcfiend/toggle/jamming_field/remove_effect(mob/living/user)
	if(field)
		GLOB.active_jammers -= field
		QDEL_NULL(field)
	var/filter = user.get_filter(aura_name)
	if(filter)
		animate(filter)
		user.remove_filter(aura_name)
	user.set_light_on(FALSE)

//////////////////////////////////////////////////////////////////////////
//------------------------------Electric Emag---------------------------//
//////////////////////////////////////////////////////////////////////////
/// A card of crackling biometal an arcfiend grows from their hand. Using it costs power, depending on what it is used on.
/obj/item/card/emag/arcfiend
	name = "electric emag"
	desc = "A card of biometal grown from an arcfiend's hand. It hacks what it touches, and the arcfiend pays for it in power."
	color = "#ffe94d"
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON | ABSTRACT | DROPDEL
	slot_flags = NONE
	microwaveable = FALSE

/obj/item/card/emag/arcfiend/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ARCFIEND_TRAIT)
	// Being electric, this works on doors too
	type_blacklist = null

/// How much power it costs to emag this
/obj/item/card/emag/arcfiend/proc/get_emag_cost(atom/target, datum/antagonist/arcfiend/arcfiend)
	var/cost = 50
	if(issilicon(target))
		cost = 1500
	else if(istype(target, /obj/machinery/computer))
		cost = 150
	else if(istype(target, /obj/machinery/door))
		cost = 60
	else if(ismachinery(target))
		cost = 100
	else if(isobj(target))
		cost = 40
	var/level = arcfiend.get_power_level(/datum/action/cooldown/arcfiend/electric_emag)
	return round(cost * list(1, 0.75, 0.5)[clamp(level, 1, 3)])

/obj/item/card/emag/arcfiend/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	var/datum/antagonist/arcfiend/arcfiend = user.mind?.has_antag_datum(/datum/antagonist/arcfiend)
	if(!arcfiend)
		return ..()
	var/cost = get_emag_cost(interacting_with, arcfiend)
	if(!arcfiend.has_power(cost))
		user.balloon_alert(user, "need [cost] power!")
		return ITEM_INTERACT_BLOCKING
	if(!can_emag(interacting_with, user))
		return ITEM_INTERACT_BLOCKING
	log_combat(user, interacting_with, "attempted to emag")
	if(interacting_with.emag_act(user, src))
		arcfiend.spend_power(cost)
		SSblackbox.record_feedback("tally", "atom_emagged", 1, interacting_with.type)
		return ITEM_INTERACT_SUCCESS
	return NONE

/datum/action/cooldown/arcfiend/electric_emag
	name = "Electric Emag"
	desc = "Grow an emag in your hand. Growing it and putting it away is free, using it costs power. Doors are cheap, consoles aren't, and cyborgs cost a fortune."
	button_icon_state = "lightning"
	cooldown_time = 1 SECONDS
	shop_tier = 2
	unlock_cost = 500
	upgrade_costs = list(400, 800)
	upgrade_descriptions = list(
		"Hacking costs 25% less.",
		"Hacking costs 50% less.",
	)

/datum/action/cooldown/arcfiend/electric_emag/Remove(mob/remove_from)
	if(remove_from)
		put_away(remove_from)
	return ..()

/// Gets rid of the emag if we are holding it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/electric_emag/proc/put_away(mob/user)
	var/found = FALSE
	for(var/obj/item/card/emag/arcfiend/emag in user.held_items)
		user.temporarilyRemoveItemFromInventory(emag, TRUE) // DROPDEL deletes it
		found = TRUE
	if(found)
		user.update_held_items()
	return found

/// Lets the emag crumble away, with the sparks and messages that go with it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/electric_emag/proc/dismiss(mob/living/user)
	if(!put_away(user))
		return FALSE
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_notice("[user]'s electric emag crumbles away."), span_notice("You let the electric emag crumble away."))
	StartCooldown()
	return TRUE

/// Pressing the drop key while holding the emag dismisses it instead of trying to drop it
/datum/action/cooldown/arcfiend/electric_emag/on_drop_key(mob/user, obj/item/held)
	if(istype(held, /obj/item/card/emag/arcfiend) && isliving(user))
		return dismiss(user)
	return ..()

/datum/action/cooldown/arcfiend/electric_emag/Activate(atom/target)
	if(!get_arcfiend() || !isliving(owner))
		return FALSE
	var/mob/living/user = owner
	if(dismiss(user))
		return TRUE
	var/obj/item/held = user.get_active_held_item()
	if(held && !user.dropItemToGround(held))
		user.balloon_alert(user, "hand occupied!")
		return FALSE
	var/obj/item/card/emag/arcfiend/emag = new(user)
	user.put_in_hands(emag)
	do_sparks(2, FALSE, user)
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_warning("A card of crackling biometal grows out of [user]'s hand!"), span_notice("You grow an electric emag."))
	StartCooldown()
	return TRUE

//////////////////////////////////////////////////////////////////////////
//--------------------------------EMP Burst-----------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/emp_burst
	name = "EMP Burst"
	desc = "Spend a third of your stored power on an EMP. The more power you have, the bigger it is. It doesn't hurt you or what you carry, but it does hurt other arcfiends."
	button_icon_state = "lightning"
	cooldown_time = 30 SECONDS
	power_cost = 100
	shop_tier = 3
	unlock_cost = 900
	upgrade_costs = list(600, 1000)
	upgrade_descriptions = list(
		"A bigger pulse for the same power.",
		"A bigger pulse again.",
	)
	/// The fraction of our stored power the pulse takes
	var/power_fraction = 0.33

/datum/action/cooldown/arcfiend/emp_burst/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(owner))
		return FALSE
	var/spent = round(arcfiend.power * power_fraction)
	if(spent < power_cost || !arcfiend.spend_power(spent))
		return FALSE
	// 120 power buys a tile of radius, and upgrades make that go further
	var/power_per_tile = 120 * (1 - 0.15 * (clamp(get_level(), 1, 3) - 1))
	var/heavy_range = clamp(round(spent / power_per_tile), 1, 7)
	var/light_range = heavy_range + 2
	owner.visible_message(span_danger("[owner] releases a thunderous electromagnetic pulse!"), span_notice("You release an electromagnetic pulse, spending [spent] power."))
	playsound(owner, 'sound/magic/lightningshock.ogg', 70, TRUE)
	// Our own pulse never hurts us, but it does hurt anyone else, including other arcfiends
	arcfiend.emitting_emp = TRUE
	empulse(get_turf(owner), heavy_range, light_range, TRUE)
	arcfiend.emitting_emp = FALSE
	StartCooldown()
	return TRUE

//////////////////////////////////////////////////////////////////////////
//----------------------------------Jolt--------------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/jolt
	name = "Jolt"
	desc = "After a long windup, send a huge jolt through someone you're touching. In combat mode it stops their heart and burns them badly. Out of combat mode it restarts a stopped heart like a defibrillator, and can revive the dead, even without a soul in them. If they can't be revived the power is still spent, but your instincts tell you why."
	button_icon_state = "lightning"
	click_to_activate = TRUE
	shows_hand = TRUE
	hand_message = "Your hand is charged. Click someone next to you to jolt them, or use the power again to cancel. In combat mode it stops their heart, otherwise it restarts it."
	cooldown_time = 45 SECONDS
	power_cost = 200
	shop_tier = 3
	unlock_cost = 1000
	upgrade_costs = list(700, 1200)
	upgrade_descriptions = list(
		"Shorter windup and cooldown, and more burn damage.",
		"Shorter again, and more burn damage.",
	)

/datum/action/cooldown/arcfiend/jolt/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !iscarbon(target) || target == owner)
		return FALSE
	if(!owner.Adjacent(target))
		owner.balloon_alert(owner, "too far away!")
		return FALSE
	var/mob/living/carbon/victim = target
	var/mob/living/user = owner
	var/lethal = !!(user.istate & ISTATE_HARM)
	if(lethal)
		if(HAS_TRAIT(victim, TRAIT_SHOCKIMMUNE))
			user.balloon_alert(user, "they're immune!")
			return FALSE
	else if(victim.stat != DEAD && !victim.undergoing_cardiac_arrest())
		user.balloon_alert(user, "they don't need it!")
		return FALSE
	// Anyone who is dead can be tried, whether or not there is a soul in them and whether or not it will work.
	// You only find out why it didn't after the charge is spent, as your intuition tells you.

	var/level = clamp(get_level(), 1, 3)
	user.visible_message(
		span_danger("[user] grips [victim] as a huge charge begins to build between them!"),
		span_notice("You gather a massive charge, ready to [lethal ? "stop [victim]'s heart" : "restart [victim]'s heart"]."),
	)
	playsound(user, 'sound/magic/lightning_chargeup.ogg', 60, TRUE)
	var/datum/callback/still_valid = CALLBACK(src, PROC_REF(still_valid), victim, lethal)
	if(!do_after(user, list(6 SECONDS, 5 SECONDS, 4 SECONDS)[level], victim, extra_checks = still_valid))
		user.balloon_alert(user, "interrupted!")
		return FALSE
	if(!arcfiend.spend_power(power_cost))
		return FALSE

	do_sparks(5, FALSE, victim)
	playsound(victim, 'sound/magic/lightningshock.ogg', 70, TRUE)
	user.Beam(victim, icon_state = "lightning[rand(1, 12)]", time = 5)
	if(lethal)
		stop_heart(victim, list(40, 50, 60)[level])
	else
		restart_heart(victim)
	StartCooldown(list(45 SECONDS, 35 SECONDS, 25 SECONDS)[level])
	return TRUE

/// Whether the jolt can still go ahead, checked throughout the windup
/datum/action/cooldown/arcfiend/jolt/proc/still_valid(mob/living/carbon/victim, was_lethal)
	return owner && !QDELETED(victim) && !!(owner.istate & ISTATE_HARM) == was_lethal

/datum/action/cooldown/arcfiend/jolt/proc/stop_heart(mob/living/carbon/victim, burn_damage)
	victim.apply_damage(burn_damage, BURN, spread_damage = TRUE)
	victim.set_jitter_if_lower(20 SECONDS)
	if(victim.needs_heart() && !victim.undergoing_cardiac_arrest())
		victim.set_heartattack(TRUE)
	// Another arcfiend's heart can't be stopped, so all they get is the burns
	if(HAS_TRAIT(victim, TRAIT_HEART_ATTACK_IMMUNE) && !victim.undergoing_cardiac_arrest())
		victim.visible_message(span_danger("[victim] convulses violently, but [victim.p_their()] heart keeps beating through the jolt!"), span_userdanger("A jolt of lightning tears through your chest, but your heart keeps beating!"))
		return
	victim.visible_message(span_danger("[victim] convulses violently, [victim.p_their()] heart giving out!"), span_userdanger("A jolt of lightning tears through your chest, and your heart stops!"))

/// What the arcfiend's intuition tells them about why a body can't be revived. Null means it can be.
/datum/action/cooldown/arcfiend/jolt/proc/get_failure_feeling(defib_result)
	switch(defib_result)
		if(DEFIB_FAIL_SUICIDE)
			return "You reach for their spark and find nothing to catch. They let go of it themselves, and nothing you do will pull it back."
		if(DEFIB_FAIL_HUSK)
			return "There is nothing left in this body for the current to hold on to. It is dried out, a husk, and the charge just bleeds away. It would need mending before anything could wake in it."
		if(DEFIB_FAIL_BLACKLISTED)
			return "Something has sealed them away. The current finds no way in, and you sense that it never will."
		if(DEFIB_FAIL_TISSUE_DAMAGE)
			return "The flesh is too ravaged to carry the current. It scatters through torn muscle and leaks away. Mend the worst of the damage and try again."
		if(DEFIB_FAIL_NO_HEART)
			return "You feel for a heartbeat to restart and find only emptiness where a heart should be."
		if(DEFIB_FAIL_FAILING_HEART)
			return "Their heart is too damaged to take the beat. It quivers under the current and falls still. Mend it and try again."
		if(DEFIB_FAIL_NO_BRAIN)
			return "The current runs all the way through them and finds nobody home. There is nothing in the skull that could wake."
		if(DEFIB_FAIL_FAILING_BRAIN)
			return "Their mind is too damaged to wake. You sense it flicker under the current and fade. Mend it and try again."
		if(DEFIB_FAIL_NO_INTELLIGENCE)
			return "You sense no spark of a mind left to call back. Whatever lived here is long gone."
	return null

/// Tells the arcfiend what their intuition says, as a quiet thought and not an announcement
/datum/action/cooldown/arcfiend/jolt/proc/intuit(message)
	to_chat(owner, span_notice("<i>[message]</i>"))

/// Restarts a stopped heart, or brings back the dead like a defibrillator would. The power has already been spent by now.
/datum/action/cooldown/arcfiend/jolt/proc/restart_heart(mob/living/carbon/victim)
	if(victim.stat != DEAD)
		// Alive, but in cardiac arrest
		var/obj/item/organ/internal/heart/heart = victim.get_organ_by_type(/obj/item/organ/internal/heart)
		if(heart && (heart.organ_flags & ORGAN_FAILING))
			victim.visible_message(span_warning("The jolt rolls over [victim], but [victim.p_their()] heart will not take the beat."))
			intuit(get_failure_feeling(DEFIB_FAIL_FAILING_HEART))
			return FALSE
		victim.set_heartattack(FALSE)
		victim.emote("gasp")
		victim.visible_message(span_notice("[victim] jolts and gasps as [victim.p_their()] heart starts beating again!"), span_userdanger("A jolt of lightning restarts your heart!"))
		return TRUE

	var/defib_result = victim.can_defib()
	var/failure_feeling = get_failure_feeling(defib_result)
	if(failure_feeling)
		victim.visible_message(span_warning("The jolt rolls over [victim]'s body, but nothing stirs."))
		intuit(failure_feeling)
		return FALSE

	// A body that is too damaged would just die again, so it is brought back to the edge of critical, the way a defibrillator does
	var/total_brute = victim.getBruteLoss()
	var/total_burn = victim.getFireLoss()
	var/halfway_to_death = (victim.crit_threshold + victim.dead_threshold) * 0.5
	if(victim.health > halfway_to_death)
		victim.adjustOxyLoss(victim.health - halfway_to_death, 0)
	else
		var/overall_damage = total_brute + total_burn + victim.getToxLoss() + victim.getOxyLoss()
		var/current_health = victim.health
		victim.adjustOxyLoss((current_health - halfway_to_death) * (victim.getOxyLoss() / overall_damage), 0)
		victim.adjustToxLoss((current_health - halfway_to_death) * (victim.getToxLoss() / overall_damage), 0, TRUE)
		victim.adjustFireLoss((current_health - halfway_to_death) * (total_burn / overall_damage), 0)
		victim.adjustBruteLoss((current_health - halfway_to_death) * (total_brute / overall_damage), 0)
	victim.updatehealth()

	victim.set_heartattack(FALSE)
	// Whoever used to live in there is called back if they are still around. If they aren't, the body wakes up anyway.
	if(defib_result == DEFIB_POSSIBLE)
		victim.grab_ghost()
	victim.revive()
	victim.emote("gasp")
	victim.set_jitter_if_lower(60 SECONDS)
	SEND_SIGNAL(victim, COMSIG_LIVING_MINOR_SHOCK)
	victim.visible_message(span_notice("[victim] jolts and gasps as [victim.p_their()] heart starts beating again!"), span_userdanger("A jolt of lightning restarts your heart!"))
	var/mob/living/saver = owner
	saver?.add_mood_event("saved_life", /datum/mood_event/saved_life)
	log_combat(saver, victim, "revived", "Jolt")
	if(!victim.client)
		intuit("The body breathes again, but there is nobody home behind its eyes.")
	return TRUE
