/**
 * Bond beacon for Blood Brothers.
 *
 * A single use item that a blood brother applies to themselves, sharing their location
 * with the rest of their team in the conspirators tab for the rest of the round.
 * Does nothing for anyone who isn't a blood brother.
 */
/obj/item/bond_beacon
	name = "bond beacon"
	desc = "A tiny tracking chip keyed to a blood bond. Apply it to yourself to share your location with your brothers."
	icon = 'icons/obj/antags/blood_brother.dmi'
	icon_state = "bond_beacon"
	w_class = WEIGHT_CLASS_TINY

/obj/item/bond_beacon/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	var/datum/antagonist/brother/bond = user.mind?.has_antag_datum(/datum/antagonist/brother)
	if(!bond)
		balloon_alert(user, "nothing happens")
		return TRUE
	if(bond.sharing_location)
		balloon_alert(user, "already sharing location!")
		return TRUE

	bond.sharing_location = TRUE
	to_chat(user, span_notice("You press [src] against your skin. Your brothers can now see where you are in the conspirators tab."))
	playsound(user, 'sound/machines/click.ogg', 30, TRUE)
	qdel(src)
	return TRUE
