local raw_tonumber = raw.tonumber
local os_time = os.time
local sqlite = sqlite

---@class ash.storage
local storage = {}

local gamemode_info = ash.Chain[ 1 ]
local gamemode_name = gamemode_info.name

sqlite.query( [[
	CREATE TABLE IF NOT EXISTS "ash.player.storage.integer" (
		"account_id"     INTEGER NOT NULL,
		"gamemode_name"  TEXT NOT NULL,
		"storage_key"    TEXT NOT NULL,
		"value"          INTEGER NOT NULL,
		"expires_at"     INTEGER NOT NULL DEFAULT 0,

		PRIMARY KEY (
			"account_id",
			"gamemode_name",
			"storage_key"
		)
	);
]] )

sqlite.query( [[
	CREATE TABLE IF NOT EXISTS "ash.player.storage.string" (
		"account_id"     INTEGER NOT NULL,
		"gamemode_name"  TEXT NOT NULL,
		"storage_key"    TEXT NOT NULL,
		"value"          TEXT NOT NULL,
		"expires_at"     INTEGER NOT NULL DEFAULT 0,

		PRIMARY KEY (
			"account_id",
			"gamemode_name",
			"storage_key"
		)
	);
]] )

sqlite.query( [[
	CREATE TABLE IF NOT EXISTS "ash.player.storage.boolean" (
		"account_id"     INTEGER NOT NULL,
		"gamemode_name"  TEXT NOT NULL,
		"storage_key"    TEXT NOT NULL,
		"value"          INTEGER NOT NULL,
		"expires_at"     INTEGER NOT NULL DEFAULT 0,

		PRIMARY KEY (
			"account_id",
			"gamemode_name",
			"storage_key"
		)
	);
]] )

---@param ttl number | nil
---@return number
local function getExpireTime( ttl )
    if ttl ~= nil and ttl > 0 then
        return os_time() + ttl
    end

    return 0
end

---@param expires_at number
---@return boolean
local function isExpired( expires_at )
    return expires_at ~= 0 and expires_at <= os_time()
end

---@param table_name string
local function cleanupExpired( table_name )
    sqlite.query(
        "DELETE FROM ? WHERE `expires_at` != 0 AND `expires_at` <= ?;",
        table_name,
        os_time()
    )
end

---@param pl Player
---@param key string
---@return boolean | nil
function storage.getBoolean( pl, key )
    ---@type table | nil
    local result = sqlite.queryFirst(
        [[
			SELECT
				`value`,
				`expires_at`
			FROM
				`ash.player.storage.boolean`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
        pl:AccountID(),
        gamemode_name,
        key
    )

    if result == nil then
        return nil
    end

    local expires_at = raw_tonumber( result.expires_at ) or 0

    if isExpired( expires_at ) then
        storage.setBoolean( pl, key, nil )
        return nil
    end

    return raw_tonumber( result.value, 10 ) == 1
end

---@param pl Player
---@param key string
---@param value? boolean
---@param ttl? integer
function storage.setBoolean( pl, key, value, ttl )
    if value == nil then
        sqlite.query(
            [[
			DELETE FROM
				`ash.player.storage.boolean`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
            pl:AccountID(),
            gamemode_name,
            key
        )

        return
    end

    sqlite.query(
        [[
			INSERT OR REPLACE INTO
				`ash.player.storage.boolean`
			(
				`account_id`,
				`gamemode_name`,
				`storage_key`,
				`value`,
				`expires_at`
			)
			VALUES
			(
				?,
				?,
				?,
				?,
				?
			);
		]],
        pl:AccountID(),
        gamemode_name,
        key,
        value and 1 or 0,
        getExpireTime( ttl )
    )
end

---@param pl Player
---@param key string
---@return string | nil
function storage.getString( pl, key )
    ---@type table | nil
    local result = sqlite.queryFirst(
        [[
			SELECT
				`value`,
				`expires_at`
			FROM
				`ash.player.storage.string`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
        pl:AccountID(),
        gamemode_name,
        key
    )

    if result == nil then
        return nil
    end

    local expires_at = tonumber( result.expires_at ) or 0

    if isExpired( expires_at ) then
        storage.setString( pl, key, nil )
        return nil
    end

    return tostring( result.value )
end

---@param pl Player
---@param key string
---@param value? string
---@param ttl? integer
function storage.setString( pl, key, value, ttl )
    if value == nil then
        sqlite.query(
            [[
			DELETE FROM
				`ash.player.storage.string`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
            pl:AccountID(),
            gamemode_name,
            key
        )

        return
    end

    sqlite.query(
        [[
			INSERT OR REPLACE INTO
				`ash.player.storage.string`
			(
				`account_id`,
				`gamemode_name`,
				`storage_key`,
				`value`,
				`expires_at`
			)
			VALUES
			(
				?,
				?,
				?,
				?,
				?
			);
		]],
        pl:AccountID(),
        gamemode_name,
        key,
        value,
        getExpireTime( ttl )
    )
end

---@param pl Player
---@param key string
---@return integer | nil
function storage.getInteger( pl, key )
    ---@type table | nil
    local result = sqlite.queryFirst(
        [[
			SELECT
				`value`,
				`expires_at`
			FROM
				`ash.player.storage.integer`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
        pl:AccountID(),
        gamemode_name,
        key
    )

    if result == nil then
        return nil
    end

    local expires_at = tonumber( result.expires_at ) or 0

    if isExpired( expires_at ) then
        storage.setInteger( pl, key, nil )
        return nil
    end

    return tonumber( result.value )
end

---@param pl Player
---@param key string
---@param value? integer
---@param ttl? integer
function storage.setInteger( pl, key, value, ttl )
    if value == nil then
        sqlite.query(
            [[
			DELETE FROM
				`ash.player.storage.integer`
			WHERE
				`account_id` = ?
				AND `gamemode_name` = ?
				AND `storage_key` = ?;
		]],
            pl:AccountID(),
            gamemode_name,
            key
        )

        return
    end

    sqlite.query(
        [[
			INSERT OR REPLACE INTO
				`ash.player.storage.integer`
			(
				`account_id`,
				`gamemode_name`,
				`storage_key`,
				`value`,
				`expires_at`
			)
			VALUES
			(
				?,
				?,
				?,
				?,
				?
			);
		]],
        pl:AccountID(),
        gamemode_name,
        key,
        math.floor( value ),
        getExpireTime( ttl )
    )
end

function storage.cleanup()
    cleanupExpired( "ash.player.storage.boolean" )
    cleanupExpired( "ash.player.storage.string" )
    cleanupExpired( "ash.player.storage.integer" )
end

timer.Create( "ash.storage.cleanup", 300, 0, storage.cleanup )

return storage
