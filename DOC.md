### pdu module

Contains various encoder/decoder functions and some of most used SMPP constants

#### pdu_header_encode(command_id, command_status, sequence_number)

Encode PDU that contains only header part:

* `unbind` and `unbind_resp`
* `enquire_link` and `enquire_link_resp`
* `generic_nack`

```lua
local pdu = require("pdu")

local enquire_link = pdu.pdu_header_encode(pdu.ENQUIRE_LINK_CMD, pdu.STATUS_OK, 256)
-- send enquire_link through tcp connection
```

#### pdu_header_decode(bytes)

Decode header-only PDU

```lua
local pdu = require("pdu")

local bytes = get_16_bytes_from_tcp()
local header_only_pdu, err = pdu.pdu_header_decode(bytes)
if header_only_pdu ~= nil then
  local command_id = header_only_pdu.command_id
  local command_status = header_only_pdu.command_status
  local sequence_number = header_only_pdu.sequence_number
  -- use command_id, command_status, sequence_number variables somehow
else
  print(err)
end
```

#### bind_request_encode(bind_data, command_id, sequence_number)

Encode bind request

* `bind_transmitter`
* `bind_receiver`
* `bind_transceiver`

```lua
local pdu = require("pdu")

local bind_data = {
  system_id = "test_account",
  password = "super_secret",
  system_type = "luasmpp"
}

local bind_transmitter = pdu.bind_request_encode(bind_data, pdu.BIND_TRANSMITTER_CMD, 1)
-- send bind_transmitter through tcp connection
```

#### bind_request_decode(bytes)

Decode bind request

Usage:
```lua
local pdu = require("pdu")

local bytes = get_pdu_bytes_from_tcp()
local bind_request, pdu_header, err = pdu.bind_request_decode(bytes)
if bind_request ~= nil then
  local command_id = bind_request.command_id
  local sequence_number = bind_request.sequence_number
  local system_id = bind_request.system_id
  local password = bind_request.password
elseif pdu_header ~= nil then
  -- oops. it seems that this is not bind request
  local command_id = pdu_header.command_id
  local command_status = pdu_header.command_status
  local sequence_number = pdu_header.sequence_number
  -- do something with this. check command_id
else
  print(err)
end
```

#### bind_response_encode(command_id, command_status, system_id, sequence_number)

Encode bind response

* `bind_transmitter_resp`
* `bind_receiver_resp`
* `bind_transceiver_resp`

```lua
local pdu = require("pdu")

local bind_transmitter_resp = pdu.bind_response_encode(pdu.BIND_TRANSMITTER_RESP_CMD, pdu.STATUS_OK, "luasmpp", 1)
-- send bind_transceiver_resp through tcp connection
```

#### bind_response_decode(bytes)

Decode bind response

```lua
local pdu = require("pdu")

local bytes = get_bytes_from_tcp()
local bind_resp, pdu_header, err = pdu.bind_response_decode(bytes)
if bind_resp ~= nil then
  local command_id = bind_resp.command_id
  local sequence_number = bind_resp.sequence_number
  local command_status = bind_resp.command_status
  local system_id = bind_resp.system_id
  -- check command_status
elseif pdu_header ~= nil then
  -- oops. provided bytes are not bind_response bytes
  local command_id = pdu_header.command_id
  local sequence_number = pdu_header.sequence_number
  local command_status = pdu_header.command_status
  -- check command_id
else
  print(err)
end
```

