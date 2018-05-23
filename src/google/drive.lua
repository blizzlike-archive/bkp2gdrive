local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local drive = {
  api = 'https://www.googleapis.com',
  scopes = {
    drivefile = 'https://www.googleapis.com/auth/drive.file'
  }
}

local _toJson = function(t)
  local json = cjson.new()
  return json.encode(t)
end

local _toTable = function(s)
  local json = cjson.new()
  return json.decode(s)
end

function drive.chown(self, bearer, id, email)
  if type(folder) == 'string' then
    local permission = _toJson({
      role = 'owner',
      type = 'user',
      emailAddress = email
    })
    local headers = {
      ['Authorization'] = 'Bearer ' .. bearer,
      ['Content-Type'] = 'application/json; charset=UTF-8',
      ['Content-Length'] = #permission
    }

    local repsBody = {}
    local resp, respStatus, respHeader = https.request({
      method = 'POST',
      headers = headers,
      source = ltn12.source.string(permission),
      sink = ltn12.sink.table(respBody)
      url = drive.api .. '/drive/v3/files/' .. id ..
        '/permissions?transferOwnership=true&sendNotificationEmail=false'
    })

    if respStatus == 200 then
      local c = ''
      for _, v in pairs(respBody) do c = c .. v end
      return _toTable(c)
    end
  end
end

function drive.list(self, bearer, q, token)
  if type(q) == 'string' then
    local params = '?q=' .. q
    if page then params = params .. '&pageToken=' .. token end
    local headers = {
      ['Authorization'] = 'Bearer ' .. bearer,
    }

    local respBody = {}
    local resp, respStatus, respHeader = https.request({
      method = 'GET',
      headers = headers,
      sink = ltn12.sink.table(respBody),
      url = drive.api .. '/drive/v3/files?q=' .. query
    })

    if respStatus == 200 then
      local d = ''
      for _, v in pairs(respBody) do d = d .. v end
      return _toTable(d)
    end
    return nil, 'google api returned ' .. respStatus
  end
  return nil, 'parameter q has to be type of string'
end

function drive.mkdir(self, bearer, folder)
  if type(folder) == 'string' then
    local metadata = _toJson({
      name = folder,
      mimeType = 'application/vnd.google-apps.folder'
    })
    local headers = {
      ['Authorization'] = 'Bearer ' .. bearer,
      ['Content-Type'] = 'application/json; charset=UTF-8',
      ['Content-Length'] = #metadata
    }

    local repsBody = {}
    local resp, respStatus, respHeader = https.request({
      method = 'POST',
      headers = headers,
      source = ltn12.source.string(metadata),
      sink = ltn12.sink.table(respBody)
      url = drive.api .. '/upload/drive/v3/files?uploadType=media'
    })

    if respStatus == 200 then
      local c = ''
      for _, v in pairs(respBody) do c = c .. v end
      return _toTable(c)
    end
  end
end

function drive.upload(self, bearer, folder, file)
  if type(folder) == 'string' and file.name and
      file.mime and file.size and file.content then
    local metadata = _toJson({
      name = file.name,
      parents =  { folder }
    })
    local headers = {
      ['Authorization'] = 'Bearer ' .. bearer,
      ['Content-Type'] = 'application/json; charset=UTF-8',
      ['Content-Length'] = #metadata,
      ['X-Upload-Content-Type'] = file.mime,
      ['X-Upload-Content-Length'] = file.size
    }

    local resp, respStatus, respHeader = https.request({
      method = 'POST',
      headers = headers,
      source = ltn12.source.string(metadata),
      url = drive.api .. '/upload/drive/v3/files?uploadType=resumable'
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
        local c = ''
        for _, v in pairs(respBody) do c = c .. v end
        return _toTable(c)
      end
    end
  end
end

return drive
