//
// Bellies subsystem - Process vore bellies
//

PROCESSING_SUBSYSTEM_DEF(bellies)
	name = "Bellies"
	wait = 6 SECONDS
	flags = SS_KEEP_TIMING|SS_NO_INIT
	runlevels = RUNLEVEL_GAME|RUNLEVEL_POSTGAME
