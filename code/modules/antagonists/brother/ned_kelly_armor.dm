/**
 * Ned Kelly armor set for Blood Brothers.
 *
 * Heavy plate armor covering the chest, groin and arms, and a helmet covering the face.
 * Wearing both together makes the wearer immune to stuns.
 */

#define NED_KELLY_SET_TRAIT "ned_kelly_set"

/datum/armor/ned_kelly
	melee = 60
	bullet = 70
	laser = 40
	energy = 40
	bomb = 50
	fire = 50
	acid = 50
	wound = 30

/obj/item/clothing/suit/armor/ned_kelly
	name = "Ned Kelly armor"
	desc = "Crude plate armor hammered together from scrap metal. It weighs a ton, but very little gets through it. It's missing any protection for the legs."
	icon_state = "armor_nedkelly"
	worn_icon = 'icons/mob/clothing/suit.dmi'
	worn_icon_state = "armor_nedkelly"
	inhand_icon_state = "armor_nedkelly"
	w_class = WEIGHT_CLASS_BULKY
	body_parts_covered = CHEST|GROIN|ARMS
	slowdown = 1.5
	armor_type = /datum/armor/ned_kelly

/obj/item/clothing/suit/armor/ned_kelly/equipped(mob/living/user, slot)
	. = ..()
	update_ned_kelly_set(user)

/obj/item/clothing/suit/armor/ned_kelly/dropped(mob/living/user)
	. = ..()
	update_ned_kelly_set(user, removed = src)

/obj/item/clothing/head/helmet/ned_kelly
	name = "Ned Kelly helmet"
	desc = "A heavy iron bucket with a slit cut out for the eyes. It covers the wearer's whole face."
	icon_state = "helmet_nedkelly"
	base_icon_state = "helmet_nedkelly"
	worn_icon = 'icons/mob/clothing/head.dmi'
	worn_icon_state = "helmet_nedkelly"
	inhand_icon_state = "helmet_nedkelly"
	flags_cover = HEADCOVERSEYES|HEADCOVERSMOUTH
	flags_inv = HIDEHAIR|HIDEEARS|HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
	slowdown = 0.5
	armor_type = /datum/armor/ned_kelly
	dog_fashion = null

/obj/item/clothing/head/helmet/ned_kelly/equipped(mob/living/user, slot)
	. = ..()
	update_ned_kelly_set(user)

/obj/item/clothing/head/helmet/ned_kelly/dropped(mob/living/user)
	. = ..()
	update_ned_kelly_set(user, removed = src)

/**
 * Grants stun immunity while the full Ned Kelly set is worn, and removes it otherwise.
 *
 * Arguments:
 * * wearer - The mob to check.
 * * removed - An item being taken off, which shouldn't count even if it hasn't left its slot yet.
 */
/proc/update_ned_kelly_set(mob/living/carbon/human/wearer, obj/item/removed)
	if(!istype(wearer))
		return
	var/wearing_armor = istype(wearer.wear_suit, /obj/item/clothing/suit/armor/ned_kelly) && wearer.wear_suit != removed
	var/wearing_helmet = istype(wearer.head, /obj/item/clothing/head/helmet/ned_kelly) && wearer.head != removed
	if(wearing_armor && wearing_helmet)
		if(!HAS_TRAIT_FROM(wearer, TRAIT_STUNIMMUNE, NED_KELLY_SET_TRAIT))
			ADD_TRAIT(wearer, TRAIT_STUNIMMUNE, NED_KELLY_SET_TRAIT)
			to_chat(wearer, span_notice("With the full set of plate on, you feel like nothing could knock you down."))
	else if(HAS_TRAIT_FROM(wearer, TRAIT_STUNIMMUNE, NED_KELLY_SET_TRAIT))
		REMOVE_TRAIT(wearer, TRAIT_STUNIMMUNE, NED_KELLY_SET_TRAIT)
		to_chat(wearer, span_warning("Without the full set of plate, you no longer feel unstoppable."))

#undef NED_KELLY_SET_TRAIT
