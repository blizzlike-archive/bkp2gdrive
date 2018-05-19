local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local gdrive = {
  api = 'https://www.googleapis.com',
}

local _toJson = function(t)
  local json = cjson.new()
  return json.encode(t)
end

local _toTable = function(s)
  local json = cjson.new()
  return json.decode(s)
end

function gdrive.upload(self, apiKey, folder, file)
  if type(folder) == 'string' and file.name and
      file.mime and file.size and file.content then
    local metadata = _toJson({
      name = file.name,
      parents = folder
    })
    local headers = {
      ['Authorization'] = 'Bearer ' .. apiKey,
      ['Content-Type'] = 'application/json; charset=UTF-8',
      ['Content-Length'] = #metadata
      ['X-Upload-Content-Type'] = file.mime,
      ['X-Upload-Content-Length'] = file.size
    }

    local resp, respStatus, respHeader = https.request({
      method = 'POST',
      headers = headers,
      source = ltn12.source.string(metadata),
      url = gdrive.api .. '/uploads/drive/v3/files?uploadType=resumable?key=' .. apiKey
    })

    local location = respHeader['Location']
    if respStatus == 200 and location then
      local headers = {
        ['Content-Type'] = file.mime,
        ['Content-Length'] = file.size
      }
      local respBody = {}
      local resp, respStatus, respHeader = https.request({
        method = 'PUT',
        headers = headers,
        source = ltn12.source.string(file.content),
        sink = ltn12.sink.table(respBody),
        url = location
      })

      if respStatus == 200 or respStatus == 201 then
        return true
      end
    end
  end
end

return gdrive
