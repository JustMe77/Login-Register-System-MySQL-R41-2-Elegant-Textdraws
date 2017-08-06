/*
       _       __  __                            _           _   __  __       ______ ______ 
      | |     / _|/ _|              ___         | |         | | |  \/  |     |____  |____  |
      | | ___| |_| |_ _ __ _   _   ( _ )        | |_   _ ___| |_| \  / | ___     / /    / / 
  _   | |/ _ \  _|  _| '__| | | |  / _ \/\  _   | | | | / __| __| |\/| |/ _ \   / /    / /  
 | |__| |  __/ | | | | |  | |_| | | (_>  < | |__| | |_| \__ \ |_| |  | |  __/_ / /    / /   
  \____/ \___|_| |_| |_|   \__, |  \___/\/  \____/ \__,_|___/\__|_|  |_|\___(_)_/    /_/    
                            __/ |                                                           
                           |___/                                                            

@ Titel: Login / Register System [MySQL R41-2] + Elegant Textdraws
@ Version: 2.0.0
@ Login/Register System by Jeffry
@ Login/Register TextDraws by JustMe.77
@ Jeffry's Default Version (keine TextDraws): https://goo.gl/XgWgpb
@ JustMe.77's Default Version (nur TextDraw Design): https://goo.gl/dzRNcT
@ Current Version (Login/Register + TextDraws): https://github.com/JustMe77/Login-Register-System-MySQL-R41-2-Elegant-Textdraws/tree/master/Englisch ) 


*/

#include <a_samp>
#include <a_mysql>
#include <logintextdraws-en>


#define MYSQL_HOST    "127.0.0.1"      //IP Adresse from the MySQL Server
#define MYSQL_USER    "root"           //Username to sign in
#define MYSQL_PASS    ""               //Password from the user
#define MYSQL_DBSE    "samp_db"        //Name from the database

new MySQL:handle; //The connection handle which we need later to acces the tables

//Dialog IDs (you may change them if they're already taken)
#define DIALOG_REGISTER  1403
#define DIALOG_LOGIN     2401

enum pDataEnum
{
	p_id,
	bool:pLoggedIn,
	pName[MAX_PLAYER_NAME],
	pLevel,
	pMoney,
	pKills,
	pDeaths
}
new PlayerInfo[MAX_PLAYERS][pDataEnum];

public OnFilterScriptInit()
{
	MySQL_SetupConnection();
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(handle);
	return 1;
}

public OnPlayerConnect(playerid)
{
	CreatePlayerLoginTextDraws(playerid);
	PlayerInfo[playerid][p_id]       = 0;
	PlayerInfo[playerid][pLoggedIn]  = false;
	PlayerInfo[playerid][pLevel]     = 0;
	PlayerInfo[playerid][pMoney]     = 0;
	PlayerInfo[playerid][pKills]     = 0;
	PlayerInfo[playerid][pDeaths]    = 0;
	GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
	return 1;
}

public OnPlayerRequestClass(playerid)
{
	//If the player enters the class selection, we check if he's already logged in
	if(!PlayerInfo[playerid][pLoggedIn])
	{
		//If not, we check if he got already an account
		//We send a query and call a new callback
		new query[128];
		mysql_format(handle, query, sizeof(query), "SELECT id FROM users WHERE name = '%e'", PlayerInfo[playerid][pName]);

		mysql_pquery(handle, query, "OnUserCheck", "d", playerid);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!PlayerInfo[playerid][pLoggedIn])
	{
		SendClientMessage(playerid, -1, "{FF0000}You've to login before you're able to spawn yourself!");
		return 0;
	}
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid) 
{
	if(playertextid == PlayerLoginTextDraw[playerid][0])
  	{
    	if(pRegistered[playerid] == true)
    	{
      		ShowPlayerDialog(playerid, DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"Login", "Please login to your account:", "Ok", "Cancel");
    	}
    	else
    	{
      		ShowPlayerDialog(playerid, DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"Registration", "Please register yourself:", "Ok", "Cancel");
    	}
  	}
  	return 0;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_REGISTER)
	{
		//The player has selected cancel
		if(!response) return Kick(playerid);

		//If the player has typed nothing or a short password
		if(strlen(inputtext) < 3) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration", "Please register yourself:\n{FF0000}At least 3 character!", "Ok", "Cancel");

		//If everything is alright, we insert the user into the databse
		//We encode the password with the MD5 hash
		new query[256];
		mysql_format(handle, query, sizeof(query), "INSERT INTO users (name, password) VALUES ('%e', MD5('%e'))", PlayerInfo[playerid][pName], inputtext);

		//The query is sent and we call OnUserRegister
		mysql_pquery(handle, query, "OnUserRegister", "d", playerid);
		return 1;
	}
	if(dialogid == DIALOG_LOGIN)
	{
		//The player has selected cancel
		if(!response) return Kick(playerid);

		//If the player has typed nothing or a short password
		if(strlen(inputtext) < 3) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Please login to your account:\n{FF0000}At least 3 charachter!", "Ok", "Cancel");

		//If everything is alright, we read from the database
		new query[256];
		mysql_format(handle, query, sizeof(query), "SELECT * FROM users WHERE name = '%e' AND password = MD5('%e')", PlayerInfo[playerid][pName], inputtext);

		//The query is sent and we call OnUserLogin
		mysql_pquery(handle, query, "OnUserLogin", "d", playerid);
		return 1;
	}
	return 0;
}

public OnPlayerDisconnect(playerid, reason)
{
	//We save the player when he leave the server
	SaveUserStats(playerid);
	DestroyPlayerLoginTextDraws(playerid);
	return 1;
}

forward OnUserCheck(playerid);
public OnUserCheck(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{
		//The player was not found, he has to register
		PlayerIsNotRegistered(playerid);
		ShowLoginTextDraws(playerid);
	}
	else
	{
		//The account exist, he has to login
		PlayerIsRegistered(playerid);
		ShowLoginTextDraws(playerid);
	}
	return 1;
}

forward OnUserRegister(playerid);
public OnUserRegister(playerid)
{
	PlayerInfo[playerid][p_id] = cache_insert_id();
	PlayerInfo[playerid][pLoggedIn]  = true;
	SendClientMessage(playerid, 0x00FF00FF, "[Account] Registration succesful.");
	PlayerPlaySound(playerid, 1057 , 0.0, 0.0, 0.0);
	HideLoginTextDraws(playerid);
	return 1;
}

forward OnUserLogin(playerid);
public OnUserLogin(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{
		//The player has typed in a wrong password
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Please login to your account:\n{FF0000}Wrong password!", "Ok", "Cancel");
	}
	else
	{
		//The player has typed in his correct password
 		cache_get_value_name_int(0, "id", PlayerInfo[playerid][p_id]);
		cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
		cache_get_value_name_int(0, "money", PlayerInfo[playerid][pMoney]);
		cache_get_value_name_int(0, "kills", PlayerInfo[playerid][pKills]);
		cache_get_value_name_int(0, "deaths", PlayerInfo[playerid][pDeaths]);
		PlayerInfo[playerid][pLoggedIn]  = true;
		SendClientMessage(playerid, 0x00FF00FF, "[Account] Signed in.");
		PlayerPlaySound(playerid, 1057 , 0.0, 0.0, 0.0);
		GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
		HideLoginTextDraws(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	//Example Code
	if(killerid != INVALID_PLAYER_ID)
	{
		PlayerInfo[killerid][pKills]++;
		GivePlayerMoney(killerid, 10);
		PlayerInfo[killerid][pMoney] += 10;
		if(PlayerInfo[killerid][pKills] > 3)
		{
			PlayerInfo[killerid][pLevel] = 1;
		}
	}
	PlayerInfo[playerid][pDeaths]++;
	return 1;
}

stock SaveUserStats(playerid)
{
	//If the player is not logged in, we don't save his account
	if(!PlayerInfo[playerid][pLoggedIn]) return 1;

	//If he has an account, we save it
	new query[256];
	mysql_format(handle, query, sizeof(query), "UPDATE users SET level = '%d', money = '%d', kills = '%d', deaths = '%d' WHERE id = '%d'",
		PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths], PlayerInfo[playerid][p_id]);

	//Query sent
	mysql_pquery(handle, query);
	return 1;
}

stock MySQL_SetupConnection(ttl = 3)
{
	print("[MySQL] Connecting to the database...");
	//mysql_log();  //<- Remove the // to activate the Debug Mode

	handle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DBSE);

	if(mysql_errno(handle) != 0)
	{
		if(ttl > 1)
		{
			//We try again to connect to the database
			print("[MySQL] The connection to the databse was not succesful.");
			printf("[MySQL] Try again (TTL: %d).", ttl-1);
			return MySQL_SetupConnection(ttl-1);
		}
		else
		{
			//Cancel and close the server
			print("[MySQL] The connection to the database was not succesful.");
			print("[MySQL] Please check the MySQL Login Information.");
			print("[MySQL] Shutting server down");
			return SendRconCommand("exit");
		}
	}
	printf("[MySQL] The connection to the database was succesful! Handle: %d", _:handle);
	return 1;
}
