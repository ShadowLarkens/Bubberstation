/mob
	var/datum/vore_info/vore_info

/mob/Initialize(mapload)
	. = ..()
	init_vore()

/mob/proc/init_vore()
	//Something else made organs, meanwhile.
	if(LAZYLEN(vore_info?.vore_organs))
		return TRUE

	//We'll load our client's organs if we have one
	if(client && client.prefs_vr)
		if(!copy_from_prefs_vr())
			to_chat(src,"<span class='warning'>ERROR: You seem to have saved VOREStation prefs, but they couldn't be loaded.</span>")
			return FALSE
		if(LAZYLEN(vore_info?.vore_organs))
			vore_info.vore_selected = vore_info.vore_organs[1]
			return TRUE

	//Or, we can create a basic one for them
	if((!vore_info || !LAZYLEN(vore_info?.vore_organs)) && isliving(src))
		vore_info = new()
		LAZYINITLIST(vore_info?.vore_organs)
		var/obj/belly/B = new /obj/belly(src)
		vore_info.vore_selected = B
		B.immutable = TRUE
		B.name = "Stomach"
		B.desc = "It appears to be rather warm and wet. Makes sense, considering it's inside \the [name]."
		B.can_taste = TRUE
		// TODO: TF
		// if(ishuman(src))
		// 	var/mob/living/carbon/human/H = src
		// 	if(istype(H.species,/datum/species/monkey))
		// 		allow_spontaneous_tf = TRUE
		return TRUE

/mob/proc/update_fullness()
	// TODO: belly sprites

//
// Release everything in every vore organ
//
/mob/living/proc/release_vore_contents(var/include_absorbed = TRUE, var/silent = FALSE)
	for(var/obj/belly/B as anything in vore_info.vore_organs)
		B.release_all_contents(include_absorbed, silent)
