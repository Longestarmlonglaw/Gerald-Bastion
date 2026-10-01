/**
 * Smokebomb lungs for Blood Brothers.
 *
 * Lets the owner exhale a cloud of choking smoke, and makes them immune to the coughing it causes.
 */
/obj/item/organ/internal/lungs/smokebomb
	name = "smokebomb lungs"
	desc = "A pair of lungs packed with smoke-producing glands. Whoever has these can exhale a thick, choking cloud without so much as a cough."
	icon_state = "lungs_smokebomb"
	actions_types = list(/datum/action/cooldown/smokebomb_lungs)
	organ_traits = list(TRAIT_SMOKE_COUGH_IMMUNE)

/datum/action/cooldown/smokebomb_lungs
	name = "Exhale Smoke"
	desc = "Exhale a thick cloud of smoke that blocks vision and makes anyone caught in it cough. You won't cough, but you can't see through it either."
	button_icon = 'icons/obj/weapons/grenade.dmi'
	button_icon_state = "smokewhite"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 1 MINUTES

/datum/action/cooldown/smokebomb_lungs/Activate(atom/target)
	var/mob/living/exhaler = owner
	exhaler.visible_message(
		span_warning("[exhaler] exhales a thick cloud of smoke!"),
		span_notice("You exhale a thick cloud of smoke."),
	)
	playsound(exhaler, 'sound/effects/smoke.ogg', 50, TRUE, -3)
	var/datum/effect_system/fluid_spread/smoke/bad/smoke = new
	smoke.set_up(4, holder = exhaler, location = get_turf(exhaler))
	smoke.start()
	qdel(smoke)
	StartCooldown()
	return TRUE
