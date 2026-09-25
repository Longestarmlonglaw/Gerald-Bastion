/datum/component/personal_crafting/blood_brother
	forced_mode = TRUE
	var/list/blood_brother_recipes

/datum/component/personal_crafting/blood_brother/Initialize()
	blood_brother_recipes = list(
		new /datum/crafting_recipe/blood_brother/sanguine_lantern,
		new /datum/crafting_recipe/blood_brother/brotherly_token,
		new /datum/crafting_recipe/blood_brother/blood_bond,
		new /datum/crafting_recipe/blood_brother/brotherly_weapon,
		new /datum/crafting_recipe/blood_brother/brotherly_ammunition,
		new /datum/crafting_recipe/blood_brother/brotherly_gadget,
		new /datum/crafting_recipe/blood_brother/brotherly_explosive,
		new /datum/crafting_recipe/blood_brother/brotherly_parts,
		new /datum/crafting_recipe/blood_brother/brotherly_implant,
		new /datum/crafting_recipe/blood_brother/electrified_bola,
		new /datum/crafting_recipe/blood_brother/scrap_revolver,
	)
	return

/datum/component/personal_crafting/blood_brother/can_use_special_recipes(mob/user)
	return IS_BROTHER(user)

/datum/component/personal_crafting/blood_brother/get_crafting_recipes()
	return blood_brother_recipes

/datum/component/personal_crafting/blood_brother/get_ui_title()
	return "Blood Brother Crafting"

/datum/component/personal_crafting/blood_brother/is_recipe_available(datum/crafting_recipe/recipe, mob/user)
	if(!IS_BROTHER(user))
		return FALSE
	return ..()

/datum/component/personal_crafting/blood_brother/ui_interact(mob/user, datum/tgui/ui)
	if(!IS_BROTHER(user))
		return
	return ..()

/datum/crafting_recipe/blood_brother
	blood_brother_only = TRUE
	category = CAT_BB_MISC
	time = 3 SECONDS

/datum/crafting_recipe/blood_brother/sanguine_lantern
	category = CAT_BB_GADGETS
	name = "Sanguine Lantern"
	desc = "A simple lantern prepared for a trusted conspirator."
	result = /obj/item/flashlight/lantern
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/cable_coil = 1,
	)

/datum/crafting_recipe/blood_brother/brotherly_token
	category = CAT_BB_MISC
	name = "Brotherly Token"
	desc = "A small metal token bearing a private mark."
	result = /obj/item/coin/iron
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/sheet/glass = 1,
	)

/datum/crafting_recipe/blood_brother/blood_bond
	category = CAT_BB_ARMOR
	name = "Blood Bond Bandage"
	desc = "A practical bandage kit shared among blood brothers."
	result = /obj/item/stack/medical/gauze
	reqs = list(
		/obj/item/stack/sheet/cloth = 1,
		/obj/item/food/meat/slab = 1,
)

/datum/crafting_recipe/blood_brother/brotherly_weapon
	name = "Brotherly Weapon"
	desc = "A simple weapon made for someone you trust."
	category = CAT_BB_WEAPONS
	result = /obj/item/knife
	reqs = list(
		/obj/item/stack/sheet/iron = 2,
)

/datum/crafting_recipe/blood_brother/brotherly_ammunition
	name = "Brotherly Ammunition"
	desc = "A small supply of improvised ammunition."
	category = CAT_BB_AMMUNITION
	result = /obj/item/stack/cable_coil
	result_amount = 2
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
)

/datum/crafting_recipe/blood_brother/brotherly_gadget
	name = "Brotherly Gadget"
	desc = "A compact tool for solving problems quietly."
	category = CAT_BB_GADGETS
	result = /obj/item/flashlight
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/cable_coil = 1,
)

/datum/crafting_recipe/blood_brother/brotherly_explosive
	name = "Brotherly Explosive"
	desc = "A dangerous package best handled by a trusted conspirator."
	category = CAT_BB_EXPLOSIVES
	result = /obj/item/assembly/flash
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/cable_coil = 1,
)

/datum/crafting_recipe/blood_brother/brotherly_parts
	name = "Brotherly Parts"
	desc = "Spare components reserved for the blood bond."
	category = CAT_BB_PARTS
	result = /obj/item/stack/sheet/iron
	result_amount = 2
	reqs = list(
		/obj/item/stack/sheet/glass = 1,
)

/datum/crafting_recipe/blood_brother/brotherly_implant
	name = "Brotherly Implant"
	desc = "A placeholder implant for future Blood Brother designs."
	category = CAT_BB_IMPLANTS
	result = /obj/item/coin/iron
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/sheet/glass = 1,
)


/datum/crafting_recipe/blood_brother/electrified_bola
	name = "Electrified Bola"
	desc = "A modified bola wired to deliver a sustained electrical shock."
	category = CAT_BB_WEAPONS
	result = /obj/item/restraints/legcuffs/bola/electrified
	reqs = list(
		/obj/item/restraints/legcuffs/bola = 1,
		/obj/item/stock_parts/power_store/cell = 1,
		/obj/item/stock_parts/capacitor = 3,
	)
	tool_behaviors = list(
		TOOL_MULTITOOL,
		TOOL_WIRECUTTER,
	)

/datum/crafting_recipe/blood_brother/electrified_bola/check_requirements(atom/a, list/collected_requirements)
	var/found_bola = FALSE
	for(var/obj/item/restraints/legcuffs/bola/bola in collected_requirements[/obj/item/restraints/legcuffs/bola])
		if(bola.type == /obj/item/restraints/legcuffs/bola)
			found_bola = TRUE
			break
	if(!found_bola)
		return FALSE

	return ..()


/datum/crafting_recipe/blood_brother/scrap_revolver
	name = "Scrap Revolver"
	desc = "A crude revolver built around a matter-bin cylinder that can be configured for .38 rounds or 12 gauge shells."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/ballistic/revolver/blood_brother_scrap
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/pipe = 1,
		/obj/item/stack/sticky_tape = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)
	tool_paths = list(
		/obj/item/surgicaldrill,
	)
