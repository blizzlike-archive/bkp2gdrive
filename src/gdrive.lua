local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local digest = require('openssl.digest')
local pkey = require('openssl.pkey')

local base64 = require('ee5_base64')

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

function gdrive.mkdir(self, bearer, folder)
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
      url = gdrive.api .. '/upload/drive/v3/files?uploadType=media'
    })

    if respStatus == 200 then
      local c = ''
      for _, v in pairs(respBody) do c = c .. v end
      local response = _toTable(c)
      return response
    end
  end
end

function gdrive.oauth(self, email, key)
  base64.alpha('base64url')
  local header = _toJson({
    alg = 'RS256',
    typ = 'JWT'
  })
  local claimset = _toJson({
    iss = email,
    scope = 'https://www.googleapis.com/auth/drive.file',
    aud = 'https://www.googleapis.com/oauth2/v4/token',
    exp = os.time() + 1800, -- 30 mins valid
    iat = os.time()
  })
  local jwt = base64.encode(header) .. '.' .. base64.encode(claimset)
  local jws = base64.encode(gdrive:sign(key, jwt))
  jwt = jwt .. '.' .. jws
  local body = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' ..
      '&assertion=' .. jwt
  local respBody = {}
  local resp, respStatus, respHeader = https.request({
    method = 'POST',
    headers = {
      ['Content-Type'] = 'application/x-www-form-urlencoded',
      ['Content-Length'] = #body
    },
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(respBody),
    url = 'https://www.googleapis.com/oauth2/v4/token'
  })

  if respHeader and respHeader['content-type']:match('application/json') then
    local c = ''
    for _, v in pairs(respBody) do c = c .. v end
    local response = _toTable(c)
    if response.access_token then return response end
  end
end

function gdrive.sign(self, key, jwt)
  local privkey = pkey.new({ type = 'RSA' })
  privkey:setPrivateKey(key, 'PEM')
  local data = digest.new('sha256')
  data:update(jwt)

  if not privkey then return nil, 'cannot read privkey' end
  return privkey:sign(data)
end

function gdrive.upload(self, bearer, folder, file)
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
      url = gdrive.api .. '/upload/drive/v3/files?uploadType=resumable'
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
