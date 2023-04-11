ALLOWED_Serials = { -- disable check serials
	[ 'Serial' ] = true -- your serial
}

addEventHandler ( 'onResourceStart' , resourceRoot ,
	function ( )
		database = dbConnect ( 'sqlite' , 'Database/Players-List.db' )
		dbExec ( database , 'CREATE TABLE IF NOT EXISTS PlayersList ( Name , Serial , Account , Ip , Date )' )
		for _ , Players in ipairs ( getElementsByType ( 'player' ) ) do
			setPlayerName (Players, removeHex (getPlayerName (Players)))
		end
	end
)

addCommandHandler ( 'whowas' ,
	function ( Player , _ , Name )
		cancelEvent ( )
		if ( not hasObjectPermissionTo ( Player , 'general.adminpanel' ) ) then
			return false
		end
		local result = dbPoll ( dbQuery ( database , 'SELECT * FROM PlayersList WHERE Name = ?' , Name ) , -1 )
		local Num = 1
		if type ( result ) == "table" and #result ~= 0 and result [ 1 ] [ 'Name' ] then
			if ALLOWED_Serials [ result [ 1 ] [ 'Serial' ] ] then
				return false
			end
			for _ , Value in ipairs ( result ) do
				outputConsole ( '( ' .. Num .. ' ) - ( Name: ' .. Value [ 'Name' ] .. ' , Serial: ' .. Value [ 'Serial' ] .. ' , Account: ' .. Value [ 'Account' ] .. ' , IP: ' .. Value [ 'Ip' ] .. ' , LastJoin: ' .. Value [ 'Date' ] .. ' )' , Player )
				Num = Num + 1
			end
		end
	end
)

addEventHandler ( 'onPlayerJoin' , root ,
	function ( )
		setPlayerName (source, removeHex (getPlayerName (source)))
		local result = dbPoll( dbQuery ( database , 'SELECT * FROM PlayersList WHERE Serial = ?' , getPlayerSerial ( source ) ) , -1 )
		if type ( result ) == "table" and #result ~= 0 then
			dbExec ( database , 'UPDATE PlayersList SET Name = ?, Date = ? WHERE Serial = ?' , getPlayerName ( source ) , GetDate ( ) , getPlayerSerial ( source ) )
		else
			dbExec ( database , 'INSERT INTO PlayersList VALUES ( ? , ? , ? , ? , ? )' , getPlayerName ( source ) , getPlayerSerial ( source ) , 'No Account' , getPlayerIP ( source ) , GetDate ( ) )
		end
	end
)

addEventHandler ( 'onPlayerConnect' , root ,
	function ( CurrentNick )
		if ( #CurrentNick < 4 ) then
			cancelEvent ( true , 'Your name is invalid , Please change your name!' )
		end
	end
)

addEventHandler ( 'onPlayerLogin' , root ,
	function ( _ , CurrentAccount )
		local result = dbPoll( dbQuery ( database , 'SELECT * FROM PlayersList WHERE Serial = ?' , getPlayerSerial ( source ) ) , -1 )
		if type ( result ) == "table" and #result ~= 0 then
			dbExec ( database , 'UPDATE PlayersList SET Account = ? WHERE Serial = ?' , getAccountName ( CurrentAccount ) , getPlayerSerial ( source ) )
		end
	end
)

function GetDate ( )
	local time = getRealTime()
	local hours = time.hour
	local minutes = time.minute
	local seconds = time.second

	local monthday = time.monthday
	local month = time.month
	local year = time.year

	local formattedTime = string.format("[%04d-%02d-%02d-%02d:%02d:%02d]", year + 1900, month + 1, monthday, hours, minutes, seconds)
	return formattedTime
end

function removeHex (name)
    return type (name) == "string" and string.gsub (name, "#%x%x%x%x%x%x", "") or name
end