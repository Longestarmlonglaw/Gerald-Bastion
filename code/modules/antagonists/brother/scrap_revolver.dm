/**
 * Scrap revolver for Blood Brothers.
 *
 * Its improvised cylinder can be configured between .38 and 12 gauge ammunition.
 */

/// How many .38 rounds the scrap revolver's cylinder holds, before any magazine part.
#define SCRAP_REVOLVER_38_CAPACITY 6
/// In shotgun mode, the cylinder holds this fraction of its .38 capacity, magazine part included.
#define SCRAP_REVOLVER_SHOTGUN_CAPACITY_MULTIPLIER 0.5

/obj/item/ammo_box/magazine/internal/cylinder/scrap
	name = "scrap revolver cylinder"
	ammo_type = /obj/item/ammo_casing/c38
	caliber = CALIBER_38
	max_ammo = SCRAP_REVOLVER_38_CAPACITY
	start_empty = TRUE

	/// Whether the cylinder is set up for 12 gauge shells instead of .38 rounds. Switched with a wrench.
	var/shotgun_mode = FALSE

/obj/item/ammo_box/magazine/internal/cylinder/scrap/Initialize(mapload)
	. = ..()
	// Cylinders need one slot per chamber so the cylinder-specific give_round()
	// proc has empty chambers to place ammunition into.
	stored_ammo = list()
	for(var/i in 1 to max_ammo)
		stored_ammo += null

/obj/item/gun/ballistic/revolver/scrap
	name = "scrap revolver"
	desc = "A crude revolver cobbled together from whatever parts were available. Its matter-bin cylinder can be configured for .38 rounds or 12 gauge shells."
	icon_state = "revolver_scrap_c38"
	base_icon_state = "revolver_scrap_c38"
	inhand_icon_state = "gun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder/scrap
	fire_sound = 'sound/weapons/gun/revolver/shot.ogg'
	w_class = WEIGHT_CLASS_SMALL
	pinless = TRUE
	spawnwithmagazine = TRUE

/obj/item/gun/ballistic/revolver/scrap/examine(mob/user)
	. = ..()
	var/obj/item/ammo_box/magazine/internal/cylinder/scrap/cylinder = magazine
	if(cylinder?.shotgun_mode)
		. += span_notice("The cylinder is configured for 12 gauge shotgun shells. It holds up to [cylinder.max_ammo] shells.")
	else if(cylinder)
		. += span_notice("The cylinder is configured for .38 rounds. It holds up to [cylinder.max_ammo] rounds.")
	. += span_warning("Do not wrench the cylinder while live ammunition is loaded.")

/// Wrenching the revolver switches its cylinder between .38 and 12 gauge. It has to be unloaded first, or a round goes off.
/obj/item/gun/ballistic/revolver/scrap/wrench_act(mob/living/user, obj/item/I)
	if(!user.is_holding(src))
		balloon_alert(user, "hold to modify!")
		return TRUE

	// Wrenching the cylinder with live rounds loaded sets one off.
	if(get_ammo(FALSE, FALSE))
		if(!chambered)
			chamber_round()
		if(blow_up(user))
			user.visible_message(
				span_danger("[src] goes off in [user]'s face!"),
				span_userdanger("[src] goes off in your face!"),
			)
		return TRUE

	var/obj/item/ammo_box/magazine/internal/cylinder/scrap/cylinder = magazine
	if(!cylinder)
		return TRUE

	balloon_alert(user, "reconfiguring...")
	I.play_tool_sound(src)
	if(!I.use_tool(src, user, 3 SECONDS))
		return TRUE

	var/new_capacity_multiplier
	cylinder.shotgun_mode = !cylinder.shotgun_mode
	if(cylinder.shotgun_mode)
		cylinder.ammo_type = /obj/item/ammo_casing/shotgun
		cylinder.caliber = CALIBER_SHOTGUN
		new_capacity_multiplier = SCRAP_REVOLVER_SHOTGUN_CAPACITY_MULTIPLIER
		base_icon_state = "revolver_scrap_shotgun"
		fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
		to_chat(user, span_notice("You reconfigure [src]'s cylinder for 12 gauge shotgun shells."))
	else
		cylinder.ammo_type = /obj/item/ammo_casing/c38
		cylinder.caliber = CALIBER_38
		new_capacity_multiplier = 1
		base_icon_state = "revolver_scrap_c38"
		fire_sound = 'sound/weapons/gun/revolver/shot.ogg'
		to_chat(user, span_notice("You reconfigure [src]'s cylinder for .38 rounds."))

	// A mode switch is only possible with no live rounds, so anything left in the cylinder
	// is a spent casing of the old caliber. Dump them all, then resize the cylinder for the new caliber.
	var/list/spent_casings = cylinder.ammo_list()
	cylinder.stored_ammo = list()
	for(var/obj/item/ammo_casing/spent_casing as anything in spent_casings)
		spent_casing.forceMove(drop_location())
	// The gun component works out the new capacity, including any magazine part's extra rounds.
	var/datum/component/blood_brother_gun/modular_gun = GetComponent(/datum/component/blood_brother_gun)
	modular_gun.set_capacity_multiplier(new_capacity_multiplier)
	update_appearance()

/obj/item/gun/ballistic/revolver/scrap/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/blood_brother_gun, \
		weapon_family = BB_GUN_BALLISTIC, \
		part_slots = list(BB_GUN_PART_MAGAZINE, BB_GUN_PART_RECEIVER, BB_GUN_PART_BARREL, BB_GUN_PART_UNDERBARREL), \
		default_parts = list(/obj/item/blood_brother_gun_part/receiver/semi_auto), \
	)

#undef SCRAP_REVOLVER_38_CAPACITY
#undef SCRAP_REVOLVER_SHOTGUN_CAPACITY_MULTIPLIER
