untyped
global function SwitchInit
global function CommandSwitch

bool switchEnabled = true // true: users can use !switch | false: users cant use !switch
bool adminSwitchPlayerEnabled = true // true: admins can switch users | false: admins cant switch users
int maxPlayerDiff = 1 // how many more players one team can have over the other.
int maxSwitches = 2 // how many times a player can switch teams per match. should be kept low so players cant spam to get an advantage

array<string>exitlist
void function SwitchInit(){
    // add commands here. i added some varieants for accidents, however not for brain damage. do whatever :P
    AddClientCommandCallback("!switch", CommandSwitch)
    AddClientCommandCallback("!SWITCH", CommandSwitch)
    AddClientCommandCallback("!Switch", CommandSwitch)

    // ConVars
    switchEnabled = GetConVarBool( "pv_switch_enabled" )
    adminSwitchPlayerEnabled = GetConVarBool( "pv_switch_admin_switch_enabled" )
    maxPlayerDiff = GetConVarInt( "pv_switch_max_player_diff" )
    maxSwitches = GetConVarInt( "pv_max_switches" )
	AddCallback_OnClientConnected( SetSwitchs )
	AddCallback_OnClientDisconnected( Record )
}

void function SetSwitchs(entity player)
{
	player.s.switchamount <- 0
	if(exitlist.contains(player.GetUID()))
		player.s.switchamount = 10
}
void function Record(entity player)
{
	exitlist.append(player.GetUID())
}

bool function CommandSwitch(entity player, array<string> args)
{
	if(IsLobby() || IsFFAGame())
	return false
	
	printl("USER USED SWITCH")

	// check if enabled
	if(!switchEnabled){
		Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + COMMAND_DISABLED, false)
		return false
	}

	// no name or force given so it cant be an admin switch. -> switch player that requested
	if(args.len() < 1)
	{
		// check if player has already switched too often
		if(player.s.switchamount >= maxSwitches)
		{
			Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + SWITCHED_TOO_OFTEN, false)
			return false
		}
		if(BalanceTime>0)
			if(Time()-BalanceTime<90)
			{
				if(IsAlive(player))
					KillPlayer(player,0)
				Chat_ServerPrivateMessage(player, "平衡一段时间后不可换队", false)
				return false
			}
		if(GetCurrentPlaylistVarInt("max_players",0)/2 == GetPlayerArrayOfEnemies(player.GetTeam()).len() )
		{
			if(IsAlive(player))
				KillPlayer(player,0)
			return false
		}
		switchedPlayers.append(player.GetPlayerName())
		SwitchPlayer(player)
		return true
	}

	// no player name given
	if(args.len() == 1){
		Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + NO_PLAYERNAME_FOUND, false)
		return false
	}

	// admin force switch
	if(args.len() >= 2 && args[0] == "force"){
		// Check if user is admin
		if(!IsPlayerAdmin(player)){
			Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + MISSING_PRIVILEGES, false)
			return false
		}

		// player not on server or substring unspecific
		if(!CanFindPlayerFromSubstring(args[1])){
			Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + CANT_FIND_PLAYER_FROM_SUBSTRING + args[1], false)
			return false
		}

		// get the full player name based on substring. we can be sure this will work because above we check if it can find exactly one matching name... or at least i hope so
		string fullPlayerName = GetFullPlayerNameFromSubstring(args[1])

		// give player and admin feedback
		SendHudMessageBuilder(player, fullPlayerName + SWITCH_ADMIN_SUCCESS, 255, 200, 200)
		SendHudMessageBuilder(GetPlayerFromName(fullPlayerName), SWITCHED_BY_ADMIN, 255, 200, 200)
		SwitchPlayer(GetPlayerFromName(fullPlayerName), true)
	}

	return true
}


void function SwitchPlayer(entity player, bool force = false)
{
	int myteam = player.GetTeam()
	int otherteam = GetOtherTeam( myteam )
    int myAmount = GetPlayerArrayOfTeam(myteam).len()
    int youAmount = GetPlayerArrayOfTeam(otherteam).len()
	

	if(youAmount-myAmount>1 && !force)
		return	Chat_ServerPrivateMessage(player, "\x1b[38;2;220;0;0m" + SWITCH_TOO_MANY_PLAYERS, false)
            
        
	SetTeam(player, otherteam)
	SendHudMessageBuilder(player, SWITCH_SUCCESS, 200, 200, 255)
	if( myAmount-2 < youAmount && IsAlive( player ) )
		KillPlayer(player,0)
}