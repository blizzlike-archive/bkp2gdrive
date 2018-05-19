local gdrive = require('gdrive')

local config = bkp2gdrive:config(arg[1] or './rc.lua')

local bkp2gdrive = {}

function bkp2gdrive.backup_database(self)
  local workdir = os.tmpname()
  os.execute('install -d ' .. workdir .. '/databases')
  for _, v in pairs(config.databases) do
    os.execute(
      'mysqldump -h' .. config.db.host .. ' -P' .. config.db.port ..
        ' -u' .. config.db.user .. ' -p' .. config.db.pass .. ' ' .. v ..
        ' > ' .. workdir .. '/databases/' .. v .. '.sql')
  end
  local archive = '/tmp/databases-' .. os.time() .. 'tar.xz'
  os.execute('tar cJf ' .. archive .. ' -C ' .. workdir .. ' ./databases')
  os.execute('rm -rf ' .. workdir)
  return archive
end

function bkp2gdrive.config(self, file)
  local fd = io.open(file, 'r')
  if fd then
    fd:close()
    return dofile(file)
  end
end

function bkp2gdrive.run(self)
  if config then
    local archive = bkp2gdrive:backup_database()
    local fd = io.open(archive, 'rb')
    gdrive:upload(config.gdrive.apiKey, config.gdrive.folder, {
      name = archive,
      mime = 'application/x-compressed-tar',
      size = fd:seek('end'),
      content = fd:read('*a')
    })
    fd:close()
    os.execute('rm -rf ' .. archive)
  end
end

bkp2gdrive:run()
