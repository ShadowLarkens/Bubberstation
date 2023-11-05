/**
 * Small helper component to manage the vore panel HUD icon
 */
/datum/component/vore_panel
	var/atom/movable/screen/vore_panel/screen_icon

/datum/component/vore_panel/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	. = ..()

/datum/component/vore_panel/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(create_mob_button))
	var/mob/living/owner = parent
	if(owner.client)
		create_mob_button(parent)
	owner.verbs |= /mob/proc/insidePanel
	if(!owner.vorePanel) //CHOMPEdit
		owner.vorePanel = new(owner)

/datum/component/vore_panel/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN)
	var/mob/living/owner = parent
	if(screen_icon)
		owner?.client?.screen -= screen_icon
		UnregisterSignal(screen_icon, COMSIG_CLICK)
		QDEL_NULL(screen_icon)
	owner.verbs -= /mob/proc/insidePanel
	QDEL_NULL(owner.vorePanel)

/datum/component/vore_panel/proc/create_mob_button(mob/user)
	var/datum/hud/HUD = user.hud_used
	if(!screen_icon)
		screen_icon = new()
		RegisterSignal(screen_icon, COMSIG_CLICK, PROC_REF(vore_panel_click))
	screen_icon.icon = HUD.ui_style
	HUD.static_inventory += screen_icon
	user.client?.screen += screen_icon

/datum/component/vore_panel/proc/vore_panel_click(source, location, control, params, user)
	var/mob/living/owner = user
	if(istype(owner) && owner.vorePanel)
		INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, insidePanel), owner) //CHOMPEdit
/**
 * Screen object for vore panel
 */
/atom/movable/screen/vore_panel
	name = "vore panel"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "vore"
	screen_loc = ui_vore_menu
