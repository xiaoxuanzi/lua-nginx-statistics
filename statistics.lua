local record = require "record.record"

local dict = ngx.shared.statistics_dict
local item_sep = "|"
local exptime = 3600 * 24 --second

local function run()

	local prefix = ngx.var.proxy_host
	--or set $statistics_prefix in location
	--local prefix = ngx.var.statistics_prefix

	if prefix == nil then
		return
	end

    rd = record:new(dict, item_sep, prefix, exptime)
    rd:run()

end

local function errorlog(err)
    return string.format("%s: %s", err or "", debug.traceback())
end

local status, err = xpcall(run, errorlog)
if not status then
    ngx.log(ngx.ERR, "[ERROR] nginx statistics failed, err: ", err)
end
