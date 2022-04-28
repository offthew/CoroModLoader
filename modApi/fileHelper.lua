local t = {}



function t:file_exists(path)
   local f=io.open(path,"r")
   if f~=nil then io.close(f) return true else return false end
end

function t:write(text, path,mode)
  mode = mode or "a"
  
  local file, errorString = io.open( path, mode )

  if not file then
      -- Error occurred; output the cause
      print( "File error: " .. errorString )
  else
      -- Write data to file
      file:write(text)
      -- Close the file handle
      io.close( file )
  end

  file = nil
end

function t:read(path, mode)
  mode = mode or '*a'
  local file, errorString = io.open(path, 'rb')
  if not file then
    print( "File error: " .. errorString )
    return nil
  else
    local text = file:read(mode)
    io.close(file)
    return text
  end
  file= nil
end

function t:copy(src, dest)
  local text = t:read(src)
  t:write(text,dest)
end

function t:move(src, dest)
  os.rename(src, dest)
end

function t:remove(path)
  os.remove(path)
end

return t