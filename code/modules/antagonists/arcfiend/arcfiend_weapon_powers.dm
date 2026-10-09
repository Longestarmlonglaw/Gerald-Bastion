//////////////////////////////////////////////////////////////////////////
//------------------------------Manifest Coilgun-------------------------//
//////////////////////////////////////////////////////////////////////////
/obj/projectile/bullet/arcfiend_slug
	name = "biometal slug"
	damage = 20
	color = "#ffe94d"
	embed_type = null
	shrapnel_type = null

/obj/item/ammo_casing/energy/arcfiend_slug
	projectile_type = /obj/projectile/bullet/arcfiend_slug
	fire_sound = 'sound/magic/lightningbolt.ogg'
	select_name = "slug"
	e_cost = 0
	delay = 0.8 SECONDS

/**
 * A crude gun of biometal that an arcfiend grows out of their hand. A pulse of electricity throws the slugs.
 * Every shot costs its owner power and a slug from an internal magazine, which slowly rebuilds.
 * The magazine belongs to the arcfiend's power, so putting the gun away and growing it again doesn't refill it.
 */
/obj/item/gun/energy/arcfiend_coilgun
	name = "biometal coilgun"
	desc = "A lumpy biometal gun grown from an arcfiend's hand. It fires slugs using its owner's electricity."
	color = "#ffe94d"
	item_flags = ABSTRACT | DROPDEL
	ammo_type = list(/obj/item/ammo_casing/energy/arcfiend_slug)
	can_select = FALSE
	can_charge = FALSE
	automatic_charge_overlays = FALSE
	display_empty = FALSE

/obj/item/gun/energy/arcfiend_coilgun/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ARCFIEND_TRAIT)

/// It has no battery that anything could charge, the power comes from the arcfiend holding it
/obj/item/gun/energy/arcfiend_coilgun/get_cell(atom/movable/interface, mob/user)
	return null

/// The arcfiend holding this
/obj/item/gun/energy/arcfiend_coilgun/proc/get_holder_antag()
	if(!ismob(loc))
		return null
	var/mob/holder = loc
	return holder.mind?.has_antag_datum(/datum/antagonist/arcfiend)

/// How much power a shot costs, which gets cheaper with upgrades
/obj/item/gun/energy/arcfiend_coilgun/proc/get_shot_cost(datum/antagonist/arcfiend/arcfiend)
	var/level = clamp(arcfiend.get_power_level(/datum/action/cooldown/arcfiend/manifest_coilgun), 1, 3)
	return list(15, 12, 9)[level]

/// The power that owns the magazine this gun fires from
/obj/item/gun/energy/arcfiend_coilgun/proc/get_holder_action()
	if(!ismob(loc))
		return null
	var/mob/holder = loc
	return locate(/datum/action/cooldown/arcfiend/manifest_coilgun) in holder.actions

/obj/item/gun/energy/arcfiend_coilgun/can_shoot()
	var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
	var/datum/action/cooldown/arcfiend/manifest_coilgun/magazine_owner = get_holder_action()
	if(!arcfiend || !magazine_owner)
		return FALSE
	return arcfiend.has_power(get_shot_cost(arcfiend)) && magazine_owner.get_magazine() >= 1

/// Says why it won't fire, as well as clicking
/obj/item/gun/energy/arcfiend_coilgun/shoot_with_empty_chamber(mob/living/user as mob|obj)
	var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
	var/datum/action/cooldown/arcfiend/manifest_coilgun/magazine_owner = get_holder_action()
	if(magazine_owner && magazine_owner.get_magazine() < 1)
		balloon_alert_to_viewers("out of slugs!")
	else if(arcfiend)
		balloon_alert_to_viewers("need [get_shot_cost(arcfiend)] power!")
	else
		balloon_alert_to_viewers("*click*")
	playsound(src, dry_fire_sound, dry_fire_sound_volume, TRUE)

/obj/item/gun/energy/arcfiend_coilgun/examine(mob/user)
	. = ..()
	var/datum/action/cooldown/arcfiend/manifest_coilgun/magazine_owner = get_holder_action()
	if(magazine_owner)
		. += span_notice("Its magazine holds [magazine_owner.get_magazine()] of [magazine_owner.get_magazine_size()] slugs. It rebuilds one every [magazine_owner.get_slug_recharge_time() / 10] seconds.")

/// Always has a round ready, the cost is only paid when it is fired
/obj/item/gun/energy/arcfiend_coilgun/recharge_newshot(no_cyborg_drain)
	if(!ammo_type || chambered)
		return
	chambered = ammo_type[select]
	if(!chambered.loaded_projectile)
		chambered.newshot()
	var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
	if(arcfiend && chambered.loaded_projectile)
		var/level = clamp(arcfiend.get_power_level(/datum/action/cooldown/arcfiend/manifest_coilgun), 1, 3)
		chambered.loaded_projectile.damage = list(20, 25, 30)[level]

/obj/item/gun/energy/arcfiend_coilgun/handle_chamber(mob/living/user, empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	// A spent round means the shot was fired, so that is when it is paid for, in power and in a slug.
	// The game doesn't always pass the shooter in here (a single shot doesn't), so whoever is holding the gun is used instead.
	if(chambered && !chambered.loaded_projectile)
		var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
		if(arcfiend)
			arcfiend.spend_power(get_shot_cost(arcfiend))
		var/datum/action/cooldown/arcfiend/manifest_coilgun/magazine_owner = get_holder_action()
		if(magazine_owner?.use_slug() && ismob(loc))
			var/mob/shooter = loc
			shooter.balloon_alert(shooter, "[magazine_owner.get_magazine()] slug[magazine_owner.get_magazine() == 1 ? "" : "s"] left")
	chambered = null
	recharge_newshot()

/datum/action/cooldown/arcfiend/manifest_coilgun
	name = "Manifest Coilgun"
	desc = "Grow a coilgun in your hand. Growing it and putting it away is free. Each shot costs power and a slug from its magazine, which holds 4 and rebuilds one every 8 seconds, even while the gun is away."
	button_icon_state = "lightning"
	cooldown_time = 1 SECONDS
	shop_tier = 2
	unlock_cost = 600
	upgrade_costs = list(500, 900)
	upgrade_descriptions = list(
		"Hits harder and costs less power per shot. Holds 5 slugs, rebuilds one every 6 seconds.",
		"Hits harder and costs less per shot. Holds 6 slugs, rebuilds one every 4 seconds.",
	)
	/// The slugs in the magazine right now. It starts out full, see get_magazine().
	var/magazine
	/// The timer that rebuilds the next slug, while the magazine isn't full
	var/slug_timer

/// How many slugs the magazine holds
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/get_magazine_size()
	return list(4, 5, 6)[clamp(get_level(), 1, 3)]

/// How long it takes to rebuild one slug
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/get_slug_recharge_time()
	return list(8 SECONDS, 6 SECONDS, 4 SECONDS)[clamp(get_level(), 1, 3)]

/// The slugs in the magazine. The first time anyone asks, it is full.
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/get_magazine()
	if(isnull(magazine))
		magazine = get_magazine_size()
	return magazine

/// Takes a slug out of the magazine, and starts rebuilding one. Returns FALSE if the magazine is empty.
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/use_slug()
	if(get_magazine() < 1)
		return FALSE
	magazine--
	start_slug_recharge()
	return TRUE

/// Starts rebuilding a slug, if the magazine isn't full and one isn't being rebuilt already
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/start_slug_recharge()
	if(slug_timer || get_magazine() >= get_magazine_size())
		return
	slug_timer = addtimer(CALLBACK(src, PROC_REF(slug_recharged)), get_slug_recharge_time(), TIMER_STOPPABLE)

/// A slug has been rebuilt
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/slug_recharged()
	slug_timer = null
	magazine = min(get_magazine() + 1, get_magazine_size())
	if(owner && (locate(/obj/item/gun/energy/arcfiend_coilgun) in owner.held_items))
		owner.balloon_alert(owner, "slug rebuilt ([magazine]/[get_magazine_size()])")
		playsound(owner, 'sound/weapons/gun/general/chunkyrack.ogg', 20, TRUE)
	start_slug_recharge()

/// A bigger magazine means there may be room to rebuild again
/datum/action/cooldown/arcfiend/manifest_coilgun/on_upgraded()
	start_slug_recharge()

/datum/action/cooldown/arcfiend/manifest_coilgun/Destroy()
	if(slug_timer)
		deltimer(slug_timer)
		slug_timer = null
	return ..()

/datum/action/cooldown/arcfiend/manifest_coilgun/Remove(mob/remove_from)
	if(remove_from)
		put_away(remove_from)
	return ..()

/// Gets rid of the weapon if we are holding it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/put_away(mob/user)
	var/found = FALSE
	for(var/obj/item/gun/energy/arcfiend_coilgun/gun in user.held_items)
		user.temporarilyRemoveItemFromInventory(gun, TRUE) // DROPDEL deletes it
		found = TRUE
	if(found)
		user.update_held_items()
	return found

/// Lets the coilgun crumble away, with the sparks and messages that go with it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/manifest_coilgun/proc/dismiss(mob/living/user)
	if(!put_away(user))
		return FALSE
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_notice("[user]'s biometal coilgun crumbles away."), span_notice("You let the biometal coilgun crumble away."))
	StartCooldown()
	return TRUE

/// Pressing the drop key while holding the coilgun dismisses it instead of trying to drop it
/datum/action/cooldown/arcfiend/manifest_coilgun/on_drop_key(mob/user, obj/item/held)
	if(istype(held, /obj/item/gun/energy/arcfiend_coilgun) && isliving(user))
		return dismiss(user)
	return ..()

/datum/action/cooldown/arcfiend/manifest_coilgun/Activate(atom/target)
	if(!get_arcfiend() || !isliving(owner))
		return FALSE
	var/mob/living/user = owner
	if(dismiss(user))
		return TRUE
	var/obj/item/held = user.get_active_held_item()
	if(held && !user.dropItemToGround(held))
		user.balloon_alert(user, "hand occupied!")
		return FALSE
	var/obj/item/gun/energy/arcfiend_coilgun/gun = new(user)
	user.put_in_hands(gun)
	do_sparks(2, FALSE, user)
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_warning("A crude gun of lumpy biometal grows out of [user]'s hand!"), span_notice("You grow a biometal coilgun."))
	StartCooldown()
	return TRUE

//////////////////////////////////////////////////////////////////////////
//------------------------------Biometal Tether-------------------------//
//////////////////////////////////////////////////////////////////////////
/datum/action/cooldown/arcfiend/biometal_tether
	name = "Biometal Tether"
	desc = "Fire a biometal hook and reel yourself to where it lands. Costs power each time."
	button_icon_state = "lightning"
	click_to_activate = TRUE
	shows_hand = TRUE
	hand_message = "Your hand is charged. Click where you want to go, or use the power again to cancel."
	cooldown_time = 6 SECONDS
	power_cost = 50
	shop_tier = 2
	unlock_cost = 450
	upgrade_costs = list(350, 700)
	upgrade_descriptions = list(
		"Reaches 8 tiles, recharges faster, and can pull light items to you.",
		"Reaches 10 tiles, and recharges faster again.",
	)

/datum/action/cooldown/arcfiend/biometal_tether/Activate(atom/target)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !isliving(owner) || target == owner)
		return FALSE
	var/mob/living/user = owner
	var/level = clamp(get_level(), 1, 3)
	var/tether_range = list(6, 8, 10)[level]
	if(!can_see(user, target, tether_range))
		user.balloon_alert(user, "can't reach that!")
		return FALSE

	// Upgraded, a light item is yanked to us instead of us going to it
	var/pull_item = FALSE
	if(level >= 2 && isitem(target))
		var/obj/item/item_target = target
		pull_item = !item_target.anchored && item_target.w_class <= WEIGHT_CLASS_NORMAL && isturf(item_target.loc)

	var/turf/landing
	if(!pull_item)
		landing = get_turf(target)
		if(!isturf(target) || landing.is_blocked_turf(TRUE))
			// Solid things and people stop the hook, so we land in front of them
			landing = get_step_towards(get_turf(target), user)
		if(!landing || landing == get_turf(user) || landing.is_blocked_turf(TRUE))
			user.balloon_alert(user, "no room to land!")
			return FALSE

	if(!arcfiend.spend_power(power_cost))
		return FALSE

	playsound(user, 'sound/magic/lightningbolt.ogg', 40, TRUE)
	user.Beam(target, icon_state = "lightning[rand(1, 12)]", time = 5)
	user.visible_message(
		span_danger("[user] flings a crackling hook of biometal at [target] and [pull_item ? "yanks it back" : "is reeled through the air"]!"),
		span_notice("You fling a biometal hook at [target]."),
	)
	if(pull_item)
		var/atom/movable/pulled = target
		pulled.throw_at(get_turf(user), tether_range, 2, user, spin = FALSE)
	else
		user.throw_at(landing, get_dist(user, landing), 2, user, spin = FALSE)
	StartCooldown(list(6 SECONDS, 5 SECONDS, 4 SECONDS)[level])
	return TRUE

//////////////////////////////////////////////////////////////////////////
//------------------------------Lateral Laser---------------------------//
//////////////////////////////////////////////////////////////////////////
/**
 * A thin beam of flash-boiled nanites that goes through everything: walls, objects, people, even people lying on the floor.
 * It only reaches as far as the range it is set to. The nanites are superheated, and at the very end of their range they
 * rupture and detonate, which is where nearly all of the damage comes from. Before that the beam only scorches
 * what it passes through, and past that there is nothing left of it.
 */
/obj/projectile/beam/laser/hitscan/arcfiend_lateral
	name = "lateral beam"
	damage = 6
	damage_type = BURN
	hitscan_light_color_override = "#ffe94d"
	impact_light_color_override = "#ffe94d"
	// Hits people on the floor, however far away they are
	hit_prone_targets = TRUE
	ignore_range_hit_prone_targets = TRUE
	/// How far the beam reaches, in tiles. This is also the one distance it does its full damage at.
	var/travel_range = 4
	/// The damage done to everything that isn't at the very end of the beam
	var/weak_damage = 6
	/// The damage done to whatever is at exactly the end of the beam
	var/power_damage = 45

/// Sets how far this beam reaches and how hard it hits
/obj/projectile/beam/laser/hitscan/arcfiend_lateral/proc/set_up(range_in_tiles, weak, strong)
	travel_range = range_in_tiles
	range = range_in_tiles
	weak_damage = weak
	power_damage = strong
	damage = weak

/// How much damage a hit does at this many tiles from where the beam started. Only the very end of the beam hurts.
/obj/projectile/beam/laser/hitscan/arcfiend_lateral/proc/damage_at_distance(distance)
	if(distance > travel_range)
		return 0
	return (distance == travel_range) ? power_damage : weak_damage

/// Goes through absolutely everything, but still hurts it. The one thing it skips is the one who fired it.
/obj/projectile/beam/laser/hitscan/arcfiend_lateral/prehit_pierce(atom/target)
	if(target == firer)
		return PROJECTILE_PIERCE_PHASE
	return PROJECTILE_PIERCE_HIT

/// Every living thing in the way is hit, whatever it is doing and whatever it is wearing
/obj/projectile/beam/laser/hitscan/arcfiend_lateral/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(isliving(target))
		if(QDELETED(target) || impacted[target.weak_reference] || target == firer)
			return FALSE
		if(!ignore_loc && loc != target.loc)
			return FALSE
		return TRUE
	return ..()

/obj/projectile/beam/laser/hitscan/arcfiend_lateral/on_hit(atom/target, blocked = 0, pierce_hit)
	var/distance = get_dist(starting, get_turf(target))
	damage = damage_at_distance(distance)
	// At the very end of the beam the superheated nanites rupture
	if(distance == travel_range && isliving(target))
		do_sparks(4, FALSE, target)
		target.visible_message(span_danger("The nanites in the beam rupture violently against [target]!"), span_userdanger("The superheated nanites in the beam rupture inside you!"))
	return ..()

/obj/item/ammo_casing/energy/arcfiend_lateral_beam
	projectile_type = /obj/projectile/beam/laser/hitscan/arcfiend_lateral
	fire_sound = 'sound/weapons/lasercannonfire.ogg'
	select_name = "lateral beam"
	firing_effect_type = null
	e_cost = 0
	delay = 1.2 SECONDS

/**
 * The gun that fires the lateral beam, grown from an arcfiend's hand. Every shot costs its owner power and a charge from
 * an internal magazine, which slowly rebuilds. The magazine belongs to the arcfiend's power, so putting the gun away and
 * growing it again doesn't refill it. Using the gun in hand changes how far the beam reaches.
 */
/obj/item/gun/energy/arcfiend_lateral_laser
	name = "lateral laser"
	desc = "A thin biometal lance that fires a beam of flash-boiled nanites. The beam passes through everything and only scorches what it touches, until the nanites rupture at the very end of their range. Use it in hand to change the range."
	color = "#ffe94d"
	item_flags = ABSTRACT | DROPDEL
	ammo_type = list(/obj/item/ammo_casing/energy/arcfiend_lateral_beam)
	can_select = FALSE
	can_charge = FALSE
	automatic_charge_overlays = FALSE
	display_empty = FALSE

/obj/item/gun/energy/arcfiend_lateral_laser/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ARCFIEND_TRAIT)

/// It has no battery that anything could charge, the power comes from the arcfiend holding it
/obj/item/gun/energy/arcfiend_lateral_laser/get_cell(atom/movable/interface, mob/user)
	return null

/// The arcfiend holding this
/obj/item/gun/energy/arcfiend_lateral_laser/proc/get_holder_antag()
	if(!ismob(loc))
		return null
	var/mob/holder = loc
	return holder.mind?.has_antag_datum(/datum/antagonist/arcfiend)

/// The power that this gun's settings belong to
/obj/item/gun/energy/arcfiend_lateral_laser/proc/get_holder_action()
	if(!ismob(loc))
		return null
	var/mob/holder = loc
	return locate(/datum/action/cooldown/arcfiend/lateral_laser) in holder.actions

/obj/item/gun/energy/arcfiend_lateral_laser/can_shoot()
	var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
	var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
	if(!arcfiend || !settings)
		return FALSE
	return arcfiend.has_power(settings.get_shot_cost()) && settings.get_magazine() >= 1

/// Says why it won't fire, as well as clicking
/obj/item/gun/energy/arcfiend_lateral_laser/shoot_with_empty_chamber(mob/living/user as mob|obj)
	var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
	if(settings && settings.get_magazine() < 1)
		balloon_alert_to_viewers("out of charges!")
	else if(settings)
		balloon_alert_to_viewers("need [settings.get_shot_cost()] power!")
	else
		balloon_alert_to_viewers("*click*")
	playsound(src, dry_fire_sound, dry_fire_sound_volume, TRUE)

/// Always has a round ready, set to the range and damage the arcfiend has chosen. The cost is only paid when it is fired.
/obj/item/gun/energy/arcfiend_lateral_laser/recharge_newshot(no_cyborg_drain)
	if(!ammo_type || chambered)
		return
	chambered = ammo_type[select]
	if(!chambered.loaded_projectile)
		chambered.newshot()
	var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
	var/obj/projectile/beam/laser/hitscan/arcfiend_lateral/beam = chambered.loaded_projectile
	if(settings && istype(beam))
		beam.set_up(settings.get_selected_range(), settings.get_weak_damage(), settings.get_power_damage())

/obj/item/gun/energy/arcfiend_lateral_laser/handle_chamber(mob/living/user, empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	// A spent round means the shot was fired, so that is when it is paid for, in power and in a charge.
	// The game doesn't always pass the shooter in here, so whoever is holding the gun is used instead.
	if(chambered && !chambered.loaded_projectile)
		var/datum/antagonist/arcfiend/arcfiend = get_holder_antag()
		var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
		if(arcfiend && settings)
			arcfiend.spend_power(settings.get_shot_cost())
			if(settings.use_charge() && ismob(loc))
				var/mob/shooter = loc
				shooter.balloon_alert(shooter, "[settings.get_magazine()] charge[settings.get_magazine() == 1 ? "" : "s"] left")
	chambered = null
	recharge_newshot()

/// Using the gun in hand changes how far the beam reaches
/obj/item/gun/energy/arcfiend_lateral_laser/attack_self(mob/living/user)
	. = ..()
	var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
	if(!settings)
		return
	settings.cycle_range(user)
	// The round that is ready was set up for the old range
	chambered = null
	recharge_newshot()

/obj/item/gun/energy/arcfiend_lateral_laser/examine(mob/user)
	. = ..()
	var/datum/action/cooldown/arcfiend/lateral_laser/settings = get_holder_action()
	if(settings)
		. += span_notice("It is set to [settings.get_selected_range()] tile[settings.get_selected_range() == 1 ? "" : "s"]. The beam does [settings.get_weak_damage()] damage along the way and [settings.get_power_damage()] to whatever is at the very end of it.")
		. += span_notice("Its magazine holds [settings.get_magazine()] of [settings.get_magazine_size()] charges. It rebuilds one every [settings.get_charge_recharge_time() / 10] seconds.")

/datum/action/cooldown/arcfiend/lateral_laser
	name = "Lateral Laser"
	desc = "Grow a lance in your hand that fires a beam of superheated nanites. The beam passes through everything, including walls and people lying down, and stops at the range you set, 4 tiles at most. It does little damage along the way, but the nanites rupture at the very end of their range and do heavy damage there. Use the gun in your hand to change the range. Growing it and putting it away is free. Each shot costs power and a charge from its magazine, which holds 3 and rebuilds one every 10 seconds, even while the gun is away."
	button_icon_state = "lightning"
	cooldown_time = 1 SECONDS
	shop_tier = 2
	unlock_cost = 650
	upgrade_costs = list(500, 900)
	upgrade_descriptions = list(
		"Reaches 5 tiles, does 8 damage along the way and 60 at the end. Cheaper shots. Holds 4 charges, rebuilds one every 8 seconds.",
		"Reaches 6 tiles, does 10 damage along the way and 80 at the end. Cheaper shots. Holds 5 charges, rebuilds one every 6 seconds.",
	)
	/// The range the arcfiend has chosen. This lives here, so putting the gun away doesn't reset it. Null means as far as it can go.
	var/selected_range
	/// The charges in the magazine right now. It starts out full, see get_magazine().
	var/magazine
	/// The timer that rebuilds the next charge, while the magazine isn't full
	var/charge_timer

/// How many charges the magazine holds
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_magazine_size()
	return list(3, 4, 5)[clamp(get_level(), 1, 3)]

/// How long it takes to rebuild one charge
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_charge_recharge_time()
	return list(10 SECONDS, 8 SECONDS, 6 SECONDS)[clamp(get_level(), 1, 3)]

/// The charges in the magazine. The first time anyone asks, it is full.
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_magazine()
	if(isnull(magazine))
		magazine = get_magazine_size()
	return magazine

/// Takes a charge out of the magazine, and starts rebuilding one. Returns FALSE if the magazine is empty.
/datum/action/cooldown/arcfiend/lateral_laser/proc/use_charge()
	if(get_magazine() < 1)
		return FALSE
	magazine--
	start_charge_recharge()
	return TRUE

/// Starts rebuilding a charge, if the magazine isn't full and one isn't being rebuilt already
/datum/action/cooldown/arcfiend/lateral_laser/proc/start_charge_recharge()
	if(charge_timer || get_magazine() >= get_magazine_size())
		return
	charge_timer = addtimer(CALLBACK(src, PROC_REF(charge_recharged)), get_charge_recharge_time(), TIMER_STOPPABLE)

/// A charge has been rebuilt
/datum/action/cooldown/arcfiend/lateral_laser/proc/charge_recharged()
	charge_timer = null
	magazine = min(get_magazine() + 1, get_magazine_size())
	if(owner && (locate(/obj/item/gun/energy/arcfiend_lateral_laser) in owner.held_items))
		owner.balloon_alert(owner, "charge rebuilt ([magazine]/[get_magazine_size()])")
		playsound(owner, 'sound/weapons/gun/general/chunkyrack.ogg', 20, TRUE)
	start_charge_recharge()

/// A bigger magazine means there may be room to rebuild again
/datum/action/cooldown/arcfiend/lateral_laser/on_upgraded()
	start_charge_recharge()

/datum/action/cooldown/arcfiend/lateral_laser/Destroy()
	if(charge_timer)
		deltimer(charge_timer)
		charge_timer = null
	return ..()

/// How far the beam can be set to reach
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_max_range()
	return list(4, 5, 6)[clamp(get_level(), 1, 3)]

/// The range the beam is set to, never further than it can go
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_selected_range()
	selected_range = clamp(selected_range || get_max_range(), 1, get_max_range())
	return selected_range

/// The damage along the way
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_weak_damage()
	return list(6, 8, 10)[clamp(get_level(), 1, 3)]

/// The damage at exactly the end of the beam
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_power_damage()
	return list(45, 60, 80)[clamp(get_level(), 1, 3)]

/// The power a shot costs
/datum/action/cooldown/arcfiend/lateral_laser/proc/get_shot_cost()
	return list(30, 25, 20)[clamp(get_level(), 1, 3)]

/// Goes to the next range, and back to the shortest after the longest
/datum/action/cooldown/arcfiend/lateral_laser/proc/cycle_range(mob/user)
	selected_range = (get_selected_range() % get_max_range()) + 1
	to_chat(user, span_notice("You set the lateral laser to [selected_range] tile[selected_range == 1 ? "" : "s"]. Only what is exactly [selected_range] tile[selected_range == 1 ? "" : "s"] away takes its full damage."))
	user.balloon_alert(user, "range: [selected_range]")
	playsound(user, 'sound/items/click.ogg', 40, TRUE)

/datum/action/cooldown/arcfiend/lateral_laser/Remove(mob/remove_from)
	if(remove_from)
		put_away(remove_from)
	return ..()

/// Gets rid of the gun if we are holding it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/lateral_laser/proc/put_away(mob/user)
	var/found = FALSE
	for(var/obj/item/gun/energy/arcfiend_lateral_laser/gun in user.held_items)
		user.temporarilyRemoveItemFromInventory(gun, TRUE) // DROPDEL deletes it
		found = TRUE
	if(found)
		user.update_held_items()
	return found

/// Lets the gun crumble away, with the sparks and messages that go with it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/lateral_laser/proc/dismiss(mob/living/user)
	if(!put_away(user))
		return FALSE
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_notice("[user]'s lateral laser crumbles away."), span_notice("You let the lateral laser crumble away."))
	StartCooldown()
	return TRUE

/// Pressing the drop key while holding the gun dismisses it instead of trying to drop it
/datum/action/cooldown/arcfiend/lateral_laser/on_drop_key(mob/user, obj/item/held)
	if(istype(held, /obj/item/gun/energy/arcfiend_lateral_laser) && isliving(user))
		return dismiss(user)
	return ..()

/datum/action/cooldown/arcfiend/lateral_laser/Activate(atom/target)
	if(!get_arcfiend() || !isliving(owner))
		return FALSE
	var/mob/living/user = owner
	if(dismiss(user))
		return TRUE
	var/obj/item/held = user.get_active_held_item()
	if(held && !user.dropItemToGround(held))
		user.balloon_alert(user, "hand occupied!")
		return FALSE
	var/obj/item/gun/energy/arcfiend_lateral_laser/gun = new(user)
	user.put_in_hands(gun)
	do_sparks(2, FALSE, user)
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_warning("A thin lance of glowing biometal grows out of [user]'s hand!"), span_notice("You grow a lateral laser. It is set to [get_selected_range()] tile[get_selected_range() == 1 ? "" : "s"]. Use it in your hand to change that."))
	StartCooldown()
	return TRUE

//////////////////////////////////////////////////////////////////////////
//------------------------------Galvanic Prod---------------------------//
//////////////////////////////////////////////////////////////////////////
/**
 * A prod of crackling biometal that an arcfiend grows from their arm. Right-clicking someone with it
 * zaps them the way an emagged defibrillator does. The zaps cost its owner power, and it needs time to recharge.
 */
/obj/item/melee/arcfiend_prod
	name = "galvanic prod"
	desc = "A biometal prod grown from an arcfiend's arm. Left-click to hit with it, right-click to zap someone."
	icon = 'icons/obj/weapons/spear.dmi'
	icon_state = "stunprod"
	inhand_icon_state = "prod"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_flags = ABSTRACT | DROPDEL
	w_class = WEIGHT_CLASS_BULKY
	// A plain hit is ordinary melee, so anything that reacts to melee hits, like Electrokinetic Smash, reacts to it
	force = 15
	damtype = BURN
	hitsound = SFX_SPARKS
	throwforce = 0
	color = ARCFIEND_YELLOW_TINT
	light_outer_range = 2
	light_power = 1
	light_color = "#ffe94d"

/obj/item/melee/arcfiend_prod/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ARCFIEND_TRAIT)
	set_light_on(TRUE)

/// A right-click zaps, costing power. A plain click is an ordinary hit with a spark, which is free.
/obj/item/melee/arcfiend_prod/attack(mob/living/target_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	if(user.istate & ISTATE_SECONDARY)
		var/datum/action/cooldown/arcfiend/shock_prod/prod_action = locate() in user.actions
		prod_action?.try_zap(target_mob, user, src)
		user.changeNext_move(CLICK_CD_MELEE)
		return TRUE
	. = ..()
	if(!.)
		do_sparks(1, FALSE, target_mob)

/datum/action/cooldown/arcfiend/shock_prod
	name = "Galvanic Prod"
	desc = "Grow a prod from your arm. Growing it and putting it away is free. Left-click is a normal hit that burns for 15 and costs nothing. Right-click zaps like an emagged defibrillator: it drains stamina, knocks the target down and makes them drop what they hold. Zaps cost power, and the prod needs a few seconds to recharge between them."
	button_icon_state = "lightning"
	cooldown_time = 1 SECONDS
	shop_tier = 1
	unlock_cost = 0
	upgrade_costs = list(200, 450)
	upgrade_descriptions = list(
		"Zaps cost less power, and the prod recharges in 4 seconds.",
		"Zaps cost less power again, and the prod recharges in 3 seconds.",
	)
	/// The time at which the prod is ready to zap again. This lives here and not on the prod, so putting it away doesn't reset it.
	var/prod_ready_time = 0

/// How much power a zap costs
/datum/action/cooldown/arcfiend/shock_prod/proc/get_zap_cost()
	return list(40, 32, 25)[clamp(get_level(), 1, 3)]

/// How long the prod takes to recharge after a zap. The same as a defibrillator unit.
/datum/action/cooldown/arcfiend/shock_prod/proc/get_zap_cooldown()
	return list(5 SECONDS, 4 SECONDS, 3 SECONDS)[clamp(get_level(), 1, 3)]

/datum/action/cooldown/arcfiend/shock_prod/Remove(mob/remove_from)
	if(remove_from)
		put_away(remove_from)
	return ..()

/// Gets rid of the prod if we are holding it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/shock_prod/proc/put_away(mob/user)
	var/found = FALSE
	for(var/obj/item/melee/arcfiend_prod/prod in user.held_items)
		user.temporarilyRemoveItemFromInventory(prod, TRUE) // DROPDEL deletes it
		found = TRUE
	if(found)
		user.update_held_items()
	return found

/// Lets the prod crumble away, with the sparks and messages that go with it. Returns TRUE if there was one.
/datum/action/cooldown/arcfiend/shock_prod/proc/dismiss(mob/living/user)
	if(!put_away(user))
		return FALSE
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_notice("[user]'s galvanic prod crumbles away."), span_notice("You let the galvanic prod crumble away."))
	StartCooldown()
	return TRUE

/// Pressing the drop key while holding the prod dismisses it instead of trying to drop it
/datum/action/cooldown/arcfiend/shock_prod/on_drop_key(mob/user, obj/item/held)
	if(istype(held, /obj/item/melee/arcfiend_prod) && isliving(user))
		return dismiss(user)
	return ..()

/datum/action/cooldown/arcfiend/shock_prod/Activate(atom/target)
	if(!get_arcfiend() || !isliving(owner))
		return FALSE
	var/mob/living/user = owner
	if(dismiss(user))
		return TRUE
	var/obj/item/held = user.get_active_held_item()
	if(held && !user.dropItemToGround(held))
		user.balloon_alert(user, "hand occupied!")
		return FALSE
	var/obj/item/melee/arcfiend_prod/prod = new(user)
	user.put_in_hands(prod)
	do_sparks(2, FALSE, user)
	playsound(user, SFX_SPARKS, 30, TRUE)
	user.visible_message(span_warning("A crackling prod of biometal grows out of [user]'s arm!"), span_notice("You grow a galvanic prod. Left-click to hit with it, or right-click someone to zap them."))
	StartCooldown()
	return TRUE

/// Zaps someone with the prod. Returns TRUE if they were zapped.
/datum/action/cooldown/arcfiend/shock_prod/proc/try_zap(mob/living/target, mob/living/user, obj/item/melee/arcfiend_prod/prod)
	var/datum/antagonist/arcfiend/arcfiend = get_arcfiend()
	if(!arcfiend || !istype(target) || target == user)
		return FALSE
	if(prod_ready_time > world.time)
		user.balloon_alert(user, "recharging!")
		to_chat(user, span_warning("[prod] is still recharging. Give it another [round((prod_ready_time - world.time) / 10, 0.1)] seconds."))
		return FALSE
	var/cost = get_zap_cost()
	if(!arcfiend.has_power(cost))
		user.balloon_alert(user, "need [cost] power!")
		return FALSE
	if(HAS_TRAIT(target, TRAIT_SHOCKIMMUNE))
		target.visible_message(span_warning("The electricity from [prod] washes harmlessly over [target]!"))
		return FALSE

	arcfiend.spend_power(cost)
	var/recharge_time = get_zap_cooldown()
	prod_ready_time = world.time + recharge_time
	addtimer(CALLBACK(src, PROC_REF(announce_ready)), recharge_time)

	// The same effect as the right-click of an emagged defibrillator
	target.visible_message(
		span_danger("[user] touches [target] with [prod]!"),
		span_userdanger("[user] touches you with [prod], and a huge jolt of electricity floods through your body!"),
	)
	target.stamina.adjust(-80)
	target.Knockdown(75)
	target.set_jitter_if_lower(100 SECONDS)
	target.apply_status_effect(/datum/status_effect/convulsing)
	playsound(user, 'sound/machines/defib_zap.ogg', 50, TRUE, -1)
	do_sparks(2, FALSE, target)
	if(target.mob_biotypes & MOB_ORGANIC)
		target.emote("gasp")
	log_combat(user, target, "zapped", prod)
	return TRUE

/// Tells the arcfiend that the prod can zap again
/datum/action/cooldown/arcfiend/shock_prod/proc/announce_ready()
	if(!owner || !(locate(/obj/item/melee/arcfiend_prod) in owner.held_items))
		return
	to_chat(owner, span_notice("Your galvanic prod finishes recharging."))
	playsound(owner, 'sound/machines/defib_ready.ogg', 30, TRUE)
