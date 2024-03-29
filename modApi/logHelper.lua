local fileHelper = require("Resources.coroModLoader.modLoader.modApi.fileHelper")
local t = {}

function t:write(text,path,modeString)
  text = text or nil
  path = path or "logs.log"
  modeString = modeString or "a"
  if text then
    text = os.date("[%x %X] ")..text.."\n"
    path = "Resources/coroModLoader/"..path
    fileHelper:write(text,path,modeString)
  end
end

function t:saveOldLog(path)
  path = path or "logs.log"
  local logPath = "Resources/coroModLoader/"..path
  local newPath = "Resources/coroModLoader/old"..path
  local oldLog = fileHelper:read(logPath)
  if(oldLog) then
    oldLog = os.date("\n Backup Made on the %x  at %X\n")..oldLog
    fileHelper:write(oldLog,newPath)
    fileHelper:remove(logPath)
  end
end





return t