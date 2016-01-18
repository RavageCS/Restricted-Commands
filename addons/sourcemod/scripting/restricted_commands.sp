// Plugin definitions
#define PLUGIN_VERSION "2.0.0"
#pragma semicolon 1
#include <sourcemod>

new String:sound[512];
char soundBuffer[512];
new String:soundString[512];

new Handle:g_plugin_enabled = INVALID_HANDLE;
new Handle:g_sound_enabled = INVALID_HANDLE;
new Handle:g_message_enabled = INVALID_HANDLE;
new Handle:g_sound = INVALID_HANDLE;

new bool:g_LoggedFileName = false;			/* Whether or not the file name has been logged */
new g_ErrorCount = 0;						/* Current error count */
new g_CurrentLine = 0;						/* Current line we're on */
new String:g_Filename[PLATFORM_MAX_PATH];	/* Used for error messages */

public Plugin:myinfo =
{
	name = "[CS:GO]Restricted Commands",
	author = "Gdk",
	version = PLUGIN_VERSION,
	description = "Plays a negative sound and or message when players type a restricted command",
	url = "https://topsecretgaming.net"
};

public OnPluginStart()
{
	LoadTranslations("restrictedcommands.phrases");
	ReadCommands();
	g_plugin_enabled = CreateConVar("sm_restricted_commands_enabled", "1", "Whether plugin is enabled");
	g_sound_enabled = CreateConVar("sm_restricted_commands_sound_enabled", "1", "Whether a sound should be played");
	g_message_enabled = CreateConVar("sm_restricted_commands_message_enabled", "1", "Whether a message should be shown");
	g_sound = CreateConVar("sm_restricted_commands_sound", "random", "Game sound to play. Examples: error.wav, /buttons/weapon_cant_buy.wav, /player/vo/fbihrt/radiobotreponsenegative09.wav");

	GetConVarString(g_sound, sound, sizeof(sound));
	Format(soundBuffer, sizeof(soundBuffer), "playgamesound %s", sound);
	GetConVarString(g_sound, soundString, sizeof(soundString));

	HookConVarChange(g_plugin_enabled, OnConvarChanged);
  	HookConVarChange(g_sound_enabled, OnConvarChanged);
  	HookConVarChange(g_message_enabled, OnConvarChanged);
  	HookConVarChange(g_sound, OnConvarChanged);	

	AutoExecConfig(true, "restricted_commands", "sourcemod");
}

public OnConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_plugin_enabled)
  	{
    		if (newValue[0] == '1')
    		{
			SetConVarInt(convar, 1);
    		}	
  	}
	if (convar == g_sound_enabled)
  	{
    		if (newValue[0] == '1')
    		{
			SetConVarInt(convar, 1);
    		}
  	}
	if (convar == g_message_enabled)
  	{
    		if (newValue[0] == '1')
    		{
			SetConVarInt(convar, 1);
    		}
  	}
	if (convar == g_sound)
  	{
    		GetConVarString(g_sound, sound, sizeof(sound));
		Format(soundBuffer, sizeof(soundBuffer), "playgamesound %s", sound);
		GetConVarString(g_sound, soundString, sizeof(soundString));
  	}
}

RegCommands(const String:line[])
{
	RegConsoleCmd(line, Command_RestrictedCommand);
}

public Action Command_RestrictedCommand(int client, int args) 
{
	//Testing
	//PrintToChatAll("sound: %s", sound);
	//PrintToChatAll("soundBuffer: %s", soundBuffer);
	//PrintToChatAll("soundString: %s", soundString);
	if(GetConVarBool(g_plugin_enabled))
	{
		if(GetConVarBool(g_sound_enabled))
		{
			if(StrEqual(soundString, "random", false))
			{
				int num = GetRandomInt(1, 112);
				randSound(num);
				ClientCommand(client, sound);
			}
			else
			{
				ClientCommand(client, soundBuffer);
			}
		}
		if(GetConVarBool(g_message_enabled))
		{
			PrintToChat(client, "%t", "restricted");
		}
	}
	return Plugin_Handled;
}

public ReadCommands()
{
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/restricted_commands.ini");
	
	File file = OpenFile(g_Filename, "rt");
	if (!file)
	{
		ParseError("Could not open file!");
		return;
	}
	
	while (!file.EndOfFile())
	{
		char line[255];
		if (!file.ReadLine(line, sizeof(line)))
			break;
		
		/* Trim comments */
		int len = strlen(line);
		bool ignoring = false;
		for (int i=0; i<len; i++)
		{
			if (ignoring)
			{
				if (line[i] == '"')
					ignoring = false;
			} else {
				if (line[i] == '"')
				{
					ignoring = true;
				} else if (line[i] == ';') {
					line[i] = '\0';
					break;
				} else if (line[i] == '/'
							&& i != len - 1
							&& line[i+1] == '/')
				{
					line[i] = '\0';
					break;
				}
			}
		}
		
		TrimString(line);
		
		if ((line[0] == '/' && line[1] == '/')
			|| (line[0] == ';' || line[0] == '\0'))
		{
			continue;
		}
	
		RegCommands(line);
	}
	
	file.Close();
}

ParseError(const String:format[], any:...)
{
	decl String:buffer[512];
	
	if (!g_LoggedFileName)
	{
		LogError("Error(s) detected parsing %s", g_Filename);
		g_LoggedFileName = true;
	}
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogError(" (line %d) %s", g_CurrentLine, buffer);
	
	g_ErrorCount++;
}

public randSound(int num)
{
	if(num == 1)
		sound = "playgamesound player/vo/balkan/negative01.wav";
	if(num == 2)
		sound = "playgamesound player/vo/balkan/negative02.wav";
	if(num == 3)
		sound = "playgamesound player/vo/balkan/negative04.wav";
	if(num == 4)
		sound = "playgamesound player/vo/balkan/negative03.wav";
	if(num == 5)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative08.wav";
	if(num == 6)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative10.wav";
	if(num == 7)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative12.wav";
	if(num == 8)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative11.wav";
	if(num == 9)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative06.wav";
	if(num == 10)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative09.wav";
	if(num == 11)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative03.wav";
	if(num == 12)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative07.wav";
	if(num == 13)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative04.wav";
	if(num == 14)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative01.wav";
	if(num == 15)
		sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative05.wav";
	if(num == 16)
		sound = "playgamesound player/vo/gsg9/negative01.wav";
	if(num == 17)
		sound = "playgamesound player/vo/gsg9/disagree04.wav";
	if(num == 18)
		sound = "playgamesound player/vo/gsg9/negative02.wav";
	if(num == 19)
		sound = "playgamesound player/vo/gsg9/disagree01.wav";
	if(num == 20)
		sound = "playgamesound player/vo/gsg9/disagree02.wav";
	if(num == 21)
		sound = "playgamesound player/vo/gsg9/negative04.wav";
	if(num == 22)
		sound = "playgamesound player/vo/gsg9/negative03.wav";
	if(num == 23)
		sound = "playgamesound player/vo/sas/negative01.wav";
	if(num == 24)
		sound = "playgamesound player/vo/sas/negative05.wav";
	if(num == 25)
		sound = "playgamesound player/vo/sas/negative02.wav";
	if(num == 26)
		sound = "playgamesound player/vo/sas/disagree01.wav";
	if(num == 27)
		sound = "playgamesound player/vo/sas/disagree02.wav";
	if(num == 28)
		sound = "playgamesound player/vo/sas/negative06.wav";
	if(num == 29)
		sound = "playgamesound player/vo/sas/negative04.wav";
	if(num == 30)
		sound = "playgamesound player/vo/sas/negative03.wav";
	if(num == 31)
		sound = "playgamesound player/vo/pirate/negativeno05.wav";
	if(num == 32)
		sound = "playgamesound player/vo/pirate/negativeno04.wav";
	if(num == 33)
		sound = "playgamesound player/vo/pirate/negative01.wav";
	if(num == 34)
		sound = "playgamesound player/vo/pirate/disagree03.wav";
	if(num == 35)
		sound = "playgamesound player/vo/pirate/disagree04.wav";
	if(num == 36)
		sound = "playgamesound player/vo/pirate/negative02.wav";
	if(num == 37)
		sound = "playgamesound player/vo/pirate/disagree01.wav";
	if(num == 38)
		sound = "playgamesound player/vo/pirate/disagree02.wav";
	if(num == 39)
		sound = "playgamesound player/vo/pirate/negative04.wav";
	if(num == 40)
		sound = "playgamesound player/vo/pirate/negative03.wav";
	if(num == 41)
		sound = "playgamesound player/vo/gign/disagree06.wav";
	if(num == 42)
		sound = "playgamesound player/vo/gign/negative01.wav";
	if(num == 43)
		sound = "playgamesound player/vo/gign/negative05.wav";
	if(num == 44)
		sound = "playgamesound player/vo/gign/disagree03.wav";
	if(num == 45)
		sound = "playgamesound player/vo/gign/negative02.wav";
	if(num == 46)
		sound = "playgamesound player/vo/gign/disagree01.wav";
	if(num == 47)
		sound = "playgamesound player/vo/gign/disagree02.wav";
	if(num == 48)
		sound = "playgamesound player/vo/gign/disagree05.wav";
	if(num == 49)
		sound = "playgamesound player/vo/gign/negative04.wav";
	if(num == 50)
		sound = "playgamesound player/vo/gign/negative03.wav";
	if(num == 51)
		sound = "playgamesound player/vo/gign/disagree07.wav";
	if(num == 52)
		sound = "playgamesound player/vo/gign/disagree10.wav";
	if(num == 53)
		sound = "playgamesound player/vo/anarchist/negativeno05.wav";
	if(num == 54)
		sound = "playgamesound player/vo/anarchist/negativeno04.wav";
	if(num == 55)
		sound = "playgamesound player/vo/anarchist/negative01.wav";
	if(num == 56)
		sound = "playgamesound player/vo/anarchist/negative02.wav";
	if(num == 57)
		sound = "playgamesound player/vo/anarchist/negative04.wav";
	if(num == 58)
		sound = "playgamesound player/vo/anarchist/negative03.wav";
	if(num == 59)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative08.wav";
	if(num == 60)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative10.wav";
	if(num == 61)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative19.wav";
	if(num == 62)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative14.wav";
	if(num == 63)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative12.wav";
	if(num == 64)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative06.wav";
	if(num == 65)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative09.wav";
	if(num == 66)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative03.wav";
	if(num == 67)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative07.wav";
	if(num == 68)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative01.wav";
	if(num == 69)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative02.wav";
	if(num == 70)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative05.wav";
	if(num == 71)
		sound = "playgamesound player/vo/professional/radiobotreponsenegative16.wav";
	if(num == 72)
		sound = "playgamesound player/vo/separatist/negative01.wav";
	if(num == 73)
		sound = "playgamesound player/vo/separatist/disagree04.wav";
	if(num == 74)
		sound = "playgamesound player/vo/separatist/negative02.wav";
	if(num == 75)
		sound = "playgamesound player/vo/separatist/negative04.wav";
	if(num == 76)
		sound = "playgamesound player/vo/separatist/negative03.wav";
	if(num == 77)
		sound = "playgamesound player/vo/leet/negativeno04.wav";
	if(num == 78)
		sound = "playgamesound player/vo/leet/negative01.wav";
	if(num == 79)
		sound = "playgamesound player/vo/leet/negativeno03.wav";
	if(num == 80)
		sound = "playgamesound player/vo/leet/negative02.wav";
	if(num == 81)
		sound = "playgamesound player/vo/leet/disagree01.wav";
	if(num == 82)
		sound = "playgamesound player/vo/leet/negative04.wav";
	if(num == 83)
		sound = "playgamesound player/vo/leet/negative03.wav";
	if(num == 84)
		sound = "playgamesound player/vo/idf/negative01.wav";
	if(num == 85)
		sound = "playgamesound player/vo/idf/disagree03.wav";
	if(num == 86)
		sound = "playgamesound player/vo/idf/negative02.wav";
	if(num == 87)
		sound = "playgamesound player/vo/idf/disagree01.wav";
	if(num == 88)
		sound = "playgamesound player/vo/idf/disagree02.wav";
	if(num == 89)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative08.wav";
	if(num == 90)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative10.wav";
	if(num == 91)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative06.wav";
	if(num == 92)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative09.wav";
	if(num == 93)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative03.wav";
	if(num == 94)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative07.wav";
	if(num == 95)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative01.wav";
	if(num == 96)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative02.wav";
	if(num == 97)
		sound = "playgamesound player/vo/swat/radiobotreponsenegative05.wav";
	if(num == 98)
		sound = "playgamesound player/vo/seal/negative01.wav";
	if(num == 99)
		sound = "playgamesound player/vo/seal/disagree03.wav";
	if(num == 100)
		sound = "playgamesound player/vo/seal/disagree04.wav";
	if(num == 101)
		sound = "playgamesound player/vo/seal/negative02.wav";
	if(num == 102)
		sound = "playgamesound player/vo/seal/disagree01.wav";
	if(num == 103)
		sound = "playgamesound player/vo/seal/disagree02.wav";
	if(num == 104)
		sound = "playgamesound player/vo/seal/disagree05.wav";
	if(num == 105)
		sound = "playgamesound player/vo/seal/negative04.wav";
	if(num == 106)
		sound = "playgamesound player/vo/seal/negative03.wav";
	if(num == 107)
		sound = "playgamesound player/vo/phoenix/negativeno05.wav";
	if(num == 108)
		sound = "playgamesound player/vo/phoenix/negative01.wav";
	if(num == 109)
		sound = "playgamesound player/vo/phoenix/negative02.wav";
	if(num == 110)
		sound = "playgamesound player/vo/phoenix/disagree01.wav";
	if(num == 111)
		sound = "playgamesound player/vo/phoenix/negative04.wav";
	if(num == 112)
		sound = "playgamesound player/vo/phoenix/negative03.wav";
}