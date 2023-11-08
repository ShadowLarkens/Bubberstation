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
	updateVRPanels()
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
	if(isanimal(owner))
		owner.update_icon()

	updateVRPanels()

	// if(prey.ckey)
		// GLOB.prey_eaten_roundstat++
		// if(owner.mind)
		// 	owner.mind.vore_prey_eaten++

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

// Release a specific atom from the contents of this belly into the owning mob's location.
// If that location is another mob, the atom is transferred into whichever of its bellies the owning mob is in.
// Returns the number of atoms so released.
/obj/belly/proc/release_specific_contents(atom/movable/M, silent = FALSE)
	if (!(M in contents))
		return 0 // They weren't in this belly anyway

	// if(istype(M, /mob/living/simple_mob/vore/morph/dominated_prey))
	// 	var/mob/living/simple_mob/vore/morph/dominated_prey/p = M
	// 	p.undo_prey_takeover(FALSE)
	// 	return 0
	// for(var/mob/living/L in M.contents)
		// L.vore_info.muffled = FALSE
		// L.forced_psay = FALSE

	// for(var/obj/item/weapon/holder/H in M.contents)
	// 	H.held_mob.prey_info.muffled = FALSE
		// H.held_mob.forced_psay = FALSE

	// if(isliving(M))
	// 	var/mob/living/slip = M
	// 	slip.slip_protect = world.time + 25 // This is to prevent slipping back into your pred if they stand on soap or something.
	//Place them into our drop_location
	M.forceMove(drop_location())
	if(ismob(M))
		var/mob/ourmob = M
		ourmob.reset_perspective(null)
	items_preserved -= M

	//Special treatment for absorbed prey
	if(isliving(M))
		var/mob/living/ML = M
		// var/mob/living/OW = owner
		// if(ML.client)
		// 	ML.stop_sound_channel(CHANNEL_PREYLOOP) //Stop the internal loop, it'll restart if the isbelly check on next tick anyway
		// if(ML.vore_info.muffled)
		// 	ML.vore_info.muffled = FALSE
		// if(ML.forced_psay)
		// 	ML.forced_psay = FALSE
		if(ML.vore_info.absorbed)
			ML.vore_info.absorbed = FALSE
			// handle_absorb_langs(ML, owner)
			// if(ishuman(M) && ishuman(OW))
			// 	var/mob/living/carbon/human/Prey = M
			// 	var/mob/living/carbon/human/Pred = OW
			// 	var/absorbed_count = 2 //Prey that we were, plus the pred gets a portion
			// 	for(var/mob/living/P in contents)
			// 		if(P.absorbed)
			// 			absorbed_count++
			// 	Pred.bloodstr.trans_to(Prey, Pred.reagents.total_volume / absorbed_count)

	//Clean up our own business
	if(!ishuman(owner))
		owner.update_icons()

	//Determines privacy
	var/privacy_range = world.view
	//var/privacy_volume = 100
	switch(eating_privacy_local) //Third case of if("loud") not defined, as it'd just leave privacy_range and volume untouched
		if("default")
			if(owner.vore_info.eating_privacy_global)
				privacy_range = 1
				//privacy_volume = 25
		if("subtle")
			privacy_range = 1
			//privacy_volume = 25

	//Print notifications/sound if necessary
	if(istype(M, /mob/dead/observer))
		silent = TRUE
	if(!silent)
		owner.visible_message("<font color='green'><b>[owner] [release_verb] [M] from their [lowertext(name)]!</b></font>", vision_distance = privacy_range)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound_with_pref(src, soundfile, vol = sound_volume, vary = 1, falloff_exponent = VORE_SOUND_FALLOFF, frequency = noise_freq, preference = /datum/preference/toggle/vore_eating_sounds) //CHOMPEdit
	//Should fix your view not following you out of mobs sometimes!
	if(ismob(M))
		var/mob/ourmob = M
		ourmob.reset_perspective(null)

	// if(!owner.ckey && escape_stun)
	// 	owner.Weaken(escape_stun)

	return 1

/obj/belly/proc/handle_absorb_langs()
	// TODO: absorb_langs
	// owner.absorb_langs()

// Release all contents of this belly into the owning mob's location.
// If that location is another mob, contents are transferred into whichever of its bellies the owning mob is in.
// Returns the number of mobs so released.
/obj/belly/proc/release_all_contents(include_absorbed = FALSE, silent = FALSE)//Don't bother if we don't have contents
	if(!contents.len)
		return FALSE

	//Find where we should drop things into (certainly not the owner)
	var/count = 0

	//Iterate over contents and move them all
	for(var/atom/movable/AM as anything in contents)
		if(isliving(AM))
			var/mob/living/L = AM
			if(L.vore_info?.absorbed && !include_absorbed)
				continue
		count += release_specific_contents(AM, silent = TRUE)

	//Clean up our own business
	items_preserved.Cut()
	if(!ishuman(owner))
		owner.update_icons()

	//Determines privacy
	var/privacy_range = world.view
	//var/privacy_volume = 100
	switch(eating_privacy_local) //Third case of if("loud") not defined, as it'd just leave privacy_range and volume untouched
		if("default")
			if(owner.vore_info?.eating_privacy_global)
				privacy_range = 1
				//privacy_volume = 25
		if("subtle")
			privacy_range = 1
			//privacy_volume = 25

	//Print notifications/sound if necessary
	if(!silent && count)
		owner.visible_message("<font color='green'><b>[owner] [release_verb] everything from their [lowertext(name)]!</b></font>", vision_distance = privacy_range)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound_with_pref(src, soundfile, vol = sound_volume, vary = 1, falloff_exponent = VORE_SOUND_FALLOFF, frequency = noise_freq, preference = /datum/preference/toggle/vore_eating_sounds) //CHOMPEdit

	return count
	// TODO: release_all_contents

//Transfers contents from one belly to another
/obj/belly/proc/transfer_contents(atom/movable/content, obj/belly/target, silent = 0)
	if(!(content in src) || !istype(target))
		return
	// content.belly_cycles = 0 //CHOMPEdit
	content.forceMove(target)
	if(ismob(content))
		var/mob/ourmob = content
		ourmob.reset_perspective(owner)
	// if(isitem(content))
	// 	var/obj/item/I = content
	// 	if(istype(I,/obj/item/weapon/card/id))
	// 		I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
	// 	if(I.gurgled && target.contaminates)
	// 		I.decontaminate()
	// 		I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
	items_preserved -= content
	updateVRPanels()
	owner.update_icon()

/obj/belly/proc/handle_digestion_death(mob/living/M, instant = FALSE)
	// TODO: handle_digestion_death

// Handle a mob being absorbed
/obj/belly/proc/absorb_living(mob/living/M)
	// TODO: absorb_living
	
// Handle a mob being unabsorbed
/obj/belly/proc/unabsorb_living(mob/living/M)
	// TODO: unabsorb_living

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
