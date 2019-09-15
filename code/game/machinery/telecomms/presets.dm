// ### Preset machines  ###


//var/list/freq_listening = list()  USE THIS FOR NEW RELAY STUFF WHEN I GET THIS - APOPHIS

//Relay
/obj/machinery/telecomms/relay/preset
	network = "tcommsat"

/obj/machinery/telecomms/relay/preset/station
	id = "Station Relay"
	listening_level = 1
	autolinkers = list("s_relay")

/obj/machinery/telecomms/relay/preset/station/prison
	unacidable = 1

/obj/machinery/telecomms/relay/preset/ice_colony
	icon = 'icons/obj/structures/machinery/comm_tower.dmi'
	icon_state = "comm_tower"
	id = "Station Relay"
	listening_level = 1
	autolinkers = list("s_relay")
	unacidable = 1

	//We dont want anyone to mess with it
/obj/machinery/telecomms/relay/preset/ice_colony/attackby()
	return
		
/obj/machinery/telecomms/relay/preset/tower
	name = "TC-4T telecommunications tower"
	icon = 'icons/obj/structures/machinery/comm_tower2.dmi'
	icon_state = "comm_tower"
	desc = "A portable compact TC-4T telecommunications tower. Used to set up subspace communications lines between planetary and extra-planetary locations."
	id = "Station Relay"
	listening_level = 1
	autolinkers = list("s_relay")
	layer = ABOVE_FLY_LAYER
	use_power = 0
	idle_power_usage = 0
	unacidable = 1
	health = 450

/obj/machinery/telecomms/relay/preset/tower/get_explosion_resistance()
	return 1000000

/obj/machinery/telecomms/relay/preset/tower/bullet_act(var/obj/item/projectile/P)
	..()
	if (istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		update_health(50)

	else if (P.ammo.flags_ammo_behavior & AMMO_ANTISTRUCT)
		update_health(P.damage*ANTISTRUCT_DMG_MULT_BARRICADES)

	update_health(round(P.damage/2))

	return TRUE

/obj/machinery/telecomms/relay/preset/tower/update_power()
	if(health <= 0)
		on = FALSE
	else
		on = TRUE

/obj/machinery/telecomms/relay/preset/tower/update_health(var/damage = 0)
	if(damage)
		health -= damage
		health = Clamp(health, 0, initial(health))
	if(health <= 0)
		toggled = FALSE
		desc = "[initial(desc)] [SPAN_WARNING(" It is damaged and needs a welder for repairs!")]"
	else if(health >= (initial(health) / 2))
		toggled = TRUE
	
	if(health < initial(health))
		desc = "[initial(desc)] [SPAN_WARNING(" It is damaged and needs a welder for repairs!")]"
	else
		desc = initial(desc)
	update_icon()

/obj/machinery/telecomms/relay/preset/tower/update_icon()
	if(health <= 0)
		icon_state = "[initial(icon_state)]_broken"
	else if(on)
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]_off"

/obj/machinery/telecomms/relay/preset/tower/attackby(obj/item/I, mob/user)
	if(iswelder(I))
		if(user.action_busy)
			return
		if(!skillcheck(user, SKILL_ENGINEER, SKILL_ENGINEER_METAL))
			to_chat(user, SPAN_WARNING("You're not trained to repair [src]..."))
			return
		var/obj/item/tool/weldingtool/WT = I

		if(health >= initial(health))
			to_chat(user, SPAN_WARNING("[src] doesn't need repairs."))
			return

		if(WT.remove_fuel(0, user))
			user.visible_message(SPAN_NOTICE("[user] begins repairing damage to [src]."),
			SPAN_NOTICE("You begin repairing the damage to [src]."))
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			if(do_after(user, 50, INTERRUPT_ALL, BUSY_ICON_FRIENDLY, src))
				user.visible_message(SPAN_NOTICE("[user] repairs some damage on [src]."),
				SPAN_NOTICE("You repair [src]."))
				update_health(-150)
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
		return
		
		if(ismultitool(I))
			return
	else return ..()

/obj/machinery/telecomms/relay/preset/telecomms
	id = "Telecomms Relay"
	autolinkers = list("relay")

/obj/machinery/telecomms/relay/preset/mining
	id = "Mining Relay"
	autolinkers = list("m_relay")

/obj/machinery/telecomms/relay/preset/ruskie
	id = "Ruskie Relay"
	hide = 1
	toggled = 0
	autolinkers = list("r_relay")

/obj/machinery/telecomms/relay/preset/centcom
	id = "Centcom Relay"
	hide = 1
	toggled = 1
	produces_heat = 0
	use_power = 0
	autolinkers = list("c_relay")

//HUB

/obj/machinery/telecomms/hub/preset
	id = "Hub"
	network = "tcommsat"
	autolinkers = list("hub", "relay", "s_relay", "medical",
		"common", "command", "engineering", "squads", "security",
		"receiverA", "receiverB",  "broadcasterA", "broadcasterB")

/obj/machinery/telecomms/hub/preset_cent
	id = "CentComm Hub"
	network = "tcommsat"
	produces_heat = 0
	autolinkers = list("hub_cent", "relay", "c_relay", "s_relay", "centcomm", "receiverCent", "broadcasterCent")

//Receivers

//--PRESET LEFT--//


/obj/machinery/telecomms/receiver/preset_left
	id = "Receiver A"
	network = "tcommsat"
	autolinkers = list("receiverA") // link to relay
	freq_listening = list(ALPHA_FREQ, BRAVO_FREQ, CHARLIE_FREQ, DELTA_FREQ)

//--PRESET RIGHT--//

/obj/machinery/telecomms/receiver/preset
	id = "Receiver B"
	network = "tcommsat"
	autolinkers = list("receiverB") // link to relay
	freq_listening = list(COMM_FREQ, ENG_FREQ, SEC_FREQ, MED_FREQ, CIV_GEN_FREQ, CIV_COMM_FREQ, SUP_FREQ, ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ, JTAC_FREQ, INTEL_FREQ)

	//Common and other radio frequencies for people to freely use
	New()
		for(var/i = 1441, i < 1489, i += 2)
			freq_listening |= i
		..()

/obj/machinery/telecomms/receiver/preset_cent
	id = "CentComm Receiver"
	network = "tcommsat"
	produces_heat = 0
	autolinkers = list("receiverCent")
	freq_listening = list(ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ)


//Buses

/obj/machinery/telecomms/bus/preset_one
	id = "Bus 1"
	network = "tcommsat"
	freq_listening = list(MED_FREQ, ENG_FREQ, SUP_FREQ)
	autolinkers = list("processor1", "medical", "engineering", "cargo")

/obj/machinery/telecomms/bus/preset_two
	id = "Bus 2"
	network = "tcommsat"
	freq_listening = list(ALPHA_FREQ, BRAVO_FREQ, CHARLIE_FREQ, DELTA_FREQ)
	autolinkers = list("processor2","squads")

/obj/machinery/telecomms/bus/preset_three
	id = "Bus 3"
	network = "tcommsat"
	freq_listening = list(SEC_FREQ, COMM_FREQ, ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ, JTAC_FREQ, INTEL_FREQ)
	autolinkers = list("processor3", "security", "command", "JTAC")

/obj/machinery/telecomms/bus/preset_four
	id = "Bus 4"
	network = "tcommsat"
	freq_listening = list(CIV_GEN_FREQ)
	autolinkers = list("processor4", "common")

/obj/machinery/telecomms/bus/preset_four/New()
	for(var/i = 1441, i < 1489, i += 2)
		freq_listening |= i
	..()

/obj/machinery/telecomms/bus/preset_cent
	id = "CentComm Bus"
	network = "tcommsat"
	freq_listening = list(ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ)
	produces_heat = 0
	autolinkers = list("processorCent", "centcomm")

//Processors

/obj/machinery/telecomms/processor/preset_one
	id = "Processor 1"
	network = "tcommsat"
	autolinkers = list("processor1") // processors are sort of isolated; they don't need backward links

/obj/machinery/telecomms/processor/preset_two
	id = "Processor 2"
	network = "tcommsat"
	autolinkers = list("processor2")

/obj/machinery/telecomms/processor/preset_three
	id = "Processor 3"
	network = "tcommsat"
	autolinkers = list("processor3")

/obj/machinery/telecomms/processor/preset_four
	id = "Processor 4"
	network = "tcommsat"
	autolinkers = list("processor4")

/obj/machinery/telecomms/processor/preset_cent
	id = "CentComm Processor"
	network = "tcommsat"
	produces_heat = 0
	autolinkers = list("processorCent")

//Servers

/obj/machinery/telecomms/server/presets

	network = "tcommsat"

/obj/machinery/telecomms/server/presets/squads
	id = "Squad Server"
	freq_listening = list(ALPHA_FREQ, BRAVO_FREQ, CHARLIE_FREQ, DELTA_FREQ)
	autolinkers = list("squads")

/obj/machinery/telecomms/server/presets/medical
	id = "Medical Server"
	freq_listening = list(MED_FREQ)
	autolinkers = list("medical")
/*
/obj/machinery/telecomms/server/presets/supply
	id = "Supply Server"
	freq_listening = list(SUP_FREQ)
	autolinkers = list("supply")
*/
/obj/machinery/telecomms/server/presets/common
	id = "Common Server"
	freq_listening = list()
	autolinkers = list("common")

	//Common and other radio frequencies for people to freely use
	// 1441 to 1489
/obj/machinery/telecomms/server/presets/common/New()
	for(var/i = 1441, i < 1489, i += 2)
		freq_listening |= i
	..()

/obj/machinery/telecomms/server/presets/command
	id = "Command Server"
	freq_listening = list(COMM_FREQ, ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ, JTAC_FREQ, INTEL_FREQ)
	autolinkers = list("command")

/obj/machinery/telecomms/server/presets/engineering
	id = "Engineering Server"
	freq_listening = list(ENG_FREQ, SUP_FREQ)
	autolinkers = list("engineering", "cargo")

/obj/machinery/telecomms/server/presets/security
	id = "Security Server"
	freq_listening = list(SEC_FREQ)
	autolinkers = list("security")

/obj/machinery/telecomms/server/presets/centcomm
	id = "CentComm Server"
	freq_listening = list(ERT_FREQ, DTH_FREQ, PMC_FREQ, DUT_FREQ, YAUT_FREQ)
	produces_heat = 0
	autolinkers = list("centcomm")


//Broadcasters

//--PRESET LEFT--//

/obj/machinery/telecomms/broadcaster/preset_left
	id = "Broadcaster A"
	network = "tcommsat"
	autolinkers = list("broadcasterA")

//--PRESET RIGHT--//

/obj/machinery/telecomms/broadcaster/preset_right
	id = "Broadcaster B"
	network = "tcommsat"
	autolinkers = list("broadcasterB")

/obj/machinery/telecomms/broadcaster/preset_cent
	id = "CentComm Broadcaster"
	network = "tcommsat"
	produces_heat = 0
	autolinkers = list("broadcasterCent")

/*
	Basically just an empty shell for receiving and broadcasting radio messages. Not
	very flexible, but it gets the job done.
*/

/obj/machinery/telecomms/allinone
	name = "Telecommunications Mainframe"
	icon = 'icons/obj/structures/props/stationobjs.dmi'
	icon_state = "comm_server"
	desc = "A compact machine used for portable subspace telecommuniations processing."
	density = 1
	anchored = 1
	use_power = 0
	idle_power_usage = 0
	machinetype = 6
	produces_heat = 0
	unacidable = 1
	var/intercept = 0 // if nonzero, broadcasts all messages to syndicate channel

/obj/machinery/telecomms/allinone/interceptor
	name = "Message Intercept Mainframe"
	intercept = 1
	freq_listening = list(SYND_FREQ, RUS_FREQ)

/obj/machinery/telecomms/allinone/receive_signal(datum/signal/signal)

	if(!on) // has to be on to receive messages
		return

	if(is_freq_listening(signal)) // detect subspace signals

		signal.data["done"] = 1 // mark the signal as being broadcasted
		signal.data["compression"] = 0

		// Search for the original signal and mark it as done as well
		var/datum/signal/original = signal.data["original"]
		if(original)
			original.data["done"] = 1

		if(signal.data["slow"] > 0)
			sleep(signal.data["slow"]) // simulate the network lag if necessary

		/* ###### Broadcast a message using signal.data ###### */

		var/datum/radio_frequency/connection = signal.data["connection"]

		if(connection.frequency in ANTAG_FREQS) // if antag broadcast, just
			Broadcast_Message(signal.data["connection"], signal.data["mob"],
							  signal.data["vmask"], signal.data["vmessage"],
							  signal.data["radio"], signal.data["message"],
							  signal.data["name"], signal.data["job"],
							  signal.data["realname"], signal.data["vname"],, signal.data["compression"], list(0), connection.frequency,
							  signal.data["verb"], signal.data["language"])
		else
			if(intercept)
				Broadcast_Message(signal.data["connection"], signal.data["mob"],
							  signal.data["vmask"], signal.data["vmessage"],
							  signal.data["radio"], signal.data["message"],
							  signal.data["name"], signal.data["job"],
							  signal.data["realname"], signal.data["vname"], 3, signal.data["compression"], list(0), connection.frequency,
							  signal.data["verb"], signal.data["language"])