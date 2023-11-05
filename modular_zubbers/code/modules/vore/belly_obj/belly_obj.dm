/obj/belly/Initialize()
	. = ..()
	// If not, we're probably just in a prefs list or something.
	if(isliving(loc))
		owner = loc
		owner.vore_info?.vore_organs |= src
		if(speedy_mob_processing)
			START_PROCESSING(SSobj, src)
		else
			START_PROCESSING(SSbellies, src)

	// So we can have some liquids in bellies
	// We dont want bellies to start bubling nonstop due to people mixing when transfering and making different reagents
	create_reagents(300, NO_REACT)	

/obj/belly/Destroy()
	if(speedy_mob_processing)
		STOP_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSbellies, src)
	owner?.vore_info?.vore_organs?.Remove(src)
	owner = null
	// Note: ghosts are allowed to go in bellies to enjoy descriptions
	for(var/mob/dead/observer/G in src)
		G.forceMove(get_turf(src))
	return ..()

// Called whenever an atom enters this belly
/obj/belly/Entered(atom/movable/thing, atom/OldLoc)
	. = ..()
	if(!owner)
		thing.forceMove(get_turf(src))
		return
	SEND_SIGNAL(thing, COMSIG_ENTER_BELLY, src)
	try_play_slosh()
	if(isobserver(thing)) //Silence, spook.
		if(desc)
			//Allow ghosts see where they are if they're still getting squished along inside.
			var/formatted_desc
			formatted_desc = replacetext(desc, "%belly", lowertext(name)) //replace with this belly's name
			formatted_desc = replacetext(formatted_desc, "%pred", owner) //replace with this belly's owner
			formatted_desc = replacetext(formatted_desc, "%prey", thing) //replace with whatever mob entered into this belly
			to_chat(thing, "<span class='notice'><B>[formatted_desc]</B></span>")
		return
	if(OldLoc in contents)
		return //Someone dropping something (or being stripdigested)
	if(isobserver(OldLoc) || istype(OldLoc, /obj/item/mmi)) // Prevent reforming causing a lot of log spam/sounds
		return //Someone getting reformed most likely (And if not, uh... shouldn't happen anyways?)
	
	//Generic entered message
	if(!owner.vore_info.mute_entry && entrance_logs) //CHOMPEdit
		to_chat(owner,"<span class='notice'>[thing] slides into your [lowertext(name)].</span>")

	try_play_entry_sound()

	if(reagents.total_volume >= 5 && !isliving(thing) && (item_digest_mode == IM_DIGEST || item_digest_mode == IM_DIGEST_PARALLEL))
		reagents.trans_to(thing, reagents.total_volume * 0.1, 1 / max(LAZYLEN(contents), 1), FALSE)

	//Messages if it's a mob
	if(isliving(thing))
		living_entered(thing)

	// This is run whenever a belly's contents are changed.
	owner.update_fullness()

/obj/belly/proc/try_play_slosh()
	// TODO: base_vorefootstep_sounds

/obj/belly/proc/try_play_entry_sound()
	// TODO: Sound
	//Sound w/ antispam flag setting
	if(vore_sound && !recent_sound)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_vore_sounds[vore_sound]
		else
			soundfile = fancy_vore_sounds[vore_sound]
		if(special_entrance_sound) //CHOMPEdit: Custom sound set by mob's init_vore or ingame varedits.
			soundfile = special_entrance_sound
		if(soundfile)
			playsound_with_pref(src, soundfile, vol = sound_volume, vary = 1, falloff_exponent = VORE_SOUND_FALLOFF, frequency = noise_freq, preference = /datum/preference/toggle/vore_eating_sounds)
			recent_sound = TRUE

/obj/belly/proc/living_entered(mob/living/M)
	// TODO: VRPanel
	// M.updateVRPanel()
	var/raw_desc //Let's use this to avoid needing to write the reformat code twice
	if(absorbed_desc && M.vore_info.absorbed)
		raw_desc = absorbed_desc
	else if(desc)
		raw_desc = desc

	//Was there a description text? If so, it's time to format it!
	if(raw_desc)
		//Replace placeholder vars
		var/formatted_desc
		formatted_desc = replacetext(raw_desc, "%belly", lowertext(name)) //replace with this belly's name
		formatted_desc = replacetext(formatted_desc, "%pred", owner) //replace with this belly's owner
		formatted_desc = replacetext(formatted_desc, "%prey", M) //replace with whatever mob entered into this belly
		to_chat(M, "<span class='notice'><B>[formatted_desc]</B></span>")

	// TODO: Taste
	// var/taste = M.get_taste_message(FALSE)
	// if(can_taste && taste)
	// 	to_chat(owner, "<span class='notice'>[M] tastes of [taste].</span>")
	// TODO: vore_fx
	// vore_fx(M, TRUE)
	// if(owner.previewing_belly == src)
	// 	vore_fx(owner, TRUE)
	
	//Stop AI processing in bellies
	if(isanimal(M))
		var/mob/living/simple_animal/S = M
		S.toggle_ai(AI_OFF)
	
	if(reagents.total_volume >= 5 && M.vore_info.digestable)
		if(digest_mode == DM_DIGEST)
			reagents.trans_to(M, reagents.total_volume * 0.1, 1 / max(LAZYLEN(contents), 1), FALSE)
		to_chat(M, "<span class='warning'><B>You splash into a pool of [reagent_name]!</B></span>")

// Called whenever an atom leaves this belly
/obj/belly/Exited(atom/movable/thing, atom/OldLoc)
	. = ..()
	SEND_SIGNAL(thing, COMSIG_EXIT_BELLY, src)
	if(isbelly(thing.loc))
		var/obj/belly/B = thing.loc
		B.owner.update_fullness()
		return
	
	if(isliving(thing))
		var/mob/living/L = thing
		L.clear_fullscreen("belly")
		if(L.hud_used)
			if(!L.hud_used.hud_shown)
				L.hud_used.show_hud(HUD_STYLE_STANDARD)
		//Stop AI processing in bellies
		if(isanimal(L))
			var/mob/living/simple_animal/S = L
			S.toggle_ai(AI_ON)

	// TODO: item gurgling
	// if(isitem(thing))
		// var/obj/item/I = thing
		// if(I.gurgled)

	owner.update_fullness()

// Actually perform the mechanics of devouring the tasty prey.
// The purpose of this method is to avoid duplicate code, and ensure that all necessary
// steps are taken.
/obj/belly/proc/nom_mob(mob/prey, mob/user)
	if(owner.stat == DEAD)
		return
	if(prey.buckled)
		prey.buckled.unbuckle_mob()

	prey.forceMove(src)
	if(ismob(prey))
		var/mob/ourmob = prey
		ourmob.reset_perspective(owner)
	// owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

	// for(var/mob/living/M in contents)
	// 	M.updateVRPanel()

	// if(prey.ckey)
		// GLOB.prey_eaten_roundstat++
		// if(owner.mind)
		// 	owner.mind.vore_prey_eaten++


// The next function gets the messages set on the belly, in human-readable format.
// This is useful in customization boxes and such. The delimiter right now is \n\n so
// in message boxes, this looks nice and is easily delimited.
/obj/belly/proc/get_messages(type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "asmo" || type == "asmi" || type == "dmo" || type == "dmp" || type == "amo" || type == "amp" || type == "uamo" || type == "uamp" || type == "em" || type == "ema" || type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")

	var/list/raw_messages
	switch(type)
		if("smo")
			raw_messages = struggle_messages_outside
		if("smi")
			raw_messages = struggle_messages_inside
		if("asmo")
			raw_messages = absorbed_struggle_messages_outside
		if("asmi")
			raw_messages = absorbed_struggle_messages_inside
		if("dmo")
			raw_messages = digest_messages_owner
		if("dmp")
			raw_messages = digest_messages_prey
		if("em")
			raw_messages = examine_messages
		if("ema")
			raw_messages = examine_messages_absorbed
		if("amo")
			raw_messages = absorb_messages_owner
		if("amp")
			raw_messages = absorb_messages_prey
		if("uamo")
			raw_messages = unabsorb_messages_owner
		if("uamp")
			raw_messages = unabsorb_messages_prey
		if("im_digest")
			raw_messages = emote_lists[DM_DIGEST]
		if("im_hold")
			raw_messages = emote_lists[DM_HOLD]
		if("im_holdabsorbed")
			raw_messages = emote_lists[DM_HOLD_ABSORBED]
		if("im_absorb")
			raw_messages = emote_lists[DM_ABSORB]
		if("im_heal")
			raw_messages = emote_lists[DM_HEAL]
		if("im_drain")
			raw_messages = emote_lists[DM_DRAIN]
		if("im_steal")
			raw_messages = emote_lists[DM_SIZE_STEAL]
		if("im_egg")
			raw_messages = emote_lists[DM_EGG]
		if("im_shrink")
			raw_messages = emote_lists[DM_SHRINK]
		if("im_grow")
			raw_messages = emote_lists[DM_GROW]
		if("im_unabsorb")
			raw_messages = emote_lists[DM_UNABSORB]
	var/messages = null
	if(raw_messages)
		messages = raw_messages.Join(delim)
	return messages

// The next function sets the messages on the belly, from human-readable var
// replacement strings and linebreaks as delimiters (two \n\n by default).
// They also sanitize the messages.
/obj/belly/proc/set_messages(raw_text, type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "asmo" || type == "asmi" || type == "dmo" || type == "dmp" || type == "amo" || type == "amp" || type == "uamo" || type == "uamp" || type == "em" || type == "ema" || type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")

	var/list/raw_list = splittext(html_encode(raw_text),delim)
	if(raw_list.len > 10)
		raw_list.Cut(11)
		warning("[owner] tried to set [lowertext(name)] with 11+ messages")

	for(var/i = 1, i <= raw_list.len, i++)
		if((length(raw_list[i]) > 160 || length(raw_list[i]) < 10) && !(type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb")) //160 is fudged value due to htmlencoding increasing the size
			raw_list.Cut(i,i)
			warning("[owner] tried to set [lowertext(name)] with >121 or <10 char message")
		else if((type == "im_digest" || type == "im_hold" || type == "im_holdabsorbed" || type == "im_absorb" || type == "im_heal" || type == "im_drain" || type == "im_steal" || type == "im_egg" || type == "im_shrink" || type == "im_grow" || type == "im_unabsorb") && (length(raw_list[i]) > 510 || length(raw_list[i]) < 10))
			raw_list.Cut(i,i)
			warning("[owner] tried to set [lowertext(name)] idle message with >501 or <10 char message")
		else if((type == "em" || type == "ema") && (length(raw_list[i]) > 260 || length(raw_list[i]) < 10))
			raw_list.Cut(i,i)
			warning("[owner] tried to set [lowertext(name)] examine message with >260 or <10 char message")
		else
			raw_list[i] = readd_quotes(raw_list[i])
			//Also fix % sign for var replacement
			raw_list[i] = replacetext(raw_list[i],"&#37;","%")

	ASSERT(raw_list.len <= 10) //Sanity

	switch(type)
		if("smo")
			struggle_messages_outside = raw_list
		if("smi")
			struggle_messages_inside = raw_list
		if("asmo")
			absorbed_struggle_messages_outside = raw_list
		if("asmi")
			absorbed_struggle_messages_inside = raw_list
		if("dmo")
			digest_messages_owner = raw_list
		if("dmp")
			digest_messages_prey = raw_list
		if("amo")
			absorb_messages_owner = raw_list
		if("amp")
			absorb_messages_prey = raw_list
		if("uamo")
			unabsorb_messages_owner = raw_list
		if("uamp")
			unabsorb_messages_prey = raw_list
		if("em")
			examine_messages = raw_list
		if("ema")
			examine_messages_absorbed = raw_list
		if("im_digest")
			emote_lists[DM_DIGEST] = raw_list
		if("im_hold")
			emote_lists[DM_HOLD] = raw_list
		if("im_holdabsorbed")
			emote_lists[DM_HOLD_ABSORBED] = raw_list
		if("im_absorb")
			emote_lists[DM_ABSORB] = raw_list
		if("im_heal")
			emote_lists[DM_HEAL] = raw_list
		if("im_drain")
			emote_lists[DM_DRAIN] = raw_list
		if("im_steal")
			emote_lists[DM_SIZE_STEAL] = raw_list
		if("im_egg")
			emote_lists[DM_EGG] = raw_list
		if("im_shrink")
			emote_lists[DM_SHRINK] = raw_list
		if("im_grow")
			emote_lists[DM_GROW] = raw_list
		if("im_unabsorb")
			emote_lists[DM_UNABSORB] = raw_list

	return

/obj/belly/proc/update_internal_overlay()
	// TODO: vore_fx
	// if(LAZYLEN(contents))
	// 	SEND_SIGNAL(src, COMSIG_BELLY_UPDATE_VORE_FX, TRUE) // Signals vore_fx() to listening atoms. Atoms must handle appropriate isliving() checks.
	// for(var/A in contents)
	// 	if(isliving(A))
	// 		vore_fx(A,1)
	// if(owner.previewing_belly == src)
	// 	if(isbelly(owner.loc))
	// 		owner.previewing_belly = null
	// 		return
	// 	vore_fx(owner,1)

// The next function gets the messages set on the belly, in human-readable format.
// This is useful in customization boxes and such. The delimiter right now is \n\n so
// in message boxes, this looks nice and is easily delimited.
/obj/belly/proc/get_reagent_messages(var/type, var/delim = "\n\n")
	ASSERT(type == "full1" || type == "full2" || type == "full3" || type == "full4" || type == "full5")
	var/list/raw_messages

	switch(type)
		if("full1")
			raw_messages = fullness1_messages
		if("full2")
			raw_messages = fullness2_messages
		if("full3")
			raw_messages = fullness3_messages
		if("full4")
			raw_messages = fullness4_messages
		if("full5")
			raw_messages = fullness5_messages

	var/messages = raw_messages.Join(delim)
	return messages

// The next function sets the messages on the belly, from human-readable var

// replacement strings and linebreaks as delimiters (two \n\n by default).
// They also sanitize the messages.
/obj/belly/proc/set_reagent_messages(var/raw_text, var/type, var/delim = "\n\n")
	ASSERT(type == "full1" || type == "full2" || type == "full3" || type == "full4" || type == "full5")

	var/list/raw_list = splittext(html_encode(raw_text),delim)
	if(raw_list.len > 10)
		raw_list.Cut(11)
		warning("[owner] tried to set [lowertext(name)] with 11+ messages")

	for(var/i = 1, i <= raw_list.len, i++)
		if(length(raw_list[i]) > 160 || length(raw_list[i]) < 10) //160 is fudged value due to htmlencoding increasing the size
			raw_list.Cut(i,i)
			warning("[owner] tried to set [lowertext(name)] with >121 or <10 char message")
		else
			raw_list[i] = readd_quotes(raw_list[i])
			//Also fix % sign for var replacement
			raw_list[i] = replacetext(raw_list[i],"&#37;","%")

	ASSERT(raw_list.len <= 10) //Sanity

	switch(type)
		if("full1")
			fullness1_messages = raw_list
		if("full2")
			fullness2_messages = raw_list
		if("full3")
			fullness3_messages = raw_list
		if("full4")
			fullness4_messages = raw_list
		if("full5")
			fullness5_messages = raw_list

	return
// Release a specific atom from the contents of this belly into the owning mob's location.
// If that location is another mob, the atom is transferred into whichever of its bellies the owning mob is in.
// Returns the number of atoms so released.
/obj/belly/proc/release_specific_contents(atom/movable/M, silent = FALSE)
	// TODO: release_specific_contents

/obj/belly/proc/handle_absorb_langs()
	// TODO: absorb_langs
	// owner.absorb_langs()

// Release all contents of this belly into the owning mob's location.
// If that location is another mob, contents are transferred into whichever of its bellies the owning mob is in.
// Returns the number of mobs so released.
/obj/belly/proc/release_all_contents(include_absorbed = FALSE, silent = FALSE)
	// TODO: release_all_contents

//Transfers contents from one belly to another
/obj/belly/proc/transfer_contents(atom/movable/content, obj/belly/target, silent = 0)
	// TODO: transfer_contents

/obj/belly/proc/handle_digestion_death(mob/living/M, instant = FALSE)
	// TODO: handle_digestion_death

// Handle a mob being absorbed
/obj/belly/proc/absorb_living(mob/living/M)
	// TODO: absorb_living

//This is gonna end up a long proc, but its gonna have to make do for now
/obj/belly/proc/ReagentSwitch()
	// TODO: ReagentSwitch

/obj/belly/proc/updateVRPanels()
	for(var/mob/living/M in contents)
		if(M.client)
			M.updateVRPanel()
	if(owner.client)
		owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

/obj/belly/proc/vore_preview(mob/living/L)
	if(!istype(L) || !L.client)
		L.vore_info.previewing_belly = null
		return
	L.vore_info.previewing_belly = src
	// TODO: vore_fx
	// vore_fx(L)

/obj/belly/proc/clear_preview(mob/living/L)
	L.vore_info.previewing_belly = null 
	L.clear_fullscreen("belly")
