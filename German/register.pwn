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
@ Jeffry's Standard Version (keine TextDraws): https://goo.gl/XgWgpb
@ JustMe.77's Standard Version (nur TextDraw Design): https://goo.gl/dzRNcT
@ Aktuelle Version (Login/Register + TextDraws): https://github.com/JustMe77/Login-Register-System-MySQL-R41-2-Elegant-Textdraws/tree/master/German ) 


*/

#include <a_samp>
#include <a_mysql>
#include <logintextdraws-de>


#define MYSQL_HOST    "127.0.0.1"      //IP Adresse des MySQL Servers
#define MYSQL_USER    "root"           //Benutzername der angemeldet wird
#define MYSQL_PASS    ""               //Passwort des Benutzers
#define MYSQL_DBSE    "samp_db"        //Name der Datenbank

new MySQL:handle; //Die Connection-Handle, über die wir später auf die Tabellen der Datenbank zugreifen

//Dialog IDs (gegebenenfalls ändern, falls bereits belegt)
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
	//Wenn der Spieler die Class-Selection betritt prüfe, ob er bereits eingeloggt ist
	if(!PlayerInfo[playerid][pLoggedIn])
	{
		//Wenn nicht, dann prüfe ob der Spieler ein Konto hat
		//Dazu wird ein Query gesendet und ein neues Callback aufgerufen
		//%e steht für einen geprüften String (sollte anstatt %s in Queries verwendet werden)
		new query[128];
		mysql_format(handle, query, sizeof(query), "SELECT id FROM users WHERE name = '%e'", PlayerInfo[playerid][pName]);

		//Das Query wird abgesendet und die playerid an OnUserCheck übergeben
		mysql_pquery(handle, query, "OnUserCheck", "d", playerid);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!PlayerInfo[playerid][pLoggedIn])
	{
		SendClientMessage(playerid, -1, "{FF0000}Du musst dich einloggen bevor du spawnen kannst!");
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
      		ShowPlayerDialog(playerid, DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"Anmeldung", "Bitte logge Dich ein:", "Ok", "Abbrechen");
    	}
    	else
    	{
      		ShowPlayerDialog(playerid, DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"Registration", "Bitte registriere Dich:", "Ok", "Abbrechen");
    	}
  	}
  	return 0;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_REGISTER)
	{
		//Spieler hat Abbrechen gewählt
		if(!response) return Kick(playerid);

		//Wenn der Spieler kein, oder ein zu kurzes, Passwort eingegeben hat
		if(strlen(inputtext) < 3) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration", "Bitte registriere Dich:\n{FF0000}Mindestens 3 Zeichen!", "Ok", "Abbrechen");

		//Wenn alles passt wird der Spieler in der Datenbank angelegt
		//Als Verschlüsselung für das Passwort wird MD5 verwendet
		new query[256];
		mysql_format(handle, query, sizeof(query), "INSERT INTO users (name, password) VALUES ('%e', MD5('%e'))", PlayerInfo[playerid][pName], inputtext);

		//Das Query wird abgesendet und die playerid an OnUserRegister übergeben
		mysql_pquery(handle, query, "OnUserRegister", "d", playerid);
		return 1;
	}
	if(dialogid == DIALOG_LOGIN)
	{
		//Spieler hat Abbrechen gewählt
		if(!response) return Kick(playerid);

		//Wenn der Spieler kein, oder ein zu kurzes, Passwort eingegeben hat
		if(strlen(inputtext) < 3) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Anmeldung", "Bitte logge Dich ein:\n{FF0000}Mindestens 3 Zeichen!", "Ok", "Abbrechen");

		//Wenn alles passt wird die Datenbank ausgelesen
		new query[256];
		mysql_format(handle, query, sizeof(query), "SELECT * FROM users WHERE name = '%e' AND password = MD5('%e')", PlayerInfo[playerid][pName], inputtext);

		//Das Query wird abgesendet und die playerid an OnUserLogin übergeben
		mysql_pquery(handle, query, "OnUserLogin", "d", playerid);
		return 1;
	}
	return 0;
}

public OnPlayerDisconnect(playerid, reason)
{
	//Speichere den Spieler wenn er der Server verlässt
	SaveUserStats(playerid);
	DestroyPlayerLoginTextDraws(playerid);
	return 1;
}

forward OnUserCheck(playerid);
public OnUserCheck(playerid)
{
	//Query wurde ausgeführt und das Ergebnis im Cache gespeichert
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{
		//Der Spieler konnte nicht gefunden werden, er muss sich registrieren
		PlayerIsNotRegistered(playerid);
		ShowLoginTextDraws(playerid);
	}
	else
	{
		//Es existiert ein Ergebnis, das heißt der Spieler ist registriert und muss sich einloggen
		PlayerIsRegistered(playerid);
		ShowLoginTextDraws(playerid);
	}
	return 1;
}

forward OnUserRegister(playerid);
public OnUserRegister(playerid)
{
	//Der Spieler wurde in die Datenbank eingetragen, es wird die id ausgelesen
	PlayerInfo[playerid][p_id] = cache_insert_id();
	PlayerInfo[playerid][pLoggedIn]  = true;
	SendClientMessage(playerid, 0x00FF00FF, "[Konto] Registration erfolgreich.");
	PlayerPlaySound(playerid, 1057 , 0.0, 0.0, 0.0);
	HideLoginTextDraws(playerid);
	return 1;
}

forward OnUserLogin(playerid);
public OnUserLogin(playerid)
{
	//Query wurde ausgeführt und das Ergebnis im Cache gespeichert
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{
		//Der Spieler hat ein falsches Passwort eingegeben
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Anmeldung", "Bitte logge Dich ein:\n{FF0000}Falsches Passwort!", "Ok", "Abbrechen");
	}
	else
	{
		//Es existiert ein Ergebnis, das heißt der Spieler hat das richtige Passwort eingegeben
		//Wir lesen nun die erste Zeile des Caches aus (ID 0)
 		cache_get_value_name_int(0, "id", PlayerInfo[playerid][p_id]);
		cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
		cache_get_value_name_int(0, "money", PlayerInfo[playerid][pMoney]);
		cache_get_value_name_int(0, "kills", PlayerInfo[playerid][pKills]);
		cache_get_value_name_int(0, "deaths", PlayerInfo[playerid][pDeaths]);
		PlayerInfo[playerid][pLoggedIn]  = true;
		SendClientMessage(playerid, 0x00FF00FF, "[Konto] Eingeloggt.");
		PlayerPlaySound(playerid, 1057 , 0.0, 0.0, 0.0);
		GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
		HideLoginTextDraws(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	//Beispielcode
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
	//Wenn der Spieler nicht eingeloggt ist, dann speichere seine Statistiken nicht
	if(!PlayerInfo[playerid][pLoggedIn]) return 1;

	//Ansonsten speichere sie
	new query[256];
	mysql_format(handle, query, sizeof(query), "UPDATE users SET level = '%d', money = '%d', kills = '%d', deaths = '%d' WHERE id = '%d'",
		PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths], PlayerInfo[playerid][p_id]);

	//Das Query wird abgesendet
	mysql_pquery(handle, query);
	return 1;
}

stock MySQL_SetupConnection(ttl = 3)
{
	print("[MySQL] Verbindungsaufbau...");
	//mysql_log();  //<- Kommentar vor mysql_log entfernen um den MySQL Debug-Modus zu aktivieren

	handle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DBSE);

	//Prüfen und gegebenenfalls wiederholen
	if(mysql_errno(handle) != 0)
	{
		//Fehler im Verbindungsaufbau, prüfe ob ein weiterer Versuch gestartet werden soll
		if(ttl > 1)
		{
			//Versuche erneut eine Verbindung aufzubauen
			print("[MySQL] Es konnte keine Verbindung zur Datenbank hergestellt werden.");
			printf("[MySQL] Starte neuen Verbindungsversuch (TTL: %d).", ttl-1);
			return MySQL_SetupConnection(ttl-1);
		}
		else
		{
			//Abbrechen und Server schließen
			print("[MySQL] Es konnte keine Verbindung zur Datenbank hergestellt werden.");
			print("[MySQL] Bitte prüfen Sie die Verbindungsdaten.");
			print("[MySQL] Der Server wird heruntergefahren.");
			return SendRconCommand("exit");
		}
	}
	printf("[MySQL] Die Verbindung zur Datenbank wurde erfolgreich hergestellt! Handle: %d", _:handle);
	return 1;
}
