# BunnyCDN Gem v2.0.0 Design Specification

## Overview

Modernize the `bunny_cdn` gem from a global-configuration, class-method, `rest-client`-based library to an instance-based, `faraday`-powered client with a resource-oriented API. This is a **breaking change** (major version bump to 2.0.0) that removes the old class-level API entirely.

## Goals

1. Replace `rest-client` with `faraday` + `faraday-retry` for modern, configurable HTTP handling.
2. Eliminate global state (`BunnyCdn.configure` block) in favor of instance-level configuration.
3. Separate HTTP client concerns from API resource concerns.
4. Support thread-safe usage in multi-threaded environments (Puma, Sidekiq).
5. Support both single-tenant (global Rails config) and multi-tenant (dynamic per-request) usage.
6. Maintain parity with all existing v1 methods while adding the methods required by the user's application.
7. Provide a unified `upload` method that replaces both `uploadFile` and `uploadFormFile` via duck typing.
8. Provide a custom `ApiError` exception with accessible `status` and `response` attributes.

## Non-Goals

- Adding new Bunny.net endpoints beyond what exists in v1 + the user's application requirements.
- OAuth or token-based authentication (Bunny.net uses a single AccessKey header).
- Async/background job integration (the gem is a plain HTTP client; users wire it into their own jobs).

---

## Architecture

### Design Pattern: Resource-Based with Shared Connection

The gem follows the pattern used by modern Ruby SDKs (Stripe, GitHub, etc.):

- **`BunnyCdn::Client`** holds a `Faraday` connection instance and exposes resource accessors.
- **`BunnyCdn::Resources::Base`** provides shared HTTP verb wrappers and response handling.
- **`BunnyCdn::Resources::PullZones`** and **`BunnyCdn::Resources::Storage`** implement endpoint-specific logic.

This keeps the `Client` class small, the resource classes focused, and makes it trivial to add new Bunny.net APIs later (e.g., a `Statistics` or `Billing` resource).

### Thread Safety

The `Client` connection is lazily initialized and memoized on the instance. Each call to `BunnyCdn::Client.new` creates an independent connection, so sharing a single client instance across threads is safe because `Faraday` connections are stateless after initialization. For multi-tenant apps, users instantiate a new `Client` per tenant/request.

---

## File Structure

```
lib/
├── bunny_cdn.rb                    # Entry point: requires all files
├── bunny_cdn/
│   ├── version.rb                  # VERSION = "2.0.0"
│   ├── client.rb                   # Faraday connection + resource accessors
│   ├── error.rb                    # ApiError exception class
│   └── resources/
│       ├── base.rb                 # Shared HTTP helpers (get, post, delete, handle_response)
│       ├── pull_zones.rb           # Pull zone API methods
│       └── storage.rb              # Storage API methods
spec/
├── spec_helper.rb
├── client_spec.rb
├── error_spec.rb
└── resources/
    ├── pull_zones_spec.rb
    └── storage_spec.rb
```

---

## Components

### `BunnyCdn::Client`

**Responsibility:** Hold configuration, build the `Faraday` connection, expose resource accessors.

**Interface:**

```ruby
client = BunnyCdn::Client.new(
  api_key: "my-api-key",
  base_url: "https://api.bunny.net",      # optional, default shown
  adapter: Faraday.default_adapter         # optional, default shown
)

client.pull_zones   # => BunnyCdn::Resources::PullZones
client.storage(zone_name: "my-zone", region: "ny")  # => BunnyCdn::Resources::Storage
```

**Connection Configuration:**

- `headers["AccessKey"]` = `api_key`
- `headers["Accept"]` = `"application/json"`
- `request :json` — serializes request bodies to JSON
- `response :json, content_type: /\bjson$/` — parses JSON responses
- `request :retry` — max 3, interval 1s, backoff factor 2, jitter 0.5, retries on `ServerError`, `TimeoutError`, `ConnectionFailed`
- `adapter` — injected at initialization (default `Faraday.default_adapter`)

### `BunnyCdn::ApiError`

**Responsibility:** Wrap non-2xx HTTP responses into a structured exception.

```ruby
class ApiError < StandardError
  attr_reader :status, :response

  def initialize(message, status:, response:)
    super(message)
    @status = status
    @response = response
  end
end
```

The `response` attribute holds the parsed JSON body (or raw body if not JSON).

### `BunnyCdn::Resources::Base`

**Responsibility:** Provide thin wrappers around `Faraday` verbs and uniform response handling.

```ruby
class Base
  attr_reader :client

  def initialize(client)
    @client = client
  end

  protected

  def connection
    client.connection
  end

  private

  def get(path, params = {})
    response = connection.get(path, params)
    handle_response(response, path)
  end

  def post(path, body = {})
    response = connection.post(path, body)
    handle_response(response, path)
  end

  def delete(path)
    response = connection.delete(path)
    handle_response(response, path)
  end

  def handle_response(response, path)
    if response.success?
      response.body
    else
      raise ApiError.new(
        "[BunnyCdn] #{path} failed: #{response.status} #{response.body}",
        status: response.status,
        response: response.body
      )
    end
  end
end
```

### `BunnyCdn::Resources::PullZones`

**Responsibility:** All `/pullzone/*` endpoints.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `list` | `GET /pullzone` | List all pull zones. |
| `find(id)` | `GET /pullzone/{id}` | Get a single pull zone by ID. |
| `create(name:, type:, origin_url:)` | `POST /pullzone` | Create a new pull zone. |
| `delete(id)` | `DELETE /pullzone/{id}` | Delete a pull zone. |
| `purge(id)` | `POST /pullzone/{id}/purgeCache` | Purge all cache for a pull zone. |
| `add_hostname(id, hostname)` | `POST /pullzone/{id}/addHostname` | Add a hostname. Returns `{ "success" => true, "skipped" => true }` if already registered. |
| `load_free_ssl(hostname:)` | `GET /pullzone/loadFreeCertificate` | Load a free SSL certificate for a hostname. Accepts keyword argument for consistency. |
| `purge_by_tag(id, tag)` | `POST /pullzone/{id}/purgeCache?cacheTag={tag}` | Purge cache by tag. |
| `health_check` | `GET /pullzone?page=1&perPage=1` | Lightweight check. Returns `true` on success, `false` on `ApiError`. |

**Special Behavior — `add_hostname`:**

If the API responds with HTTP 400 and `ErrorKey == "pullzone.hostname_already_registered"`, the method rescues the `ApiError` and returns `{ "success" => true, "skipped" => true }` instead of raising. Any other error is re-raised.

**Special Behavior — `health_check`:**

Wraps the `list` call with `page: 1, perPage: 1` in a `begin/rescue ApiError` block. Returns `true` on success, `false` on failure.

### `BunnyCdn::Resources::Storage`

**Responsibility:** All storage zone file operations.

**Dynamic Connection Override:**

`BunnyCdn::Resources::Storage` overrides the `connection` method from `Base` to build a `Faraday` connection targeting the region-specific storage subdomain:

```ruby
def connection
  @storage_connection ||= Faraday.new(url: storage_base_url) do |conn|
    conn.headers["AccessKey"] = client.api_key
    conn.request :json
    conn.response :json, content_type: /\bjson$/
    conn.adapter client.adapter
  end
end
```

`storage_base_url` resolves to `https://storage.bunnycdn.com` for `"de"` (default) or `https://{region}.storage.bunnycdn.com` for other regions.

**Initialization:**

```ruby
storage = client.storage(zone_name: "my-zone", region: "ny")
```

`region` is optional. Defaults to `"de"` (Frankfurt) if `nil` or `"de"`. Other valid values: `"uk"`, `"ny"`, `"la"`, `"sg"`, `"se"`, `"br"`, `"jh"`, `"syd"`.

The base URL is `https://{region}.storage.bunnycdn.com` (or `https://storage.bunnycdn.com` for `"de"`).

| Method | Endpoint | Description |
|--------|----------|-------------|
| `list(path: "")` | `GET /{zone}/{path}` | List files in a storage zone path. Automatically appends a trailing `/` if missing. |
| `get(remote_path)` | `GET /{zone}/{remote_path}` | Download a single file. Returns raw body. |
| `upload(remote_path, file)` | `PUT /{zone}/{remote_path}` | Upload a file. Accepts a file path (String) or a Rails-like uploaded file object (responds to `original_filename` and `tempfile`). |
| `delete(remote_path)` | `DELETE /{zone}/{remote_path}` | Delete a file. |

**Upload Duck Typing:**

```ruby
# From filesystem path
storage.upload("images/logo.png", "/path/to/logo.png")

# From Rails uploaded file
storage.upload("images/logo.png", params[:file])
```

The `upload` method accepts a `remote_path` (where the file lives in storage) and a `file` argument. It inspects the file argument:
- If it responds to `original_filename` and `tempfile`, it reads from `file.tempfile`.
- Otherwise, it treats the argument as a local file path and reads it with `File.read`.

**`get` and `delete`:**

```ruby
# Download a file
storage.get("images/logo.png")

# Delete a file
storage.delete("images/logo.png")
```

---

## Error Handling

1. **2xx responses:** Return the parsed JSON body directly.
2. **Non-2xx responses:** Raise `BunnyCdn::ApiError` with:
   - `message`: `"[BunnyCdn] {path} failed: {status} {body}"`
   - `status`: HTTP status code (Integer)
   - `response`: Parsed JSON body (Hash/Array) or raw body string
3. **Network errors:** Handled by Faraday retry middleware. After 3 retries, Faraday raises its own exception (`Faraday::TimeoutError`, `Faraday::ConnectionFailed`, etc.), which bubbles up uncaught.

---

## Testing Strategy

### Spec Files

- **`spec/client_spec.rb`:** Tests initialization, default options, custom adapter injection, and resource accessor return types.
- **`spec/error_spec.rb`:** Tests `ApiError` attribute accessors.
- **`spec/resources/pull_zones_spec.rb`:**
  - Stub each endpoint with WebMock.
  - Assert correct HTTP method, path, headers, and body.
  - Test happy path (returns parsed JSON).
  - Test error path (raises `ApiError` with correct status and response).
  - Test `add_hostname` skipped behavior (400 with `ErrorKey == "pullzone.hostname_already_registered"`).
  - Test `health_check` returns `true` / `false`.
- **`spec/resources/storage_spec.rb`:**
  - Test `list`, `get`, `upload` (both path and uploaded-file variants), `delete`.
  - Assert correct region-based URLs.
  - Assert `AccessKey` header is passed.

### WebMock Configuration

Keep WebMock in `spec_helper.rb`. Disable monkey patching. Use `expect` syntax.

### No Live API Calls

All specs use WebMock stubs. No VCR or live integration tests.

---

## Dependency Changes

### Gemspec (`bunny_cdn.gemspec`)

| Change | From | To |
|--------|------|-----|
| Runtime dependency | `rest-client ~> 2.1` | **`faraday >= 2.0, < 3`** |
| Runtime dependency | — | **`faraday-retry >= 2.0, < 3`** |
| Runtime dependency | — | **`faraday-multipart >= 1.0, < 2`** |
| Runtime dependency | `json ~> 2.12` | **`json ~> 2.12`** (keep) |
| Dev dependency | `bundler ~> 4.0.10` | `bundler ~> 2.6` |
| Dev dependency | `rake ~> 13.2` | `rake ~> 13.2` (keep) |
| Dev dependency | `rspec ~> 3.13` | `rspec ~> 3.13` (keep) |
| Dev dependency | `webmock ~> 3.25` | `webmock ~> 3.25` (keep) |
| Required Ruby | `>= 3.0.0` | **`>= 3.1.0`** (Ruby 3.0 is EOL) |

### `lib/bunny_cdn.rb`

Replace:
```ruby
require "rest-client"
require "json"
require "bunny_cdn/version"
require_relative "bunny_cdn/configuration"
require_relative "bunny_cdn/storage"
require_relative "bunny_cdn/pullzone"
```

With:
```ruby
require "faraday"
require "faraday/retry"
require "json"
require "bunny_cdn/version"
require "bunny_cdn/error"
require "bunny_cdn/client"
require "bunny_cdn/resources/base"
require "bunny_cdn/resources/pull_zones"
require "bunny_cdn/resources/storage"
```

---

## Rails Integration Guide

### Single-Tenant (Global Instance)

Create `config/initializers/bunny_cdn.rb`:

```ruby
Rails.application.configure do
  api_key = Rails.application.credentials.dig(:bunny_cdn, :api_key)
  config.bunny_cdn = BunnyCdn::Client.new(api_key: api_key) if api_key
end
```

Usage in controllers/jobs:

```ruby
Rails.configuration.bunny_cdn.pull_zones.find(12345)
Rails.configuration.bunny_cdn.storage(zone_name: "assets").list
```

### Multi-Tenant (Dynamic Per-Request)

Instantiate directly in services or controllers:

```ruby
bunny = BunnyCdn::Client.new(api_key: tenant.bunny_api_key)
bunny.storage(zone_name: tenant.bunny_storage_zone).upload("logos", file)
```

---

## Breaking Changes Summary (v1 → v2)

| v1 API | v2 Equivalent |
|--------|---------------|
| `BunnyCdn.configure { \|c\| c.apiKey = ... }` | `BunnyCdn::Client.new(api_key: ...)` |
| `BunnyCdn::Pullzone.getAllPullzones` | `client.pull_zones.list` |
| `BunnyCdn::Pullzone.getSinglePullzone(id)` | `client.pull_zones.find(id)` |
| `BunnyCdn::Pullzone.createPullzone(name, type, originUrl)` | `client.pull_zones.create(name:, type:, origin_url:)` |
| `BunnyCdn::Pullzone.deletePullzone(id)` | `client.pull_zones.delete(id)` |
| `BunnyCdn::Pullzone.purgeCache(id)` | `client.pull_zones.purge(id)` |
| `BunnyCdn::Storage.getZoneFiles(path)` | `client.storage(zone_name: ...).list(path:)` |
| `BunnyCdn::Storage.getFile(path, file)` | `client.storage(zone_name: ...).get(path, file)` |
| `BunnyCdn::Storage.uploadFile(path, file)` | `client.storage(zone_name: ...).upload(path, file)` |
| `BunnyCdn::Storage.uploadFormFile(path, file)` | `client.storage(zone_name: ...).upload(path, file)` (same method) |
| `BunnyCdn::Storage.deleteFile(path, file)` | `client.storage(zone_name: ...).delete(path, file)` |

---

## Open Questions / Future Work

- **Rate limiting:** Bunny.net does not publish rate limits. If needed, add a custom Faraday middleware for rate-limit response handling in a future version.
- **Pagination:** The `list` methods currently return the raw API response. A future helper could wrap paginated endpoints with an `Enumerator`.
