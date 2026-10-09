/// Base type for every power an arcfiend can use
/datum/action/cooldown/arcfiend
	name = "Arcfiend power"
	panel = "Arcfiend"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "lightning"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_HANDS_BLOCKED | AB_CHECK_IMMOBILE
	/// Power spent each time this is used
	var/power_cost = 0

	/// Whether this power shows up in the shop
	var/shop_listed = TRUE
	/// Whether this is a passive with no button, shown as such in the shop
	var/is_passive = FALSE
	/// Which shop tier this power is sold in. Higher tiers need more minds drained.
	var/shop_tier = 1
	/// Power it costs to buy this. Powers that cost nothing are free starters everyone already has.
	var/unlock_cost = 0
	/// Power it costs to upgrade this to level 2, then level 3, and so on
	var/list/upgrade_costs = list()
	/// What each upgrade level adds, in the same order as upgrade_costs, shown in the shop
	var/list/upgrade_descriptions = list()

	/// Whether a glowing hand appears in the owner's hand while this power is ready to be aimed, so everyone can see it
	var/shows_hand = FALSE
	/// What the owner is told when the hand appears
	var/hand_message = "Your hand is charged. Click something to use it, or use the power again to cancel."
	/// The glowing hand we are showing right now
	var/obj/item/melee/touch_attack/arcfiend_hand/hand

/datum/action/cooldown/arcfiend/Destroy()
	QDEL_NULL(hand)
	return ..()

/datum/action/cooldown/arcfiend/set_click_ability(mob/on_who)
	. = ..()
	if(shows_hand)
		raise_hand(on_who)

/datum/action/cooldown/arcfiend/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	// If we're being refunded, then the owner cancelled it rather than using it
	lower_hand(on_who, refund_cooldown)

/// Puts a glowing hand in the owner's hand, as a sign that the power is ready
/datum/action/cooldown/arcfiend/proc/raise_hand(mob/on_who)
	if(hand || !isliving(on_who))
		return
	var/mob/living/user = on_who
	hand = new(user)
	hand.name = "crackling hand ([name])"
	if(!user.put_in_hands(hand, del_on_fail = TRUE))
		hand = null
		user.balloon_alert(user, "no free hand to use!")
		return
	RegisterSignal(hand, COMSIG_QDELETING, PROC_REF(on_hand_deleted))
	do_sparks(1, FALSE, user)
	playsound(user, SFX_SPARKS, 25, TRUE)
	user.visible_message(span_warning("[user]'s hand starts to crackle with yellow electricity!"), span_notice(hand_message))

/// Gets rid of the glowing hand
/datum/action/cooldown/arcfiend/proc/lower_hand(mob/on_who, cancelled = FALSE)
	if(!hand)
		return
	var/obj/item/melee/touch_attack/arcfiend_hand/old_hand = hand
	hand = null
	UnregisterSignal(old_hand, COMSIG_QDELETING)
	on_who?.temporarilyRemoveItemFromInventory(old_hand, TRUE) // DROPDEL deletes it
	if(!QDELETED(old_hand))
		qdel(old_hand)
	if(cancelled && on_who)
		to_chat(on_who, span_notice("You let the electricity fade from your hand."))

/**
 * Called when the owner presses the drop key with something in their active hand.
 * Return TRUE if this power dealt with it by dispelling something it made, which stops the normal drop.
 */
/datum/action/cooldown/arcfiend/proc/on_drop_key(mob/user, obj/item/held)
	if(hand && held == hand)
		unset_click_ability(user, TRUE)
		return TRUE
	return FALSE

/// If the hand goes away some other way, like being dropped, then the power is no longer ready
/datum/action/cooldown/arcfiend/proc/on_hand_deleted(datum/source)
	SIGNAL_HANDLER
	hand = null
	var/mob/user = owner
	if(user?.click_intercept == src)
		unset_click_ability(user, TRUE)

/// The glowing yellow hand an arcfiend has while a power is ready. It only shows that the power is ready,
/// the click itself is handled by the power.
/obj/item/melee/touch_attack/arcfiend_hand
	name = "crackling hand"
	desc = "Electricity arcs between the fingers."
	icon_state = "zapper"
	inhand_icon_state = "zapper"
	item_flags = ABSTRACT | HAND_ITEM | DROPDEL | NOBLUDGEON
	color = ARCFIEND_YELLOW_TINT
	light_outer_range = 2
	light_power = 1.2
	light_color = "#ffe94d"

/obj/item/melee/touch_attack/arcfiend_hand/Initialize(mapload, datum/action/cooldown/spell/spell)
	. = ..()
	set_light_on(TRUE)

/// It is only for show, so it never attacks
/obj/item/melee/touch_attack/arcfiend_hand/attack(mob/target, mob/living/carbon/user)
	return TRUE

/// Returns the antag datum of whoever owns this power
/datum/action/cooldown/arcfiend/proc/get_arcfiend()
	return owner?.mind?.has_antag_datum(/datum/antagonist/arcfiend)

/// Called after the shop upgrades this power, for powers that need to react to it
/datum/action/cooldown/arcfiend/proc/on_upgraded()
	return

/// Our upgrade level, 1 is the base power
/datum/action/cooldown/arcfiend/proc/get_level()
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	return arcfiend?.get_power_level(type) || 1

/datum/action/cooldown/arcfiend/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend)
		return FALSE
	if(!arcfiend.has_power(power_cost))
		if(feedback)
			owner.balloon_alert(owner, "not enough power!")
		return FALSE
	return TRUE

//////////////////////////////////////////////////////////////////////////
//--------------------------------Sap Power-----------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/sap_power
	name = "Sap Power"
	desc = "Drain power from something next to you. APCs, SMES units, cables and machines all work, but people and cyborgs give far more, and they get hurt. It's loud and bright. Sapping also feeds you, but never makes you fat, or overcharges you if you're an ethereal."
	button_icon_state = "lightning"
	click_to_activate = TRUE
	shows_hand = TRUE
	hand_message = "Your hand is charged. Click something next to you to sap it, or use the power again to cancel."
	cooldown_time = 1 SECONDS
	upgrade_costs = list(150, 400)
	upgrade_descriptions = list(
		"Drains 33% faster.",
		"Drains 66% faster.",
	)
	/// Whether we are currently channeling a drain
	var/draining = FALSE

/// How much faster than normal we drain, from upgrades
/datum/action/cooldown/arcfiend/sap_power/proc/get_drain_speed()
	return 1 + 0.33 * (get_level() - 1)

/datum/action/cooldown/arcfiend/sap_power/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || draining)
		return FALSE
	if(target == owner || !owner.Adjacent(target))
		owner.balloon_alert(owner, "too far away!")
		return FALSE
	if(!target.can_arcfiend_drain(owner))
		owner.balloon_alert(owner, "nothing to drain!")
		return FALSE
	if(arcfiend.power >= arcfiend.power_cap)
		owner.balloon_alert(owner, "fully charged!")
		return FALSE

	draining = TRUE
	owner.visible_message(
		span_danger("[owner] grips [target], and arcs of electricity start crawling across [owner.p_their()] body!"),
		span_notice("You begin sapping power from [target]."),
		span_hear("You hear loud crackling."),
	)
	var/total_gained = 0
	var/ticks = 0
	var/datum/callback/still_drainable = CALLBACK(target, TYPE_PROC_REF(/atom, can_arcfiend_drain), owner)
	start_sap_effects(target)
	while(!QDELETED(target) && arcfiend.power < arcfiend.power_cap)
		if(!do_after(owner, 1 SECONDS, target, progress = FALSE, extra_checks = still_drainable, interaction_key = "arcfiend_sap"))
			break
		var/gained = target.arcfiend_drain(owner, arcfiend, get_drain_speed())
		if(gained <= 0)
			break
		total_gained += gained
		ticks++
		sap_tick_effects(target, ticks)
	draining = FALSE
	stop_sap_effects()

	if(total_gained > 0)
		to_chat(owner, span_notice("You sapped [round(total_gained)] power."))
	StartCooldown()
	return TRUE

/// The name of the glow an arcfiend has while they are sapping
#define ARCFIEND_SAP_GLOW "arcfiend_sap_glow"

/// Makes it obvious to everyone nearby that something is being sapped, from the very start
/datum/action/cooldown/arcfiend/sap_power/proc/start_sap_effects(atom/target)
	// A bright, fast-pulsing glow around the arcfiend
	owner.add_filter(ARCFIEND_SAP_GLOW, 2, list("type" = "outline", "color" = "#ffe94d", "alpha" = 80, "size" = 2))
	var/filter = owner.get_filter(ARCFIEND_SAP_GLOW)
	animate(filter, alpha = 255, time = 0.25 SECONDS, loop = -1)
	animate(alpha = 80, time = 0.25 SECONDS)
	// A beam straight from the source to them, and a flash of light and thunder as it starts
	owner.Beam(target, icon_state = "lightning[rand(1, 12)]", time = 1.2 SECONDS)
	owner.flash_lighting_fx(5, 4, "#ffe94d", 1 SECONDS)
	playsound(target, 'sound/magic/lightningshock.ogg', 60, TRUE, extrarange = 12)

/// Keeps it obvious for as long as it goes on: a beam, loud crackling, flashes of light, flickering lights, and the odd warning
/datum/action/cooldown/arcfiend/sap_power/proc/sap_tick_effects(atom/target, ticks)
	owner.Beam(target, icon_state = "lightning[rand(1, 12)]", time = 1.2 SECONDS)
	do_sparks(3, FALSE, target)
	do_sparks(2, FALSE, owner)
	playsound(target, SFX_SPARKS, 100, TRUE, extrarange = 10)
	owner.flash_lighting_fx(4, 3, "#ffe94d", 1 SECONDS)
	// The lights nearby can't take it
	for(var/obj/machinery/light/nearby_light in range(3, target))
		if(prob(40))
			INVOKE_ASYNC(nearby_light, TYPE_PROC_REF(/obj/machinery/light, flicker), rand(2, 4))
	// Every few seconds, those watching are told what is happening, and hear a thunderclap
	if(!(ticks % 3))
		playsound(target, 'sound/magic/lightningshock.ogg', 70, TRUE, extrarange = 12)
		owner.visible_message(
			span_danger("Arcs of crackling electricity pour out of [target] and into [owner]!"),
			ignored_mobs = list(owner),
		)
		owner.balloon_alert_to_viewers("sapping power!")

/// Takes the glow away
/datum/action/cooldown/arcfiend/sap_power/proc/stop_sap_effects()
	if(!owner)
		return
	var/filter = owner.get_filter(ARCFIEND_SAP_GLOW)
	if(filter)
		animate(filter)
		owner.remove_filter(ARCFIEND_SAP_GLOW)

#undef ARCFIEND_SAP_GLOW

//////////////////////////////////////////////////////////////////////////
//----------------------------------Charge------------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/charge
	name = "Charge"
	desc = "Use your own power to refill the cells of whatever you're holding, or of a cyborg you're pulling. Doesn't work on anything magical."
	button_icon_state = "charge"
	cooldown_time = 3 SECONDS
	power_cost = 1
	upgrade_costs = list(100, 300)
	upgrade_descriptions = list(
		"50% more efficient.",
		"Twice as efficient.",
	)

/// How many joules each unit of power buys when charging, from upgrades
/datum/action/cooldown/arcfiend/charge/proc/get_joules_per_power()
	return ARCFIEND_JOULES_PER_POWER * (1 + 0.5 * (get_level() - 1))

/datum/action/cooldown/arcfiend/charge/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend)
		return FALSE

	var/list/obj/item/stock_parts/power_store/cells = list()
	for(var/obj/item/held in owner.held_items)
		var/obj/item/stock_parts/power_store/held_cell = held.get_cell()
		if(held_cell)
			cells |= held_cell
	if(iscyborg(owner.pulling))
		var/mob/living/silicon/robot/pulled_borg = owner.pulling
		if(pulled_borg.cell)
			cells |= pulled_borg.cell

	var/charged_anything = FALSE
	var/joules_per_power = get_joules_per_power()
	for(var/obj/item/stock_parts/power_store/cell as anything in cells)
		var/missing = cell.maxcharge - cell.charge
		if(missing <= 0)
			continue
		var/energy = min(missing, arcfiend.power * joules_per_power)
		var/cost = CEILING(energy / joules_per_power, 1)
		if(cost <= 0 || !arcfiend.spend_power(cost))
			continue
		cell.give(energy)
		cell.update_appearance()
		var/atom/cell_holder = cell.loc
		if(isgun(cell_holder))
			var/obj/item/gun/charged_gun = cell_holder
			charged_gun.process_chamber()
		if(!ismob(cell_holder))
			cell_holder?.update_appearance()
		to_chat(owner, span_notice("You charge [cell_holder == owner ? cell : cell_holder]."))
		charged_anything = TRUE

	if(!charged_anything)
		owner.balloon_alert(owner, "nothing to charge!")
		return FALSE

	do_sparks(3, FALSE, owner)
	playsound(owner, 'sound/magic/charge.ogg', 50, TRUE)
	StartCooldown()
	return TRUE

/// Whether an arcfiend could currently sap power from this
/atom/proc/can_arcfiend_drain(mob/living/arcfiend)
	return FALSE

/**
 * Called once for every second of a Sap Power channel.
 * Removes energy from the source and gives power to the arcfiend. Returns how much power the arcfiend gained.
 * * arcfiend - the mob doing the sapping
 * * antag - their antag datum
 * * seconds - how long this tick represents
 */
/atom/proc/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	return 0

/// How much more power the arcfiend has room for
/datum/antagonist/arcfiend/proc/get_power_room()
	return max(power_cap - power, 0)

//APC//
/obj/machinery/power/apc/can_arcfiend_drain(mob/living/arcfiend)
	return !QDELETED(cell) && cell.charge > 0

/obj/machinery/power/apc/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	var/units = min(ARCFIEND_DRAIN_APC * seconds, antag.get_power_room())
	var/energy_used = cell.use(units * ARCFIEND_JOULES_PER_POWER, force = TRUE)
	. = antag.add_power(energy_used / ARCFIEND_JOULES_PER_POWER)
	if(prob(ARCFIEND_SAP_APC_BREAK_PROB * seconds))
		set_broken()

//SMES//
/obj/machinery/power/smes/can_arcfiend_drain(mob/living/arcfiend)
	return arcfiend_total_charge() > 0

/// The SMES's real charge. The charge var is only used at roundstart, the rest lives in its internal cells.
/// total_charge() is protected, so this is how the tests get at it.
/obj/machinery/power/smes/proc/arcfiend_total_charge()
	return total_charge()

/obj/machinery/power/smes/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	var/units = min(ARCFIEND_DRAIN_SMES * seconds, antag.get_power_room())
	var/energy_used = abs(adjust_charge(-units * ARCFIEND_SMES_JOULES_PER_POWER))
	return antag.add_power(energy_used / ARCFIEND_SMES_JOULES_PER_POWER)

//CABLES//
/obj/structure/cable/can_arcfiend_drain(mob/living/arcfiend)
	return powernet && surplus() > 0

/obj/structure/cable/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	var/units = min(ARCFIEND_DRAIN_CABLE * seconds, antag.get_power_room())
	var/energy_taken = min(units * ARCFIEND_JOULES_PER_POWER, surplus())
	add_load(energy_taken)
	return antag.add_power(energy_taken / ARCFIEND_JOULES_PER_POWER)

//OTHER MACHINES//
/obj/machinery/can_arcfiend_drain(mob/living/arcfiend)
	return !(machine_stat & (NOPOWER|BROKEN)) && powered()

/obj/machinery/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	// Slow, and scaled to how much power the machine idles on
	var/units = clamp(round(idle_power_usage / ARCFIEND_JOULES_PER_POWER), 1, ARCFIEND_DRAIN_MACHINE_MAX) * seconds
	units = min(units, antag.get_power_room())
	var/energy_used = use_energy(units * ARCFIEND_JOULES_PER_POWER)
	return antag.add_power(energy_used / ARCFIEND_JOULES_PER_POWER)

//PEOPLE//
/mob/living/carbon/human/can_arcfiend_drain(mob/living/arcfiend)
	return stat != DEAD && src != arcfiend

/mob/living/carbon/human/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	apply_damage(ARCFIEND_SAP_MOB_BURN * seconds, BURN, spread_damage = TRUE)
	apply_damage(ARCFIEND_SAP_MOB_STAMINA * seconds, STAMINA)
	to_chat(src, span_userdanger("Something is tearing the electricity out of your body!"))
	. = antag.add_power(min(ARCFIEND_DRAIN_MOB * seconds, antag.get_power_room()))
	// An ethereal's charge is what is being drained, so it runs down. Anyone else only takes the damage.
	if(. && isethereal(src))
		var/obj/item/organ/internal/stomach/ethereal/battery = get_organ_slot(ORGAN_SLOT_STOMACH)
		battery?.adjust_charge(-. * ARCFIEND_ETHEREAL_CHARGE_PER_POWER)
	antag.credit_mind_drain(src, .)

//CYBORGS//
/mob/living/silicon/robot/can_arcfiend_drain(mob/living/arcfiend)
	return stat != DEAD && src != arcfiend && !QDELETED(cell) && cell.charge > 0

/mob/living/silicon/robot/arcfiend_drain(mob/living/arcfiend, datum/antagonist/arcfiend/antag, seconds)
	if(!can_arcfiend_drain(arcfiend))
		return 0
	apply_damage(ARCFIEND_SAP_CYBORG_BURN * seconds, BURN)
	adjust_confusion(3 SECONDS * seconds)
	to_chat(src, span_userdanger("Your power cell is being drained!"))
	var/units = min(ARCFIEND_DRAIN_CYBORG * seconds, antag.get_power_room())
	var/energy_used = cell.use(units * ARCFIEND_JOULES_PER_POWER, force = TRUE)
	. = antag.add_power(energy_used / ARCFIEND_JOULES_PER_POWER)
	antag.credit_mind_drain(src, .)

//////////////////////////////////////////////////////////////////////////
//-----------------------------Ride the Lightning-----------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/ride_lightning
	name = "Ride the Lightning"
	desc = "Dive into the cable under you and ride it. You can only move along connected cables, and getting in or out takes a moment. It costs power to enter, per tile and per second. If someone cuts the cable you're on, you're thrown out and stunned."
	button_icon_state = "jaunt"
	// You have to be able to use this while riding, to get out again
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 3 SECONDS
	power_cost = ARCFIEND_RIDE_ENTRY_COST
	/// Whether we are in the middle of going in or coming out, so we can't start a second go
	var/transitioning = FALSE
	upgrade_costs = list(150, 400)
	upgrade_descriptions = list(
		"Riding costs 25% less.",
		"Riding costs 50% less.",
	)

/// Multiplier to what riding costs per tile and per second, from upgrades
/proc/arcfiend_ride_cost_multiplier(datum/antagonist/arcfiend/arcfiend)
	return 1 - 0.25 * (arcfiend.get_power_level(/datum/action/cooldown/arcfiend/ride_lightning) - 1)

/// Whether we are currently riding the cables
/datum/action/cooldown/arcfiend/ride_lightning/proc/riding()
	return istype(owner?.loc, /obj/effect/dummy/phased_mob/arcfiend_lightning)

/datum/action/cooldown/arcfiend/ride_lightning/IsAvailable(feedback = FALSE)
	// Leaving the cables is always free
	if(riding())
		return (owner.stat == CONSCIOUS) && (next_use_time <= world.time)
	return ..()

/// Whether we are still riding this particular ride, used while waiting to leave it
/datum/action/cooldown/arcfiend/ride_lightning/proc/still_riding(obj/effect/dummy/phased_mob/arcfiend_lightning/expected_ride)
	return !QDELETED(expected_ride) && owner?.loc == expected_ride

/// Whether the cable we are about to dive into is still there, used while waiting to enter it
/datum/action/cooldown/arcfiend/ride_lightning/proc/cable_still_there(turf/cable_turf)
	return !!(locate(/obj/structure/cable) in cable_turf)

/datum/action/cooldown/arcfiend/ride_lightning/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || transitioning)
		return FALSE

	if(riding())
		var/obj/effect/dummy/phased_mob/arcfiend_lightning/current_ride = owner.loc
		transitioning = TRUE
		to_chat(owner, span_notice("You start to pull yourself back out of the wires..."))
		if(!do_after(owner, ARCFIEND_RIDE_TRANSITION_TIME, extra_checks = CALLBACK(src, PROC_REF(still_riding), current_ride)))
			transitioning = FALSE
			return FALSE
		transitioning = FALSE
		var/mob/living/leaving = owner
		current_ride.eject_jaunter()
		do_sparks(3, FALSE, leaving)
		playsound(leaving, SFX_SPARKS, 50, TRUE)
		leaving.visible_message(span_danger("[leaving] bursts out of the floor in a shower of sparks!"), span_notice("You pull yourself out of the wires."))
		StartCooldown()
		return TRUE

	if(!isturf(owner.loc))
		owner.balloon_alert(owner, "no room!")
		return FALSE
	var/turf/here = get_turf(owner)
	// Any cable will do. One with nothing connected to it has no directions, but it is still a cable.
	if(!cable_still_there(here))
		owner.balloon_alert(owner, "no cable here!")
		return FALSE
	if(!arcfiend.has_power(ARCFIEND_RIDE_ENTRY_COST))
		owner.balloon_alert(owner, "not enough power!")
		return FALSE

	transitioning = TRUE
	do_sparks(2, FALSE, owner)
	playsound(here, SFX_SPARKS, 40, TRUE)
	owner.visible_message(
		span_danger("[owner]'s body starts to crackle and dissolve into electricity!"),
		span_notice("You start to dissolve into the cable beneath you..."),
	)
	if(!do_after(owner, ARCFIEND_RIDE_TRANSITION_TIME, extra_checks = CALLBACK(src, PROC_REF(cable_still_there), here)))
		transitioning = FALSE
		return FALSE
	transitioning = FALSE
	// The power is only taken once we actually go in
	if(!arcfiend.spend_power(ARCFIEND_RIDE_ENTRY_COST))
		return FALSE

	do_sparks(3, FALSE, owner)
	playsound(here, SFX_SPARKS, 50, TRUE)
	owner.visible_message(span_danger("[owner] dissolves into a flash of electricity and vanishes into the floor!"))
	new /obj/effect/dummy/phased_mob/arcfiend_lightning(here, owner)
	StartCooldown()
	return TRUE

/// Returns the combined bitflag of every direction the cables on this turf connect in
/proc/arcfiend_cable_dirs(turf/checked)
	. = NONE
	for(var/obj/structure/cable/cable in checked)
		. |= cable.linked_dirs

/// The visible ball of electricity that follows an arcfiend riding the cables, so everyone can tell one is in the wires
/obj/effect/arcfiend_spark
	name = "ball of lightning"
	desc = "A ball of electricity racing through the wires."
	icon = 'icons/obj/engine/energy_ball.dmi'
	icon_state = "energy_ball"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_LIGHTING_PLANE
	layer = FLY_LAYER
	// The sprite is 64x64, so center it on the tile and shrink it down
	pixel_x = -32
	pixel_y = -32
	color = "#ffe94d"
	light_outer_range = 3
	light_power = 1.5
	light_color = "#ffe94d"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/effect/arcfiend_spark/Initialize(mapload)
	. = ..()
	transform = transform.Scale(0.4, 0.4)

/obj/effect/dummy/phased_mob/arcfiend_lightning
	name = "electric arc"
	movespeed = 1
	/// The directions the cables on our turf connected in when we arrived, used to tell if one has been cut
	var/known_dirs = NONE
	/// The visible ball of electricity that follows us around
	var/obj/effect/arcfiend_spark/spark

/obj/effect/dummy/phased_mob/arcfiend_lightning/Initialize(mapload, atom/movable/jaunter)
	. = ..()
	known_dirs = arcfiend_cable_dirs(get_turf(src))
	spark = new(get_turf(src))
	START_PROCESSING(SSobj, src)

/obj/effect/dummy/phased_mob/arcfiend_lightning/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(spark)
	return ..()

/obj/effect/dummy/phased_mob/arcfiend_lightning/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	known_dirs = arcfiend_cable_dirs(get_turf(src))
	spark?.forceMove(get_turf(src))

/obj/effect/dummy/phased_mob/arcfiend_lightning/process(seconds_per_tick)
	// The cable we're riding on has been removed entirely
	if(!(locate(/obj/structure/cable) in get_turf(src)))
		cut_out()
		return
	// Riding costs power every second, even when standing still
	var/mob/living/rider = jaunter
	var/datum/antagonist/arcfiend/arcfiend = rider?.mind?.has_antag_datum(/datum/antagonist/arcfiend)
	if(!arcfiend?.spend_power(ARCFIEND_RIDE_UPKEEP * seconds_per_tick * arcfiend_ride_cost_multiplier(arcfiend)))
		to_chat(rider, span_warning("You run out of power and are forced out of the wires!"))
		eject_jaunter()

/obj/effect/dummy/phased_mob/arcfiend_lightning/phased_check(mob/living/user, direction)
	if(!(direction in GLOB.cardinals))
		return
	var/turf/newloc = ..()
	if(!newloc)
		return
	var/turf/here = get_turf(src)
	var/live_dirs = arcfiend_cable_dirs(here)
	if(!(live_dirs & direction))
		// There used to be a cable that way, someone has cut it and we tried to ride over it
		if(known_dirs & direction)
			cut_out()
		else
			to_chat(user, span_warning("There is no cable that way."))
		return
	if(!(arcfiend_cable_dirs(newloc) & turn(direction, 180)))
		return
	var/datum/antagonist/arcfiend/arcfiend = user.mind?.has_antag_datum(/datum/antagonist/arcfiend)
	if(!arcfiend?.spend_power(ARCFIEND_RIDE_TILE_COST * arcfiend_ride_cost_multiplier(arcfiend)))
		to_chat(user, span_warning("You don't have the power to go any further!"))
		eject_jaunter()
		return
	return newloc

/// An EMP that hits the cable reaches whoever is riding it too. Things inside other things normally never feel an EMP.
/obj/effect/dummy/phased_mob/arcfiend_lightning/emp_act(severity)
	. = ..()
	var/mob/living/rider = jaunter
	rider?.emp_act(severity)

/// Our rider is thrown out of the wires and stunned, because a cable was cut out from under them or an EMP hit them
/obj/effect/dummy/phased_mob/arcfiend_lightning/proc/cut_out(message = "The cable was cut, and you are thrown out of the wires!", stun_time = ARCFIEND_RIDE_CUT_STUN)
	var/mob/living/rider = jaunter
	if(!rider)
		return
	eject_jaunter()
	do_sparks(5, FALSE, rider)
	playsound(rider, SFX_SPARKS, 60, TRUE)
	to_chat(rider, span_userdanger(message))
	rider.Paralyze(stun_time)

/**
 * Passives are powers that are bought in the shop like any other, but have no button.
 * They apply their effects as soon as they are granted, and again whenever they are upgraded.
 */
/datum/action/cooldown/arcfiend/passive
	owner_has_control = FALSE
	shop_listed = FALSE
	is_passive = TRUE
	/// Whether our effects are currently applied to our owner
	var/applied = FALSE

/datum/action/cooldown/arcfiend/passive/Grant(mob/granted_to)
	. = ..()
	if(owner)
		// With no button we never get put in the mob's list of actions, so the antag keeps track of us
		var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
		arcfiend?.passive_powers |= src
		refresh_passive()

/datum/action/cooldown/arcfiend/passive/Remove(mob/remove_from)
	if(applied && remove_from)
		remove_passive(remove_from)
		applied = FALSE
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	arcfiend?.passive_powers -= src
	return ..()

/datum/action/cooldown/arcfiend/passive/on_upgraded()
	refresh_passive()

/// Reapplies our effects at our current level
/datum/action/cooldown/arcfiend/passive/proc/refresh_passive()
	if(!isliving(owner))
		return
	if(applied)
		remove_passive(owner)
	apply_passive(owner, get_level())
	applied = TRUE

/// Applies our effects to the user. Override this.
/datum/action/cooldown/arcfiend/passive/proc/apply_passive(mob/living/user, level)
	return

/// Removes everything apply_passive did. Override this.
/datum/action/cooldown/arcfiend/passive/proc/remove_passive(mob/living/user)
	return

/// Called every second while the arcfiend is alive, for passives that do something over time
/datum/action/cooldown/arcfiend/passive/proc/passive_tick(mob/living/user, seconds_per_tick)
	return

//////////////////////////////////////////////////////////////////////////
//-----------------------------Nanite Regeneration-----------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/passive/nanite_regeneration
	name = "Nanite Regeneration"
	desc = "The nanites slowly heal your brute and burn damage."
	shop_listed = TRUE
	shop_tier = 1
	unlock_cost = 200
	upgrade_costs = list(250, 500)
	upgrade_descriptions = list(
		"Heals twice as fast.",
		"Heals three times as fast.",
	)

/datum/action/cooldown/arcfiend/passive/nanite_regeneration/passive_tick(mob/living/user, seconds_per_tick)
	var/heal_amount = 0.5 * get_level() * seconds_per_tick
	user.heal_overall_damage(brute = heal_amount, burn = heal_amount)

//////////////////////////////////////////////////////////////////////////
//------------------------------Organ Resonance-------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/passive/organ_resonance
	name = "Organ Resonance"
	desc = "The nanites slowly repair damage to your organs."
	shop_listed = TRUE
	shop_tier = 2
	unlock_cost = 450
	upgrade_costs = list(300)
	upgrade_descriptions = list(
		"Repairs twice as fast.",
	)

/datum/action/cooldown/arcfiend/passive/organ_resonance/passive_tick(mob/living/user, seconds_per_tick)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/carbon_user = user
	var/repair_amount = 0.4 * (2 ** (get_level() - 1)) * seconds_per_tick
	for(var/obj/item/organ/organ as anything in carbon_user.organs)
		if(organ.damage > 0)
			organ.apply_organ_damage(-repair_amount)

//////////////////////////////////////////////////////////////////////////
//------------------------------Ampullary Sense-------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/passive/ampullary_sense
	name = "Ampullary Sense"
	desc = "Your eyes pick up electric fields like a shark's do. You can see in the dark, better than with night vision."
	shop_listed = TRUE
	shop_tier = 2
	unlock_cost = 400
	upgrade_costs = list(350)
	upgrade_descriptions = list(
		"You can also see living things through walls.",
	)

/datum/action/cooldown/arcfiend/passive/ampullary_sense/apply_passive(mob/living/user, level)
	user.add_traits(list(TRAIT_TRUE_NIGHT_VISION), ARCFIEND_TRAIT)
	if(level >= 2)
		user.add_traits(list(TRAIT_THERMAL_VISION), ARCFIEND_TRAIT)
	RegisterSignal(user, COMSIG_MOB_UPDATE_SIGHT, PROC_REF(on_update_sight))
	user.update_sight()

/datum/action/cooldown/arcfiend/passive/ampullary_sense/remove_passive(mob/living/user)
	user.remove_traits(list(TRAIT_TRUE_NIGHT_VISION, TRAIT_THERMAL_VISION), ARCFIEND_TRAIT)
	UnregisterSignal(user, COMSIG_MOB_UPDATE_SIGHT)
	user.update_sight()

/// Lifts the dark further than ordinary night vision does. This runs after the mob's sight has been worked out.
/datum/action/cooldown/arcfiend/passive/ampullary_sense/proc/on_update_sight(mob/living/source)
	SIGNAL_HANDLER
	var/cutoff = (get_level() >= 2) ? ARCFIEND_NIGHT_VISION_CUTOFF_UPGRADED : ARCFIEND_NIGHT_VISION_CUTOFF
	source.lighting_cutoff = max(source.lighting_cutoff, cutoff)

//////////////////////////////////////////////////////////////////////////
//------------------------------Capacitive Soles------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/passive/capacitive_soles
	name = "Capacitive Soles"
	desc = "Your footsteps make no sound."
	shop_listed = TRUE
	shop_tier = 1
	unlock_cost = 150
	upgrade_costs = list(200)
	upgrade_descriptions = list(
		"You also can't slip on wet or icy floors.",
	)

/datum/action/cooldown/arcfiend/passive/capacitive_soles/apply_passive(mob/living/user, level)
	user.add_traits(list(TRAIT_SILENT_FOOTSTEPS), ARCFIEND_TRAIT)
	if(level >= 2)
		user.add_traits(list(TRAIT_NO_SLIP_ALL), ARCFIEND_TRAIT)

/datum/action/cooldown/arcfiend/passive/capacitive_soles/remove_passive(mob/living/user)
	user.remove_traits(list(TRAIT_SILENT_FOOTSTEPS, TRAIT_NO_SLIP_ALL), ARCFIEND_TRAIT)

//////////////////////////////////////////////////////////////////////////
//--------------------------------Surge Reflex--------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/surge_reflex
	name = "Surge Reflex"
	desc = "Instantly clears your stuns and stamina damage and heals some of your wounds. Works while stunned."
	button_icon_state = "lightning"
	// This has to work while stunned, that is the point of it
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 60 SECONDS
	power_cost = 100
	shop_tier = 1
	unlock_cost = 250
	upgrade_costs = list(200, 450)
	upgrade_descriptions = list(
		"Heals more and recharges in 40 seconds.",
		"Heals more and recharges in 25 seconds.",
	)

/datum/action/cooldown/arcfiend/surge_reflex/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(owner))
		return FALSE
	if(!arcfiend.spend_power(power_cost))
		return FALSE
	var/mob/living/user = owner
	var/level = get_level()
	user.SetStun(0)
	user.SetKnockdown(0)
	user.SetParalyzed(0)
	user.SetImmobilized(0)
	var/heal_amount = 5 + 10 * level
	user.heal_overall_damage(brute = heal_amount, burn = heal_amount, stamina = 100)
	do_sparks(4, FALSE, user)
	playsound(user, SFX_SPARKS, 60, TRUE)
	user.visible_message(span_danger("[user] convulses as a surge of electricity crackles over [user.p_their()] body!"), span_notice("You shake off the blow as the nanites surge through you."))
	StartCooldown(list(60 SECONDS, 40 SECONDS, 25 SECONDS)[clamp(level, 1, 3)])
	return TRUE
