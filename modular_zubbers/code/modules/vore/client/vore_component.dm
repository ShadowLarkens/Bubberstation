/**
 * Small helper component to enable vore_attack_hand
 */
/datum/component/vore

/datum/component/vore/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	. = ..()

/datum/component/vore/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(attack_hand))
	RegisterSignal(parent, COMSIG_MOB_LOGIN, PROC_REF(mob_login))

/datum/component/vore/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_ATOM_ATTACK_HAND)
	UnregisterSignal(parent, COMSIG_MOB_LOGIN)

// Signal handlers

// TODO: port vore to this component entirely
/datum/component/vore/proc/attack_hand(mob/living/attacked, mob/living/attacker, list/modifiers)
	SIGNAL_HANDLER

	// This shouldn't even be possible but who knows
	if(attacked != parent)
		return

	if(!attacker.Adjacent(attacked))
		return


	// Most vore interactions revolve around someone that is being pulled
	if(isliving(attacker.pulling))
		var/mob/living/pulled = attacker.pulling
		// If the attacker and attacked are the same, then our user clicked on themselves while pulling something
		// Therefore they want to personally eat their pulled prey
		if(attacked == attacker && is_vore_predator(attacker))
			var/mob/living/user = attacker
			var/mob/living/pred = attacker
			var/mob/living/prey = pulled
			var/belly = pred.vore_info.vore_selected

			// No additional checks, do_the_nom handles base preferences

			INVOKE_ASYNC(src, PROC_REF(do_the_nom), user, prey, pred, belly)
			return COMPONENT_CANCEL_ATTACK_CHAIN
		// If the attacked is the "pulled" one, then the attacker is trying to feed themselves to their pulled pred
		else if(attacked == pulled && is_vore_predator(pulled))
			var/mob/living/user = attacker
			var/mob/living/pred = pulled
			var/mob/living/prey = attacker

			// This is the prey force-feeding themselves to the pred, so make sure the pred is okay with feeding
			if(!pred.vore_info.feeding)
				to_chat(user, "<span class='notice'>[pred] isn't willing to be fed.</span>")
				log_admin("[key_name_admin(prey)] attempted to feed themselves to [key_name_admin(pred)] against their prefs ([pred ? ADMIN_JMP(pred) : "null"])")
				message_admins("[key_name_admin(prey)] attempted to feed themselves to [key_name_admin(pred)] against their prefs ([pred ? ADMIN_JMP(pred) : "null"])")
				return

			INVOKE_ASYNC(src, PROC_REF(select_belly), user, prey, pred)
			return COMPONENT_CANCEL_ATTACK_CHAIN
		// Otherwise, the attacker is trying to feed their pulled prey to the attacked as a third party
		else if(is_vore_predator(attacked))
			var/mob/living/user = attacker
			var/mob/living/pred = attacked
			var/mob/living/prey = pulled
			
			// This is the user force-feeding prey to the pred, so make sure the pred is okay with feeding
			if(!pred.vore_info?.feeding)
				to_chat(user, "<span class='notice'>[pred] isn't willing to be fed.</span>")
				log_admin("[key_name_admin(user)] attempted to feed [key_name_admin(prey)] to [key_name_admin(pred)] against predator's prefs ([pred ? ADMIN_JMP(pred) : "null"])")
				message_admins("[key_name_admin(user)] attempted to feed [key_name_admin(prey)] to [key_name_admin(pred)] against predator's prefs ([pred ? ADMIN_JMP(pred) : "null"])")
				return
			
			// This is already covered by do_the_nom, but we want to give better logs
			// Check if the prey is okay with being eaten
			if(!prey.vore_info?.devourable)
				to_chat(user, "<span class='notice'>[prey] isn't able to be devoured.</span>")
				log_admin("[key_name_admin(attacker)] attempted to feed [key_name_admin(prey)] to [key_name_admin(src)] against prey's prefs ([prey ? ADMIN_JMP(prey) : "null"])")
				message_admins("[key_name_admin(attacker)] attempted to feed [key_name_admin(prey)] to [key_name_admin(src)] against prey's prefs ([prey ? ADMIN_JMP(prey) : "null"])")
				return

			INVOKE_ASYNC(src, PROC_REF(select_belly), user, prey, pred)
			return COMPONENT_CANCEL_ATTACK_CHAIN


/datum/component/vore/proc/mob_login(mob/living/source)
	SIGNAL_HANDLER
	
	if(!source.vore_info.no_vore)
		// source.verbs |= /mob/living/proc/vorebelly_printout
		if(!source.vorePanel)
			source.AddComponent(/datum/component/vore_panel)

// Helpers

// This allows the user to select the pred belly they want to feed prey to.
/datum/component/vore/proc/select_belly(mob/living/user, mob/living/prey, mob/living/pred)
	var/belly = tgui_input_list(user, "Choose Belly", "Belly Choice", pred.feedable_bellies())
	if(belly)
		do_the_nom(user, prey, pred, belly)

// Actually set up and do the nom
/datum/component/vore/proc/do_the_nom(mob/living/user, mob/living/prey, mob/living/pred, obj/belly/belly, delay)
	//Sanity
	if(!user || !prey || !pred || !istype(belly) || !(belly in pred.vore_info.vore_organs))
		warning("[user] attempted to feed [prey] to [pred], via [belly ? lowertext(belly.name) : "*null*"] but it went wrong.")
		return FALSE
	if(pred == prey)
		return FALSE

	// The belly selected at the time of noms
	var/attempt_msg = "ERROR: Vore message couldn't be created. Notify a dev. (at)"
	var/success_msg = "ERROR: Vore message couldn't be created. Notify a dev. (sc)"

	//Final distance check. Time has passed, menus have come and gone. Can't use do_after adjacent because doesn't behave for held micros
	var/user_to_pred = get_dist(get_turf(user),get_turf(pred))
	var/user_to_prey = get_dist(get_turf(user),get_turf(prey))

	if(user_to_pred > 1 || user_to_prey > 1)
		return FALSE

	if(!prey.vore_info.devourable)
		to_chat(user, "<span class='notice'>They aren't able to be devoured.</span>")
		log_admin("[key_name_admin(src)] attempted to devour [key_name_admin(prey)] against their prefs ([prey ? ADMIN_JMP(prey) : "null"])")
		message_admins("[key_name_admin(src)] attempted to devour [key_name_admin(prey)] against their prefs ([prey ? ADMIN_JMP(prey) : "null"])")
		return FALSE
	if(prey.vore_info.absorbed || pred.vore_info.absorbed)
		to_chat(user, "<span class='warning'>They aren't aren't in a state to be devoured.</span>")
		return FALSE

	//Determining vore attempt privacy
	var/message_range = world.view
	// if(!pred.is_slipping && !prey.is_slipping) //We only care about privacy preference if it's NOT a spontaneous vore.
	// 	switch(belly.eating_privacy_local) //if("loud") case not added, as it would not modify message_range
	// 		if("default")
	// 			if(pred.eating_privacy_global)
	// 				message_range = 1
	// 		if("subtle")
	// 			message_range = 1



	// Slipnoms from chompstation downstream, credit to cadyn for the original PR.
	// Prepare messages
	// if(prey.is_slipping)
	// 	attempt_msg = "<span class='warning'>It seems like [prey] is about to slide into [pred]'s [lowertext(belly.name)]!</span>"
	// 	success_msg = "<span class='warning'>[prey] suddenly slides into [pred]'s [lowertext(belly.name)]!</span>"
	// else if(pred.is_slipping)
	// 	attempt_msg = "<span class='warning'>It seems like [prey] is gonna end up inside [pred]'s [lowertext(belly.name)] as [pred] comes sliding over!</span>"
	// 	success_msg = "<span class='warning'>[prey] suddenly slips inside of [pred]'s [lowertext(belly.name)] as [pred] slides into them!</span>"
	/*else*/ if(user == pred) //Feeding someone to yourself
		attempt_msg = "<span class='warning'>[pred] is attempting to [lowertext(belly.vore_verb)] [prey] into their [lowertext(belly.name)]!</span>"
		success_msg = "<span class='warning'>[pred] manages to [lowertext(belly.vore_verb)] [prey] into their [lowertext(belly.name)]!</span>"
	else //Feeding someone to another person
		attempt_msg = "<span class='warning'>[user] is attempting to make [pred] [lowertext(belly.vore_verb)] [prey] into their [lowertext(belly.name)]!</span>"
		success_msg = "<span class='warning'>[user] manages to make [pred] [lowertext(belly.vore_verb)] [prey] into their [lowertext(belly.name)]!</span>"

	// Announce that we start the attempt!


	user.visible_message(attempt_msg, vision_distance = message_range)


	// Now give the prey time to escape... return if they did
	var/swallow_time
	if(delay)
		swallow_time = delay
	else
		swallow_time = istype(prey, /mob/living/carbon/human) ? belly.human_prey_swallow_time : belly.nonhuman_prey_swallow_time

	// Their AI should get notified so they can stab us
	// prey.ai_holder?.react_to_attack(user)

	//Timer and progress bar
	if(!do_after(user, swallow_time, prey))
		return FALSE // Prey escpaed (or user disabled) before timer expired.

	// If we got this far, nom successful! Announce it!
	user.visible_message(success_msg, vision_distance = message_range)

	// Actually shove prey into the belly.
	// if(istype(prey.loc, /obj/item/weapon/holder))
	// 	var/obj/item/weapon/holder/H = prey.loc
	// 	for(var/mob/living/M in H.contents)
	// 		belly.nom_mob(M, user)
	// 		if(M.loc == H) // In case nom_mob failed somehow.
	// 			M.forceMove(get_turf(src))
	// 	H.held_mob = null
	// 	qdel(H)
	// else
	belly.nom_mob(prey, user)

	user.update_icon()

	// TODO: Inform Admins
	// if(pred == user)
	// 	add_attack_logs(pred, prey, "Eaten via [belly.name]")
	// else
	// 	add_attack_logs(user, pred, "Forced to eat [key_name(prey)]")
	return TRUE
