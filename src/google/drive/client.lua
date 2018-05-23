local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local client = {
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

function client.request(self, bearer, context, method, data, header)
  local header = {
    ['Authorization'] = 'Bearer ' .. bearer,
  }
  local body = nil
  local headers = {}
  local source = nil

  if data then
    if type(data) == 'table' then
      body = _toJson(data)
      headers = {
        ['Content-Type'] = 'application/json; charset=UTF-8',
        ['Content-Length'] = #(body)
      }
      source = ltn12.source.string(body)
    else
      source = ltn12.source.string(data)
    end
  end

  if header then
    for k, v in pairs(header) do headers[k] = v end
  end

  local respBody = {}
  local resp, respStatus, respHeader = https.request({
    method = method,
    headers = headers,
    source = source,
    sink = ltn12.sink.table(respBody),
    url = client.api .. context
  })

  if ((respHeader or {})['content-type'] or ''):match('application/json') then
    local d = ''
    for _, v in pairs(respBody) do d = d .. v end
    return _toTable(d), respStatus, respHeader
  end
  return nil, respStatus, respHeader, 'response is not in json format'
end

return client
