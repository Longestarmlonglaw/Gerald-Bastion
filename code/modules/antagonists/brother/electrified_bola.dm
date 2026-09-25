/**
 * Electrified Blood Brother bola.
 *
 * Uses the normal bola sprite for now as a placeholder.
 */

/obj/item/restraints/legcuffs/bola/electrified
	name = "electrified bola"
	desc = "A bola modified to deliver a sustained electrical shock to whoever it ensnares."
	// Placeholder: intentionally inherits the regular bola sprite.

/obj/item/restraints/legcuffs/bola/electrified/ensnare(mob/living/carbon/C)
	. = ..()
	if(C.legcuffed != src)
		return

	// The EMP happens once, immediately when the bola successfully ensnares its target.
	C.emp_act(EMP_HEAVY)
	C.remove_status_effect(/datum/status_effect/electrified_bola)
	C.apply_status_effect(/datum/status_effect/electrified_bola, src)

/datum/status_effect/electrified_bola
	id = "electrified_bola"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 2 SECONDS
	processing_speed = STATUS_EFFECT_FAST_PROCESS
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = null
	var/obj/item/restraints/legcuffs/bola/electrified/source_bola

/datum/status_effect/electrified_bola/on_creation(mob/living/new_owner, obj/item/restraints/legcuffs/bola/electrified/new_source)
	source_bola = new_source
	return ..()

/datum/status_effect/electrified_bola/tick(seconds_between_ticks)
	if(QDELETED(source_bola) || !istype(owner, /mob/living/carbon) || owner:legcuffed != source_bola)
		qdel(src)
		return

	// Leave at least 25 stamina so this effect cannot repeatedly force stamina stuns.
	var/stamina_damage = min(5, max(0, owner.stamina.current - 25))
	if(stamina_damage)
		owner.stamina.adjust(-stamina_damage)

	owner.take_overall_damage(burn = 2 * seconds_between_ticks)
