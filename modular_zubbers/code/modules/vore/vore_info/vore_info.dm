
// Replacement for CHOMP's million /mob and /mob/living variables
// Instead collect them all in one datum
/datum/vore_info
	// List of vore containers inside a mob
	var/list/vore_organs = list()
	// Default to no vore capability.
	var/obj/belly/vore_selected
	// If a mob is absorbed into another
	var/absorbed = FALSE
	//Toggleable vorgan entry logs.
	var/mute_entry = FALSE
	// Can the mob be digested inside a belly?
	var/digestable = TRUE
	// Can the mob be devoured at all?
	var/devourable = TRUE
	// Allow participation in macro-micro step mechanics
	var/step_mechanics_pref = TRUE
	// Allow participation in macro-micro pickup mechanics
	var/pickup_pref = TRUE

	//Pref for people to avoid others transfering reagents into them.
	var/receive_reagents = FALSE
	//Pref for people to avoid others taking reagents from them.
	var/give_reagents = FALSE

	// CHOMP vore icons refactor (Now on mob)
	// Maximum capacity, -1 for unlimited
	var/vore_capacity = 0
	//expanded list of capacities
	var/vore_capacity_ex = list("stomach" = 0)
	// How "full" the belly is (controls icons)
	var/vore_fullness = 0
	// Expanded list of fullness
	var/list/vore_fullness_ex = list("stomach" = 0)
	var/belly_size_multiplier = 1
	var/vore_sprite_multiply = list("stomach" = FALSE, "taur belly" = FALSE)
	var/vore_sprite_color = list("stomach" = "#000", "taur belly" = "#000")

	var/list/vore_icon_bellies = list("stomach")
	var/updating_fullness = FALSE
	var/obj/belly/previewing_belly

	var/feeding = TRUE					// Can the mob be vorishly force fed or fed to others?
	var/absorbable = TRUE				// Are you allowed to absorb this person?
	var/resizable = TRUE				// Can other people resize you? (Usually ignored for self-resizes)
	var/digest_leave_remains = FALSE	// Will this mob leave bones/skull/etc after the melty demise?
	var/allowmobvore = TRUE				// Will simplemobs attempt to eat the mob?
	var/vore_taste = null				// What the character tastes like
	var/vore_smell = null				// What the character smells like
	var/noisy = FALSE					// Toggle audible hunger.
	var/permit_healbelly = TRUE
	var/stumble_vore = TRUE				//Enabled by default since you have to enable drop pred/prey to do this anyway
	var/slip_vore = TRUE				//Enabled by default since you have to enable drop pred/prey to do this anyway
	var/drop_vore = TRUE				//Enabled by default since you have to enable drop pred/prey to do this anyway
	var/throw_vore = TRUE				//Enabled by default since you have to enable drop pred/prey to do this anyway
	var/food_vore = TRUE				//Enabled by default since you have to enable drop pred/prey to do this anyway
	var/can_be_drop_prey = FALSE
	var/can_be_drop_pred = FALSE
	var/allow_spontaneous_tf = FALSE	// Obviously.
	var/show_vore_fx = TRUE				// Show belly fullscreens
	var/latejoin_vore = FALSE			//CHOMPedit: If enabled, latejoiners can spawn into this, assuming they have a client
	var/latejoin_prey = FALSE			//CHOMPedit: If enabled, latejoiners can spawn ontop of and instantly eat the victim
	var/noisy_full = FALSE				//CHOMPedit: Enables belching when a mob has overeaten
	var/selective_preference = DM_DEFAULT	// Preference for selective bellymode
	var/eating_privacy_global = FALSE //Makes eating attempt/success messages only reach for subtle range if true, overwritten by belly-specific var
	var/nutrition_message_visible = TRUE
	var/list/nutrition_messages = list(
							"They are starving! You can hear their stomach snarling from across the room!",
							"They are extremely hungry. A deep growl occasionally rumbles from their empty stomach.",
							"",
							"They have a stuffed belly, bloated fat and round from eating too much.",
							"They have a rotund, thick gut. It bulges from their body obscenely, close to sagging under its own weight.",
							"They are sporting a large, round, sagging stomach. It contains at least their body weight worth of glorping slush.",
							"They are engorged with a huge stomach that sags and wobbles as they move. They must have consumed at least twice their body weight. It looks incredibly soft.",
							"Their stomach is firmly packed with digesting slop. They must have eaten at least a few times worth their body weight! It looks hard for them to stand, and their gut jiggles when they move.",
							"They are so absolutely stuffed that you aren't sure how it's possible for them to move. They can't seem to swell any bigger. The surface of their belly looks sorely strained!",
							"They are utterly filled to the point where it's hard to even imagine them moving, much less comprehend it when they do. Their gut is swollen to monumental sizes and amount of food they consumed must be insane.")
	var/weight_message_visible = TRUE
	var/list/weight_messages = list(
							"They are terribly lithe and frail!",
							"They have a very slender frame.",
							"They have a lightweight, athletic build.",
							"They have a healthy, average body.",
							"They have a thick, curvy physique.",
							"They have a plush, chubby figure.",
							"They have an especially plump body with a round potbelly and large hips.",
							"They have a very fat frame with a bulging potbelly, squishy rolls of pudge, very wide hips, and plump set of jiggling thighs.",
							"They are incredibly obese. Their massive potbelly sags over their waistline while their fat ass would probably require two chairs to sit down comfortably!",
							"They are so morbidly obese, you wonder how they can even stand, let alone waddle around the station. They can't get any fatter without being immobilized.")

	var/no_vore = FALSE					// If the character/mob can vore.
