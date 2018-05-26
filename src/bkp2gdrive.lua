local oauth = require('google.oauth')
local files = require('google.drive.files')
local driveclient = require('google.drive.client')

local bkp2gdrive = {}
local config = nil

function bkp2gdrive.backup_database(self)
  local workdir = '/tmp/bkp2gdrive'
  os.execute('install -d ' .. workdir .. '/databases')
  for _, v in pairs(config.databases) do
    os.execute(
      'mysqldump -h' .. config.db.host .. ' -P' .. config.db.port ..
        ' -u' .. config.db.user .. ' -p' .. config.db.pass .. ' ' .. v ..
        ' > ' .. workdir .. '/databases/' .. v .. '.sql')
  end
  local archive = '/databases-' .. os.time() .. 'tar.xz'
  os.execute('tar cJf ' .. workdir .. archive .. ' -C ' .. workdir .. ' ./databases')
    os.execute('openssl enc aes-256-cbc -salt -in ' ..
      workdir .. archive ..
      ' -out /tmp' .. archive .. '.enc -pass pass:' .. config.enc.passphrase)
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
    local _, basename = archive:match('(.-)([^\\/]-%.?([^%.\\/]*))$')
    local jwt = oauth:create_jwt(
      'RS256', config.oauth.email, config.oauth.key,
      driveclient.scopes.drivefile, nil)
    local auth = oauth:request(jwt)
    if auth then
      print('Got google oauth bearer')
      local fd = io.open(archive, 'rb')
      local file, s, e = files:create(auth.access_token, {
        name = basename,
        mimetype = 'application/octet-stream',
        size = fd:seek('end'),
        data = fd:read('*a')
      }, { config.gdrive.folder })
      fd:close()
      print('upload: ' .. (s or '-') .. ' ' .. (e or '-'))
    else
      print('Cannot get google oauth bearer')
    end
    os.execute('rm -rf ' .. archive)
  end
end

bkp2gdrive:run()
