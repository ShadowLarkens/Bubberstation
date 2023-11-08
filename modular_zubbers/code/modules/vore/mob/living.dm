/mob/living/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/vore)

/mob/living/proc/feedable_bellies()
	var/list/bellies = list()
	for(var/obj/belly/Y in vore_info?.vore_organs)
		if(Y.is_feedable)
			bellies += Y
	return bellies

//
// OOC Escape code for pref-breaking or AFK preds
//
/mob/living/proc/escapeOOC()
	set name = "OOC Escape"
	set category = "OOC"

	//You're in a belly!
	if(isbelly(loc))
		//You've been taken over by a morph
		// if(istype(src, /mob/living/simple_mob/vore/morph/dominated_prey))
		// 	var/mob/living/simple_mob/vore/morph/dominated_prey/s = src
		// 	s.undo_prey_takeover(TRUE)
		// 	return
		var/obj/belly/B = loc
		var/confirm = tgui_alert(src, "Please feel free to press use this button at any time you are uncomfortable and in a belly. Consent is important.", "Confirmation", list("Okay", "Cancel"))
		if(confirm != "Okay" || loc != B)
			return
		//Actual escaping
		vore_info?.absorbed = FALSE	//Make sure we're not absorbed
		// vore_info?.muffled = FALSE		//Removes Muffling
		forceMove(get_turf(src)) //Just move me up to the turf, let's not cascade through bellies, there's been a problem, let's just leave.
		// TODO: simple mob vore
		// for(var/mob/living/simple_mob/SA in range(10))
		// 	LAZYSET(SA.prey_excludes, src, world.time)
		log_admin("[key_name(src)] used the OOC escape button to get out of [key_name(B.owner)] ([B.owner ? "<a href='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[B.owner.x];Y=[B.owner.y];Z=[B.owner.z]'>JMP</a>" : "null"])")
		message_admins("[key_name_admin(src)] used the OOC escape button to get out of [key_name(B.owner)] ([B.owner ? "<a href='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[B.owner.x];Y=[B.owner.y];Z=[B.owner.z]'>JMP</a>" : "null"])")

		B.owner.update_fullness()
		if(!ishuman(B.owner))
			B.owner.update_icons()

	//You're in a dogborg!
	// else if(istype(loc, /obj/item/device/dogborg/sleeper))
	// 	var/mob/living/silicon/pred = loc.loc //Thing holding the belly!
	// 	var/obj/item/device/dogborg/sleeper/belly = loc //The belly!

	// 	var/confirm = tgui_alert(src, "You're in a cyborg sleeper. This is for escaping from preference-breaking or if your predator disconnects/AFKs. If your preferences were being broken, please admin-help as well.", "Confirmation", list("Okay", "Cancel"))
	// 	if(confirm != "Okay" || loc != belly)
	// 		return
	// 	//Actual escaping
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to get out of [key_name(pred)] (BORG) ([pred ? "<a href='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[pred.x];Y=[pred.y];Z=[pred.z]'>JMP</a>" : "null"])")
	// 	belly.go_out(src) //Just force-ejects from the borg as if they'd clicked the eject button.

	//You're in an AI hologram!
	// else if(istype(loc, /obj/effect/overlay/aiholo))
	// 	var/obj/effect/overlay/aiholo/holo = loc
	// 	holo.drop_prey() //Easiest way
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to get out of [key_name(holo.master)] (AI HOLO) ([holo ? "<a href='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[holo.x];Y=[holo.y];Z=[holo.z]'>JMP</a>" : "null"])")

	//You're in a capture crystal! ((It's not vore but close enough!))
	// else if(iscapturecrystal(loc))
	// 	var/obj/item/capture_crystal/crystal = loc
	// 	crystal.unleash()
	// 	crystal.bound_mob = null
	// 	crystal.bound_mob = capture_crystal = 0
	// 	clear_fullscreen(ATOM_BELLY_FULLSCREEN) // CHOMPedit
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to get out of [crystal] owned by [crystal.owner]. [ADMIN_FLW(src)]")

	//You've been turned into an item!
	// else if(tf_mob_holder && istype(src, /mob/living/voice) && istype(src.loc, /obj/item))
	// 	var/obj/item/item_to_destroy = src.loc //If so, let's destroy the item they just TF'd out of.
	// 	if(istype(src.loc, /obj/item/clothing)) //Are they in clothes? Delete the item then revert them.
	// 		qdel(item_to_destroy)
	// 		log_and_message_admins("[key_name(src)] used the OOC escape button to revert back to their original form from being TFed into an object.")
	// 		revert_mob_tf()
	// 	else //Are they in any other type of object? If qdel is done first, the mob is deleted from the world.
	// 		forceMove(get_turf(src))
	// 		qdel(item_to_destroy)
	// 		log_and_message_admins("[key_name(src)] used the OOC escape button to revert back to their original form from being TFed into an object.")
	// 		revert_mob_tf()

	//You've been turned into a mob!
	// else if(tf_mob_holder)
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to revert back to their original form from being TFed into another mob.")
	// 	revert_mob_tf()
	//CHOMPEdit - petrification (again not vore but hey- ooc escape)
	// else if(istype(loc, /obj/structure/gargoyle) && loc:was_rayed)
	// 	var/obj/structure/gargoyle/G = loc
	// 	G.can_revert = TRUE
	// 	qdel(G)
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to revert back from being petrified.")
	//CHOMPEdit - In-shoe OOC escape. Checking voices as precaution if something akin to obj TF or possession happens
	// else if(!istype(src, /mob/living/voice) && istype(src.loc, /obj/item/clothing/shoes))
	// 	var/obj/item/clothing/shoes/S = src.loc
	// 	forceMove(get_turf(src))
	// 	log_and_message_admins("[key_name(src)] used the OOC escape button to escape from of a pair of shoes. [ADMIN_FLW(src)] - Shoes [ADMIN_VV(S)]")
	//Don't appear to be in a vore situation
	else
		to_chat(src,"<span class='alert'>You aren't inside anyone, though, is the thing.</span>")

// TODO: species nutrition modifiers
/mob/living/proc/get_digestion_nutrition_modifier()
	return 1

/mob/living/proc/get_digestion_efficiency_modifier()
	return 1
