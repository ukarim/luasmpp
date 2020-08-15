-- SMSC simulator
-- requires luasocket and copas installed
-- Run `luarocks install copas` to install dependencies
-- 
-- Bind port 2775
-- 

-- load modules also from src folder
package.path = package.path .. ';../src/?.lua;'

-- imports
--
local socker = require("socket")
local copas = require("copas")
local pdu = require("pdu")
local smpputil = require("smpputil")

-- default constants
--
local HOST = "localhost"
local PORT = 2775

-- logger helper
--
local function log(msg)
  print(string.format("%s %s", os.date('%Y-%m-%d %H:%M:%S'), msg))
end

-- smpp packets handler function
--
local function pdu_handler(client)
  local client_name = "unknown"
  while true do
    local pdu_bytes = copas.receive(client, 16)
    if pdu_bytes == "quit" then
      break
    end

    local pdu_len = smpputil.ui32_decode(pdu_bytes)
    if pdu_len > 16 then
      pdu_bytes = pdu_bytes .. copas.receive(client, pdu_len - 16)
    end

    local cmd_id = smpputil.ui32_decode(pdu_bytes, 5)
    local seq_num = smpputil.ui32_decode(pdu_bytes, 13)

      -- handle bind request
    if cmd_id == pdu.BIND_TRANSMITTER_CMD or cmd_id == pdu.BIND_RECEIVER_CMD or cmd_id == pdu.BIND_TRANSCEIVER_CMD then
      local bind_req = pdu.bind_request_decode(pdu_bytes)
      client_name = bind_req.system_id
      log("bind request from: " .. bind_req.system_id)
      local resp_cmd = 2147483648 + bind_req.command_id -- hack to calc bind_response_cmd
      local bind_resp = pdu.bind_response_encode(resp_cmd, pdu.STATUS_OK, "smscsimulator", seq_num)
      copas.send(client, bind_resp)
    elseif cmd_id == pdu.SUBMIT_SM_CMD then
      local submit_sm = pdu.submit_sm_decode(pdu_bytes)
      local src_addr = submit_sm.source_addr
      local dest_addr = submit_sm.destination_addr
      log(string.format("submit_sm received from %s. src: %s, dest: %s", client_name, src_addr, dest_addr))

      math.randomseed(os.time())
      local msg_id = math.floor(math.random() * 100000000000000)
      local submit_sm_resp = pdu.submit_sm_resp_encode(pdu.STATUS_OK, msg_id, seq_num)
      copas.send(client, submit_sm_resp)
    elseif cmd_id == pdu.ENQUIRE_LINK_CMD then
      log("enquire link received from " .. client_name)
      local enq_lnk_resp = pdu.pdu_header_encode(pdu.ENQUIRE_LINK_RESP_CMD, pdu.STATUS_OK, seq_num)
      copas.send(client, enq_lnk_resp)
    elseif cmd_id == pdu.UNBIND_CMD then
      log("unbind received from " .. client_name)
      local unbind_resp = pdu.pdu_header_encode(pdu.UNBIND_RESP_CMD, pdu.STATUS_OK, seq_num)
      copas.send(client, unbind_resp)
      client:close()
      break
    else
      print("unsupported pdu received. command_id: " .. cmd_id)
      local gen_nack = pdu.pdu_header_encode(pdu.GENERIC_NACK_CMD, pdu.STATUS_SYS_ERR, seq_num)
      copas.send(client, gen_nack)
      client:close()
      break
    end

  end
end

local function main()
  local server, err = socket.bind(HOST, PORT)
  if server == nil then
    log("cannot start server: " .. err)
    return
  end
  log(string.format("started on %s:%s", HOST, PORT))
  copas.addserver(server, pdu_handler)
  copas.loop()
end

main()

