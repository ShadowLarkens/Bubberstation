
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
