
if ( !sql.TableExists( "menuCookies" ) ) then

	sql.Query( "CREATE TABLE IF NOT EXISTS menuCookies ( key TEXT NOT NULL PRIMARY KEY, value TEXT );" )
	
end


menuCookie = {}

local CachedEntries = {}
local BufferedWrites = {}

local function GetCache( key )
	local entry = CachedEntries[ key ]
	
	if entry == nil || SysTime() > entry[ 1 ] then
		local name = SQLStr( key )
		local val = sql.QueryValue( "SELECT value FROM menuCookies WHERE key = " .. name )
		
		if !val then
			return false
		end
		
		CachedEntries[ key ] = { SysTime() + 30, val }
	end
	
	return CachedEntries[ key ][ 2 ]
end

local function FlushCacheEntry( key )
	CachedEntries[ key ] = nil
	BufferedWrites[ key ] = nil
end

local function FlushCache()
	CachedEntries = {}
	BufferedWrites = {}
end

local function CommitToSQLite()
	sql.Begin()
	
	for k,v in pairs(BufferedWrites) do
		local name = SQLStr( k )
		local value = SQLStr( v )

		sql.Query( "INSERT OR REPLACE INTO menuCookies ( key, value ) VALUES ( "..name..", "..value.." )" )
	end
	
	BufferedWrites = {}
	sql.Commit()
end

local function ScheduleCommit()	
	timer.Create("menuCookie_CommitToSQLite", 0.1, 1, CommitToSQLite)
end

local function SetCache( key, value )
	if !CachedEntries[ key ] then
		CachedEntries[ key ] = { SysTime() + 30, value }
	end
	
	CachedEntries[ key ][ 2 ] = value
	BufferedWrites[ key ] = value

	ScheduleCommit()
end

--[[---------------------------------------------------------
   Get a String Value
-----------------------------------------------------------]]
function menuCookie.GetString( name, default )

	local val = GetCache( name )
	if (!val) then return default end
	
	return val
	
end


--[[---------------------------------------------------------
   Get a Number Value
-----------------------------------------------------------]]
function menuCookie.GetNumber( name, default )

	local val = GetCache( name )
	if (!val) then return default end
	
	return tonumber( val )
	
end

--[[---------------------------------------------------------
   Delete a Value
-----------------------------------------------------------]]
function menuCookie.Delete( name )

	FlushCacheEntry( name )
	
	name = SQLStr( name )
	sql.Query( "DELETE FROM menuCookies WHERE key = " .. name )

end

--[[---------------------------------------------------------
   Set a Value
-----------------------------------------------------------]]
function menuCookie.Set( name, value )
	SetCache( name, value )
end




--[[---------------------------------------------------------
   ClearCookies
-----------------------------------------------------------]]
local function ClearCookies( ply, command, arguments )   

	sql.Query( "DELETE FROM menuCookies" )
	FlushCache()
	
end     

concommand.Add( "lua_menucookieclear", ClearCookies )  


--[[---------------------------------------------------------
   ClearCookies
-----------------------------------------------------------]]
local function SpewCookies( ply, command, arguments )   

	local res = sql.Query( "SELECT key, value FROM menuCookies LIMIT 200" )
	
	for k, v in ipairs( res ) do
	
		MsgN( v['key'], " = ", v['value'] )
	
	end

end     

concommand.Add( "lua_menucookiespew", SpewCookies ) 