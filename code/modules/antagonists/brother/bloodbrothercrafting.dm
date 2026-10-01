/datum/component/personal_crafting/blood_brother
	forced_mode = TRUE
	/// Every Blood Brother recipe, shared between all instances of this component.
	var/static/list/blood_brother_recipes

/datum/component/personal_crafting/blood_brother/Initialize()
	// Deliberately skips the parent, which would add a second crafting button to the mob's HUD.
	if(blood_brother_recipes)
		return
	blood_brother_recipes = list()
	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(recipe.blood_brother_only)
			blood_brother_recipes += recipe

/datum/component/personal_crafting/blood_brother/can_use_special_recipes(mob/user)
	return IS_BROTHER(user)

/datum/component/personal_crafting/blood_brother/get_crafting_recipes()
	return blood_brother_recipes

/datum/component/personal_crafting/blood_brother/is_recipe_available(datum/crafting_recipe/recipe, mob/user)
	if(!IS_BROTHER(user))
		return FALSE
	return ..()

/// Blood Brother crafting has no window of its own, it is shown in the crafting tab of the brother panel instead.
/datum/component/personal_crafting/blood_brother/ui_interact(mob/user, datum/tgui/ui)
	var/datum/antagonist/brother/bond = user?.mind?.has_antag_datum(/datum/antagonist/brother)
	bond?.open_tab(BB_UI_TAB_CRAFTING)

/datum/crafting_recipe/blood_brother
	blood_brother_only = TRUE
	category = CAT_BB_MISC
	time = 3 SECONDS

/datum/crafting_recipe/blood_brother/magazine_part
	name = "Magazine"
	desc = "An improvised ballistic magazine component built around a matter bin."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/magazine
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
	)

/datum/crafting_recipe/blood_brother/semi_auto_receiver_part
	name = "Semi-Auto Receiver"
	desc = "An improvised semi-automatic receiver."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/semi_auto
	reqs = list(
		/obj/item/firing_pin = 1,
	)

/datum/crafting_recipe/blood_brother/automatic_receiver_part
	name = "Automatic Receiver"
	desc = "An improvised automatic receiver."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/automatic
	reqs = list(
		/obj/item/firing_pin = 1,
	)

/datum/crafting_recipe/blood_brother/rifle_receiver_part
	name = "Rifle Receiver"
	desc = "An improvised rifle receiver."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/rifle
	reqs = list(
		/obj/item/firing_pin = 1,
	)

/datum/crafting_recipe/blood_brother/carbine_receiver_part
	name = "Carbine Receiver"
	desc = "An improvised carbine receiver."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/carbine
	reqs = list(
		/obj/item/firing_pin = 1,
	)

/datum/crafting_recipe/blood_brother/barrel_part
	name = "Barrel"
	desc = "An improvised ballistic barrel."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/barrel
	reqs = list(
		/obj/item/pipe = 1,
	)

/datum/crafting_recipe/blood_brother/power_cell_part
	name = "Power Cell"
	desc = "An improvised energy weapon power cell."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/power_cell
	reqs = list(
		/obj/item/stock_parts/power_store/cell = 1,
	)

/datum/crafting_recipe/blood_brother/lens_part
	name = "Lens"
	desc = "An improvised energy weapon lens."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/lens
	reqs = list(
		/obj/item/stock_parts/scanning_module = 1,
	)

/datum/crafting_recipe/blood_brother/underbarrel_part
	name = "Underbarrel"
	desc = "An improvised underbarrel component for a Blood Brother weapon."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/underbarrel
	reqs = list(
		/obj/item/ammo_box/magazine/smgm45 = 1,
	)

/datum/crafting_recipe/blood_brother/toolset_implant
	name = "Toolset Arm Implant"
	desc = "A full set of tools crammed into a cyborg arm, ready to be implanted into your own. Either cyborg arm will do."
	category = CAT_BB_IMPLANTS
	result = /obj/item/organ/internal/cyberimp/arm/item_set/toolset
	reqs = list(
		/obj/item/bodypart/arm = 1,
		/obj/item/screwdriver = 1,
		/obj/item/weldingtool = 1,
		/obj/item/wirecutters = 1,
		/obj/item/multitool = 1,
		/obj/item/wrench = 1,
		/obj/item/stack/cable_coil = 10,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/toolset_implant/New()
	. = ..()
	// Accept either cyborg arm, but never any other kind of arm.
	blacklist |= typesof(/obj/item/bodypart/arm) - typesof(/obj/item/bodypart/arm/left/robot) - typesof(/obj/item/bodypart/arm/right/robot)

/datum/crafting_recipe/blood_brother/smokebomb_lungs
	name = "Smokebomb Lungs"
	desc = "A pair of lungs packed with smoke powder, letting you exhale a cloud of choking smoke on demand. You'll be immune to the coughing, but not the blindness."
	category = CAT_BB_IMPLANTS
	result = /obj/item/organ/internal/lungs/smokebomb
	reqs = list(
		/obj/item/organ/internal/lungs = 1,
		/datum/reagent/smoke_powder = 15,
	)
	time = 10 SECONDS

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

/datum/crafting_recipe/blood_brother/makeshift_emag
	name = "Improvised Emag"
	desc = "A crude cryptographic sequencer assembled from scavenged electronics. It is slow, unreliable, and must be manually recharged."
	category = CAT_BB_GADGETS
	result = /obj/item/card/emag/improvised
	reqs = list(
		/obj/item/stock_parts/subspace/amplifier = 1,
		/obj/item/card/id = 1,
		/obj/item/electronics/firelock = 1,
		/obj/item/stack/cable_coil = 10,
	)
	tool_behaviors = list(
		TOOL_MULTITOOL,
		TOOL_WIRECUTTER,
	)
	time = 12 SECONDS

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

/datum/crafting_recipe/blood_brother/hardlight_laser_cannon
	name = "Hardlight Laser Cannon"
	desc = "A crude laser cannon that fires dense beams of hardlight."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/energy/laser/hardlight
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/power_store/cell = 1,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 2,
	)
