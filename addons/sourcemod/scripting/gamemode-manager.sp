#include <sourcemod>

#define VERSION "0.0.1"

public Plugin:myinfo = 
{
	name = "Gamemode Manager",
	author = "thesupremecommander",
	description = "A plugin to help automate gamemode shuffling on a multimod server.",
	version = VERSION,
	url = "http://steamcommunity.com/groups/fwdcp"
};

new Handle:hConfig;

new Handle:hDefaultOption;
new Handle:hDefaultGamemode;

new bool:bDebug;

new String:sNextGamemode[255];

public OnPluginStart()
{
	CreateConVar("gamemode_manager_version", VERSION, "Gamemode Manager version", FCVAR_PLUGIN|FCVAR_CHEAT|FCVAR_DONTRECORD);
	hDefaultOption = CreateConVar("gamemode_manager_use_default", "1", "how map change should be handled if no gamemode was specifically set (0 - use gamemode of current map, 1 - use default gamemode specified by gamemode_manager_default_gamemode)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hDefaultGamemode = CreateConVar("gamemode_manager_default_gamemode", "vanilla", "the default gamemode to be loaded each map (for gamemode_manager_use_default 1)", FCVAR_PLUGIN);
	new Handle:hDebug = CreateConVar("gamemode_manager_debug", "0", "turns on debugging and action logging", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	HookConVarChange(hDebug, ToggleDebugging);
	
	AutoExecConfig();
	
	RegAdminCmd("sm_reloadgamemodes", ReloadGamemodes, ADMFLAG_CONFIG, "reload game modes from config");
	RegAdminCmd("sm_nextgamemode", NextGamemode, ADMFLAG_CONFIG, "get/set the next map's gamemode");
	
	LoadGamemodeConfig();
}

public ToggleDebugging(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (StringToInt(newValue) == 0) {
		bDebug = false;
	}
	else {
		bDebug = true;
	}
}

public Action:ReloadGamemodes(client, args) {
	LoadGamemodeConfig();
}

public Action:NextGamemode(client, args) {
	if (args == 0) {
		ReplyToCommand(client, "Gamemode for next map will be '%s'.", sNextGamemode);
		
		return Plugin_Handled;
	}
	else {
		decl String:sGamemode[255];
		GetCmdArg(1, sGamemode, sizeof(sGamemode));
		
		KvRewind(hConfig);
		
		if (!KvJumpToKey(hConfig, sGamemode)) {
			ReplyToCommand(client, "Gamemode '%s' not found in config!", sNextGamemode);
			if (bDebug) {
				LogMessage("Gamemode '%s' not found in config!", sNextGamemode);
			}
		}
		else {
			strcopy(sNextGamemode, sizeof(sNextGamemode), sGamemode);
			ReplyToCommand(client, "Gamemode for next map set to '%s'.", sNextGamemode);
			if (bDebug) {
				LogMessage("Gamemode for next map set to '%s'.", sNextGamemode);
			}
		}
		
		KvRewind(hConfig);
		
		return Plugin_Handled;
	}
}

public OnMapEnd() {
	LoadGamemode(sNextGamemode);
	
	if (GetConVarInt(hDefaultOption) == 1) {
		decl String:sDefaultGamemode[255];
		GetConVarString(hDefaultGamemode, sDefaultGamemode, sizeof(sDefaultGamemode));
		strcopy(sNextGamemode, sizeof(sNextGamemode), sDefaultGamemode);
	}
}

LoadGamemodeConfig() {
	decl String:sConfigPath[255];
	
	BuildPath(PathType:FileType_File, sConfigPath, sizeof(sConfigPath), "configs/gamemodes.cfg");

	hConfig = CreateKeyValues("gamemodes");
	if (!FileToKeyValues(hConfig, sConfigPath)) {
		SetFailState("Config could not be loaded!");
	}
	else {
		if (bDebug) {
			LogMessage("Gamemode config loaded.");
		}
	}
}

LoadGamemode(const String:sGamemode[]) {
	KvRewind(hConfig);
	KvGotoFirstSubKey(hConfig);
	
	do {
		decl String:sGamemodeSection[255];
		
		KvGetSectionName(hConfig, sGamemodeSection, sizeof(sGamemodeSection));
		
		if (!StrEqual(sGamemode, sGamemodeSection)) {
			if (bDebug) {
				LogMessage("Unloading gamemode: %s", sGamemodeSection);
			}
			if (KvJumpToKey(hConfig, "disable-commands")) {
				KvGotoFirstSubKey(hConfig, false);
				
				do {
					if (KvGetDataType(hConfig, NULL_STRING) == KvData_String) {
						decl String:sCommand[255];
						
						KvGetString(hConfig, NULL_STRING, sCommand, sizeof(sCommand));
						ServerCommand("%s", sCommand);
					}
				} while (KvGotoNextKey(hConfig));
				
				KvGoBack(hConfig);
				KvGoBack(hConfig);
			}
			if (KvJumpToKey(hConfig, "plugins")) {
				KvGotoFirstSubKey(hConfig, false);
				
				do {
					if (KvGetDataType(hConfig, NULL_STRING) == KvData_String) {
						decl String:sPlugin[255];
						decl String:sPluginPath[511];
						
						KvGetString(hConfig, NULL_STRING, sPlugin, sizeof(sPlugin));
						BuildPath(PathType:FileType_File, sPluginPath, sizeof(sPluginPath), "plugins/%s", sPlugin);
						
						decl String:sDisabledPluginPath[511];
						BuildPath(PathType:FileType_File, sDisabledPluginPath, sizeof(sDisabledPluginPath), "plugins/disabled/%s", sPlugin);
						
						ServerCommand("sm plugins unload %s", sPlugin);
						
						if (FileExists(sPluginPath)) {
							RenameFile(sDisabledPluginPath, sPluginPath);
						}
					}
				} while (KvGotoNextKey(hConfig));
				
				KvGoBack(hConfig);
				KvGoBack(hConfig);
			}
		}
	} while (KvGotoNextKey(hConfig));
	
	KvGoBack(hConfig);
	
	if (KvJumpToKey(hConfig, sGamemode)) {
		if (bDebug) {
			LogMessage("Loading gamemode: %s", sGamemode);
		}
		if (KvJumpToKey(hConfig, "plugins")) {
			KvGotoFirstSubKey(hConfig, false);
			
			do {
				if (KvGetDataType(hConfig, NULL_STRING) == KvData_String) {
					decl String:sPlugin[255];
					decl String:sPluginPath[511];
					
					KvGetString(hConfig, NULL_STRING, sPlugin, sizeof(sPlugin));
					BuildPath(PathType:FileType_File, sPluginPath, sizeof(sPluginPath), "plugins/%s", sPlugin);
					
					decl String:sDisabledPluginPath[511];
					BuildPath(PathType:FileType_File, sDisabledPluginPath, sizeof(sDisabledPluginPath), "plugins/disabled/%s", sPlugin);
					
					if (FileExists(sDisabledPluginPath)) {
						RenameFile(sPluginPath, sDisabledPluginPath);
					}
					
					ServerCommand("sm plugins load %s", sPlugin);
				}
			} while (KvGotoNextKey(hConfig));
			
			KvGoBack(hConfig);
			KvGoBack(hConfig);
		}
		if (KvJumpToKey(hConfig, "enable-commands")) {
			KvGotoFirstSubKey(hConfig, false);
			
			do {
				if (KvGetDataType(hConfig, NULL_STRING) == KvData_String) {
					decl String:sCommand[255];
					
					KvGetString(hConfig, NULL_STRING, sCommand, sizeof(sCommand));
					ServerCommand("%s", sCommand);
				}
			} while (KvGotoNextKey(hConfig));
			
			KvGoBack(hConfig);
			KvGoBack(hConfig);
		}
	}
	
	KvRewind(hConfig);
}