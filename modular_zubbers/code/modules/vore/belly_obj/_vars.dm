/obj/belly
	name = "belly"							// Name of this location
	desc = "It's a belly! You're in it!"	// Flavor text description of inside sight/sound/smells/feels.
	var/vore_sound = "Gulp"					// Sound when ingesting someone
	var/vore_verb = "ingest"				// Verb for eating with this in messages
	var/release_verb = "expels"				// Verb for releasing something from a stomach
	var/human_prey_swallow_time = 100		// Time in deciseconds to swallow /mob/living/carbon/human
	var/nonhuman_prey_swallow_time = 30		// Time in deciseconds to swallow anything else
	var/nutrition_percent = 100				// Nutritional percentage per tick in digestion mode
	var/digest_brute = 0.5					// Brute damage per tick in digestion mode
	var/digest_burn = 0.5					// Burn damage per tick in digestion mode
	var/digest_oxy = 0						// Oxy damage per tick in digestion mode
	var/digest_tox = 0						// Toxins damage per tick in digestion mode
	var/digest_clone = 0					// Clone damage per tick in digestion mode
	var/immutable = FALSE					// Prevents this belly from being deleted
	var/escapable = FALSE					// Belly can be resisted out of at any time
	var/escapetime = 20 SECONDS				// Deciseconds, how long to escape this belly
	var/digestchance = 0					// % Chance of stomach beginning to digest if prey struggles
	var/absorbchance = 0					// % Chance of stomach beginning to absorb if prey struggles
	var/escapechance = 0 					// % Chance of prey beginning to escape if prey struggles.
	var/escape_stun = 0						// AI controlled mobs with a number here will be weakened by the provided var when someone escapes, to prevent endless nom loops
	var/transferchance = 0 					// % Chance of prey being trasnsfered, goes from 0-100%
	var/transferchance_secondary = 0 		// % Chance of prey being transfered to transferchance_secondary, also goes 0-100%
	var/save_digest_mode = TRUE				// Whether this belly's digest mode persists across rounds
	var/can_taste = FALSE					// If this belly prints the flavor of prey when it eats someone.
	var/bulge_size = 0.25					// The minimum size the prey has to be in order to show up on examine.
	var/display_absorbed_examine = FALSE	// Do we display absorption examine messages for this belly at all?
	var/absorbed_desc						// Desc shown to absorbed prey. Defaults to regular if left empty.
	var/shrink_grow_size = 1				// This horribly named variable determines the minimum/maximum size it will shrink/grow prey to.
	var/transferlocation					// Location that the prey is released if they struggle and get dropped off.
	var/transferlocation_secondary			// Secondary location that prey is released to.
	var/release_sound = "Splatter"			// Sound for letting someone out. Replaced from True/false
	var/mode_flags = 0						// Stripping, numbing, etc.
	var/fancy_vore = FALSE					// Using the new sounds?
	var/is_wet = TRUE						// Is this belly's insides made of slimy parts?
	var/wet_loop = TRUE						// Does the belly have a fleshy loop playing?
	// TODO: EGG
	// var/obj/item/weapon/storage/vore_egg/ownegg	// Is this belly creating an egg?
	// var/egg_type = "Egg"					// Default egg type and path.
	// var/egg_path = /obj/item/weapon/storage/vore_egg
	// var/egg_name = null						// CHOMPAdd. Custom egg name
	var/list/list/emote_lists = list()			// Idle emotes that happen on their own, depending on the bellymode. Contains lists of strings indexed by bellymode
	var/emote_time = 60						// How long between stomach emotes at prey (in seconds)
	var/emote_active = TRUE					// Are we even giving emotes out at all or not?
	var/next_emote = 0						// When we're supposed to print our next emote, as a world.time
	var/selective_preference = DM_DIGEST	// Which type of selective bellymode do we default to?
	var/eating_privacy_local = "default"	//Overrides eating_privacy_global if not "default". Determines if attempt/success messages are subtle/loud
	var/is_feedable = TRUE					// If this belly shows up in belly selections for others. //CHOMPAdd
	var/silicon_belly_overlay_preference = "Sleeper" //Selects between placing belly overlay in sleeper or normal vore mode. Exclusive
	var/belly_mob_mult = 1		//Multiplier for how filling mob types are in borg bellies
	var/belly_item_mult = 1 	//Multiplier for how filling items are in borg borg bellies. Items are also weighted on item size
	var/belly_overall_mult = 1	//Multiplier applied ontop of any other specific multipliers

	// Generally just used by AI
	var/autotransferchance = 0 				// % Chance of prey being autotransferred to transfer location
	var/autotransferwait = 10 				// Time between trying to transfer.
	var/autotransferlocation				// Place to send them
	var/autotransfer_whitelist = 0			// Flags for what can be transferred to the primary location //CHOMPAdd
	var/autotransfer_blacklist = 2			// Flags for what can not be transferred to the primary location, defaults to Absorbed //CHOMPAdd
	var/autotransfer_whitelist_items = 0	// Flags for what can be transferred to the primary location //CHOMPAdd
	var/autotransfer_blacklist_items = 0	// Flags for what can not be transferred to the primary location //CHOMPAdd
	var/autotransferchance_secondary = 0 	// % Chance of prey being autotransferred to secondary transfer location //CHOMPAdd
	var/autotransferlocation_secondary		// Second place to send them //CHOMPAdd
	var/autotransfer_secondary_whitelist = 0// Flags for what can be transferred to the secondary location //CHOMPAdd
	var/autotransfer_secondary_blacklist = 2// Flags for what can not be transferred to the secondary location, defaults to Absorbed //CHOMPAdd
	var/autotransfer_secondary_whitelist_items = 0// Flags for what can be transferred to the secondary location //CHOMPAdd
	var/autotransfer_secondary_blacklist_items = 0// Flags for what can not be transferred to the secondary location //CHOMPAdd
	var/autotransfer_enabled = FALSE		// Player toggle
	var/autotransfer_min_amount = 0			// Minimum amount of things to pass at once. //CHOMPAdd
	var/autotransfer_max_amount = 0			// Maximum amount of things to pass at once. //CHOMPAdd
	var/tmp/list/autotransfer_queue = list()// Reserve for above things. //CHOMPAdd
	//Auto-transfer flags for whitelist //CHOMPAdd
	var/tmp/static/list/autotransfer_flags_list = list("Creatures" = AT_FLAG_CREATURES, "Absorbed" = AT_FLAG_ABSORBED, "Carbon" = AT_FLAG_CARBON, "Silicon" = AT_FLAG_SILICON, "Mobs" = AT_FLAG_MOBS, "Animals" = AT_FLAG_ANIMALS, "Mice" = AT_FLAG_MICE, "Dead" = AT_FLAG_DEAD, "Digestable Creatures" = AT_FLAG_CANDIGEST, "Absorbable Creatures" = AT_FLAG_CANABSORB, "Full Health" = AT_FLAG_HEALTHY)
	var/tmp/static/list/autotransfer_flags_list_items = list("Items" = AT_FLAG_ITEMS, "Trash" = AT_FLAG_TRASH, "Eggs" = AT_FLAG_EGGS, "Remains" = AT_FLAG_REMAINS, "Indigestible Items" = AT_FLAG_INDIGESTIBLE, "Recyclable Items" = AT_FLAG_RECYCLABLE, "Ores" = AT_FLAG_ORES, "Clothes and Bags" = AT_FLAG_CLOTHES, "Food" = AT_FLAG_FOOD)

	//I don't think we've ever altered these lists. making them static until someone actually overrides them somewhere.
	//Actual full digest modes
	var/tmp/static/list/digest_modes = list(DM_HOLD,DM_DIGEST,DM_ABSORB,DM_DRAIN,DM_SELECT,DM_UNABSORB,DM_HEAL,DM_SHRINK,DM_GROW,DM_SIZE_STEAL,DM_EGG)
	//Digest mode addon flags
	var/tmp/static/list/mode_flag_list = list("Numbing" = DM_FLAG_NUMBING, "Stripping" = DM_FLAG_STRIPPING, "Leave Remains" = DM_FLAG_LEAVEREMAINS, "Muffles" = DM_FLAG_THICKBELLY, "Affect Worn Items" = DM_FLAG_AFFECTWORN, "Jams Sensors" = DM_FLAG_JAMSENSORS, "Complete Absorb" = DM_FLAG_FORCEPSAY, "Slow Body Digestion" = DM_FLAG_SLOWBODY, "Muffle Items" = DM_FLAG_MUFFLEITEMS, "TURBO MODE" = DM_FLAG_TURBOMODE)
	//Item related modes
	var/tmp/static/list/item_digest_modes = list(IM_HOLD,IM_DIGEST_FOOD,IM_DIGEST,IM_DIGEST_PARALLEL)

	var/tmp/mob/living/owner					// The mob whose belly this is.
	var/tmp/digest_mode = DM_HOLD				// Current mode the belly is set to from digest_modes (+transform_modes if human)
	var/tmp/list/items_preserved = list()		// Stuff that wont digest so we shouldn't process it again.
	var/tmp/recent_sound = FALSE				// Prevent audio spam

	// Don't forget to watch your commas at the end of each line if you change these.
	var/list/struggle_messages_outside = list(
		"%pred's %belly wobbles with a squirming meal.",
		"%pred's %belly jostles with movement.",
		"%pred's %belly briefly swells outward as someone pushes from inside.",
		"%pred's %belly fidgets with a trapped victim.",
		"%pred's %belly jiggles with motion from inside.",
		"%pred's %belly sloshes around.",
		"%pred's %belly gushes softly.",
		"%pred's %belly lets out a wet squelch.")

	var/list/struggle_messages_inside = list(
		"Your useless squirming only causes %pred's slimy %belly to squelch over your body.",
		"Your struggles only cause %pred's %belly to gush softly around you.",
		"Your movement only causes %pred's %belly to slosh around you.",
		"Your motion causes %pred's %belly to jiggle.",
		"You fidget around inside of %pred's %belly.",
		"You shove against the walls of %pred's %belly, making it briefly swell outward.",
		"You jostle %pred's %belly with movement.",
		"You squirm inside of %pred's %belly, making it wobble around.")

	var/list/absorbed_struggle_messages_outside = list(
		"%pred's %belly wobbles, seemingly on its own.",
		"%pred's %belly jiggles without apparent cause.",
		"%pred's %belly seems to shake for a second without an obvious reason.")

	var/list/absorbed_struggle_messages_inside = list(
		"You try and resist %pred's %belly, but only cause it to jiggle slightly.",
		"Your fruitless mental struggles only shift %pred's %belly a tiny bit.",
		"You can't make any progress freeing yourself from %pred's %belly.")

	var/list/digest_messages_owner = list(
		"You feel %prey's body succumb to your digestive system, which breaks it apart into soft slurry.",
		"You hear a lewd glorp as your %belly muscles grind %prey into a warm pulp.",
		"Your %belly lets out a rumble as it melts %prey into sludge.",
		"You feel a soft gurgle as %prey's body loses form in your %belly. They're nothing but a soft mass of churning slop now.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your thighs.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your rump.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your belly.",
		"Your %belly groans as %prey falls apart into a thick soup. You can feel their remains soon flowing deeper into your body to be absorbed.",
		"Your %belly kneads on every fiber of %prey, softening them down into mush to fuel your next hunt.",
		"Your %belly churns %prey down into a hot slush. You can feel the nutrients coursing through your digestive track with a series of long, wet glorps.")

	var/list/digest_messages_prey = list(
		"Your body succumbs to %pred's digestive system, which breaks you apart into soft slurry.",
		"%pred's %belly lets out a lewd glorp as their muscles grind you into a warm pulp.",
		"%pred's %belly lets out a rumble as it melts you into sludge.",
		"%pred feels a soft gurgle as your body loses form in their %belly. You're nothing but a soft mass of churning slop now.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's thighs.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's rump.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's belly.",
		"%pred's %belly groans as you fall apart into a thick soup. Your remains soon flow deeper into %pred's body to be absorbed.",
		"%pred's %belly kneads on every fiber of your body, softening you down into mush to fuel their next hunt.",
		"%pred's %belly churns you down into a hot slush. Your nutrient-rich remains course through their digestive track with a series of long, wet glorps.")

	var/list/absorb_messages_owner = list(
		"You feel %prey becoming part of you.")

	var/list/absorb_messages_prey = list(
		"You feel yourself becoming part of %pred's %belly!")

	var/list/unabsorb_messages_owner = list(
		"You feel %prey reform into a recognizable state again.")

	var/list/unabsorb_messages_prey = list(
		"You are released from being part of %pred's %belly.")

	var/list/examine_messages = list(
		"They have something solid in their %belly!",
		"It looks like they have something in their %belly!")

	var/list/examine_messages_absorbed = list(
		"Their body looks somewhat larger than usual around the area of their %belly.",
		"Their %belly looks larger than usual.")

	var/item_digest_mode = IM_DIGEST_FOOD	// Current item-related mode from item_digest_modes
	var/contaminates = TRUE					// Whether the belly will contaminate stuff // CHOMPedit: reset to true like it always was
	var/contamination_flavor = "Generic"	// Determines descriptions of contaminated items
	var/contamination_color = "green"		// Color of contamination overlay

	// Lets you do a fullscreen overlay. Set to an icon_state string.
	var/belly_fullscreen = ""
	var/disable_hud = FALSE
	var/colorization_enabled = TRUE
	var/belly_fullscreen_color = "#823232"
	var/belly_fullscreen_color2 = "#FFFFFF"
	var/belly_fullscreen_color3 = "#823232"
	var/belly_fullscreen_color4 = "#FFFFFF"
	var/belly_fullscreen_alpha = 255

	//CHOMP - liquid bellies
	var/reagentbellymode = FALSE			// Belly has abilities to make liquids from digested/absorbed/drained prey and/or nutrition
	var/reagent_mode_flags = 0

	var/tmp/static/list/reagent_mode_flag_list= list(
		"Produce Liquids" = DM_FLAG_REAGENTSNUTRI,
		"Digestion Liquids" = DM_FLAG_REAGENTSDIGEST,
		"Absorption Liquids" = DM_FLAG_REAGENTSABSORB,
		"Draining Liquids" = DM_FLAG_REAGENTSDRAIN
		)

	var/show_liquids = FALSE //Moved from vorepanel_ch to be a belly var
	var/show_fullness_messages = FALSE //Moved from vorepanel_ch to be a belly var
	var/liquid_overlay = TRUE						//Belly-specific liquid overlay toggle
	var/max_liquid_level = 100						//Custom max level for liquid overlay
	var/mush_overlay = FALSE						//Toggle for nutrition mush overlay
	var/mush_color = "#664330"						//Nutrition mush overlay color
	var/mush_alpha = 255							//Mush overlay transparency.
	var/max_mush = 500								//How much nutrition for full mush overlay
	var/min_mush = 0								//Manual setting for lowest mush level
	var/item_mush_val = 0							//How much solid belly contents raise mush level per item
	var/metabolism_overlay = FALSE					//Extra mush layer for ingested reagents currently in metabolism.
	var/metabolism_mush_ratio = 15					//Metabolism reagent volume per unit compared to nutrition units.
	var/max_ingested = 500							//How much metabolism content for full overlay.
	var/ingested_color = "#664330"					//Normal color holder for ingested layer. Blended from existing reagent colors.
	var/custom_ingested_color = null				//Custom color for ingested reagent layer.
	var/custom_ingested_alpha = 255					//Custom alpha for ingested reagent layer if not using normal mush layer.

	var/nutri_reagent_gen = FALSE					//if belly produces reagent over time using nutrition, needs to be optimized to use subsystem - Jack
	var/list/generated_reagents = list("water" = 1) //Any number of reagents, the associated value is how many units are generated per process()
	var/reagent_name = "water" 						//What is shown when reagents are removed, doesn't need to be an actual reagent
	var/reagentid = "water"							//Selected reagent's id, for use in puddle system currently
	var/reagentcolor = "#0064C877"					//Selected reagent's color, for use in puddle system currently
	var/custom_reagentcolor							//Custom reagent color. Blank for normal reagent color
	var/custom_reagentalpha							//Custom reagent alpha. Blank for capacity based alpha
	var/gen_cost = 1 								//amount of nutrient taken from the host everytime nutrition is used to make reagents
	var/gen_amount = 1							//Does not actually influence amount produced, but is used as a way to tell the system how much total reagent it has to take into account when filling a belly

	var/gen_interval = 0							//Interval in seconds for generating fluids, once it reaches the value of gen_time one cycle of reagents generation will occur
	var/gen_time = 5								//Time it takes in seconds to produce one cycle of reagents, technically add 1 second to it for the tick where the fluid is produced
	var/gen_time_display = "1 hour"					//The displayed time it takes from a belly to go from 0 to 100
	var/custom_max_volume = 100						//Variable for people to limit amount of liquid they can receive/produce in a belly
	var/digest_nutri_gain = 0						//variable to store temporary nutrition gain from digestion and allow a seperate proc to ease up on the wall of code
	var/reagent_transfer_verb = "injects"			//verb for transfer of reagent from a vore belly

	var/vorefootsteps_sounds = FALSE				//If this belly can make sounds when someone walks around
	var/liquid_fullness1_messages = FALSE
	var/liquid_fullness2_messages = FALSE
	var/liquid_fullness3_messages = FALSE
	var/liquid_fullness4_messages = FALSE
	var/liquid_fullness5_messages = FALSE
	var/vorespawn_blacklist = FALSE

	var/list/fullness1_messages = list(
		"%pred's %belly looks empty"
		)
	var/list/fullness2_messages = list(
		"%pred's %belly looks filled"
		)
	var/list/fullness3_messages = list(
		"%pred's %belly looks like it's full of liquid"
		)
	var/list/fullness4_messages = list(
		"%pred's %belly is quite full!"
		)
	var/list/fullness5_messages = list(
		"%pred's %belly is completely filled to it's limit!"
		)

	// TODO: Match reagents up to tg reagents
	// variable for switch to figure out what to set variables when a certain reagent is selected
	var/tmp/reagent_chosen = "Water"
	// List of reagents people can chose, maybe one day expand so it covers criterias like dogborgs who can make meds, booze, etc - Jack
	var/tmp/static/list/reagent_choices = list(
	"Water",
	"Milk",
	"Cream",
	"Honey",
	"Cherry Jelly",
	"Digestive acid",
	"Diluted digestive acid",
	"Lube",
	"Biomass"
	)

	var/vore_sprite_flags = DM_FLAG_VORESPRITE_BELLY
	var/tmp/static/list/vore_sprite_flag_list= list(
		"Normal belly sprite" = DM_FLAG_VORESPRITE_BELLY,
		//"Tail adjustment" = DM_FLAG_VORESPRITE_TAIL,
		//"Marking addition" = DM_FLAG_VORESPRITE_MARKING,
		"Undergarment addition" = DM_FLAG_VORESPRITE_ARTICLE,
		)

	var/affects_vore_sprites = FALSE
	var/count_absorbed_prey_for_sprite = TRUE
	var/absorbed_multiplier = 1
	var/count_liquid_for_sprite = FALSE
	var/liquid_multiplier = 1
	var/count_items_for_sprite = FALSE
	var/item_multiplier = 1
	var/health_impacts_size = TRUE
	var/resist_triggers_animation = TRUE
	var/size_factor_for_sprite = 1
	var/belly_sprite_to_affect = "stomach"
	var/undergarment_chosen = "Underwear, bottom"
	var/undergarment_if_none
	var/undergarment_color = COLOR_GRAY
	var/datum/sprite_accessory/tail/tail_to_change_to = FALSE
	var/tail_colouration = FALSE
	var/tail_extra_overlay = FALSE
	var/tail_extra_overlay2 = FALSE
	//var/marking_to_add = NULL
	//var/marking_color = NULL
	var/special_entrance_sound				// Mob specific custom entry sound set by mob's init_vore when applicable
	var/slow_digestion = FALSE				// Gradual corpse digestion
	var/slow_brutal = FALSE					// Gradual corpse digestion: Stumpy's Special
	var/sound_volume = 100					// Volume knob.
	var/speedy_mob_processing = FALSE		// Independent belly processing to utilize SSobj instead of SSbellies 3x speed.
	var/cycle_sloshed = FALSE				// Has vorgan entrance made a wet slosh this cycle? Soundspam prevention for multiple items entered.
	var/egg_cycles = 0						// Process egg mode after 10 cycles.
	var/recycling = FALSE					// Recycling mode.
	var/entrance_logs = TRUE				// Belly-specific entry message toggle.
	var/noise_freq = 42500					// Tasty sound prefs.
	var/item_digest_logs = FALSE			// Chat messages for digested items.


//For serialization, keep this updated, required for bellies to save correctly.
/obj/belly/vars_to_save()
	var/list/saving = list(
		"name",
		"desc",
		"absorbed_desc",
		"vore_sound",
		"vore_verb",
		"release_verb",
		"human_prey_swallow_time",
		"nonhuman_prey_swallow_time",
		"emote_time",
		"nutrition_percent",
		"digest_brute",
		"digest_burn",
		"digest_oxy",
		"digest_tox",
		"digest_clone",
		"immutable",
		"can_taste",
		"escapable",
		"escapetime",
		"digestchance",
		"absorbchance",
		"escapechance",
		"transferchance",
		"transferchance_secondary",
		"transferlocation",
		"transferlocation_secondary",
		"bulge_size",
		"display_absorbed_examine",
		"shrink_grow_size",
		"struggle_messages_outside",
		"struggle_messages_inside",
		"absorbed_struggle_messages_outside",
		"absorbed_struggle_messages_inside",
		"digest_messages_owner",
		"digest_messages_prey",
		"absorb_messages_owner",
		"absorb_messages_prey",
		"unabsorb_messages_owner",
		"unabsorb_messages_prey",
		"examine_messages",
		"examine_messages_absorbed",
		"emote_lists",
		"emote_time",
		"emote_active",
		"selective_preference",
		"mode_flags",
		"item_digest_mode",
		"contaminates",
		"contamination_flavor",
		"contamination_color",
		"release_sound",
		"fancy_vore",
		"is_wet",
		"wet_loop",
		"belly_fullscreen",
		"disable_hud",
		"reagent_mode_flags",
		"belly_fullscreen_color",
		"belly_fullscreen_color2",
		"belly_fullscreen_color3",
		"belly_fullscreen_color4",
		"belly_fullscreen_alpha",
		"colorization_enabled",
		"reagentbellymode",
		"liquid_fullness1_messages",
		"liquid_fullness2_messages",
		"liquid_fullness3_messages",
		"liquid_fullness4_messages",
		"liquid_fullness5_messages",
		"reagent_name",
		"reagent_chosen",
		"reagentid",
		"reagentcolor",
		"liquid_overlay",
		"max_liquid_level",
		"mush_overlay",
		"mush_color",
		"mush_alpha",
		"max_mush",
		"min_mush",
		"item_mush_val",
		"custom_reagentcolor",
		"custom_reagentalpha",
		"metabolism_overlay",
		"metabolism_mush_ratio",
		"max_ingested",
		"custom_ingested_color",
		"custom_ingested_alpha",
		"gen_cost",
		"gen_amount",
		"gen_time",
		"gen_time_display",
		"reagent_transfer_verb",
		"custom_max_volume",
		"generated_reagents",
		"vorefootsteps_sounds",
		"fullness1_messages",
		"fullness2_messages",
		"fullness3_messages",
		"fullness4_messages",
		"fullness5_messages",
		"vorespawn_blacklist",
		"vore_sprite_flags",
		"affects_vore_sprites",
		"count_absorbed_prey_for_sprite",
		"absorbed_multiplier",
		"count_liquid_for_sprite",
		"liquid_multiplier",
		"count_items_for_sprite",
		"item_multiplier",
		"health_impacts_size",
		"resist_triggers_animation",
		"size_factor_for_sprite",
		"belly_sprite_to_affect",
		"undergarment_chosen",
		"undergarment_if_none",
		"undergarment_color",
		"autotransferchance",
		"autotransferwait",
		"autotransferlocation",
		"autotransfer_enabled",
		"autotransferchance_secondary",
		"autotransferlocation_secondary",
		"autotransfer_secondary_whitelist",
		"autotransfer_secondary_blacklist",
		"autotransfer_whitelist",
		"autotransfer_blacklist",
		"autotransfer_secondary_whitelist_items",
		"autotransfer_secondary_blacklist_items",
		"autotransfer_whitelist_items",
		"autotransfer_blacklist_items",
		"autotransfer_min_amount",
		"autotransfer_max_amount",
		"slow_digestion",
		"slow_brutal",
		"sound_volume",
		"speedy_mob_processing",
		"egg_name",
		"recycling",
		"is_feedable",
		"entrance_logs",
		"noise_freq",
		"item_digest_logs", //CHOMP end of variables from CHOMP
		"egg_type",
		"save_digest_mode",
		"eating_privacy_local",
		"silicon_belly_overlay_preference",
		"belly_mob_mult",
		"belly_item_mult",
		"belly_overall_mult",
	)

	if (save_digest_mode)
		return ..() + saving + list("digest_mode")

	return ..() + saving
