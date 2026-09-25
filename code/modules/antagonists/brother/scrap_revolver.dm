/**
 * Scrap revolver for Blood Brothers.
 *
 * Uses the regular .38 revolver sprites as a placeholder.
 * Its improvised cylinder can be configured between .38 and 12 gauge ammunition.
 */

/obj/item/ammo_box/magazine/internal/cylinder/blood_brother_scrap
	name = "scrap revolver cylinder"
	ammo_type = /obj/item/ammo_casing/c38
	caliber = CALIBER_38
	max_ammo = 6
	start_empty = TRUE
	multiload = FALSE

	var/shotgun_mode = FALSE

/obj/item/ammo_box/magazine/internal/cylinder/blood_brother_scrap/Initialize(mapload)
	. = ..()
	// Cylinders need one slot per chamber so the cylinder-specific give_round()
	// proc has empty chambers to place ammunition into.
	stored_ammo = list()
	for(var/i in 1 to max_ammo)
		stored_ammo += null

/obj/item/gun/ballistic/revolver/blood_brother_scrap
	name = "scrap revolver"
	desc = "A crude revolver cobbled together from whatever parts were available. Its matter-bin cylinder can be configured for .38 rounds or 12 gauge shells."
	icon_state = "c38"
	inhand_icon_state = "gun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder/blood_brother_scrap
	fire_sound = 'sound/weapons/gun/revolver/shot.ogg'
	w_class = WEIGHT_CLASS_SMALL
	pinless = TRUE
	spawnwithmagazine = TRUE

/obj/item/gun/ballistic/revolver/blood_brother_scrap/examine(mob/user)
	. = ..()
	var/obj/item/ammo_box/magazine/internal/cylinder/blood_brother_scrap/cylinder = magazine
	if(cylinder?.shotgun_mode)
		. += span_notice("The cylinder is configured for 12 gauge shotgun shells. It holds up to 3 shells.")
	else
		. += span_notice("The cylinder is configured for .38 rounds. It holds up to 6 rounds.")
	. += span_warning("Do not wrench the cylinder while live ammunition is loaded.")

/obj/item/gun/ballistic/revolver/blood_brother_scrap/wrench_act(mob/living/user, obj/item/I)
	if(!user.is_holding(src))
		balloon_alert(user, "hold to modify!")
		return TRUE

	// Unlike the normal ammo-modification mechanic, a loaded scrap revolver
	// catastrophically discharges when someone tries to wrench it.
	if(get_ammo(FALSE, FALSE))
		if(!chambered)
			chamber_round()
		if(blow_up(user))
			user.visible_message(
				span_danger("[src] goes off in [user]'s face!"),
				span_userdanger("[src] goes off in your face!"),
			)
		return TRUE

	var/obj/item/ammo_box/magazine/internal/cylinder/blood_brother_scrap/cylinder = magazine
	if(!cylinder)
		return TRUE

	balloon_alert(user, "reconfiguring...")
	I.play_tool_sound(src)
	if(!I.use_tool(src, user, 3 SECONDS))
		return TRUE

	cylinder.shotgun_mode = !cylinder.shotgun_mode
	if(cylinder.shotgun_mode)
		cylinder.ammo_type = /obj/item/ammo_casing/shotgun
		cylinder.caliber = CALIBER_SHOTGUN
		cylinder.max_ammo = 3
		fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
		to_chat(user, span_notice("You reconfigure [src]'s cylinder for 12 gauge shotgun shells."))
	else
		cylinder.ammo_type = /obj/item/ammo_casing/c38
		cylinder.caliber = CALIBER_38
		cylinder.max_ammo = 6
		fire_sound = 'sound/weapons/gun/revolver/shot.ogg'
		to_chat(user, span_notice("You reconfigure [src]'s cylinder for .38 rounds."))

	// A mode switch is only possible with no live rounds. Keep the cylinder's
	// chamber slots in sync with its current capacity and dump excess casings.
	while(cylinder.stored_ammo.len > cylinder.max_ammo)
		var/obj/item/ammo_casing/excess_casing = cylinder.stored_ammo[cylinder.stored_ammo.len]
		cylinder.stored_ammo.len--
		if(excess_casing)
			excess_casing.forceMove(drop_location())
	while(cylinder.stored_ammo.len < cylinder.max_ammo)
		cylinder.stored_ammo += null
	cylinder.update_appearance()
	update_appearance()
