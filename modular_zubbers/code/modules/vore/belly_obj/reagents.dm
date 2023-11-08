
//////////////////////////// REAGENT_DIGEST ////////////////////////

/obj/belly/proc/GenerateBellyReagents_digesting()	//The rate isnt based on selected reagent, due to the fact that the price of the reagent is already paid by nutrient not gained.
	if(reagents.total_volume + (digest_nutri_gain * gen_amount) <= custom_max_volume) //By default a reagent with an amount of 1 should result in pred getting 100 units from a full health prey
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] * digest_nutri_gain / gen_cost)
	else
		owner.adjust_nutrition(digest_nutri_gain * owner.get_digestion_efficiency_modifier())
	digest_nutri_gain = 0

/obj/belly/proc/GenerateBellyReagents_digested()
	if(reagents.total_volume <= custom_max_volume - 25 * gen_amount)
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] * 25)
	else
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] / gen_amount * (custom_max_volume - reagents.total_volume))
	digest_nutri_gain = 0

//////////////////////////// REAGENT_ABSORB ////////////////////////

/obj/belly/proc/GenerateBellyReagents_absorbing()
	if(reagents.total_volume <= custom_max_volume - 1.5 * gen_amount) //Going for 1.5 amount of reagent per cycle, can be adjusted in future if need adjustments
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] * 1.5)
	else
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] / gen_amount * (custom_max_volume - reagents.total_volume))

/obj/belly/proc/GenerateBellyReagents_absorbed()
	if(reagents.total_volume <= custom_max_volume - 25 * gen_amount) //Going for 25 amount of reagent for absorbing the prey, can be adjusted in future if need adjustments
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] * 10)
	else
		for(var/reagent in generated_reagents)
			reagents.add_reagent(reagent, generated_reagents[reagent] / gen_amount * (custom_max_volume - reagents.total_volume))

//////////////////////////// REAGENT_DRAIN ///////////////////////// //Currently not needed, maybe later a specific proc for drain needs to be made - Jack
