---------------------------------------------------
-- Licensed under the GNU General Public License v2
--  * (c) 2010, Adrian C. <anrxc@sysphere.org>
---------------------------------------------------

-- {{{ Grab environment
local type = type
local tonumber = tonumber
local io = { popen = io.popen }
local setmetatable = setmetatable
local string = { match = string.match }
local helpers = require("vicious.helpers")
-- }}}


-- Gmail: provides count of new and subject of last e-mail on Gmail
module("vicious.gmail")


-- {{{ Variable definitions
local rss = {
  inbox   = {
    "https://mail.google.com/mail/feed/atom",
    "Gmail - Inbox for "
  },
  unread  = {
    "https://mail.google.com/mail/feed/atom/unread",
    "Gmail - Label &#39;unread&#39; for "
  },
  --labelname = {
  --  "https://mail.google.com/mail/feed/atom/labelname",
  --  "Gmail - Label &#39;labelname&#39; for "
  --},
}

-- Todo: safer storage, maybe hook into Kwallet
local cfg = {
  user = "",        -- user@gmail.com
  pass = "",        -- users password
  feed = rss.unread -- default is all unread
}
-- }}}


-- {{{ Gmail widget type
local function worker(format, warg)
    local auth = cfg.user ..":".. cfg.pass
    local mail = {
        ["{count}"]   = 0,
        ["{subject}"] = "N/A"
    }

    -- Get info from the Gmail atom feed
    local f = io.popen("curl --connect-timeout 1 -m 3 -fsu "..auth.." "..cfg.feed[1])

    -- Could be huge don't read it all at once, info we are after is at the top
    for line in f:lines() do
        mail["{count}"] = -- Count comes before messages and matches at least 0
          tonumber(string.match(line, "<fullcount>([%d]+)</fullcount>")) or mail["{count}"]

        -- Find subject tags
        local title = string.match(line, "<title>(.*)</title>")
        -- If the subject changed then break out of the loop
        if title ~= nil and title ~= cfg.feed[2] .. cfg.user then
            -- Check if we should scroll, or maybe truncate
            if warg then
                if type(warg) == "table" then
                    title = helpers.scroll(title, warg[1], warg[2])
                else
                    title = helpers.truncate(title, warg)
                end
            end

            -- Spam sanitize the subject and store
            mail["{subject}"] = helpers.escape(title)
            break
        end
    end
    f:close()

    return mail
end
-- }}}

setmetatable(_M, { __call = function(_, ...) return worker(...) end })
