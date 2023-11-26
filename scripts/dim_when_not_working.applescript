#!/usr/bin/osascript

-- reading calendar is from:
-- https://www.macscripter.net/t/faster-way-to-find-a-calendar-event/69257/5
-- Setting greyscale is from:
-- https://stackoverflow.com/questions/75152094/applescript-ventura-toggle-accessibility-grayscale-on-off

use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "EventKit"

set listOfCalNames to {} -- list of one or more calendar names

--gain access to Event Kit.
set theEKEventStore to create_event_store_access()

--if no access is allowed to Event Kit, then exit script
if theEKEventStore is false then return

-- get calendars that can store events
set theCalendars to theEKEventStore's calendarsForEntityType:0

repeat
  checkGreyscale(listOfCalNames, theCalendars, theEKEventStore)
	delay 1
end repeat

on checkGreyscale(listOfCalNames, theCalendars, theEKEventStore)
	-- prepare times
	set nowDate to current application's NSDate's |date|()

	-- filter the find to events in the  calendar  named "Home"
	set theNSPredicate to current application's NSPredicate's predicateWithFormat_("title IN %@", listOfCalNames)
	set calsToSearch to theCalendars's filteredArrayUsingPredicate:theNSPredicate

	-- find matching events
	set thePred to theEKEventStore's predicateForEventsWithStartDate:nowDate endDate:nowDate calendars:calsToSearch
	set theEvents to (theEKEventStore's eventsMatchingPredicate:thePred)

	-- sort by date
	set theEvents to (theEvents's sortedArrayUsingSelector:("compareStartDateWithEvent:" as list))
	-- read isGreyScale
	set isGreyScale to do shell script "defaults read com.apple.universalaccess grayscale -bool"
	set prohibitedEmoji to ((character id 128683) as Unicode text)
	set currentlyProhibited to false
	-- log prohibitedString
	repeat with index from 1 to length of (theEvents as list)
		set theCurrentEvent to item index of (theEvents as list)
		-- Process the current event itemexit repeat
		set theCurrentEventTitle to (theCurrentEvent's title as Unicode text)
		-- log theCurrentEventTitle
		if theCurrentEventTitle contains prohibitedEmoji then
			-- log "currentlyProhibited"
			set currentlyProhibited to true
			if isGreyScale is equal to "0" then
				toggleGreyscale()
			end if
			exit repeat
		end if
	end repeat

	if not currentlyProhibited then
		if isGreyScale is equal to "1" then
			toggleGreyscale()
		end if
		-- log "Not currently prohibited"
	end if
end checkGreyscale

on toggleGreyscale()
  -- log "toggling greyscale"
	current application's NSWorkspace's sharedWorkspace()'s openURL:(current application's NSURL's URLWithString:"x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Display")
	tell application "System Events" to tell application process "System Settings"
		repeat until exists window "Display"
		end repeat
		set colourFiltersGroup to group 4 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Display"
		set filterTypePopup to pop up button 1 of colourFiltersGroup
		click filterTypePopup
		click menu item 1 of menu 1 of filterTypePopup
		click checkbox 1 of colourFiltersGroup
	end tell
	if application "System Settings" is running then
		tell application "System Settings" to quit
	end if
end toggleGreyscale

--sub routine to gain access to  Event Kit
on create_event_store_access()

	-- create event store and get the OK to access Calendars
	set theEKEventStore to current application's EKEventStore's alloc()'s init()
	theEKEventStore's requestAccessToEntityType:0 completion:(missing value)

	-- check if app has access; this will still occur the first time you OK authorization
	set authorizationStatus to current application's EKEventStore's authorizationStatusForEntityType:0 -- work around enum bug
	if authorizationStatus is not 3 then
		display dialog "Access must be given in System Preferences" & linefeed & "-> Security & Privacy first." buttons {"OK"} default button 1
		tell application "System Settings"
			activate
			tell pane id "com.apple.preference.security" to reveal anchor "Privacy"
		end tell
		error number -128
		false
	else
		theEKEventStore
	end if
end create_event_store_access
