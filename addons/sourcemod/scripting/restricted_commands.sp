// Plugin definitions
#define PLUGIN_VERSION "3.2.0"
#pragma semicolon 1
#include <sourcemod>

int g_num_commands;
new String:g_sound[512];
char g_soundBuffer[512];
new String:g_soundString[512];
new String:g_admin_flag[32];
new String:g_commands[512][512];
bool g_error;					//Global if cvar is a valid flag

Handle g_h_plugin_enabled = INVALID_HANDLE;
Handle g_h_sound_enabled = INVALID_HANDLE;
Handle g_h_message_enabled = INVALID_HANDLE;
Handle g_h_sound = INVALID_HANDLE;
Handle g_h_admin_flag = INVALID_HANDLE;
Handle g_h_block_chat = INVALID_HANDLE;

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
	g_h_sound 		= CreateConVar("sm_restricted_commands_sound", "random", "Game sound to play. Examples: error.wav /buttons/weapon_cant_buy.wav /player/vo/fbihrt/radiobotreponsenegative09.wav");
	g_h_admin_flag 		= CreateConVar("sm_restricted_commands_admin_flag", "any", "Do not display message and sound to admins with this flag \nValid flags: any, abcdefghijkmnzop");
	g_h_block_chat          = CreateConVar("sm_restricted_commands_block_chat", "1", "Whether to block restricted commands in chat");

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

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if(GetConVarBool(g_h_plugin_enabled) && GetConVarBool(g_h_block_chat) && IsClientConnected(client))
	{
		for(int x = 0; x < g_num_commands; x++)
		{
			if(strcmp(args[1], g_commands[x][3], false) == 0)
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
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

	int count = 0;
	
	while (!file.EndOfFile())
	{
		count++;

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

		g_commands[count] = line;
	}

	g_num_commands = count;
	
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
	switch(num)
	{
		case 1:
			g_sound = "playgamesound player/vo/balkan/negative01.wav";
		case 2:
			g_sound = "playgamesound player/vo/balkan/negative02.wav";
		case 3:
			g_sound = "playgamesound player/vo/balkan/negative04.wav";
		case 4:
			g_sound = "playgamesound player/vo/balkan/negative03.wav";
		case 5:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative08.wav";
		case 6:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative10.wav";
		case 7:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative12.wav";
		case 8:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative11.wav";
		case 9:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative06.wav";
		case 10:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative09.wav";
		case 11:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative03.wav";
		case 12:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative07.wav";
		case 13:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative04.wav";
		case 14:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative01.wav";
		case 15:
			g_sound = "playgamesound player/vo/fbihrt/radiobotreponsenegative05.wav";
		case 16:
			g_sound = "playgamesound player/vo/gsg9/negative01.wav";
		case 17:
			g_sound = "playgamesound player/vo/gsg9/disagree04.wav";
		case 18:
			g_sound = "playgamesound player/vo/gsg9/negative02.wav";
		case 19:
			g_sound = "playgamesound player/vo/gsg9/disagree01.wav";
		case 20:
			g_sound = "playgamesound player/vo/gsg9/disagree02.wav";
		case 21:
			g_sound = "playgamesound player/vo/gsg9/negative04.wav";
		case 22:
			g_sound = "playgamesound player/vo/gsg9/negative03.wav";
		case 23:
			g_sound = "playgamesound player/vo/sas/negative01.wav";
		case 24:
			g_sound = "playgamesound player/vo/sas/negative05.wav";
		case 25:
			g_sound = "playgamesound player/vo/sas/negative02.wav";
		case 26:
			g_sound = "playgamesound player/vo/sas/disagree01.wav";
		case 27:
			g_sound = "playgamesound player/vo/sas/disagree02.wav";
		case 28:
			g_sound = "playgamesound player/vo/sas/negative06.wav";
		case 29:
			g_sound = "playgamesound player/vo/sas/negative04.wav";
		case 30:
			g_sound = "playgamesound player/vo/sas/negative03.wav";
		case 31:
			g_sound = "playgamesound player/vo/pirate/negativeno05.wav";
		case 32:
			g_sound = "playgamesound player/vo/pirate/negativeno04.wav";
		case 33:
			g_sound = "playgamesound player/vo/pirate/negative01.wav";
		case 34:
			g_sound = "playgamesound player/vo/pirate/disagree03.wav";
		case 35:
			g_sound = "playgamesound player/vo/pirate/disagree04.wav";
		case 36:
			g_sound = "playgamesound player/vo/pirate/negative02.wav";
		case 37:
			g_sound = "playgamesound player/vo/pirate/disagree01.wav";
		case 38:
			g_sound = "playgamesound player/vo/pirate/disagree02.wav";
		case 39:
			g_sound = "playgamesound player/vo/pirate/negative04.wav";
		case 40:
			g_sound = "playgamesound player/vo/pirate/negative03.wav";
		case 41:
			g_sound = "playgamesound player/vo/gign/disagree06.wav";
		case 42:
			g_sound = "playgamesound player/vo/gign/negative01.wav";
		case 43:
			g_sound = "playgamesound player/vo/gign/negative05.wav";
		case 44:
			g_sound = "playgamesound player/vo/gign/disagree03.wav";
		case 45:
			g_sound = "playgamesound player/vo/gign/negative02.wav";
		case 46:
			g_sound = "playgamesound player/vo/gign/disagree01.wav";
		case 47:
			g_sound = "playgamesound player/vo/gign/disagree02.wav";
		case 48:
			g_sound = "playgamesound player/vo/gign/disagree05.wav";
		case 49:
			g_sound = "playgamesound player/vo/gign/negative04.wav";
		case 50:
			g_sound = "playgamesound player/vo/gign/negative03.wav";
		case 51:
			g_sound = "playgamesound player/vo/gign/disagree07.wav";
		case 52:
			g_sound = "playgamesound player/vo/gign/disagree10.wav";
		case 53:
			g_sound = "playgamesound player/vo/anarchist/negativeno05.wav";
		case 54:
			g_sound = "playgamesound player/vo/anarchist/negativeno04.wav";
		case 55:
			g_sound = "playgamesound player/vo/anarchist/negative01.wav";
		case 56:
			g_sound = "playgamesound player/vo/anarchist/negative02.wav";
		case 57:
			g_sound = "playgamesound player/vo/anarchist/negative04.wav";
		case 58:
			g_sound = "playgamesound player/vo/anarchist/negative03.wav";
		case 59:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative08.wav";
		case 60:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative10.wav";
		case 61:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative19.wav";
		case 62:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative14.wav";
		case 63:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative12.wav";
		case 64:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative06.wav";
		case 65:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative09.wav";
		case 66:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative03.wav";
		case 67:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative07.wav";
		case 68:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative01.wav";
		case 69:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative02.wav";
		case 70:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative05.wav";
		case 71:
			g_sound = "playgamesound player/vo/professional/radiobotreponsenegative16.wav";
		case 72:
			g_sound = "playgamesound player/vo/separatist/negative01.wav";
		case 73:
			g_sound = "playgamesound player/vo/separatist/disagree04.wav";
		case 74:
			g_sound = "playgamesound player/vo/separatist/negative02.wav";
		case 75:
			g_sound = "playgamesound player/vo/separatist/negative04.wav";
		case 76:
			g_sound = "playgamesound player/vo/separatist/negative03.wav";
		case 77:
			g_sound = "playgamesound player/vo/leet/negativeno04.wav";
		case 78:
			g_sound = "playgamesound player/vo/leet/negative01.wav";
		case 79:
			g_sound = "playgamesound player/vo/leet/negativeno03.wav";
		case 80:
			g_sound = "playgamesound player/vo/leet/negative02.wav";
		case 81:
			g_sound = "playgamesound player/vo/leet/disagree01.wav";
		case 82:
			g_sound = "playgamesound player/vo/leet/negative04.wav";
		case 83:
			g_sound = "playgamesound player/vo/leet/negative03.wav";
		case 84:
			g_sound = "playgamesound player/vo/idf/negative01.wav";
		case 85:
			g_sound = "playgamesound player/vo/idf/disagree03.wav";
		case 86:
			g_sound = "playgamesound player/vo/idf/negative02.wav";
		case 87:
			g_sound = "playgamesound player/vo/idf/disagree01.wav";
		case 88:
			g_sound = "playgamesound player/vo/idf/disagree02.wav";
		case 89:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative08.wav";
		case 90:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative10.wav";
		case 91:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative06.wav";
		case 92:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative09.wav";
		case 93:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative03.wav";
		case 94:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative07.wav";
		case 95:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative01.wav";
		case 96:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative02.wav";
		case 97:
			g_sound = "playgamesound player/vo/swat/radiobotreponsenegative05.wav";
		case 98:
			g_sound = "playgamesound player/vo/seal/negative01.wav";
		case 99:
			g_sound = "playgamesound player/vo/seal/disagree03.wav";
		case 100:
			g_sound = "playgamesound player/vo/seal/disagree04.wav";
		case 101:
			g_sound = "playgamesound player/vo/seal/negative02.wav";
		case 102:
			g_sound = "playgamesound player/vo/seal/disagree01.wav";
		case 103:
			g_sound = "playgamesound player/vo/seal/disagree02.wav";
		case 104:
			g_sound = "playgamesound player/vo/seal/disagree05.wav";
		case 105:
			g_sound = "playgamesound player/vo/seal/negative04.wav";
		case 106:
			g_sound = "playgamesound player/vo/seal/negative03.wav";
		case 107:
			g_sound = "playgamesound player/vo/phoenix/negativeno05.wav";
		case 108:
			g_sound = "playgamesound player/vo/phoenix/negative01.wav";
		case 109:
			g_sound = "playgamesound player/vo/phoenix/negative02.wav";
		case 110:
			g_sound = "playgamesound player/vo/phoenix/disagree01.wav";
		case 111:
			g_sound = "playgamesound player/vo/phoenix/negative04.wav";
		case 112:
			g_sound = "playgamesound player/vo/phoenix/negative03.wav";
	}
}