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
	category = CAT_BB_SUPPORT
	time = 3 SECONDS

/datum/crafting_recipe/blood_brother/extended_magazine
	name = "Extended Magazine"
	desc = "Adds a couple of extra rounds to a weapon's internal magazine, like a revolver's cylinder."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/magazine/extended
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/extended_magazine/New()
	. = ..()
	// Only accept a basic matter bin, so better ones never get used up by mistake.
	blacklist |= typesof(/obj/item/stock_parts/matter_bin) - /obj/item/stock_parts/matter_bin

/datum/crafting_recipe/blood_brother/big_magazine
	name = "Big Magazine"
	desc = "Adds a lot of extra rounds to a weapon's internal magazine, but makes the weapon one size bigger."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/magazine/big
	reqs = list(
		/obj/item/stock_parts/matter_bin/adv = 1,
		/obj/item/stack/sheet/iron = 10,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/bluespace_magazine
	name = "Bluespace Magazine"
	desc = "Lets a weapon's internal magazine hold an absurd number of rounds, but loading ammunition into it takes a moment."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/magazine/bluespace
	reqs = list(
		/obj/item/stock_parts/matter_bin/bluespace = 1,
		/obj/item/stack/ore/bluespace_crystal = 5,
		/obj/item/stack/sheet/mineral/diamond = 2,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_MULTITOOL,
	)
	time = 15 SECONDS

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

/datum/crafting_recipe/blood_brother/upgraded_cell
	name = "Upgraded Cell"
	desc = "Doubles an energy weapon's charge capacity."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/power_cell/upgraded
	reqs = list(
		/obj/item/stock_parts/power_store/cell/high = 1,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/emp_shielded_cell
	name = "EMP Shielded Cell"
	desc = "Holds less charge than an upgraded cell, but an EMP fully recharges your energy weapon instead of draining it."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/power_cell/emp_shielded
	reqs = list(
		/obj/item/stock_parts/power_store/cell/high = 1,
		/obj/item/stack/sheet/plasteel = 2,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/self_recharging_cell
	name = "Self-Recharging Cell"
	desc = "Slowly recharges your energy weapon over time."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/power_cell/self_recharging
	reqs = list(
		/obj/item/stock_parts/power_store/cell/high = 1,
		/obj/item/slime_extract/yellow = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/unstable_cell
	name = "Unstable Cell"
	desc = "Quadruples your energy weapon's capacity, and lets you recharge it by feeding it uranium. But it sparks with every shot, leaks radiation, and an EMP will make it violently discharge into you."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/power_cell/unstable
	reqs = list(
		/obj/item/stock_parts/power_store/cell/hyper = 1,
		/obj/item/stack/sheet/mineral/uranium = 5,
		/obj/item/stack/sheet/mineral/plasma = 2,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 10 SECONDS

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
	desc = "Cybernetic lungs loaded with smoke powder, letting you exhale a cloud of choking smoke on demand. You'll be immune to the coughing, but not the blindness. Any cybernetic lungs will do."
	category = CAT_BB_IMPLANTS
	result = /obj/item/organ/internal/lungs/cybernetic/smokebomb
	reqs = list(
		/obj/item/organ/internal/lungs = 1,
		/datum/reagent/smoke_powder = 15,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/smokebomb_lungs/New()
	. = ..()
	// Accept any robotic lungs, but never organic ones.
	for(var/obj/item/organ/internal/lungs/lungs_type as anything in typesof(/obj/item/organ/internal/lungs))
		if(!(initial(lungs_type.organ_flags) & ORGAN_ROBOTIC))
			blacklist |= lungs_type

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

/datum/crafting_recipe/blood_brother/ned_kelly_armor
	name = "Ned Kelly Armor"
	desc = "Heavy plate armor that protects your chest, groin and arms, but not your legs. Wear it with the Ned Kelly helmet to become immune to stuns."
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/suit/armor/ned_kelly
	reqs = list(
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/stack/sheet/iron = 20,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_WRENCH,
	)
	time = 20 SECONDS

/datum/crafting_recipe/blood_brother/ned_kelly_helmet
	name = "Ned Kelly Helmet"
	desc = "A heavy iron helmet that covers your whole face. Wear it with the Ned Kelly armor to become immune to stuns."
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/head/helmet/ned_kelly
	reqs = list(
		/obj/item/stack/sheet/plasteel = 2,
		/obj/item/stack/sheet/iron = 10,
	)
	tool_behaviors = list(
		TOOL_WELDER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/smoke_grenade
	name = "Smoke Grenade"
	desc = "You could probably mass produce these at the chemistry labs, but not having to steal or beg for a chem dispenser is a plus."
	category = CAT_BB_EXPLOSIVES
	result = /obj/item/grenade/smokebomb
	reqs = list(
		/obj/item/reagent_containers/cup/soda_cans = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/cable_coil = 5,
		/datum/reagent/consumable/sugar = 10,
	)
	time = 5 SECONDS

/// Converts a regular .38 speedloader into a special one. Not a recipe itself, as it has no name or result.
/datum/crafting_recipe/blood_brother/c38_speedloader
	category = CAT_BB_AMMUNITION
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/c38_speedloader/New()
	. = ..()
	// Only accept a regular .38 speedloader, so special ones never get used up by mistake.
	blacklist |= typesof(/obj/item/ammo_box/c38) - /obj/item/ammo_box/c38

/datum/crafting_recipe/blood_brother/c38_speedloader/hotshot
	name = ".38 Hot Shot Speedloader"
	desc = "Pack a regular .38 speedloader's rounds with welding fuel for an incendiary payload."
	result = /obj/item/ammo_box/c38/hotshot
	reqs = list(
		/obj/item/ammo_box/c38 = 1,
		/datum/reagent/fuel = 10,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/c38_speedloader/iceblox
	name = ".38 Iceblox Speedloader"
	desc = "Pack a regular .38 speedloader's rounds with cryostylane for a cryogenic payload."
	result = /obj/item/ammo_box/c38/iceblox
	reqs = list(
		/obj/item/ammo_box/c38 = 1,
		/datum/reagent/cryostylane = 10,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/c38_speedloader/dumdum
	name = ".38 DumDum Speedloader"
	desc = "Notch the tips of a regular .38 speedloader's rounds so they expand on impact. Devastating against unarmored targets, weak against everything else."
	result = /obj/item/ammo_box/c38/dumdum
	reqs = list(
		/obj/item/ammo_box/c38 = 1,
	)
	tool_behaviors = list(
		TOOL_WIRECUTTER,
	)

/datum/crafting_recipe/blood_brother/bond_beacon
	name = "Bond Beacon"
	desc = "A single use tracking chip keyed to your blood bond. Apply it to yourself to share your location with your brothers in the conspirators tab for the rest of the round."
	category = CAT_BB_SUPPORT
	result = /obj/item/bond_beacon
	reqs = list(
		/obj/item/assembly/signaler = 1,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)
	time = 5 SECONDS
