
local struct = require("struct")

local smpputil = {}


function smpputil.split_udh(long_message, id)
  local id = id or 0x01
  local udh_messages = {}

  local full_length = string.len(long_message)
  local parts_count = math.ceil(full_length / 134)
  local start_idx = 1

  for i = 1, parts_count do
    local end_idx = (i * 134)
    -- do not overflow
    if end_idx > full_length then
      end_idx = full_length
    end

    -- select next segment
    segment = string.sub(long_message, start_idx, end_idx)
    -- append udh headers and add to result list
    udh_messages[i] = string.char(0x05, 0x00, 0x03, id, parts_count, i) .. segment

    -- setup next segment position
    start_idx = i * 134 + 1
  end

  return udh_messages
end


function smpputil.ui8_encode(num)
  return struct.pack(">B", num)
end


function smpputil.ui8_decode(bytes, pos)
  return struct.unpack(">B", bytes, pos)
end

function smpputil.ui16_encode(num)
  return struct.pack(">H", num)
end


function smpputil.ui16_decode(bytes, pos)
  return struct.unpack(">H", bytes, pos)
end


function smpputil.ui32_encode(num)
  return struct.pack(">I", num)
end


function smpputil.ui32_decode(bytes, pos)
  return struct.unpack(">I", bytes, pos)
end


return smpputil

