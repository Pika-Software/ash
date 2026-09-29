---@class ash.binding
local binding = {}

local folder_name = ash.GamemodeName
local dir_path = "ash/binding/" .. folder_name
local path_to_file = dir_path .. "/binds.json"
local path_to_file_defaults = dir_path .. "/binds.defaults.json"
local string_sub = string.sub
local RunConsoleCommand = RunConsoleCommand

file.CreateDir(dir_path)

---@type table<string, string>
local binds = util.JSONToTable(file.Read(path_to_file) or "[]", false, true) or {}

---@type table<number, string>
local binds_to_keys = {}
for str, value in pairs(binds) do
    local key = input.GetKeyCode(str)
    if key ~= -1 then
        binds_to_keys[key] = value
    end
end

local binds_defaults = util.JSONToTable(file.Read(path_to_file_defaults) or "[]", false, true) or {}

local binds_defaults_to_keys = {}
for str, value in pairs(binds_defaults) do
    local key = input.GetKeyCode(str)
    if key ~= -1 then
        binds_defaults_to_keys[key] = value
    end
end

function binding.save()
    file.Write(path_to_file, util.TableToJSON(binds, true))
end


---@param key string
---@param cmd string | nil
function binding.set(key, cmd)
    local key_code = input.GetKeyCode(key)
    if cmd ~= nil then
        if key_code ~= -1 then
            binds_to_keys[key_code] = cmd
            binds[key] = cmd
            binding.save()
        end
    else
        if key_code ~= -1 then
            binds_to_keys[key_code] = nil
        end
        binds[key] = nil
        binding.save()
    end
end

local default_binds = {}

function binding.setDefault(key, value)
    default_binds[key] = value
end

function binding.saveDefaults()
    binds_defaults = table.copy(default_binds)

    file.Write(path_to_file_defaults, util.TableToJSON(binds_defaults, true))
end

concommand.Add( "ash_bind", function( pl, _, args )
    local key = args[1]
    local cmd = args[2]

    if cmd == nil then
        return
    end

    if key == nil then
        print("Invalid key: " .. key)
        return
    end

    local key_code = input.GetKeyCode(key)

    if key_code == -1 then
        print("Invalid key: " .. key)
        return
    end

    binding.set( key, cmd )
end)

concommand.Add( "ash_unbind", function( pl, _, args )
    local key = args[1]

    if key == nil then
        return
    end

    binding.set( key, nil )
end)

hook.Add( "PlayerButtonDown", "Defaults", function( pl, key )
    if IsFirstTimePredicted() then
        local cmd = binds_to_keys[key]
        if cmd then
            RunConsoleCommand( cmd )
        end
    end
end)

hook.Add( "PlayerButtonUp", "Defaults", function( pl, key )
    if IsFirstTimePredicted() then
        local cmd = binds_to_keys[key]
        if cmd then
            if string_sub( cmd, 1, 1 ) == "+" then
                RunConsoleCommand("-" .. string_sub(cmd, 2))
            end
        end
    end
end)

hook.Add("InitPostEntity", "Defaults", function()
    local is_changed = false

    for key, value in pairs( default_binds ) do
        if binds_defaults[key] ~= value then
            is_changed = true

            if binds[key] == nil then
                local key_code = input.GetKeyCode(key)
                binds[key] = value

                if key_code ~= -1 then
                    binds_to_keys[key_code] = value
                end
            end
        end
    end

    if is_changed then
        binding.saveDefaults()
        binding.save()
    end
end)

return binding
