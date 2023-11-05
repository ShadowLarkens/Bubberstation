
/*
VVVVVVVV           VVVVVVVV     OOOOOOOOO     RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE
V::::::V           V::::::V   OO:::::::::OO   R::::::::::::::::R  E::::::::::::::::::::E
V::::::V           V::::::V OO:::::::::::::OO R::::::RRRRRR:::::R E::::::::::::::::::::E
V::::::V           V::::::VO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEEE::::E
 V:::::V           V:::::V O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
  V:::::V         V:::::V  O:::::O     O:::::O  R::::R     R:::::R  E:::::E
   V:::::V       V:::::V   O:::::O     O:::::O  R::::RRRRRR:::::R   E::::::EEEEEEEEEE
    V:::::V     V:::::V    O:::::O     O:::::O  R:::::::::::::RR    E:::::::::::::::E
     V:::::V   V:::::V     O:::::O     O:::::O  R::::RRRRRR:::::R   E:::::::::::::::E
      V:::::V V:::::V      O:::::O     O:::::O  R::::R     R:::::R  E::::::EEEEEEEEEE
       V:::::V:::::V       O:::::O     O:::::O  R::::R     R:::::R  E:::::E
        V:::::::::V        O::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
         V:::::::V         O:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEE:::::E
          V:::::V           OO:::::::::::::OO R::::::R     R:::::RE::::::::::::::::::::E
           V:::V              OO:::::::::OO   R::::::R     R:::::RE::::::::::::::::::::E
            VVV                 OOOOOOOOO     RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE

-Aro <3 */

#define VORE_VERSION	2	//This is a Define so you don't have to worry about magic numbers.

//
// The datum type bolted onto normal preferences datums for storing Virgo stuff
//
/client
	var/datum/vore_preferences/prefs_vr

/client/New()
	. = ..()
	prefs_vr = new /datum/vore_preferences(src)

/datum/vore_preferences
	//Actual preferences
	var/digestable = TRUE
	var/devourable = TRUE
	var/absorbable = TRUE
	var/feeding = TRUE
	var/can_be_drop_prey = FALSE
	var/can_be_drop_pred = FALSE
	var/allow_spontaneous_tf = FALSE
	var/digest_leave_remains = FALSE
	var/allowmobvore = TRUE
	var/permit_healbelly = TRUE
	var/noisy = FALSE
	var/eating_privacy_global = FALSE //Makes eating attempt/success messages only reach for subtle range if true, overwritten by belly-specific var

	// These are 'modifier' prefs, do nothing on their own but pair with drop_prey/drop_pred settings.
	var/drop_vore = TRUE
	var/stumble_vore = TRUE
	var/slip_vore = TRUE
	var/throw_vore = TRUE
	var/food_vore = TRUE

	var/resizable = TRUE
	var/show_vore_fx = TRUE
	var/step_mechanics_pref = FALSE
	var/pickup_pref = TRUE

	//CHOMP stuff
	var/receive_reagents = FALSE
	var/give_reagents = FALSE
	var/latejoin_vore = FALSE
	var/latejoin_prey = FALSE
	var/autotransferable = TRUE
	var/vore_sprite_multiply = list("stomach" = FALSE, "taur belly" = FALSE)
	var/vore_sprite_color = list("stomach" = "#000", "taur belly" = "#000")
  //CHOMP stuff end

	var/list/belly_prefs = list()
	var/vore_taste = "nothing in particular"
	var/vore_smell = "nothing in particular"

	var/selective_preference = DM_DEFAULT


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

	//Mechanically required
	var/path
	var/slot
	var/client/client
	var/client_ckey

/datum/vore_preferences/New(client/C)
	if(istype(C))
		client = C
		client_ckey = C.ckey
		load_vore()

//
//	Check if an object is capable of eating things, based on vore_organs
//
/proc/is_vore_predator(mob/living/O)
	if(isliving(O))
		// if(isanimal(O)) //CHOMPEdit: On-demand belly loading.
		// 	var/mob/living/simple_mob/SM = O
		// 	if(SM.vore_active && !SM.voremob_loaded)
		// 		SM.voremob_loaded = TRUE
		// 		SM.init_vore()
		if(O.vore_info && LAZYLEN(O.vore_info.vore_organs) > 0)
			return TRUE

	return FALSE

//
//	Belly searching for simplifying other procs
//  Mostly redundant now with belly-objects and isbelly(loc)
//
/proc/check_belly(atom/movable/A)
	return isbelly(A.loc)

//
// Save/Load Vore Preferences
//
/datum/vore_preferences/proc/load_path(ckey, slot, filename="character", ext="json")
	if(!ckey || !slot)
		return
	path = "data/player_saves/[ckey[1]]/[ckey]/vore/[filename][slot].[ext]"


/datum/vore_preferences/proc/load_vore()
	if(!client || !client_ckey)
		return FALSE //No client, how can we save?
	if(!client.prefs || !client.prefs.default_slot)
		return FALSE //Need to know what character to load!

	slot = client.prefs.default_slot

	load_path(client_ckey,slot)

	if(!path)
		return FALSE //Path couldn't be set?
	if(!fexists(path)) //Never saved before
		save_vore() //Make the file first
		return TRUE

	var/list/json_from_file = json_decode(file2text(path))
	if(!json_from_file)
		return FALSE //My concern grows

	var/version = json_from_file["version"]
	json_from_file = patch_version(json_from_file,version)

	digestable = json_from_file["digestable"]
	devourable = json_from_file["devourable"]
	resizable = json_from_file["resizable"]
	feeding = json_from_file["feeding"]
	absorbable = json_from_file["absorbable"]
	digest_leave_remains = json_from_file["digest_leave_remains"]
	allowmobvore = json_from_file["allowmobvore"]
	vore_taste = json_from_file["vore_taste"]
	vore_smell = json_from_file["vore_smell"]
	permit_healbelly = json_from_file["permit_healbelly"]
	noisy = json_from_file["noisy"]
	selective_preference = json_from_file["selective_preference"]
	show_vore_fx = json_from_file["show_vore_fx"]
	can_be_drop_prey = json_from_file["can_be_drop_prey"]
	can_be_drop_pred = json_from_file["can_be_drop_pred"]
	allow_spontaneous_tf = json_from_file["allow_spontaneous_tf"]
	step_mechanics_pref = json_from_file["step_mechanics_pref"]
	pickup_pref = json_from_file["pickup_pref"]
	belly_prefs = json_from_file["belly_prefs"]
	drop_vore = json_from_file["drop_vore"]
	slip_vore = json_from_file["slip_vore"]
	food_vore = json_from_file["food_vore"]
	throw_vore = json_from_file["throw_vore"]
	stumble_vore = json_from_file["stumble_vore"]
	nutrition_message_visible = json_from_file["nutrition_message_visible"]
	nutrition_messages = json_from_file["nutrition_messages"]
	weight_message_visible = json_from_file["weight_message_visible"]
	weight_messages = json_from_file["weight_messages"]
	eating_privacy_global = json_from_file["eating_privacy_global"]


	//CHOMP stuff
	latejoin_vore = json_from_file["latejoin_vore"]
	latejoin_prey = json_from_file["latejoin_prey"]
	receive_reagents = json_from_file["receive_reagents"]
	give_reagents = json_from_file["give_reagents"]
	autotransferable = json_from_file["autotransferable"]
	vore_sprite_color = json_from_file["vore_sprite_color"]
	vore_sprite_multiply = json_from_file["vore_sprite_multiply"]


	//Quick sanitize
	if(isnull(digestable))
		digestable = TRUE
	if(isnull(devourable))
		devourable = TRUE
	if(isnull(resizable))
		resizable = TRUE
	if(isnull(feeding))
		feeding = TRUE
	if(isnull(absorbable))
		absorbable = TRUE
	if(isnull(digest_leave_remains))
		digest_leave_remains = FALSE
	if(isnull(allowmobvore))
		allowmobvore = TRUE
	if(isnull(permit_healbelly))
		permit_healbelly = TRUE
	if(isnull(selective_preference))
		selective_preference = DM_DEFAULT
	if (isnull(noisy))
		noisy = FALSE
	if(isnull(show_vore_fx))
		show_vore_fx = TRUE
	if(isnull(can_be_drop_prey))
		can_be_drop_prey = FALSE
	if(isnull(can_be_drop_pred))
		can_be_drop_pred = FALSE
	if(isnull(allow_spontaneous_tf))
		allow_spontaneous_tf = FALSE
	if(isnull(step_mechanics_pref))
		step_mechanics_pref = TRUE
	if(isnull(pickup_pref))
		pickup_pref = TRUE
	if(isnull(belly_prefs))
		belly_prefs = list()
	if(isnull(drop_vore))
		drop_vore = TRUE
	if(isnull(slip_vore))
		slip_vore = TRUE
	if(isnull(throw_vore))
		throw_vore = TRUE
	if(isnull(stumble_vore))
		stumble_vore = TRUE
	if(isnull(food_vore))
		food_vore = TRUE
	if(isnull(nutrition_message_visible))
		nutrition_message_visible = TRUE
	if(isnull(weight_message_visible))
		weight_message_visible = TRUE
	if(isnull(eating_privacy_global))
		eating_privacy_global = FALSE
	if(isnull(nutrition_messages))
		nutrition_messages = list(
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
	else if(nutrition_messages.len < 10)
		while(nutrition_messages.len < 10)
			nutrition_messages.Add("")
	if(isnull(weight_messages))
		weight_messages = list(
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
	else if(weight_messages.len < 10)
		while(weight_messages.len < 10)
			weight_messages.Add("")

	//CHOMP stuff
	if(isnull(latejoin_vore))
		latejoin_vore = FALSE
	if(isnull(latejoin_prey))
		latejoin_prey = FALSE
	if(isnull(receive_reagents))
		receive_reagents = FALSE
	if(isnull(give_reagents))
		give_reagents = FALSE
	if(isnull(autotransferable))
		autotransferable = TRUE
	if(isnull(vore_sprite_color))
		vore_sprite_color = list("stomach" = "#000", "taur belly" = "#000")
	if(isnull(vore_sprite_multiply))
		vore_sprite_multiply = list("stomach" = FALSE, "taur belly" = FALSE)

	return TRUE

/datum/vore_preferences/proc/save_vore()
	if(!path)
		return FALSE

	var/version = VORE_VERSION	//For "good times" use in the future
	var/list/settings_list = list(
			"version"				= version,
			"digestable"			= digestable,
			"devourable"			= devourable,
			"resizable"				= resizable,
			"absorbable"			= absorbable,
			"feeding"				= feeding,
			"digest_leave_remains"	= digest_leave_remains,
			"allowmobvore"			= allowmobvore,
			"vore_taste"			= vore_taste,
			"vore_smell"			= vore_smell,
			"permit_healbelly"		= permit_healbelly,
			"noisy" 				= noisy,
			"selective_preference"	= selective_preference,
			"show_vore_fx"			= show_vore_fx,
			"can_be_drop_prey"		= can_be_drop_prey,
			"can_be_drop_pred"		= can_be_drop_pred,
			"latejoin_vore"			= latejoin_vore, //CHOMPedit
			"latejoin_prey"			= latejoin_prey,
			"allow_spontaneous_tf"	= allow_spontaneous_tf,
			"step_mechanics_pref"	= step_mechanics_pref,
			"pickup_pref"			= pickup_pref,
			"belly_prefs"			= belly_prefs,
			"receive_reagents"		= receive_reagents,
			"give_reagents"			= give_reagents,
			"autotransferable"		= autotransferable,
			"drop_vore"				= drop_vore,
			"slip_vore"				= slip_vore,
			"stumble_vore"			= stumble_vore,
			"throw_vore" 			= throw_vore,
			"food_vore" 			= food_vore,
			"nutrition_message_visible"	= nutrition_message_visible,
			"nutrition_messages"		= nutrition_messages,
			"weight_message_visible"	= weight_message_visible,
			"weight_messages"			= weight_messages,
			"eating_privacy_global"		= eating_privacy_global,
			"vore_sprite_color"			= vore_sprite_color, //CHOMPEdit
			"vore_sprite_multiply"		= vore_sprite_multiply, //CHOMPEdit
		)

	//List to JSON
	var/json_to_file = json_encode(settings_list)
	if(!json_to_file)
		warning("Saving: [path] failed jsonencode")
		return FALSE

	//Write it out
	rustg_file_write(json_to_file, path)

	if(!fexists(path))
		warning("Saving: [path] failed file write")
		return FALSE

	return TRUE

//Can do conversions here
/datum/vore_preferences/proc/patch_version(var/list/json_from_file,var/version)
	return json_from_file


//
//	Verb for saving vore preferences to save file
//
/mob/proc/save_vore_prefs()
	if(!client || !client.prefs_vr)
		return FALSE
	if(!copy_to_prefs_vr())
		return FALSE
	if(!client.prefs_vr.save_vore())
		return FALSE

	return TRUE

/mob/proc/apply_vore_prefs()
	if(!client || !client.prefs_vr)
		return FALSE
	if(!client.prefs_vr.load_vore())
		return FALSE
	if(!copy_from_prefs_vr())
		return FALSE

	return TRUE

/mob/proc/copy_to_prefs_vr()
	if(!client || !client.prefs_vr)
		to_chat(src,"<span class='warning'>You attempted to save your vore prefs but somehow you're in this character without a client.prefs_vr variable. Tell a dev.</span>")
		return FALSE

	var/datum/vore_preferences/P = client.prefs_vr

	P.digestable = vore_info.digestable
	P.devourable = vore_info.devourable
	P.feeding = vore_info.feeding
	P.absorbable = vore_info.absorbable
	P.resizable = vore_info.resizable
	P.digest_leave_remains = vore_info.digest_leave_remains
	P.allowmobvore = vore_info.allowmobvore
	P.vore_taste = vore_info.vore_taste
	P.vore_smell = vore_info.vore_smell
	P.permit_healbelly = vore_info.permit_healbelly
	P.noisy = vore_info.noisy
	P.selective_preference = vore_info.selective_preference
	P.show_vore_fx = vore_info.show_vore_fx
	P.can_be_drop_prey = vore_info.can_be_drop_prey
	P.can_be_drop_pred = vore_info.can_be_drop_pred
	P.allow_spontaneous_tf = vore_info.allow_spontaneous_tf
	P.step_mechanics_pref = vore_info.step_mechanics_pref
	P.pickup_pref = vore_info.pickup_pref
	P.drop_vore = vore_info.drop_vore
	P.slip_vore = vore_info.slip_vore
	P.throw_vore = vore_info.throw_vore
	P.food_vore = vore_info.food_vore
	P.stumble_vore = vore_info.stumble_vore
	P.eating_privacy_global = vore_info.eating_privacy_global

	P.nutrition_message_visible = vore_info.nutrition_message_visible
	P.nutrition_messages = vore_info.nutrition_messages
	P.weight_message_visible = vore_info.weight_message_visible
	P.weight_messages = vore_info.weight_messages

	//CHOMP stuff
	P.latejoin_vore = vore_info.latejoin_vore
	P.latejoin_prey = vore_info.latejoin_prey
	P.receive_reagents = vore_info.receive_reagents
	P.give_reagents = vore_info.give_reagents
	// TODO: autotransferable
	// P.autotransferable = vore_info.autotransferable
	P.vore_sprite_color = vore_info.vore_sprite_color
	P.vore_sprite_multiply = vore_info.vore_sprite_multiply

	var/list/serialized = list()
	for(var/obj/belly/B as anything in vore_info.vore_organs)
		serialized += list(B.datum_json_serialize()) //Can't add a list as an object to another list in Byond. Thanks.

	P.belly_prefs = serialized

	return TRUE

//
//	Proc for applying vore preferences, given bellies
//
/mob/proc/copy_from_prefs_vr(var/bellies = TRUE, var/full_vorgans = FALSE) //CHOMPedit: full_vorgans var to bypass 1-belly load optimization.
	if(!client || !client.prefs_vr)
		to_chat(src,"<span class='warning'>You attempted to apply your vore prefs but somehow you're in this character without a client.prefs_vr variable. Tell a dev.</span>")
		return FALSE

	var/datum/vore_preferences/P = client.prefs_vr

	if(!vore_info)
		vore_info = new()

	vore_info.digestable = P.digestable
	vore_info.devourable = P.devourable
	vore_info.feeding = P.feeding
	vore_info.absorbable = P.absorbable
	vore_info.resizable = P.resizable
	vore_info.digest_leave_remains = P.digest_leave_remains
	vore_info.allowmobvore = P.allowmobvore
	vore_info.vore_taste = P.vore_taste
	vore_info.vore_smell = P.vore_smell
	vore_info.permit_healbelly = P.permit_healbelly
	vore_info.selective_preference = P.selective_preference
	vore_info.noisy = P.noisy
	vore_info.show_vore_fx = P.show_vore_fx
	vore_info.can_be_drop_prey = P.can_be_drop_prey
	vore_info.can_be_drop_pred = P.can_be_drop_pred
//	vore_info.allow_inbelly_spawning = P.allow_inbelly_spawning //CHOMP Removal: we have vore spawning at home. Actually if this were to be enabled, it would break anyway. Just leaving this here as a reference to it.
	vore_info.allow_spontaneous_tf = P.allow_spontaneous_tf
	vore_info.step_mechanics_pref = P.step_mechanics_pref
	vore_info.pickup_pref = P.pickup_pref
	vore_info.drop_vore = P.drop_vore
	vore_info.slip_vore = P.slip_vore
	vore_info.throw_vore = P.throw_vore
	vore_info.stumble_vore = P.stumble_vore
	vore_info.food_vore = P.food_vore
	vore_info.eating_privacy_global = P.eating_privacy_global

	vore_info.nutrition_message_visible = P.nutrition_message_visible
	vore_info.nutrition_messages = P.nutrition_messages
	vore_info.weight_message_visible = P.weight_message_visible
	vore_info.weight_messages = P.weight_messages

	//CHOMP stuff
	vore_info.latejoin_vore = P.latejoin_vore
	vore_info.latejoin_prey = P.latejoin_prey
	vore_info.receive_reagents = P.receive_reagents
	vore_info.give_reagents = P.give_reagents
	// TODO: autotransferable
	// vore_info.autotransferable = P.autotransferable
	vore_info.vore_sprite_color = P.vore_sprite_color
	vore_info.vore_sprite_multiply = P.vore_sprite_multiply

	if(bellies)
		if(isliving(src))
			var/mob/living/L = src
			L.release_vore_contents(silent = TRUE)
		QDEL_LIST(vore_info.vore_organs) // CHOMPedit
		for(var/entry in P.belly_prefs)
			list_to_object(entry,src)

	return TRUE
