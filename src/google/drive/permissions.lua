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
  if type(id) == 'string' and type(permission) == 'table' and
      permission.role and permission.type then
    local response, status, header, err = client:request(
      bearer, '/drive/v3/files/' .. id .. '/permissions', 'POST',
      permission, nil)
    if response then return response end
    return nil, 'cannot set permission'
  end
  return nil, 'id has to be provided'
end

return _M
