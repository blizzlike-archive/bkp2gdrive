local cjson = require('cjson')
local https = require('ssl.https')
local ltn12 = require('ltn12')

local digest = require('openssl.digest')
local pkey = require('openssl.pkey')

local base64 = require('ee5_base64')

local oauth = {
  api = 'https://www.googleapis.com/oauth2/v4/token'
}

local _toJson = function(t)
  local json = cjson.new()
  return json.encode(t)
end

local _toTable = function(s)
  local json = cjson.new()
  return json.decode(s)
end

function oauth.create_jwt(self, alg, email, key, scopes, expiry)
  if alg:upper() ~= 'RS256' then
    return nil, 'only RS256 is supported by google atm'
  end

  local reqTime = os.time()
  local header = _toJson({
    alg = alg,
    typ = 'JWT'
  })
  local claimset = _toJson({
    iss = email,
    scope = scopes,
    aud = 'https://www.googleapis.com/oauth2/v4/token',
    exp = reqTime + (expiry or 1800),
    iat = reqTime
  })

  base64.alpha('base64url')
  local base = base64.encode(header) .. '.' .. base64.encode(claimset)
  local signature, err = oauth:sign(key, base)

  if not signature then
    return nil, err
  end

  local jws = base64.encode(signature)
  return base .. '.' .. jws
end

function oauth.request(self, jwt)
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
    url = oauth.api
  })

  if respHeader and respHeader['content-type']:match('application/json') then
    local d = ''
    for _, v in pairs(respBody) do d = d .. v end
    local response = _toTable(d)
    if response.access_token then return response end
    return nil, 'response has no access token'
  end
  return nil, 'expect json response'
end

function oauth.sign(self, key, base)
  local privkey = pkey.new({ type = 'RSA' })
  privkey:setPrivateKey(key, 'PEM')
  local data = digest.new('sha256')
  data:update(base)

  if not privkey then return nil, 'cannot read privkey' end
  return privkey:sign(data)
end

return oauth
