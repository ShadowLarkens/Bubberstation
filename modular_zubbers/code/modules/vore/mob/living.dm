/mob/living/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/vore)

/mob/living/proc/feedable_bellies()
	var/list/bellies = list()
	for(var/obj/belly/Y in vore_info?.vore_organs)
		if(Y.is_feedable)
			bellies += Y
	return bellies
