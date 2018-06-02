local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local client = {
  api = 'https://www.googleapis.com',
  scopes = {
    drivefile = 'https://www.googleapis.com/auth/drive.file'
  }
}

function client.request(self, url, method, data, headers)
  local source = nil

  if data then
    source = ltn12.source.string(data)
  end

  local respBody = {}
  local _, respStatus, respHeader = https.request({
    method = method,
    headers = headers,
    source = source,
    sink = ltn12.sink.table(respBody),
    url = url
  })

  local d = ''
  for _, v in pairs(respBody) do d = d .. v end
  print(d)
  return d, respStatus, respHeader
end

function client.toJson(self, t)
  local json = cjson.new()
  return json.encode(t)
end

function client.toTable(self, s)
  local json = cjson.new()
  return json.decode(s)
end

return client
