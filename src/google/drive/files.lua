local client = require('google.drive.client')

local files = {
  mimetypes = {
    directory = 'application/vnd.google-apps.folder'
  }
}

function files.create(self, bearer, file, parents)
  if type(file) == 'table' and file.name and
      file.mimetype then
    local metadata = {
      name = file.name,
      parents = parents
    }
    local h = nil

    if file.mimetype == files.mimetypes.directory then
      metadata.mimeType = file.mimetype
    else
      if not file.size then return nil, nil, 'table file has no size attribute' end
      h = {
        ['X-Upload-Content-Type'] = file.mimetype,
        ['X-Upload-Content-Length'] = file.size
      }
    end

    local response, status, header, err = client:request(
      bearer, '/drive/v3/files', 'POST', metadata, h)

    if response then
      if (header or {})['Location'] then
        local h = {
          ['Content-Type'] = file.mimetype,
          ['Content-Length'] = file.size
        }
        response, status, _, err = client.request({
          api = header['Location']
        }, bearer, '', 'POST', file.data, h)
        if not response then return nil, status, err end
      end
      return response
    end
    return nil, status, err
  end
  return nil, nil, 'parameter file has to be of type table'
end

function files.delete(self, bearer, id)
  if type(id) == 'string' then
    local response, status, header, err = client:request(
      bearer, '/drive/v3/files/' .. id, 'DELETE', nil, nil)
    if not response then return true end
    return nil, 'not deleted'
  end
  return nil, 'id has to be provided'
end

function files.list(self, bearer, q, token)
  local separator = '?'
  local params = ''

  if type(q) == 'string' then
    params = separator .. 'q=' .. q
    separator = '&'
  end
  if token then
    params = params .. separator .. 'pageToken=' .. token
  end

  local response, status, _, err = client:request(
    bearer, '/drive/v3/files' .. params, 'GET', nil, nil)

  if response then return response end
  return nil, status, err
end

return files
