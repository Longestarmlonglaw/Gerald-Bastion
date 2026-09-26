/datum/action/bb/crafting
	name = "Blood Brother Crafting"
	desc = "Open the Blood Brother crafting menu."
	button_icon_state = "weapons"

/datum/action/bb/crafting/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return
	var/datum/component/personal_crafting/blood_brother/crafting = owner.GetComponent(/datum/component/personal_crafting/blood_brother)
	crafting?.ui_interact(owner)
