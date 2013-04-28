
local read_file = function(file)
  local f = io.open(file)
  local data = f:read("*all")
  f:close()
  return data
end

local follow_pagination = function(urls, html)
  -- pagination
  for page_url in string.gmatch(html, "href=\"(/[^\"]+/page:[0-9]+)\"") do
    table.insert(urls, { url=("http://streetfiles.org"..page_url), link_expect_html=1 })
  end
end

local url_count = 0

wget.callbacks.get_urls = function(file, url, is_css, iri)
  -- progress message
  url_count = url_count + 1
  if url_count % 10 == 0 then
    io.stdout:write("\r - Downloaded "..url_count.." URLs")
    io.stdout:flush()
  end

  local urls = {}

  -- MAIN PROFILE PAGE
  local username = string.match(url, "^http://streetfiles%.org/([-.a-zA-Z0-9_]+)$")
  if username then
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/photos"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/friends"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/groups"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/group_messages"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/bookmarks"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/photosets"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/loves/"), link_expect_html=1 })
    table.insert(urls, { url=("http://streetfiles.org/"..username.."/hates/"), link_expect_html=1 })

    return urls
  end

  -- PHOTOS
  local username = string.match(url, "^http://streetfiles%.org/([-.a-zA-Z0-9_]+)/photos")
  if username then
    local html = read_file(file)
    follow_pagination(urls, html)

    -- photos
    for photo in string.gmatch(html, "streetfiles%.org/photos/detail/([0-9]+)/") do
      table.insert(urls, { url=("http://streetfiles.org/photos/detail/"..photo.."/"), link_expect_html=1 })
    end

    return urls
  end

  -- PHOTO
  local photo = string.match(url, "^http://streetfiles%.org/photos/detail/([0-9]+)/$")
  if photo then
    local html = read_file(file)
    for user, photo in string.gmatch(html, "\"/img/user/([0-9]+)/L/([a-zA-Z0-9]+)%.jpg\"") do
      table.insert(urls, { url=("http://streetfiles.org/img/user/"..user.."/"..photo..".jpg") })
      table.insert(urls, { url=("http://streetfiles.org/img/user/"..user.."/S/"..photo..".jpg") })
      table.insert(urls, { url=("http://streetfiles.org/img/user/"..user.."/M/"..photo..".jpg") })
      table.insert(urls, { url=("http://streetfiles.org/img/user/"..user.."/L/"..photo..".jpg") })
    end

    return urls
  end

  -- PHOTOSET
  local username = string.match(url, "^http://streetfiles%.org/([-.a-zA-Z0-9_]+)/photosets/[0-9]+")
  if username then
    local html = read_file(file)
    follow_pagination(urls, html)

    -- photos
    for photo in string.gmatch(html, "streetfiles%.org/photos/detail/([0-9]+)/") do
      table.insert(urls, { url=("http://streetfiles.org/photos/detail/"..photo.."/"), link_expect_html=1 })
    end

    return urls
  end

  -- PHOTOSETS
  local username = string.match(url, "^http://streetfiles%.org/([-.a-zA-Z0-9_]+)/photosets")
  if username then
    local html = read_file(file)
    follow_pagination(urls, html)

    -- photosets
    for photoset in string.gmatch(html, "/photosets/([0-9]+)\"") do
      table.insert(urls, { url=("http://streetfiles.org/"..username.."/photosets/"..photoset), link_expect_html=1 })
    end

    return urls
  end

  -- OTHER PAGES WITH PAGINATION
  for i, pagetype in ipairs({ "bookmarks", "friends", "groups", "group_messages", "loves", "hates" }) do
    local username = string.match(url, "^http://streetfiles%.org/([-.a-zA-Z0-9_]+)/"..pagetype)
    if username then
      local html = read_file(file)
      follow_pagination(urls, html)
      return urls
    end
  end

  return urls
end

