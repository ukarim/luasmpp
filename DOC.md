### pdu.lua

Contains various encoder/decoder functions and some of the most used SMPP constants

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

#### submit_sm_encode(message_data, sequence_number)

Encode `submit_sm` PDU

```lua
local pdu = require("pdu")

local msg_data = {
  source_addr = "Test",
  source_addr_ton = 5,
  source_addr_npi = 0,
  destination_addr = "77012110000",
  dest_addr_ton = 1,
  dest_addr_npi = 1,
  short_message = "Test message",
  registered_delivery = 1
}
local submit_sm = pdu,submit_sm_encode(msg_data, 154)
-- send submit_sm through tcp connection
```

or using TLV

```lua
local pdu = require("pdu")

local tlvs = {}
tlvs[pdu.TLV_MSG_PAYLOAD] = "Realy long sms message ..."

local msg_data = {
  source_addr = "Test",
  source_addr_ton = 5,
  source_addr_npi = 0,
  destination_addr = "77012110000",
  dest_addr_ton = 1,
  dest_addr_npi = 1,
  short_message = nil,
  registered_delivery = 1,
  tlvs = tlvs
}
local submit_sm = pdu,submit_sm_encode(msg_data, 154)
-- send submit_sm through tcp connection
```

#### submit_sm_decode(bytes)

Decode `submit_sm` PDU

```lua
local pdu = require("pdu")

local bytes = get_bytes_from_tcp()
local submit_sm, pdu_header, err = pdu.submit_sm_decode(bytes)
if submit_sm ~= nil then
  local sequence_number = submit_sm.sequence_number
  local source_addr = submit_sm.source_addr
  -- etc ...
elseif pdu_header ~= nil then
  -- it seems that bytes var is not submit_sm
  local command_id = pdu_header.command_id
  local sequence_number = pdu_header.sequence_number
  -- etc ...
  -- check command_id and use proper decoder function
else
  print(err)
end
```

---

### smpputil.lua

Helper functions

#### split_udh(long_message, id)

Split long sms message to list of messages with length of 134 bytes and UDH headers applied.

id arg is optional with default value set to 1.

```lua
local pdu = require("pdu")
local smpputil = require("smpputil")

local seq_num = 123
local long_msg = "Multisegment long sms message"

local segments = smpputil.split_udh(long_msg)

for i in 1, #segments do
  local msg_data = {
    esm_class = 3,
    source_addr = "Test",
    destination_addr = "77012110000",
    short_message = segments[i]
  }
  local submit_sm = pdu.submit_sm_encode(msg_data, seq_num + i)
  -- send through tcp connection
end

```

#### uiX_encode(num) / uiX_decode(bytes, pos)

* `ui8_encode(num)` and `ui8_decode(bytes, pos)`
* `ui16_encode(num)` and `ui16_decode(bytes, pos)`
* `ui32_encode(num)` and `ui32_decode(bytes, pos)`

Set of functions for encoding and decoding unsigned ints.

Here is example of how to use these functions for TLV value encoding.

```lua
local pdu = require("pdu")
local smpputil = require("smpputil")

local tlvs = {}
tlvs[pdu.TLV_MSG_STATE] = smpputil.ui8_encode(5) -- 5 is for UNDELIVERABLE
```

and decoding

```lua
local pdu = require("pdu")
local smpputil = require("smpputil")

local tlvs = deliver_sm.tvls
local msg_state_bytes = tlvs[pdu.TLV_MSG_STATE]
local msg_state = smpputil.ui8_decode(msg_state_bytes)
if msg_state == 5 then
  print("message is undeliverable")
end
```

