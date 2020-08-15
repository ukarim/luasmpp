-- Send submit_sm and wait for submit_sm_resp
-- Start dummy_smsc.lua server and try to run this script

-- load modules from src folder
package.path = package.path .. ';../src/?.lua;'

local socket = require("socket")
local pdu = require("pdu")
local smpputil = require("smpputil")

local function main()
  local host = "localhost"
  local port = 2775

  local client, err = socket.connect(host, port)
  if client ~= nil then
    print(string.format("connected to %s:%s", host, port))
  else
    print(string.format("cannot connect to %s:%s. %s", host, port, err))
    do return end
  end

  -- should be increased monotonically for each submitted smpp request pdu
  local seq_num = 1

  -- send bind request
  local bind_data = {
    system_id = "test",
    password = "secret",
    system_type = "luasmpp"
  }
  local bind_req = pdu.bind_request_encode(bind_data, pdu.BIND_TRANSMITTER_CMD, seq_num)
  -- update seq_num after use
  seq_num = seq_num + 1
  -- send to connected smsc
  client:send(bind_req)

  -- wait for response
  local bind_resp_bytes = client:receive(16)
  local bind_resp_len = smpputil.ui32_decode(bind_resp_bytes) -- get int from first 4 bytes
  -- get remain bytes
  local bind_resp_bytes = bind_resp_bytes .. client:receive(bind_resp_len - 16)
  local bind_resp, pdu_header, err = pdu.bind_response_decode(bind_resp_bytes)

  -- handle bind response
  if bind_resp ~= nil then
    if bind_resp.command_status == pdu.STATUS_OK then
      print("bind success. smsc system_id: " .. bind_resp.system_id)
    else
      print("bind failed. cmd_status: " .. bind_resp.command_status)
      client:close()
      do return end
    end
  elseif pdu_header ~= nil then
    print(string.format("bind failed. got unexpected response. cmd_id: %s, cmd_status: %s", pdu_header.command_id, pdu_header.command_status))
    client:close()
    do return end
  else
    print("bind failed. cannot parse bind response: " .. err)
    client:close()
    do return end
  end

  -- send submit_sm
  local msg_data = {
    source_addr = "Test",
    destination_addr = "77012110000",
    short_message = "Test message from luasmpp"
  }
  local submit_req = pdu.submit_sm_encode(msg_data, seq_num)
  -- update seq_num after use
  seq_num = seq_num + 1
  -- send to smsc
  client:send(submit_req)

  -- get submit_sm response bytes
  local submit_resp_bytes = client:receive(16)
  local submit_resp_len = smpputil.ui32_decode(submit_resp_bytes) -- got int from first 4 bytes
  submit_resp_bytes = submit_resp_bytes .. client:receive(submit_resp_len - 16)

  -- decode submit_sm resp
  local submit_resp, pdu_header, err = pdu.submit_sm_resp_decode(submit_resp_bytes)
  
  -- handle submit_sm resp
  if submit_resp ~= nil then
    if submit_resp.command_status == pdu.STATUS_OK then
      print("sucessfully submitted. message id: " .. submit_resp.message_id)
    else
      print("submit failed: command status: " .. submit_resp.command_status)
    end
  elseif pdu_header ~= nil then
    print(string.format("submit failed: unexpected response. command id: %s, command status: %s", submit_resp.command_id, submit_resp.command_status))
  else
    print("failed to parse submit_sm_resp with reason: " .. err)
  end

  -- send unbindr request
  local unbind_req = pdu.pdu_header_encode(pdu.UNBIND_CMD, pdu.STATUS_OK, seq_num)
  client:send(unbind_req)

  -- todo wait here for unbind response

  -- close tcp connection
  client:close()
  print("connection closed")
end

main()

