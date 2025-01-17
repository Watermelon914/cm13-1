SUBSYSTEM_DEF(ticker)
	name = "Ticker"
	init_order = SS_INIT_TICKER

	priority = SS_PRIORITY_TICKER
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_LOBBY | RUNLEVEL_SETUP | RUNLEVEL_GAME

	var/current_state = GAME_STATE_STARTUP	//State of current round used by process()
	var/force_ending = FALSE					//Round was ended by admin intervention
	var/bypass_checks = FALSE 				//Bypass mode init checks
	var/setup_failed = FALSE 				//If the setup has failed at any point
	var/setup_started = FALSE

	var/datum/game_mode/mode = null

	var/list/login_music = null						//Music played in pregame lobby

	var/delay_end = FALSE					//If set true, the round will not restart on it's own
	var/delay_start = FALSE
	var/admin_delay_notice = ""				//A message to display to anyone who tries to restart the world after a delay

	var/time_left							//Pre-game timer
	var/start_at

	var/roundend_check_paused = FALSE

	var/round_start_time = 0
	var/list/round_start_events
	var/list/round_end_events

	var/graceful = FALSE //Will this server gracefully shut down?

	var/queue_delay = 0
	var/list/queued_players = list()		//used for join queues when the server exceeds the hard population cap

	// TODO: move this into mapview ss
	var/toweractive = FALSE

	var/list/minds = list()

	var/automatic_delay_end = FALSE

	var/totalPlayers = 0					//used for pregame stats on statpanel
	var/totalPlayersReady = 0				//used for pregame stats on statpanel
	var/datum/nmcontext/NM

/datum/controller/subsystem/ticker/Initialize(timeofday)
	load_mode()
	mode = config.pick_mode(GLOB.master_mode)
	var/list/FailedZs
	mode.load_maps(FailedZs)

	if(LAZYLEN(FailedZs))	//but seriously, unless the server's filesystem is messed up this will never happen
		var/msg = "RED ALERT! The following map files failed to load: [FailedZs[1]]"
		if(FailedZs.len > 1)
			for(var/I in 2 to FailedZs.len)
				msg += ", [FailedZs[I]]"
		msg += ". Yell at your server host!"
		to_chat(world, SPAN_WARNING(msg))
		log_world(msg)

	if(CONFIG_GET(flag/nightmare_enabled))
		NM = new
		if(!NM.init_config() || !NM.init_scenario())
			QDEL_NULL(NM)
			log_debug("TICKER: Error during Nightmare Init, aborting")

	var/all_music = CONFIG_GET(keyed_list/lobby_music)
	var/key = SAFEPICK(all_music)
	if(key)
		login_music = file(all_music[key])
	return ..()

/datum/controller/subsystem/ticker/fire(resumed = FALSE)
	switch(current_state)
		if(GAME_STATE_STARTUP)
			if(Master.initializations_finished_with_no_players_logged_in && !length(GLOB.clients))
				return
			if(isnull(start_at))
				start_at = time_left || world.time + (CONFIG_GET(number/lobby_countdown) * 10)
			to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, margin_top = 2, margin_bottom = 0, html = SPAN_ROUNDHEADER("Welcome to the pre-game lobby of [CONFIG_GET(string/servername)]!"))
			to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, margin_top = 0, html = SPAN_ROUNDBODY("Please, setup your character and select ready. Game will start in [round(time_left / 10) || CONFIG_GET(number/lobby_countdown)] seconds."))
			current_state = GAME_STATE_PREGAME
			fire()

		if(GAME_STATE_PREGAME)
			if(isnull(time_left))
				time_left = max(0, start_at - world.time)

			totalPlayers = LAZYLEN(GLOB.new_player_list)
			totalPlayersReady = 0
			for(var/i in GLOB.new_player_list)
				var/mob/new_player/player = i
				if(player.ready) // TODO: port this     == PLAYER_READY_TO_PLAY)
					++totalPlayersReady
			if(time_left < 0 || delay_start)
				return

			time_left -= wait
			if(time_left <= 0)
				request_start()

		if(GAME_STATE_PLAYING)
			mode.process(wait * 0.1)

			if(!roundend_check_paused && mode.check_finished(force_ending) || force_ending)
				current_state = GAME_STATE_FINISHED
				ooc_allowed = TRUE
				mode.declare_completion(force_ending)
				if(CONFIG_GET(number/gamemode_rounds_needed) != -1 && text2num(SSperf_logging?.round?.id) % CONFIG_GET(number/gamemode_rounds_needed) == 0)
					addtimer(CALLBACK(
						SSvote,
						/datum/controller/subsystem/vote/proc/initiate_vote,
						"gamemode",
						"SERVER",
						CALLBACK(src, .proc/handle_map_reboot)
					), 3 SECONDS)
				else
					handle_map_reboot()
				Master.SetRunLevel(RUNLEVEL_POSTGAME)

/// Attempt to start game asynchronously if applicable
/datum/controller/subsystem/ticker/proc/request_start(skip_nightmare = FALSE)
	if(current_state != GAME_STATE_PREGAME)
		return FALSE

	if(!CONFIG_GET(flag/nightmare_enabled))
		skip_nightmare = TRUE
		QDEL_NULL(NM)

	current_state = GAME_STATE_SETTING_UP
	if(!skip_nightmare)
		setup_nightmare()
	else
		INVOKE_ASYNC(src, .proc/setup_start)
	return TRUE

/// Request to start nightmare setup before moving on to regular setup
/datum/controller/subsystem/ticker/proc/setup_nightmare()
	PRIVATE_PROC(TRUE)
	if(NM && !NM.done)
		RegisterSignal(SSdcs, COMSIG_GLOB_NIGHTMARE_SETUP_DONE, .proc/nightmare_setup_done)
		if(!NM.start_setup())
			QDEL_NULL(NM)
			INVOKE_ASYNC(src, .proc/setup_start)
		return
	INVOKE_ASYNC(src, .proc/setup_start)

/// Catches nightmare result to proceed to game start
/datum/controller/subsystem/ticker/proc/nightmare_setup_done(_, datum/nmcontext/ctx, retval)
	SIGNAL_HANDLER
	PRIVATE_PROC(TRUE)
	if(ctx != NM)
		return
	if(retval != NM_TASK_OK)
		QDEL_NULL(NM)
	INVOKE_ASYNC(src, .proc/setup_start)

/// Try to effectively setup gamemode and start now
/datum/controller/subsystem/ticker/proc/setup_start()
	PRIVATE_PROC(TRUE)
	Master.SetRunLevel(RUNLEVEL_SETUP)
	setup_failed = !setup()
	if(setup_failed)
		current_state = GAME_STATE_STARTUP
		time_left = null
		start_at = world.time + (CONFIG_GET(number/lobby_countdown) * 10)
		Master.SetRunLevel(RUNLEVEL_LOBBY)
		return FALSE
	return TRUE

/datum/controller/subsystem/ticker/proc/handle_map_reboot()
	addtimer(CALLBACK(
		SSvote,
		/datum/controller/subsystem/vote/proc/initiate_vote,
		"groundmap",
		"SERVER",
		CALLBACK(src, .proc/Reboot)
	), 3 SECONDS)

/datum/controller/subsystem/ticker/proc/setup()
	to_chat(world, SPAN_BOLDNOTICE("Enjoy the game!"))
	var/init_start = world.timeofday

	CHECK_TICK
	if(!mode.can_start(bypass_checks))
		to_chat(world, "Reverting to pre-game lobby.")
		RoleAuthority.reset_roles()
		return FALSE

	CHECK_TICK
	if(!mode.pre_setup() && !bypass_checks)
		to_chat(world, "<b>Error in pre-setup for [mode.name].</b> Reverting to pre-game lobby.")
		RoleAuthority.reset_roles()
		return FALSE

	CHECK_TICK
	mode.announce()

	if(CONFIG_GET(flag/autooocmute))
		ooc_allowed = FALSE

	CHECK_TICK
	for(var/I in round_start_events)
		var/datum/callback/cb = I
		cb.InvokeAsync()
	LAZYCLEARLIST(round_start_events)
	CHECK_TICK

	//Configure mode and assign player to special mode stuff
	if (!(mode.flags_round_type & MODE_NO_SPAWN))
		var/roles_to_roll = null
		if(length(mode.roles_to_roll))
			roles_to_roll = mode.roles_to_roll
		RoleAuthority.setup_candidates_and_roles(roles_to_roll) //Distribute jobs
		if(mode.flags_round_type & MODE_NEW_SPAWN)
			create_characters() // Create and equip characters
		else
			old_create_characters() //Create player characters and transfer them
			equip_characters()

	GLOB.data_core.manifest()

	log_world("Game start took [(world.timeofday - init_start) / 10]s")
	round_start_time = world.time
	//SSdbcore.SetRoundStart()

	current_state = GAME_STATE_PLAYING
	Master.SetRunLevel(RUNLEVEL_GAME)

	CHECK_TICK

	for(var/mob/new_player/np in GLOB.new_player_list)
		INVOKE_ASYNC(np, /mob/new_player.proc/new_player_panel_proc, TRUE)

	begin_game_recording()

	setup_economy()

	shuttle_controller.setup_shuttle_docks()

	PostSetup()
	return TRUE


/datum/controller/subsystem/ticker/proc/PostSetup()
	set waitfor = FALSE
	mode.initialize_emergency_calls()
	mode.post_setup()

	// Switch back to default automatically
	//save_mode(CONFIG_GET(string/gamemode_default))

	if(round_statistics)
		to_chat_spaced(world, html = FONT_SIZE_BIG(SPAN_ROLE_BODY("<B>Welcome to [round_statistics.name]</B>")))

	supply_controller.process() 		//Start the supply shuttle regenerating points -- TLE

	for(var/i in GLOB.closet_list) //Set up special equipment for lockers and vendors, depending on gamemode
		var/obj/structure/closet/C = i
		INVOKE_ASYNC(C, /obj/structure/closet.proc/select_gamemode_equipment, mode.type)
	for(var/obj/structure/machinery/vending/V in machines)
		INVOKE_ASYNC(V, /obj/structure/machinery/vending.proc/select_gamemode_equipment, mode.type)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_POST_SETUP)


//These callbacks will fire after roundstart key transfer
/datum/controller/subsystem/ticker/proc/OnRoundstart(datum/callback/cb)
	if(!HasRoundStarted())
		LAZYADD(round_start_events, cb)
	else
		cb.InvokeAsync()


//These callbacks will fire before roundend report
/datum/controller/subsystem/ticker/proc/OnRoundend(datum/callback/cb)
	if(current_state >= GAME_STATE_FINISHED)
		cb.InvokeAsync()
	else
		LAZYADD(round_end_events, cb)

/datum/controller/subsystem/ticker/proc/HasRoundStarted()
	return current_state >= GAME_STATE_PLAYING


/datum/controller/subsystem/ticker/proc/IsRoundInProgress()
	return current_state == GAME_STATE_PLAYING


/datum/controller/subsystem/ticker/Recover()
	current_state = SSticker.current_state
	force_ending = SSticker.force_ending
	mode = SSticker.mode

	login_music = SSticker.login_music

	delay_end = SSticker.delay_end
	delay_start = SSticker.delay_start

	totalPlayers = SSticker.totalPlayers
	totalPlayersReady = SSticker.totalPlayersReady

	time_left = SSticker.time_left

	queue_delay = SSticker.queue_delay
	queued_players = SSticker.queued_players

	switch(current_state)
		if(GAME_STATE_SETTING_UP)
			Master.SetRunLevel(RUNLEVEL_SETUP)
		if(GAME_STATE_PLAYING)
			Master.SetRunLevel(RUNLEVEL_GAME)
		if(GAME_STATE_FINISHED)
			Master.SetRunLevel(RUNLEVEL_POSTGAME)


/datum/controller/subsystem/ticker/proc/GetTimeLeft()
	if(isnull(SSticker.time_left))
		return round(max(0, start_at - world.time) / 10)
	return round(time_left / 10)


/datum/controller/subsystem/ticker/proc/SetTimeLeft(newtime)
	if(newtime >= 0 && isnull(time_left))	//remember, negative means delayed
		start_at = world.time + newtime
	else
		time_left = newtime


/datum/controller/subsystem/ticker/proc/load_mode()
	var/mode = trim(file2text("data/mode.txt"))
	if(mode)
		GLOB.master_mode = mode
	else
		GLOB.master_mode = "Extended"
	log_game("Saved mode is '[GLOB.master_mode]'")


/datum/controller/subsystem/ticker/proc/save_mode(the_mode)
	var/F = file("data/mode.txt")
	fdel(F)
	WRITE_FILE(F, the_mode)


/datum/controller/subsystem/ticker/proc/Reboot(reason, delay)
	set waitfor = FALSE

	if(usr && !check_rights(R_SERVER))
		return

	if(graceful)
		to_chat_forced(world, "<h3>[SPAN_BOLDNOTICE("Shutting down...")]</h3>")
		world.Reboot(FALSE)
		return

	if(!delay)
		delay = CONFIG_GET(number/round_end_countdown) * 10

	var/skip_delay = check_rights()
	if(delay_end && !skip_delay)
		to_chat(world, SPAN_BOLDNOTICE("An admin has delayed the round end."))
		return

	to_chat(world, SPAN_BOLDNOTICE("Rebooting World in [DisplayTimeText(delay)]. [reason]"))

	var/start_wait = world.time
	sleep(delay - (world.time - start_wait))

	if(delay_end && !skip_delay)
		to_chat(world, SPAN_BOLDNOTICE("Reboot was cancelled by an admin."))
		return

	log_game("Rebooting World. [reason]")
	to_chat_forced(world, "<h3>[SPAN_BOLDNOTICE("Rebooting...")]</h3>")

	world.Reboot(TRUE)

/datum/controller/subsystem/ticker/proc/create_characters()
	if(!RoleAuthority)
		return

	for(var/mob/new_player/player in GLOB.player_list)
		if(!player || !player.ready || !player.mind || !player.job)
			continue

		INVOKE_ASYNC(src, .proc/spawn_and_equip_char, player)

/datum/controller/subsystem/ticker/proc/spawn_and_equip_char(var/mob/new_player/player)
	var/datum/job/J = RoleAuthority.roles_for_mode[player.job]
	var/mob/M = J.spawn_in_player(player)
	if(istype(M))
		J.equip_job(M)
		EquipCustomItems(M)

		if(M.client)
			var/client/C = M.client
			if(C.player_data && C.player_data.playtime_loaded && length(C.player_data.playtimes) == 0)
				msg_admin_niche("NEW PLAYER: <b>[key_name(player, 1, 1, 0)] (<A HREF='?_src_=admin_holder;ahelp=adminmoreinfo;extra=\ref[player]'>?</A>)</b>. IP: [player.lastKnownIP], CID: [player.computer_id]")

	QDEL_IN(player, 5)

/datum/controller/subsystem/ticker/proc/old_create_characters()
	for(var/mob/new_player/player in GLOB.player_list)
		if(!(player && player.ready && player.mind))
			continue

		if(!player.job && !player.mind.roundstart_picked)
			continue

		player.create_character()
		qdel(player)

/datum/controller/subsystem/ticker/proc/equip_characters()
	var/captainless=1
	if(mode && istype(mode,/datum/game_mode/huntergames)) // || istype(mode,/datum/game_mode/whiskey_outpost)
		return

	for(var/mob/living/carbon/human/player in GLOB.human_mob_list)
		if(player.mind)
			if(player.job == "Commanding Officers")
				captainless = FALSE
			if(player.job)
				RoleAuthority.equip_role(player, RoleAuthority.roles_by_name[player.job])
				EquipCustomItems(player)
			if(player.client)
				var/client/C = player.client
				if(C.player_data && C.player_data.playtime_loaded && length(C.player_data.playtimes) == 0)
					msg_admin_niche("NEW PLAYER: <b>[key_name(player, 1, 1, 0)] (<A HREF='?_src_=admin_holder;ahelp=adminmoreinfo;extra=\ref[player]'>?</A>)</b>. IP: [player.lastKnownIP], CID: [player.computer_id]")
	if(captainless)
		for(var/mob/M in GLOB.player_list)
			if(!istype(M,/mob/new_player))
				to_chat(M, "Marine commanding officer position not forced on anyone.")
