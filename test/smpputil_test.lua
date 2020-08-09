
package.path = package.path .. ';../src/?.lua;'

local luaunit = require("luaunit")
local struct = require("struct")
local smpputil = require("smpputil")

function test_udh_multiple()
  local id = 23

  -- 134
  local segment1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad"
  -- 134
  local segment2 = " minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehender"
  -- 66
  local segment3 = "it in voluptate velit esse cillum dolore eu fugiat nulla pariatur."

  local segments = {}
  segments[1] = segment1
  segments[2] = segment2
  segments[3] = segment3

  local long_message = segment1 .. segment2 .. segment3

  local udh_messages = smpputil.split_udh(long_message, id)

  for i = 1, #udh_messages do
    local msg = udh_messages[i]
    luaunit.assertTrue(#msg <= 140)
    luaunit.assertEquals(string.sub(msg, 7), segments[i])
    local ref_num = struct.unpack(">B", msg, 4)
    local total_num = struct.unpack(">B", msg, 5)
    local seq_num = struct.unpack(">B", msg, 6)

    luaunit.assertEquals(ref_num, id)
    luaunit.assertEquals(total_num, 3)
    luaunit.assertEquals(seq_num, i)
  end

end

function test_udh_single()
  local id = 24
  local segment1 = "test short message"

  local udh_messages = smpputil.split_udh(segment1, id)

  luaunit.assertEquals(#udh_messages, 1)

  local msg = udh_messages[1]

  luaunit.assertEquals(string.sub(msg, 7), segment1)

  local ref_num = struct.unpack(">B", msg, 4)
  local total_num = struct.unpack(">B", msg, 5)
  local seq_num = struct.unpack(">B", msg, 6)

  luaunit.assertEquals(ref_num, id)
  luaunit.assertEquals(total_num, 1)
  luaunit.assertEquals(seq_num, 1)
end


function test_ui8_encode_decode()
  local expected_bytes = string.char("0xA9")
  luaunit.assertEquals(smpputil.ui8_encode(169), expected_bytes)
  luaunit.assertEquals(smpputil.ui8_decode(expected_bytes), 169)

  -- check decode with position
  luaunit.assertEquals(smpputil.ui8_decode("blahblah" .. expected_bytes, 9), 169)
end


function test_ui16_encode_decode()
  local expected_bytes = string.char("0x26", "0x94")
  luaunit.assertEquals(smpputil.ui16_encode(9876), expected_bytes)
  luaunit.assertEquals(smpputil.ui16_decode(expected_bytes), 9876)

  -- check decode with position
  luaunit.assertEquals(smpputil.ui16_decode("blahblah" .. expected_bytes, 9), 9876)
end


function test_ui32_encode_decode()
  local expected_bytes = string.char("0x3D", "0x09", "0x6A", "0xA0")
  luaunit.assertEquals(smpputil.ui32_encode(1024027296), expected_bytes)
  luaunit.assertEquals(smpputil.ui32_decode(expected_bytes), 1024027296)

  -- check decode with position
  luaunit.assertEquals(smpputil.ui32_decode("blahblah" .. expected_bytes, 9), 1024027296)
end


os.exit(luaunit.LuaUnit.run())

