Gamemode Manager
================

A plugin for SourceMod that helps load gamemodes.

Features
--------

* unloads all other gamemodes before loading chosen gamemode to avoid conflicts
* changes gamemode for next map at current map's end
* works well with Ultimate Mapchooser (using `postvote-command` as `sm_nextgamemode <gamemode>`)

Usage
-----

**CVars**

* `gamemode_manager_version` - Gamemode Manager version
* `gamemode_manager_use_default <0|1>` - how map change should be handled if no gamemode was specifically set (0 - use gamemode of current map, 1 - use default gamemode specified by `gamemode_manager_default_gamemode`)
* `gamemode_manager_default_gamemode <gamemode>` - the default gamemode to be loaded each map (for `gamemode_manager_use_default 1`)
* `gamemode_manager_debug <0|1>` - turns on debugging and action logging

**Commands**
* `sm_reloadgamemodes` - reload game modes from file config
* `sm_nextgamemode [gamemode]` - get/set the next map's gamemode

Configuration
-------------

```
"gamemodes"
{
	"vanilla"											// a gamemode included by default that unloads all other gamemodes when run
	{
	}
	
	"super-awesome-nonexistent-gamemode"				// name of the gamemode - to use the gamemode, you would issue `sm_nextgamemode super-awesome-nonexistent-gamemode`
	{
		"plugins"										// these plugins will be moved to disabled/ and unloaded when gamemode is unloaded and moved to main plugin folder and loaded when gamemode is loaded
		{
			"1"	"important-dependency.smx"				// load/unload dependency first
			"2"	"gamemode/super-awesome-gamemode.smx"	// include full path to plugin - needed to move plugin between disabled and main plugin folder
			"3"	"gamemode/gamemode-modifier.smx"		// load plugin that depends on the gamemode last
		}
		
		"enable-commands"								// these commands will be executed in the order they are written after the plugins are loaded when the gamemode is loading
		{
			"1"	"super_gamemode_enabled 1"
			"2"	"super_gamemode_type 3"
			"3"	"gamemode_modifier 5.0"
		}
		
		"disable-commands"								// these commands will be executed in the order they are written before the plugins are unloaded when the gamemode is unloading
		{
			"1"	"super_gamemode_enabled 0"
		}
	}
}
```

Requirements
------------

* SourceMod

Changelog
---------

**1.0.0** (2013-09-22)
* initial release

Installation
------------

1. Place `plugins/gamemode-manager.cfg` in your `plugins` directory.
2. Edit `configs/gamemodes.cfg` appropriately and place it in your `configs` directory.