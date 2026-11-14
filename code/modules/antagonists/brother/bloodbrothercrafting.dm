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
	desc = "Fit extra rounds into a weapon's internal magazine, like a revolver's cylinder."
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
	desc = "Bolts on a much bigger magazine for a lot more rounds, though you'll definitely feel the weight."
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
	desc = "Fits an absurd number of rounds into the internal magazine, but cramming bullets into a pocket dimension is really tedious."
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
	desc = "A spring trigger in a bent iron housing. Pull once, shoot once. Simple as that."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/semi_auto
	reqs = list(
		/obj/item/assembly/mousetrap = 1,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/automatic_receiver_part
	name = "Automatic Receiver"
	desc = "A trigger group with a motorized manipulator cycling the action for you. Hold the trigger and let it rip, just watch your ammo!"
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/automatic
	reqs = list(
		/obj/item/assembly/mousetrap = 1,
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stack/sheet/iron = 10,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WIRECUTTER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/rifle_receiver_part
	name = "Rifle Receiver"
	desc = "A heavy plasteel receiver with a slow action. Your shots hit harder and fly faster, but you'll fire slower. Don't miss!"
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/rifle
	reqs = list(
		/obj/item/assembly/mousetrap = 1,
		/obj/item/stack/sheet/plasteel = 3,
		/obj/item/stack/rods = 4,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/carbine_receiver_part
	name = "Carbine Receiver"
	desc = "A short action offering a compromise of power and fire rate between semi-auto and rifle."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/receiver/carbine
	reqs = list(
		/obj/item/assembly/mousetrap = 1,
		/obj/item/stack/sheet/plasteel = 1,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/long_barrel
	name = "Long Barrel"
	desc = "Extend your barrel to punch through armor and deal more damage but makes it harder to stuff inside your bag."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/barrel/long
	reqs = list(
		/obj/item/pipe = 2,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/shortened_barrel
	name = "Shortened Barrel"
	desc = "Saw the barrel down to hide your gun more easily, but your shots will spray everywhere."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/barrel/shortened
	reqs = list(
		/obj/item/pipe = 1,
	)
	tool_behaviors = list(
		TOOL_SAW,
	)

/datum/crafting_recipe/blood_brother/lucky_barrel
	name = "Lucky Barrel"
	desc = "Gives single shot rounds like slugs and revolver rounds a chance to crit for double damage. Buckshot and other pellets get no luck, sorry!"
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/barrel/lucky
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/dice = 2,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/choke
	name = "Choke"
	desc = "Tightens your spread, increasing accuracy and allowing dual wielding to be less inaccurate."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/barrel/choke
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/plasteel = 2,
	)
	tool_behaviors = list(
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/upgraded_cell
	name = "Upgraded Cell"
	desc = "A bigger battery, so your gun holds twice the charge."
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
	desc = "Same charge as a stock cell, but an EMP fully recharges your weapon instead of draining it."
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
	desc = "Wired to a slime core so your gun slowly charges itself back up. Handy when you can't get to a charger."
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
	desc = "Four times the capacity and it recharges with uranium, but it sparks, leaks radiation, and an EMP will dump the charge straight into you. Not exactly safe!"
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

/datum/crafting_recipe/blood_brother/spray_lens
	name = "Spray Lens"
	desc = "Sprays weak and inaccurate but fast, armor-piercing shots for hardly any power. Automatic fire not included."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/lens/spray
	reqs = list(
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stack/sheet/glass = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/spray_lens/New()
	. = ..()
	// Only accept a basic scanning module, so better ones never get used up by mistake.
	blacklist |= typesof(/obj/item/stock_parts/scanning_module) - /obj/item/stock_parts/scanning_module

/datum/crafting_recipe/blood_brother/efficiency_lens
	name = "Efficiency Lens"
	desc = "Squeezes a lot more shots out of each charge, but they hit softer. Great if you need to conserve ammo."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/lens/efficiency
	reqs = list(
		/obj/item/stock_parts/scanning_module/adv = 1,
		/obj/item/stack/sheet/glass = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/densifying_lens
	name = "Densifying Lens"
	desc = "Slow, heavy shots that hit harder and knock people down. You'll fire a lot slower, so make them count."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/lens/densifying
	reqs = list(
		/obj/item/stock_parts/scanning_module/phasic = 1,
		/obj/item/stack/sheet/plasteel = 2,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/bluespace_lens
	name = "Bluespace Lens"
	desc = "Shots hit harder, fly faster, and can teleport whoever they hit. It drains your battery and fires slower, but it's worth it for the chaos."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/lens/bluespace
	reqs = list(
		/obj/item/stock_parts/scanning_module/triphasic = 1,
		/obj/item/stack/ore/bluespace_crystal = 3,
		/obj/item/stack/sheet/mineral/diamond = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_MULTITOOL,
	)
	time = 15 SECONDS

/datum/crafting_recipe/blood_brother/crude_launcher
	name = "Crude Launcher"
	desc = "A pneumatic cannon mounted onto your firearm. Right-click to fire whatever's loaded."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/underbarrel/launcher
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/tank/internals/emergency_oxygen = 1,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_WRENCH,
		TOOL_WELDER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/grenade_launcher
	name = "Underbarrel Grenade Launcher"
	desc = "Holds one grenade, any kind, and lobs it on a short fuse when you right-click with your weapon. Don't stand too close!"
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/underbarrel/grenade_launcher
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/sheet/plasteel = 3,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/saw_blade
	name = "Saw Blade"
	desc = "Turns your weapon's melee attack into a nasty cutting one. Quite cumbersome but better than a bayonet that's for sure."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/underbarrel/saw_blade
	reqs = list(
		/obj/item/stack/sheet/plasteel = 2,
		/obj/item/stack/sheet/iron = 5,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_SAW,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/scrap_foregrip
	name = "Scrap Foregrip"
	desc = "A fold-out handle that steadies your aim and makes dual wielding a lot less of a mess."
	category = CAT_BB_PARTS
	result = /obj/item/blood_brother_gun_part/underbarrel/foregrip
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WRENCH,
	)

/datum/crafting_recipe/blood_brother/toolset_implant
	name = "Toolset Arm Implant"
	desc = "A whole toolbox crammed into a cyborg arm, ready to be shoved into you. Either cyborg arm will do."
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

/datum/crafting_recipe/blood_brother/toolset_implant/surgical
	name = "Surgical Toolset Arm Implant"
	desc = "A whole surgery tray crammed into a cyborg arm, ready to be shoved into you. Either cyborg arm will do."
	result = /obj/item/organ/internal/cyberimp/arm/item_set/surgery
	reqs = list(
		/obj/item/bodypart/arm = 1,
		/obj/item/retractor = 1,
		/obj/item/hemostat = 1,
		/obj/item/cautery = 1,
		/obj/item/surgicaldrill = 1,
		/obj/item/scalpel = 1,
		/obj/item/circular_saw = 1,
		/obj/item/surgical_drapes = 1,
		/obj/item/stack/cable_coil = 10,
	)

/datum/crafting_recipe/blood_brother/smokebomb_lungs
	name = "Smokebomb Lungs"
	desc = "Cybernetic lungs packed with smoke powder, so you can breathe out a cloud to vanish like a ninja. Any cybernetic lungs will do."
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
	desc = "A bola with a battery and a few capacitors wired in, so whoever it catches gets zapped until they get it off."
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
	desc = "Scavenged electronics and a cracked screen doing a very bad impression of an emag. Slow, flaky, and you have to recharge it with uranium."
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

/datum/crafting_recipe/blood_brother/pin_clamp
	name = "Pin Clamp"
	desc = "A clamp that crushes a gun's firing pin and jams an electronic one in its place, so pin locked guns work for anyone. Single use but works on guns with normally unremoveable firing pins."
	category = CAT_BB_GADGETS
	result = /obj/item/pin_clamp
	reqs = list(
		/obj/item/stack/sheet/iron = 2,
		/obj/item/stack/rods = 2,
		/obj/item/assembly/signaler = 1,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_WRENCH,
		TOOL_SCREWDRIVER,
	)
	time = 8 SECONDS

/datum/crafting_recipe/blood_brother/bonded_agent_id
	name = "Bonded Agent ID"
	desc = "An agent ID with a subspace ansible jammed into it allowing it be linked with other bonded agent id cards and share access, so only one of you has to rob the HoP. Just don't lose yours."
	category = CAT_BB_GADGETS
	result = /obj/item/card/id/advanced/chameleon/bonded
	reqs = list(
		/obj/item/card/id = 1,
		/obj/item/stock_parts/subspace/ansible = 1,
		/obj/item/stack/cable_coil = 5,
	)
	tool_behaviors = list(
		TOOL_MULTITOOL,
		TOOL_WIRECUTTER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/makeshift_door_remote
	name = "Makeshift Door Remote"
	desc = "A door remote that opens every door on the station and can electrify them for 30 seconds. The battery can't be recharged, so when it's dead, you'll need a new one."
	category = CAT_BB_GADGETS
	result = /obj/item/door_remote/makeshift
	reqs = list(
		/obj/item/electronics/airlock = 1,
		/obj/item/assembly/signaler = 1,
		/obj/item/stock_parts/power_store/cell = 1,
		/obj/item/stack/cable_coil = 10,
	)
	tool_behaviors = list(
		TOOL_MULTITOOL,
		TOOL_SCREWDRIVER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/scrapper_gloves
	name = "Scrapper Gloves"
	desc = "You are both a scrapper (crafting things) and a scrapper (fighting) If you land a combo with these on, your fellow blood brother(s) can land any melee attack on the target and trigger a WOMBO COMBO!!."
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/gloves/scrapper
	reqs = list(
		/obj/item/clothing/gloves/color/yellow = 1,
		/obj/item/stack/sheet/plasteel = 3,
		/obj/item/stack/sheet/leather = 5,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_WIRECUTTER,
	)
	time = 15 SECONDS

/datum/crafting_recipe/blood_brother/sunglasses
	name = "Sunglasses"
	desc = "Point a welder at some glass until it's polarized. That's not how polarizing works, but you look cool now, so who's going to argue?"
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/glasses/sunglasses
	reqs = list(
		/obj/item/stack/sheet/glass = 2,
		/obj/item/stack/sheet/iron = 1,
	)
	tool_behaviors = list(
		TOOL_WELDER,
	)
	time = 3 SECONDS

/// Made like HUD sunglasses, but with a night vision HUD. Has no result, so only the subtypes show up.
/datum/crafting_recipe/blood_brother/nv_shades
	category = CAT_BB_ARMOR
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WIRECUTTER,
	)
	time = 2 SECONDS

/datum/crafting_recipe/blood_brother/nv_shades/plain
	name = "Night Vision Shades"
	desc = "Wire night vision goggles into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/night/shades
	reqs = list(
		/obj/item/clothing/glasses/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/nv_shades/meson
	name = "Night Vision Meson Shades"
	desc = "Wire night vision mesons into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/meson/night/shades
	reqs = list(
		/obj/item/clothing/glasses/meson/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/nv_shades/diagnostic
	name = "Night Vision Diagnostic Shades"
	desc = "Wire a night vision diagnostic HUD into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/hud/diagnostic/night/shades
	reqs = list(
		/obj/item/clothing/glasses/hud/diagnostic/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/nv_shades/security
	name = "Night Vision Security Shades"
	desc = "Wire a night vision security HUD into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/hud/security/night/shades
	reqs = list(
		/obj/item/clothing/glasses/hud/security/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/nv_shades/medical
	name = "Night Vision Medical Shades"
	desc = "Wire a night vision medical HUD into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/hud/health/night/shades
	reqs = list(
		/obj/item/clothing/glasses/hud/health/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/nv_shades/science
	name = "Night Vision Science Shades"
	desc = "Wire night vision science goggles into a pair of sunglasses. You can see in the dark, and welding won't blind you either."
	result = /obj/item/clothing/glasses/science/night/shades
	reqs = list(
		/obj/item/clothing/glasses/science/night = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/blood_brother/thermals
	name = "Thermal Goggles"
	desc = "Now you can see through walls! Sadly it won't have the eye protection of night vision sunglasses, so don't charge into fights with security or you'll get flashbanged."
	category = CAT_BB_GADGETS
	result = /obj/item/clothing/glasses/thermal
	reqs = list(
		/obj/item/clothing/glasses/night = 1,
		/obj/item/assembly/infra = 1,
		/obj/item/stock_parts/scanning_module/adv = 1,
		/obj/item/stack/cable_coil = 10,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WIRECUTTER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/scrap_revolver
	name = "Scrap Revolver"
	desc = "A crude revolver built around a matter bin cylinder that can be modified to accept either .38 or 12 gauge rounds."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/ballistic/revolver/scrap
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

/datum/crafting_recipe/blood_brother/mares_leg
	name = "Sawn off Lever Action Rifle"
	desc = "A trimmed down lever action rifle with a scope. Actually it's a lie because the lever works itself after every shot automatically, making this a semi auto. Why does the lever exist?."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/ballistic/mares_leg
	reqs = list(
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/plasteel = 3,
		/obj/item/stack/sticky_tape = 1,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_SCREWDRIVER,
	)
	time = 6 SECONDS

/datum/crafting_recipe/blood_brother/glockenspiel
	name = "GLOCK-inspiel"
	desc = "Combine a glock with a glockenspiel and you get this abomination. It even has a switch to toggle full auto like a real glock!."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/ballistic/automatic/pistol/glockenspiel
	reqs = list(
		/obj/item/instrument/glockenspiel = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/plastic = 10,
		/obj/item/stack/sticky_tape = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
	)

/datum/crafting_recipe/blood_brother/rapid_combat_device
	name = "Rapid Combat Device"
	desc = "Modify a rapid construction device into a weapon. It can fire balls of metal, breaching blasts that tear through structures, or erect temporary barriers on the fly. Sadly it's unorothdox construction prevents it from using gun parts nor standard RCD upgrades."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/energy/rapid_combat_device
	reqs = list(
		/obj/item/construction/rcd = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/stack/cable_coil = 10,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
		TOOL_MULTITOOL,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/hardlight_laser_cannon
	name = "Hardlight Laser Cannon"
	desc = "A crude laser cannon that fires beams of hardlight so dense they're stopped by glass and grilles."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/energy/laser/hardlight
	reqs = list(
		/obj/item/gun/energy/laser/explorer = 1,
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/power_store/cell = 1,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 2,
	)

/datum/crafting_recipe/blood_brother/scrap_akm
	name = "Scrap AKM"
	desc = "AK-47s for everyone! (Ignore the fact that it's an AKM and not an ak-47) Also comes with no magazine when crafted."
	category = CAT_BB_WEAPONS
	result = /obj/item/gun/ballistic/automatic/scrap_akm
	reqs = list(
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/pipe = 2,
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/stack/sheet/mineral/wood = 5,
		/obj/item/stack/sticky_tape = 1,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_WRENCH,
		TOOL_SCREWDRIVER,
	)
	time = 15 SECONDS

/datum/crafting_recipe/blood_brother/ned_kelly_armor
	name = "Ned Kelly Armor"
	desc = "Heavy plate over your chest, groin and arms. Wear it with the Ned Kelly helmet and nothing can stun you. Nothing covers the legs just like the real thing!"
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
	desc = "A heavy iron bucket that covers your whole face. Wear it with the Ned Kelly armor and nothing can stun you."
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

/datum/crafting_recipe/blood_brother/patchwork_duster
	name = "Patchwork Armored Duster"
	desc = "A tough leather coat with scrap plating sewn into it and a hidden holster for a gun."
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/suit/armor/patchwork_duster
	reqs = list(
		/obj/item/stack/sheet/iron = 10,
		/obj/item/stack/sheet/cloth = 5,
		/obj/item/stack/sheet/leather = 5,
	)
	tool_behaviors = list(
		TOOL_WELDER,
		TOOL_WIRECUTTER,
	)
	time = 15 SECONDS

/datum/crafting_recipe/blood_brother/patchwork_hat
	name = "Patchwork Cowboy Hat"
	desc = "10% chance a shot goes through the brim instead of your head. Fold it into a flatcap if cowboy hats aren't your style."
	category = CAT_BB_ARMOR
	result = /obj/item/clothing/head/patchwork_hat
	reqs = list(
		/obj/item/stack/sheet/iron = 2,
		/obj/item/stack/sheet/cloth = 2,
		/obj/item/stack/sheet/leather = 2,
	)
	tool_behaviors = list(
		TOOL_WIRECUTTER,
	)
	time = 5 SECONDS

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

/datum/crafting_recipe/blood_brother/empty_9mm_magazine
	name = "Empty 9mm Magazine"
	desc = "Iron bent into the shape of a 9mm magazine. Use a hacked autolathe to get bullets."
	category = CAT_BB_AMMUNITION
	result = /obj/item/ammo_box/magazine/m9mm/empty
	reqs = list(
		/obj/item/stack/sheet/iron = 4,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)
	time = 5 SECONDS

/datum/crafting_recipe/blood_brother/akm_magazine
	name = "AKM Magazine"
	desc = "Iron bent into a curved magazine, and welding fuel packed into enough homemade rounds to fill it. Comes loaded with 30 rounds."
	category = CAT_BB_AMMUNITION
	result = /obj/item/ammo_box/magazine/akm
	reqs = list(
		/obj/item/stack/sheet/iron = 10,
		/datum/reagent/fuel = 30,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/a762x39_box
	name = "7.62x39 Ammo Box"
	desc = "A cardboard box of 60 loose scrap rounds for refilling your AKM magazines."
	category = CAT_BB_AMMUNITION
	result = /obj/item/ammo_box/a762x39
	reqs = list(
		/obj/item/stack/sheet/iron = 16,
		/datum/reagent/fuel = 50,
		/obj/item/stack/sheet/cardboard = 1,
	)
	time = 15 SECONDS

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
	desc = "Pack a regular .38 speedloader's rounds with welding fuel to set your foes on fire."
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
	desc = "Pack a regular .38 speedloader's rounds with cryostylane to slow your enemies down or prevent them from running away as easily."
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
	desc = "Notch the tips of a regular .38 speedloader's rounds so they mushroom on impact, inflicting horrible bleeding."
	result = /obj/item/ammo_box/c38/dumdum
	reqs = list(
		/obj/item/ammo_box/c38 = 1,
	)
	tool_behaviors = list(
		TOOL_WIRECUTTER,
	)

/datum/crafting_recipe/blood_brother/bond_beacon
	name = "Bond Beacon"
	desc = "A tiny tracking chip that lets your brothers locate you wherever you are for the rest of the shift. Use it in your hand to switch it on."
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

/datum/crafting_recipe/blood_brother/bluespace_courier_implant
	name = "Bluespace Courier Implant"
	desc = "Use it in hand to link your blood bond to bluespace, letting you teleport anything you're holding to your brothers. Ditch contraband before security finds it, or send your brother a gun in permabrig."
	category = CAT_BB_SUPPORT
	result = /obj/item/bluespace_courier_implant
	reqs = list(
		/obj/item/stack/ore/bluespace_crystal = 1,
		/obj/item/stock_parts/subspace/ansible = 1,
		/obj/item/stack/cable_coil = 10,
	)
	tool_behaviors = list(
		TOOL_MULTITOOL,
	)
	time = 10 SECONDS

/datum/crafting_recipe/blood_brother/flash
	name = "Spare flash"
	desc = "Every recruitment attempt burns out your flash, even if they turn you down. If you run out, you can build more with this recipe. Or just print one at an exosuit fabricator, that works too."
	category = CAT_BB_SUPPORT
	result = /obj/item/assembly/flash/handheld
	reqs = list(
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/stack/cable_coil = 2,
		/obj/item/light/bulb = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
	)

/datum/crafting_recipe/blood_brother/donk_pocket_juicer
	name = "Donk Pocket Juicer"
	desc = "You're not sure how blasting food with uranium gives it healing properties, but this lunchbox microwave hybrid can do that to Donk-pockets. Uses uranium sheets as fuel."
	category = CAT_BB_SUPPORT
	result = /obj/item/donk_pocket_juicer
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/rods = 1,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/micro_laser = 1,
	)
	tool_behaviors = list(
		TOOL_SCREWDRIVER,
		TOOL_WIRECUTTER,
	)
	time = 8 SECONDS
