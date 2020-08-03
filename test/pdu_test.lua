
package.path = package.path .. ';../src/?.lua;'

local luaunit = require("luaunit")
local pdu = require("pdu")


local function read_file(filename)
  local file = io.open(filename, "rb")
  local content = file:read("*all")
  file:close()
  return content
end


-- One pdu header decode is enough

function test_decode_unbind()
  local bytes = read_file("data/unbind.bin")
  local result = pdu.pdu_header_decode(bytes)
  luaunit.assertEquals(result.command_length, 16)
  luaunit.assertEquals(result.command_id, pdu.UNBIND_CMD)
  luaunit.assertEquals(result.command_status, pdu.STATUS_OK)
  luaunit.assertEquals(result.sequence_number, 12)
end


function test_encode_enquire_link()
  local pdu_bytes = pdu.pdu_header_encode(pdu.ENQUIRE_LINK_CMD, pdu.STATUS_OK, 12)
  local expected = read_file("data/enquire_link.bin")
  luaunit.assertEquals(pdu_bytes, expected)
end


function test_encode_enquire_link_resp()
  local pdu_bytes = pdu.pdu_header_encode(pdu.ENQUIRE_LINK_RESP_CMD, pdu.STATUS_OK, 12)
  local expected = read_file("data/enquire_link_resp.bin")
  luaunit.assertEquals(pdu_bytes, expected)
end


function test_encode_unbind()
  local pdu_bytes = pdu.pdu_header_encode(pdu.UNBIND_CMD, pdu.STATUS_OK, 12)
  local expected = read_file("data/unbind.bin")
  luaunit.assertEquals(pdu_bytes, expected)
end


function test_encode_unbind_resp()
  local pdu_bytes = pdu.pdu_header_encode(pdu.UNBIND_RESP_CMD, pdu.STATUS_OK, 12)
  local expected = read_file("data/unbind_resp.bin")
  luaunit.assertEquals(pdu_bytes, expected)
end


function test_encode_generic_nack()
  local pdu_bytes = pdu.pdu_header_encode(pdu.GENERIC_NACK_CMD, pdu.STATUS_SYS_ERR, 12)
  local expected = read_file("data/generic_nack.bin")
  luaunit.assertEquals(pdu_bytes, expected)
end


-- Bind requests


function test_decode_bind_transmitter()
  local bytes = read_file("data/bind_transmitter.bin")
  local bind_transmitter, header, err = pdu.bind_request_decode(bytes)
  luaunit.assertEquals(bind_transmitter.command_length, 47)
  luaunit.assertEquals(bind_transmitter.command_id, pdu.BIND_TRANSMITTER_CMD)
  luaunit.assertEquals(bind_transmitter.command_status, pdu.STATUS_OK)
  luaunit.assertEquals(bind_transmitter.sequence_number, 1)
  luaunit.assertEquals(bind_transmitter.system_id, "SMPP3TEST")
  luaunit.assertEquals(bind_transmitter.password, "secret08")
  luaunit.assertEquals(bind_transmitter.system_type, "SUBMIT1")
  luaunit.assertEquals(bind_transmitter.addr_ton, 1)
  luaunit.assertEquals(bind_transmitter.addr_npi, 1)
  luaunit.assertEquals(bind_transmitter.address_range, "")
end


function test_decode_not_bind_req_packet()
  local bytes = read_file("data/submit_sm.bin")
  local bind_req, header, err = pdu.bind_request_decode(bytes)
  luaunit.assertNil(bind_req)
  luaunit.assertNotNil(header)
  luaunit.assertEquals(header.command_id, pdu.SUBMIT_SM_CMD)
end


function test_encode_bind_transmitter()
  local expected = read_file("data/bind_transmitter.bin")
  local bind_data = {
    system_id = "SMPP3TEST",
    password = "secret08",
    system_type = "SUBMIT1",
    addr_ton = 1,
    addr_npi = 1
  }
  local actual = pdu.bind_request_encode(bind_data, pdu.BIND_TRANSMITTER_CMD, 1)
  luaunit.assertEquals(actual, expected)
end


-- Bind responses

function test_decode_bind_receiver_resp()
  local pdu_bytes = read_file("data/bind_receiver_resp.bin")
  local bind_receiver_resp = pdu.bind_response_decode(pdu_bytes)
  luaunit.assertEquals(bind_receiver_resp.command_id, pdu.BIND_RECEIVER_RESP_CMD)
  luaunit.assertEquals(bind_receiver_resp.command_status, pdu.STATUS_OK)
  luaunit.assertEquals(bind_receiver_resp.sequence_number, 325)
  luaunit.assertEquals(bind_receiver_resp.system_id, "test_receiver")
end


function test_decode_not_bind_resp_packet()
  local bytes = read_file("data/enquire_link.bin")
  local bind_resp, header, err = pdu.bind_response_decode(bytes)
  luaunit.assertNil(bind_resp)
  luaunit.assertNotNil(header)
  luaunit.assertEquals(header.command_id, pdu.ENQUIRE_LINK_CMD)
end


function test_encode_bind_receiver_resp()
  local expected_bytes = read_file("data/bind_receiver_resp.bin")
  local actual = pdu.bind_response_encode(pdu.BIND_RECEIVER_RESP_CMD, pdu.STATUS_OK, "test_receiver", 325)
  luaunit.assertEquals(actual, expected_bytes)
end


-- SubmitSmResp


function test_decode_submit_sm_resp()
  local pdu_bytes = read_file("data/submit_sm_resp.bin")
  local submit_sm_resp = pdu.submit_sm_resp_decode(pdu_bytes)
  luaunit.assertEquals(submit_sm_resp.command_id, pdu.SUBMIT_SM_RESP_CMD)
  luaunit.assertEquals(submit_sm_resp.command_status, pdu.STATUS_OK)
  luaunit.assertEquals(submit_sm_resp.sequence_number, 99)
  luaunit.assertEquals(submit_sm_resp.message_id, "576733224354336")
end


function test_decode_not_submit_sm_resp_packet()
  local bytes = read_file("data/bind_transmitter.bin")
  local submit_sm, header, err = pdu.submit_sm_resp_decode(bytes)
  luaunit.assertNil(submit_sm)
  luaunit.assertNotNil(header)
  luaunit.assertEquals(header.command_id, pdu.BIND_TRANSMITTER_CMD)
end


function test_encode_submit_sm_resp()
  local expected_bytes = read_file("data/submit_sm_resp.bin")
  local actual_bytes = pdu.submit_sm_resp_encode(pdu.STATUS_OK, "576733224354336", 99)
  luaunit.assertEquals(actual_bytes, expected_bytes)
end


-- SubmitSm


function test_decode_submit_sm()
  local pdu_bytes = read_file("data/submit_sm.bin")
  local submit_sm = pdu.submit_sm_decode(pdu_bytes)
  luaunit.assertEquals(submit_sm.command_id, pdu.SUBMIT_SM_CMD)
  luaunit.assertEquals(submit_sm.command_status, pdu.STATUS_OK)
  luaunit.assertEquals(submit_sm.sequence_number, 1923)
  luaunit.assertEquals(submit_sm.service_type, "TEST_SERVICE")
  luaunit.assertEquals(submit_sm.source_addr_ton, 5)
  luaunit.assertEquals(submit_sm.source_addr_npi, 0)
  luaunit.assertEquals(submit_sm.source_addr, "SomeSender")
  luaunit.assertEquals(submit_sm.dest_addr_ton, 1)
  luaunit.assertEquals(submit_sm.dest_addr_npi, 1)
  luaunit.assertEquals(submit_sm.destination_addr, "77012110000")
  luaunit.assertEquals(submit_sm.esm_class, 0)
  luaunit.assertEquals(submit_sm.registered_delivery, 1)
  luaunit.assertEquals(submit_sm.data_coding, pdu.CODING_DEF)
  luaunit.assertEquals(submit_sm.short_message, "luasmpp test")
end


function test_decode_not_submit_sm_packet()
  local bytes = read_file("data/bind_transmitter.bin")
  local submit_sm, header, err = pdu.submit_sm_decode(bytes)
  luaunit.assertNil(submit_sm)
  luaunit.assertNotNil(header)
  luaunit.assertEquals(header.command_id, pdu.BIND_TRANSMITTER_CMD)
end


function test_encode_submit_sm()
  local expected_bytes = read_file("data/submit_sm.bin")
  local message_data = {
    service_type = "TEST_SERVICE",
    source_addr_ton = 5,
    source_addr_npi = 0,
    source_addr = "SomeSender",
    dest_addr_ton = 1,
    dest_addr_npi = 1,
    destination_addr = "77012110000",
    esm_class = 0,
    registered_delivery = 1,
    data_coding = pdu.CODING_DEF,
    short_message = "luasmpp test"
  }
  local submit_sm = pdu.submit_sm_encode(message_data, 1923)
  luaunit.assertEquals(submit_sm, expected_bytes)
end


os.exit(luaunit.LuaUnit.run())

