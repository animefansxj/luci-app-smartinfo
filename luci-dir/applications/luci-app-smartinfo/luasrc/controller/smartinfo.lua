--[[
LuCI - Lua Configuration Interface - smartctl support

Script by animefans_xj @ nvacg.org (af_xj@hotmail.com , xujun@smm.cn)

Licensed under the GNU GPL License, Version 3 (the "license");
you may not use this file except in compliance with the License.
you may obtain a copy of the License at

	http://www.gnu.org/licenses/gpl.txt

$Id$
]]--


module("luci.controller.smartinfo",package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("smartinfo")
	if not nixio.fs.access("/etc/config/smartinfo") then
		return
	end
	
	local page = entry({"admin","services","smartinfo"},cbi("smartinfo"),_("S.M.A.R.T Info"))
	page.i18n="smartinfo"
	page.dependent=true

	entry({"admin","services","smartinfo","status"}, call("smart_status")).leaf = true
	entry({"admin","services","smartinfo","run"},call("run_smart")).leaf=true

end


function smart_status()
  local cmd = io.popen("/usr/lib/smartinfo/smart_status.sh")
  if cmd then
    local dev = { }
    while true do
      local ln = cmd:read("*l")
      if not ln then
        break
      elseif ln:match("^.+:.+") then
        local name,status = ln:match("^.+/(.+):(.+)")
        local model,size
        
        if (status=="OK" or status=="Failed" or status=="Unsupported") then
          model="%s %s" % {nixio.fs.readfile("/sys/class/block/%s/device/vendor" % name), nixio.fs.readfile("/sys/class/block/%s/device/model" % name)}
          local s = tonumber((nixio.fs.readfile("/sys/class/block/%s/size" % name)))
          size = "%s MB" % {s and math.floor(s / 2048)}
        else
          model="Unavailabled"
          size="Unavailabled"
        end
        
        if name and status then
            dev[#dev+1]= {
              name = name,
              model = model,
              size  = size,
              status  = status
            }
        end
      end
    end
  
  cmd:close()
  luci.http.prepare_content("application/json")
  luci.http.write_json(dev)
  end
end

function run_smart(dev)
  local cmd = io.popen("smartctl --attributes -d sat /dev/%s" % dev)
  if cmd then
    local report = {}
    local ln = cmd:read("*all")
    report = {
                out = ln
              }
    cmd:close()
    luci.http.prepare_content("application/json")
    luci.http.write_json(report)
  end
end
