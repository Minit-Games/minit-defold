-- Minit Games Defold SDK — core facade (prototype).
--
-- A Defold game exported to HTML5 runs as a normal web page inside the Minit
-- host, so it talks to the host-injected `window.minit` runtime directly via
-- Defold's `html5.run` JS bridge — no bundler, no npm dependency, no CDN fetch.
-- This mirrors the Unity and PlayCanvas SDKs: the Lua API surface maps 1:1 to
-- the same `window.minit` contract, so host behaviour is identical across
-- engines.
--
-- Outside the Minit host (desktop build, an HTML5 preview with no host injected,
-- local dev) every call degrades to a `print`, exactly like the Unity SDK falls
-- back to `Debug.Log`. Safe to call from anywhere.

local M = {}

local RESERVED_CONFIG_KEY = "userData"
local LOG_PREFIX = "[Minit]"

-- The `html5` module is only present in HTML5 builds. On desktop/mobile it is
-- nil, so this doubles as our "are we running on the web at all?" check.
local function has_bridge()
    return html5 ~= nil
end

--- Signal the host the game is booted and ready to be revealed.
-- The host keeps the game hidden until this fires.
function M.loading_done()
    if has_bridge() then
        html5.run("if(window.minit&&window.minit.loadingDone){window.minit.loadingDone();}else{console.log('[Minit] loadingDone');}")
    else
        print(LOG_PREFIX, "loadingDone")
    end
end

--- Submit the final result. Call exactly once when the game ends.
-- Higher score = better by default.
-- @param score number|string
-- @param options table|nil {
--   flavor_text = string,  -- short session caption for the host result screen / feed
--   delay       = number,  -- ms the host waits before showing the result screen
--   user_data   = string,  -- persist in this player's single userData slot;
--                          -- omit to leave unchanged, "" is a valid write
-- }
function M.report_result(score, options)
    options = options or {}

    -- Build the host options object, wrapping user_data into { value } to match
    -- HostResultOptions / UserDataPatchSchema in @minit/shared/zod. Games pass a
    -- bare string; the wrapping is a wire-format detail.
    local host_options = {}
    if options.flavor_text ~= nil then host_options.flavorText = options.flavor_text end
    if options.delay ~= nil then host_options.delay = options.delay end
    if options.user_data ~= nil then host_options.userData = { value = options.user_data } end

    if has_bridge() then
        -- JSON is valid JS, so we embed an object literal the browser eval reads
        -- back. json.encode guarantees valid escaping of strings/quotes.
        local payload = json.encode({ score = score, options = host_options })
        local js = "(function(){var p=" .. payload .. ";" ..
            "if(window.minit&&window.minit.reportResult){window.minit.reportResult(p.score,p.options);}" ..
            "else{console.log('[Minit] reportResult',p.score,p.options);}})();"
        html5.run(js)
    else
        print(LOG_PREFIX, "reportResult", score)
    end
end

--- Read a game config value from URL query parameters.
-- Returns `default` when the key is absent or reserved. The `userData` key is
-- reserved and always returns `default`.
-- @param key string
-- @param default string|nil (defaults to "")
-- @return string
function M.get_config_value(key, default)
    default = default or ""
    if key == RESERVED_CONFIG_KEY then return default end
    if not has_bridge() then return default end

    -- JSON.stringify distinguishes an absent param (JS null -> "null") from an
    -- empty-but-present param (-> "\"\""). json.encode(key) yields a valid JS
    -- string literal so arbitrary keys can't break out of the expression.
    local key_literal = json.encode(key)
    local raw = html5.run("JSON.stringify(new URLSearchParams(window.location.search).get(" .. key_literal .. "))")
    if raw == nil or raw == "" or raw == "null" then return default end
    local ok, val = pcall(json.decode, raw)
    if ok and type(val) == "string" then return val end
    return default
end

--- Returns the single-slot userData string for this player, or nil.
-- Reads host-injected `window.minit.userData` directly (no JSON parsing of the
-- value). Local-dev fallback: when the host has not injected userData, falls
-- back to the `?userData=<value>` URL param. Returns "" if the stored value is
-- the empty string (distinct from nil).
-- @return string|nil
function M.get_user_data()
    if not has_bridge() then return nil end
    local raw = html5.run(
        "(function(){var v=window.minit&&window.minit.userData;" ..
        "if(v===undefined||v===null){v=new URLSearchParams(window.location.search).get('userData');}" ..
        "return JSON.stringify(v===null?null:v);})()")
    if raw == nil or raw == "" or raw == "null" then return nil end
    local ok, val = pcall(json.decode, raw)
    if ok and type(val) == "string" then return val end
    return nil
end

return M
