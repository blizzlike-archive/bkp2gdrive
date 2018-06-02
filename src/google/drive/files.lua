local client = require('google.drive.client')

local _M = {
  mimetypes = {
    directory = 'application/vnd.google-apps.folder'
  }
}

local _getfilesize = function(file)
  local fd = io.open(file, 'rb')
  local size = fd:seek('end')
  fd:close()
  return size
end

function _M.create_metadata(self, bearer, file)
  local url = client.api .. '/upload/drive/v3/files'
  print('got file name ' .. file.name)
  local metadata = {
    name = file.name,
    parents = file.parents
  }

  local headers = {
    ['Authorization'] = 'Bearer ' .. bearer,
    ['Content-Type'] = 'application/json; charset=UTF-8'
  }

  if file.mimetype == _M.mimetypes.directory then
    metadata.mimeType = file.mimetype
  else
    url = url .. '?uploadType=resumable'
    headers['X-Upload-Content-Type'] = file.mimetype
    headers['X-Upload-Content-Length'] = file.size
  end

  local body = client:toJson(metadata)
  headers['Content-Length'] = #body

  local _, status, headers = client:request(
    url, 'POST', body, headers)

  if status == 200 then
    return true, headers['location']
  end
  return nil, nil, 'cannot initialize resumable upload session'
end

function _M.create_upload(self, url, file, size, mimetype)
  local headers = {
    ['Content-Type'] = mimetype
  }

  local fd = io.open(file, 'rb')
  local chunkstart = 0
  local chunkend = 0
  local maxchunksize = 262144
  while chunkend < (size - 1) do
    chunkend = chunkstart + maxchunksize - 1
    if chunkend > (size - 1) then chunkend = size - 1 end

    headers['Content-Length'] = chunkend - chunkstart + 1
    headers['Content-Range'] = 'bytes ' .. chunkstart .. '-' .. chunkend .. '/' .. size
    local chunk = fd:read(chunkend - chunkstart + 1)

    print('uploading: ' .. chunkstart .. '-' .. chunkend .. ' of ' .. size .. ' #' .. #chunk)

    local response, status = client:request(
      url, 'POST', chunk, headers)

    print((status or '-'))

    if status == 200 or status == 201 then
      fd:close()
      return client:toTable(response)
    end
    if status == 308 then
      chunkstart = chunkend + 1
    end
    if status == 400 then
      fd:close()
      return nil, response
    end
  end
  fd:close()
  return nil, 'cannot completely upload file'
end

function _M.create(self, bearer, file, mimetype, parents)
  local _, filename = file:match('(.-)([^\\/]-%.?([^%.\\/]*))$')
  print('push metadata with filename ' .. filename)
  local metadata = {
    name = filename,
    parents = parents,
    size = _getfilesize(file),
    mimetype = mimetype
  }
  local success, location, err = _M:create_metadata(
    bearer, metadata)

  if success then
    if location then
      return _M:create_upload(location, file, metadata.size, mimetype)
    end
    return true
  end
  return nil, err
end

-- deprecated
function _M.delete(self, bearer, id)
  if type(id) == 'string' then
    local response, status, header, err = client:request(
      bearer, '/drive/v3/files/' .. id, 'DELETE', nil, nil)
    if not response then return true end
    return nil, 'not deleted'
  end
  return nil, 'id has to be provided'
end

-- deprecated
function _M.list(self, bearer, q, token)
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

return _M
