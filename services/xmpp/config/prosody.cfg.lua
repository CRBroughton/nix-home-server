-- Prosody XMPP Server Configuration
-- Documentation: https://prosody.im/doc/configure

---------- Server-wide settings ----------

-- Allow running as root (needed for rootless Podman)
run_as_root = true

-- Admin accounts (full JID)
admins = { "craig@xmpp.tail538465.ts.net" }

-- Network interfaces to listen on
interfaces = { "*" }

-- Modules to load
modules_enabled = {
    -- Generally required
    "disco";           -- Service discovery
    "roster";          -- User contact lists
    "saslauth";        -- Authentication
    "tls";             -- TLS encryption

    -- Nice to have
    "blocklist";       -- Block users
    "carbons";         -- Message synchronization
    "csi";             -- Client state indication
    "mam";             -- Message Archive Management (history)
    "pep";             -- Personal Eventing Protocol
    "private";         -- Private XML storage
    "vcard4";          -- User profiles
    "vcard_legacy";    -- Compatibility with legacy vCards

    -- Admin tools
    "admin_adhoc";     -- Admin commands

    -- HTTP modules (for web clients)
    "bosh";            -- BOSH support
    "websocket";       -- WebSocket support
    "http_files";      -- Serve static files
}

modules_disabled = {
    "s2s";  -- Disable server-to-server (private server)
}

-- Disable telemetry
statistics = "internal"

-- Authentication
authentication = "internal_hashed"

-- Storage
storage = "internal"

-- Archive settings (message history)
archive_expires_after = "1y"  -- Keep messages for 1 year
default_archive_policy = true  -- Archive by default

-- Logging
log = {
    info = "*console";
}

-- Security settings (Tailscale handles encryption)
c2s_require_encryption = false

-- HTTP settings (for BOSH/WebSocket)
http_ports = { 5280 }
http_interfaces = { "*" }
https_ports = {}

cross_domain_bosh = true
cross_domain_websocket = true

---------- Virtual hosts ----------

VirtualHost "xmpp.tail538465.ts.net"
    -- Enable user registration (disable after creating accounts)
    allow_registration = false
