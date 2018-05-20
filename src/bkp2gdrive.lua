local gdrive = require('gdrive')

local bkp2gdrive = {}
local config = nil

function bkp2gdrive.backup_database(self)
  local workdir = '/tmp/bkp2gdrive'
  os.execute('install -d ' .. workdir .. '/databases')
  for _, v in pairs(config.databases) do
--    os.execute(
--      'mysqldump -h' .. config.db.host .. ' -P' .. config.db.port ..
--        ' -u' .. config.db.user .. ' -p' .. config.db.pass .. ' ' .. v ..
--        ' > ' .. workdir .. '/databases/' .. v .. '.sql')
      os.execute('echo foo > ' .. workdir .. '/databases/' .. v .. '.foo')
  end
  local archive = '/databases-' .. os.time() .. 'tar.xz'
  os.execute('tar cJf ' .. workdir .. archive .. ' -C ' .. workdir .. ' ./databases')
  os.execute('cat ' .. workdir .. archive .. ' | openssl rsautl -encrypt -pubin -inkey ' ..
    config.rsa.pubkey .. ' > /tmp' .. archive .. '.enc')
  os.execute('rm -rf ' .. workdir)
  return '/tmp' .. archive .. '.enc'
end

function bkp2gdrive.config(self, file)
  local fd = io.open(file, 'r')
  if fd then
    fd:close()
    return dofile(file)
  end
end

function bkp2gdrive.run(self)
  config = bkp2gdrive:config(arg[1] or './rc.lua')
  if config then
    local archive = bkp2gdrive:backup_database()
    local oauth = gdrive:oauth(config.oauth.email, config.oauth.key)
    if oauth then
      print('Got google oauth bearer')
      local folder = gdrive:mkdir(oauth.access_token, config.gdrive.folder)
      if folder then
        local fd = io.open(archive, 'rb')
        gdrive:upload(oauth.access_token, folder.id, {
          name = archive,
          mime = 'application/octet-stream',
          size = fd:seek('end'),
          content = fd:read('*a')
        })
        fd:close()
      else
        print('Cannot create/get folder')
      end
    else
      print('Cannot get google oauth bearer')
    end
    os.execute('rm -rf ' .. archive)
  end
end

bkp2gdrive:run()
