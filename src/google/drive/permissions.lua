local client = require('google.drive.client')

local _M = {
  roles = {
    organzier = 'organizer',
    owner = 'owner',
    writer = 'writer',
    commenter = 'commenter',
    reader = 'reader'
  },
  types = {
    user = 'user',
    group = 'group',
    domain = 'domain',
    anyone = 'anyone'
  }
}

function _M.create(self, bearer, id, permission)
  local url = client.api .. '/drive/v3/files/' .. id .. 'permissions'
  local metadata = {
    role = permission.role,
    type = permission.type,
    emailAddress = permission.emailAddress
  }

  local headers = {
    ['Authorization'] = 'Bearer ' .. bearer,
    ['Content-Type'] = 'application/json; charset=UTF-8',
    ['Content-Length'] = #metadata
  }

  local response, status, headers = client:request(
    url, 'POST', client:toJson(metadata), headers)

  if ((headers or {})['content-type'] or ''):match('application/json') then
    return client:toTable(response)
  end

  return nil, response
end

return _M
