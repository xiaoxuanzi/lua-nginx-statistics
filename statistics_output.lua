local json = require("cjson")
local statistics_dict = ngx.shared.statistics_dict

local function output()
    local keys = statistics_dict:get_keys()
    local res = {}

    for _, k in pairs(keys) do

	local value = statistics_dict:get(k)
	local s, e = string.find(k, '|')
	local upst_name = string.sub(k, 1, s -1)
	local metric = string.sub(k,  e + 1)

	if res[ upst_name ] == nil then
		res[ upst_name ] = {}
	end

	res[upst_name][metric] = value

	if string.find(metric, "err_count") then
	    if res[upst_name]["err_count"] == nil then
		res[upst_name]["err_count"] = 0
	    end
	    res[upst_name]["err_count"] = res[upst_name]["err_count"] + value
	end

    end

    local ret = json.encode( res )
    ngx.status = ngx.HTTP_OK
    ngx.print( ret )
    ngx.exit(ngx.HTTP_OK)

    return ret
end

local function errorlog(err)
    return string.format("%s: %s", err or "", debug.traceback())
end

local status, err = xpcall(output, errorlog)
if not status then
    ngx.log(ngx.ERR, "[ERROR] nginx statistics output failed, err: ", err)
end
