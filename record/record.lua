local _M = {}
local mt = { __index = _M }

function _M.new(_, dict, item_sep, prefix, exptime)
    local self = {
        dict = dict,
        item_sep = item_sep,
        prefix = prefix,
        exptime = exptime,
    }
    return setmetatable(self, mt)
end

function _M.req_sign(self, t)
    --return t .. self.item_sep
    --return t .. self.item_sep .. ngx.var.proxy_host
    --return ngx.var.proxy_host .. self.item_sep .. t
    return self.prefix .. self.item_sep .. t
end

local function dict_safe_incr(dict, metric, value, exptime)
    if tonumber(value) == nil then
        return
    end

    local newval, err = dict:incr(metric, value)
    if not newval and err == "not found" then
        local ok, err = dict:safe_add(metric, value, exptime)
        if err == "exists" then
            dict:incr(metric, value)
        elseif err == "no memory" then
            ngx.log(ngx.ERR, "no memory for ngx_metric add kv: " .. metric .. ":" .. value)
        end
    end
end

local function str_split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

local function add(dict, metric, value, exptime)
    dict_safe_incr(dict, metric, tonumber(value), exptime)
end

function _M.request_count(self)
    local status_code = tonumber(ngx.var.status)
    if status_code < 400 then
        local metric = self:req_sign("request_count")
        add(self.dict, metric, 1, self.exptime)
    end
end

function _M.request_time(self)

    local metric = self:req_sign("request_time")
    local req_t = tonumber(ngx.var.request_time) or 0
    add(self.dict, metric, req_t, self.exptime)

end

function _M.err_count(self)

    local status_code = tonumber(ngx.var.status)
    if status_code >= 400 then
        local metric_err_qc = self:req_sign("err_count")
        local metric_err_detail = metric_err_qc.."|"..status_code
        add(self.dict, metric_err_detail, 1, self.exptime)
    end

end

function _M.upstream(self)

    local upstream_response_time_s = ngx.var.upstream_response_time or ""
    upstream_response_time_s = string.gsub(string.gsub(upstream_response_time_s, ":", ","), " ", "")
    --Times of several responses are separated by commas and colons

    if upstream_response_time_s == "" then
        return
    end

    local resp_time_arr = str_split(upstream_response_time_s, ",")

    local metric_upstream_count = self:req_sign("upstream_count")
    add(self.dict, metric_upstream_count, #(resp_time_arr), self.exptime)

    local duration = 0.0
    for _, t in pairs(resp_time_arr) do
        if tonumber(t) then
            duration = duration + tonumber(t)
        end
    end

    local metric_upstream_response_time = self:req_sign("upstream_response_time")
    add(self.dict, metric_upstream_response_time, duration, self.exptime)

end

function _M.run(self)

    self:request_count()
    self:err_count()
    self:request_time()
    self:upstream()

end

return _M
