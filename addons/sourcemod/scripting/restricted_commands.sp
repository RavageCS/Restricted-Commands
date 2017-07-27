// Plugin definitions
#define PLUGIN_VERSION "2.1.0"
#pragma semicolon 1
#include <sourcemod>

new String:g_sound[512];
char g_soundBuffer[512];
new String:g_soundString[512];
new String:g_admin_flag[32];
bool g_error;			//Global if cvar is a valid flag

Handle g_h_plugin_enabled = INVALID_HANDLE;
Handle g_h_sound_enabled = INVALID_HANDLE;
Handle g_h_message_enabled = INVALID_HANDLE;
Handle g_h_sound = INVALID_HANDLE;
Handle g_h_admin_flag = INVALID_HANDLE;

new bool:g_LoggedFileName = false;		/* Whether or not the file name has been logged */
new g_ErrorCount = 0;				/* Current error count */
new g_CurrentLine = 0;				/* Current line we're on */
new String:g_Filename[PLATFORM_MAX_PATH];	/* Used for error messages */

public Plugin:myinfo =
{
	name = "[CS:GO]Restricted Commands",
	author = "Gdk",
	version = PLUGIN_VERSION,
	description = "Plays a negative sound and or displays a message when players type a restricted command",
	url = "https://github.com/RavageCS/Restricted-Commands"
};

public OnPluginStart()
{
	LoadTranslations("restrictedcommands.phrases");
	ReadCommands();
	g_h_plugin_enabled 	= CreateConVar("sm_restricted_commands_enabled", "1", "Whether plugin is enabled");
	g_h_sound_enabled 	= CreateConVar("sm_restricted_commands_sound_enabled", "1", "Whether a sound should be played");
	g_h_message_enabled 	= CreateConVar("sm_restricted_commands_message_enabled", "1", "Whether a message should be shown");
	g_h_sound 		= CreateConVar("sm_restricted_commands_sound", "random", "Game sound to play. Examples: error.wav, /buttons/weapon_cant_buy.wav, /player/vo/fbihrt/radiobotreponsenegative09.wav");
	g_h_admin_flag 		= CreateConVar("sm_restricted_commands_admin_flag", "any", "Do not display message and sound to admins with this flag \nValid flags: any, abcdefghijkmnzop");

	GetConVarString(g_h_sound, g_sound, sizeof(g_sound));
	Format(g_soundBuffer, sizeof(g_soundBuffer), "playgamesound %s", g_sound);
	GetConVarString(g_h_sound, g_soundString, sizeof(g_soundString));

	AutoExecConfig(true, "restricted_commands", "sourcemod");
}

public void OnConfigsExecuted()
{
	GetConVarString(g_h_admin_flag, g_admin_flag, 32);

	g_error = false;	
}

RegCommands(const String:line[])
{
	RegConsoleCmd(line, Command_RestrictedCommand);
}

public Action Command_RestrictedCommand(int client, int args) 
{
	if(GetConVarBool(g_h_plugin_enabled) && !g_error && IsClientConnected(client))
	{
		if(!CheckAdmin(client))
		{
			if(GetConVarBool(g_h_sound_enabled))
			{
				if(StrEqual(g_soundString, "random", false))
				{
					int num = GetRandomInt(1, 112);
					RandSound(num);
					ClientCommand(client, g_sound);
				}
				else
				{
					ClientCommand(client, g_soundBuffer);
				}
			}
			if(GetConVarBool(g_h_message_enabled))
			{
				ReplyToCommand(client, "%t", "restricted");
			}
		}

		if(g_error) 
		{
			LogError("[restricted_commands]: Invalid admin flag: %s", g_admin_flag);
		}
	}

	return Plugin_Handled;
}

public bool CheckAdmin(int client)
{
	bool is_admin = false;

	if(StrEqual(g_admin_flag, "any", false) && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{	
			is_admin = true;
	}
	else
	{	
		g_error = true;
		new String:myFlags[17] = "abcdefghijkmnzop";
		int flags = ReadFlagString(myFlags);

		if (GetUserFlagBits(client) & flags == flags)
		{
			is_admin = true;
		}

		for(int i=0; i < sizeof(myFlags); i++)
		{
			if (FindCharInString(g_admin_flag, myFlags[i], false))
			{
				g_error = false;
			}
		}
	}
	
	return is_admin;
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

public RandSound(int num)
{
	if(num == 1)
		g_sound = "playgamesound player/vo/balkan/negative01.wav";
	if(num == 2)
		g_sound = "playgamesound player/vo/balkan/negative02.wav";
	if(num == 3)
		g_sound = "playgamesound player/vo/balkan/negative04.wav";
	if(num == 4)
		g_sound = "playgamesound player/vo/balkan/negative03.wav";
	if(num == 5)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative08.wav";
	if(num == 6)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative10.wav";
	if(num == 7)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative12.wav";
	if(num == 8)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative11.wav";
	if(num == 9)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative06.wav";
	if(num == 10)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative09.wav";
	if(num == 11)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative03.wav";
	if(num == 12)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative07.wav";
	if(num == 13)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative04.wav";
	if(num == 14)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative01.wav";
	if(num == 15)
		g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative05.wav";
	if(num == 16)
		g_sound = "playgamesound player/vo/gsg9/negative01.wav";
	if(num == 17)
		g_sound = "playgamesound player/vo/gsg9/disagree04.wav";
	if(num == 18)
		g_sound = "playgamesound player/vo/gsg9/negative02.wav";
	if(num == 19)
		g_sound = "playgamesound player/vo/gsg9/disagree01.wav";
	if(num == 20)
		g_sound = "playgamesound player/vo/gsg9/disagree02.wav";
	if(num == 21)
		g_sound = "playgamesound player/vo/gsg9/negative04.wav";
	if(num == 22)
		g_sound = "playgamesound player/vo/gsg9/negative03.wav";
	if(num == 23)
		g_sound = "playgamesound player/vo/sas/negative01.wav";
	if(num == 24)
		g_sound = "playgamesound player/vo/sas/negative05.wav";
	if(num == 25)
		g_sound = "playgamesound player/vo/sas/negative02.wav";
	if(num == 26)
		g_sound = "playgamesound player/vo/sas/disagree01.wav";
	if(num == 27)
		g_sound = "playgamesound player/vo/sas/disagree02.wav";
	if(num == 28)
		g_sound = "playgamesound player/vo/sas/negative06.wav";
	if(num == 29)
		g_sound = "playgamesound player/vo/sas/negative04.wav";
	if(num == 30)
		g_sound = "playgamesound player/vo/sas/negative03.wav";
	if(num == 31)
		g_sound = "playgamesound player/vo/pirate/negativeno05.wav";
	if(num == 32)
		g_sound = "playgamesound player/vo/pirate/negativeno04.wav";
	if(num == 33)
		g_sound = "playgamesound player/vo/pirate/negative01.wav";
	if(num == 34)
		g_sound = "playgamesound player/vo/pirate/disagree03.wav";
	if(num == 35)
		g_sound = "playgamesound player/vo/pirate/disagree04.wav";
	if(num == 36)
		g_sound = "playgamesound player/vo/pirate/negative02.wav";
	if(num == 37)
		g_sound = "playgamesound player/vo/pirate/disagree01.wav";
	if(num == 38)
		g_sound = "playgamesound player/vo/pirate/disagree02.wav";
	if(num == 39)
		g_sound = "playgamesound player/vo/pirate/negative04.wav";
	if(num == 40)
		g_sound = "playgamesound player/vo/pirate/negative03.wav";
	if(num == 41)
		g_sound = "playgamesound player/vo/gign/disagree06.wav";
	if(num == 42)
		g_sound = "playgamesound player/vo/gign/negative01.wav";
	if(num == 43)
		g_sound = "playgamesound player/vo/gign/negative05.wav";
	if(num == 44)
		g_sound = "playgamesound player/vo/gign/disagree03.wav";
	if(num == 45)
		g_sound = "playgamesound player/vo/gign/negative02.wav";
	if(num == 46)
		g_sound = "playgamesound player/vo/gign/disagree01.wav";
	if(num == 47)
		g_sound = "playgamesound player/vo/gign/disagree02.wav";
	if(num == 48)
		g_sound = "playgamesound player/vo/gign/disagree05.wav";
	if(num == 49)
		g_sound = "playgamesound player/vo/gign/negative04.wav";
	if(num == 50)
		g_sound = "playgamesound player/vo/gign/negative03.wav";
	if(num == 51)
		g_sound = "playgamesound player/vo/gign/disagree07.wav";
	if(num == 52)
		g_sound = "playgamesound player/vo/gign/disagree10.wav";
	if(num == 53)
		g_sound = "playgamesound player/vo/anarchist/negativeno05.wav";
	if(num == 54)
		g_sound = "playgamesound player/vo/anarchist/negativeno04.wav";
	if(num == 55)
		g_sound = "playgamesound player/vo/anarchist/negative01.wav";
	if(num == 56)
		g_sound = "playgamesound player/vo/anarchist/negative02.wav";
	if(num == 57)
		g_sound = "playgamesound player/vo/anarchist/negative04.wav";
	if(num == 58)
		g_sound = "playgamesound player/vo/anarchist/negative03.wav";
	if(num == 59)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative08.wav";
	if(num == 60)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative10.wav";
	if(num == 61)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative19.wav";
	if(num == 62)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative14.wav";
	if(num == 63)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative12.wav";
	if(num == 64)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative06.wav";
	if(num == 65)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative09.wav";
	if(num == 66)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative03.wav";
	if(num == 67)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative07.wav";
	if(num == 68)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative01.wav";
	if(num == 69)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative02.wav";
	if(num == 70)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative05.wav";
	if(num == 71)
		g_sound = "playgamesound player/vo/professional/radiobotreponsenegative16.wav";
	if(num == 72)
		g_sound = "playgamesound player/vo/separatist/negative01.wav";
	if(num == 73)
		g_sound = "playgamesound player/vo/separatist/disagree04.wav";
	if(num == 74)
		g_sound = "playgamesound player/vo/separatist/negative02.wav";
	if(num == 75)
		g_sound = "playgamesound player/vo/separatist/negative04.wav";
	if(num == 76)
		g_sound = "playgamesound player/vo/separatist/negative03.wav";
	if(num == 77)
		g_sound = "playgamesound player/vo/leet/negativeno04.wav";
	if(num == 78)
		g_sound = "playgamesound player/vo/leet/negative01.wav";
	if(num == 79)
		g_sound = "playgamesound player/vo/leet/negativeno03.wav";
	if(num == 80)
		g_sound = "playgamesound player/vo/leet/negative02.wav";
	if(num == 81)
		g_sound = "playgamesound player/vo/leet/disagree01.wav";
	if(num == 82)
		g_sound = "playgamesound player/vo/leet/negative04.wav";
	if(num == 83)
		g_sound = "playgamesound player/vo/leet/negative03.wav";
	if(num == 84)
		g_sound = "playgamesound player/vo/idf/negative01.wav";
	if(num == 85)
		g_sound = "playgamesound player/vo/idf/disagree03.wav";
	if(num == 86)
		g_sound = "playgamesound player/vo/idf/negative02.wav";
	if(num == 87)
		g_sound = "playgamesound player/vo/idf/disagree01.wav";
	if(num == 88)
		g_sound = "playgamesound player/vo/idf/disagree02.wav";
	if(num == 89)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative08.wav";
	if(num == 90)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative10.wav";
	if(num == 91)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative06.wav";
	if(num == 92)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative09.wav";
	if(num == 93)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative03.wav";
	if(num == 94)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative07.wav";
	if(num == 95)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative01.wav";
	if(num == 96)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative02.wav";
	if(num == 97)
		g_sound = "playgamesound player/vo/swat/radiobotreponsenegative05.wav";
	if(num == 98)
		g_sound = "playgamesound player/vo/seal/negative01.wav";
	if(num == 99)
		g_sound = "playgamesound player/vo/seal/disagree03.wav";
	if(num == 100)
		g_sound = "playgamesound player/vo/seal/disagree04.wav";
	if(num == 101)
		g_sound = "playgamesound player/vo/seal/negative02.wav";
	if(num == 102)
		g_sound = "playgamesound player/vo/seal/disagree01.wav";
	if(num == 103)
		g_sound = "playgamesound player/vo/seal/disagree02.wav";
	if(num == 104)
		g_sound = "playgamesound player/vo/seal/disagree05.wav";
	if(num == 105)
		g_sound = "playgamesound player/vo/seal/negative04.wav";
	if(num == 106)
		g_sound = "playgamesound player/vo/seal/negative03.wav";
	if(num == 107)
		g_sound = "playgamesound player/vo/phoenix/negativeno05.wav";
	if(num == 108)
		g_sound = "playgamesound player/vo/phoenix/negative01.wav";
	if(num == 109)
		g_sound = "playgamesound player/vo/phoenix/negative02.wav";
	if(num == 110)
		g_sound = "playgamesound player/vo/phoenix/disagree01.wav";
	if(num == 111)
		g_sound = "playgamesound player/vo/phoenix/negative04.wav";
	if(num == 112)
		g_sound = "playgamesound player/vo/phoenix/negative03.wav";
}