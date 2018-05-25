#!/usr/bin/env lua5.2

local oauth = require('google.oauth')
local config = dofile(arg[1])
local files = require('google.drive.files')
local gdriveclient = require('google.drive.client')

print('# testing oauth')
local jwt, e = oauth:create_jwt(
  'RS256',
  config.oauth.email,
  config.oauth.key,
  gdriveclient.scopes.drivefile, nil)
print('jwt: ' .. (jwt or '-') .. ' - ' .. (e or '-'))
local auth, e = oauth:request(jwt)
print('auth: ' .. (auth.access_token or '-') .. ' - ' .. (e or '-'))

print('# test files.create')
local f, s, e = files:create(auth.access_token, {
  mimetype = files.mimetypes.directory,
  name = 'test'
}, nil)
print((s or '-') .. ' - ' .. (e or '-'))

local f, s, e = files:create(auth.access_token, {
  mimetype = 'plain/text',
  name = 'test.txt',
  size = 4,
  content = 'test'
}, { [1] = f.id })
print((s or '-') .. ' - ' .. (e or '-'))

print('# testing files.list')
local f, s, e = files:list(auth.access_token, nil, nil)
print((s or '-') .. ' - ' .. (e or '-'))
for k, v in pairs((f or {}).files) do
  print(v.id .. ' - ' .. v.name)
  local d,e = files:delete(auth.access_token, v.id)
  if not d then print(e) end
end
