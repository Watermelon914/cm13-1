/**
 * Creates a TGUI alert window and returns the user's response.
 *
 * This proc should be used to create alerts that the caller will wait for a response from.
 * Arguments:
 * * user - The user to show the alert to.
 * * message - The content of the alert, shown in the body of the TGUI window.
 * * title - The of the alert modal, shown on the top of the TGUI window.
 * * buttons - The options that can be chosen by the user, each string is assigned a button on the UI.
 * * timeout - The timeout of the alert, after which the modal will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_alert(mob/user, message, title, list/buttons, timeout = 60 SECONDS)
	if (!user)
		user = usr
	if (!istype(user))
		if (istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return
	var/datum/tgui_modal/alert = new(user, message, title, buttons, timeout)
	alert.tgui_interact(user)
	alert.wait()
	if (alert)
		. = alert.choice
		qdel(alert)

/**
 * Creates an asynchronous TGUI alert window with an associated callback.
 *
 * This proc should be used to create alerts that invoke a callback with the user's chosen option.
 * Arguments:
 * * user - The user to show the alert to.
 * * message - The content of the alert, shown in the body of the TGUI window.
 * * title - The of the alert modal, shown on the top of the TGUI window.
 * * buttons - The options that can be chosen by the user, each string is assigned a button on the UI.
 * * callback - The callback to be invoked when a choice is made.
 * * timeout - The timeout of the alert, after which the modal will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_alert_async(mob/user, message, title, list/buttons, datum/callback/callback, timeout = 60 SECONDS)
	if (!user)
		user = usr
	if (!istype(user))
		if (istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return
	var/datum/tgui_modal/async/alert = new(user, message, title, buttons, callback, timeout)
	alert.tgui_interact(user)

/**
 * # tgui_modal
 *
 * Datum used for instantiating and using a TGUI-controlled modal that prompts the user with
 * a message and has buttons for responses.
 */
/datum/tgui_modal
	/// The title of the TGUI window
	var/title
	/// The textual body of the TGUI window
	var/message
	/// The list of buttons (responses) provided on the TGUI window
	var/list/buttons
	/// The button that the user has pressed, null if no selection has been made
	var/choice
	/// The time at which the tgui_modal was created, for displaying timeout progress.
	var/start_time
	/// The lifespan of the tgui_modal, after which the window will close and delete itself.
	var/timeout
	/// Boolean field describing if the tgui_modal was closed by the user.
	var/closed

	var/close_on_choice = TRUE

/datum/tgui_modal/New(mob/user, message, title, list/buttons, timeout)
	src.title = title
	src.message = message
	src.buttons = buttons.Copy()
	if (timeout)
		src.timeout = timeout
		start_time = world.time
		QDEL_REF_IN(src, timeout)

/datum/tgui_modal/Destroy(force, ...)
	SStgui.close_uis(src)
	buttons = null
	. = ..()

/**
 * Waits for a user's response to the tgui_modal's prompt before returning. Returns early if
 * the window was closed by the user.
 */
/datum/tgui_modal/proc/wait()
	while (!choice && !closed)
		stoplag(0.2 SECONDS)

/datum/tgui_modal/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AlertModal")
		ui.open()

/datum/tgui_modal/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_modal/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_modal/ui_data(mob/user)
	. = list(
		"title" = title,
		"message" = message,
		"buttons" = buttons
	)

	if(timeout)
		.["timeout"] = clamp((timeout - (world.time - start_time) - 1 SECONDS) / (timeout - 1 SECONDS), 0, 1)

/datum/tgui_modal/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	switch(action)
		if("choose")
			if (!(params["choice"] in buttons))
				return
			choice = params["choice"]
			if(close_on_choice)
				SStgui.close_uis(src)
			return TRUE

/**
 * # async tgui_modal
 *
 * An asynchronous version of tgui_modal to be used with callbacks instead of waiting on user responses.
 */
/datum/tgui_modal/async
	/// The callback to be invoked by the tgui_modal upon having a choice made.
	var/datum/callback/callback

	close_on_choice = FALSE

/datum/tgui_modal/async/New(mob/user, message, title, list/buttons, callback, timeout)
	..(user, message, title, buttons, timeout)
	src.callback = callback

/datum/tgui_modal/async/Destroy(force, ...)
	QDEL_NULL(callback)
	. = ..()

/datum/tgui_modal/async/ui_close(mob/user)
	. = ..()
	qdel(src)

/datum/tgui_modal/async/ui_act(action, list/params)
	. = ..()
	if (!. || choice == null)
		return
	callback.InvokeAsync(choice)
	SStgui.close_uis(src)

/datum/tgui_modal/async/wait()
	return
