
local struct = require("struct")

-- Exported module

local pdu = {}


-- Global constants

-- Command id

pdu.BIND_TRANSMITTER_CMD = 0x02
pdu.BIND_TRANSMITTER_RESP_CMD = 0x80000002
pdu.BIND_RECEIVER_CMD = 0x01
pdu.BIND_RECEIVER_RESP_CMD = 0x80000001
pdu.BIND_TRANSCEIVER_CMD = 0x09
pdu.BIND_TRANSCEIVER_RESP_CMD = 0x80000009
pdu.UNBIND_CMD = 0x06
pdu.UNBIND_RESP_CMD = 0x80000006
pdu.ENQUIRE_LINK_CMD = 0x15
pdu.ENQUIRE_LINK_RESP_CMD = 0x80000015
pdu.GENERIC_NACK_CMD = 0x80000000
pdu.SUBMIT_SM_CMD = 0x04
pdu.SUBMIT_SM_RESP_CMD = 0x80000004
pdu.DELIVER_SM_CMD = 0x05
pdu.DELIVER_SM_RESP_CMD = 0x80000005

-- Command status

pdu.STATUS_OK = 0x00
pdu.STATUS_INVMSG_LEN = 0x01
pdu.STATUS_INVCMD_LEN = 0x02
pdu.STATUS_INVCMD_ID = 0x03
pdu.STATUS_ALREADY_BOUND = 0x05
pdu.STATUS_SYS_ERR = 0x08
pdu.STATUS_INVSRC_ADDR = 0x0A
pdu.STATUS_INVDEST_ADDR = 0x0B
pdu.STATUS_BIND_FAILER = 0x0D
pdu.STATUS_INVPASS = 0x0E
pdu.STATUS_INVSYS_ID = 0x0F
pdu.STATUS_MSGQUE_FULL = 0x14
pdu.STATUS_INVSERV_TYPE = 0x15
pdu.STATUS_THROTTLING_ERR = 0x58


-- Data coding

pdu.CODING_DEF = 0x00
pdu.CODING_LATIN1 = 0x03
pdu.CODING_8BIT = 0x04
pdu.CODING_CYRLLIC = 0x06
pdu.CODING_UCS2 = 0x08


-- TVL

pdu.TLV_PAYLOAD_TYPE = 0x0019
pdu.TLV_RECEIPTED_MSG_ID = 0x001E
pdu.TLV_USR_MSG_REF = 0x0204
pdu.TLV_SAR_MSG_REF_NUM = 0x020C
pdu.TLV_SAR_TOTAL_SEGMENTS = 0x020E
pdu.TLV_SAR_SEGMENT_SEQ_NUM = 0x020F
pdu.TLV_MSG_PAYLOAD = 0x0424
pdu.TLV_MSG_STATE = 0x0427


-- Header only PDUs

-- Generic functions to encode and decode next PDUs
-- * `unbind` and `unbind_resp`
-- * `generic_nack`
-- * `enquire_link` and `enquire_link_resp`

function pdu.pdu_header_encode(command_id, command_status, sequence_number)
  return struct.pack(">IIII", 0x10, command_id, command_status, sequence_number)
end


function pdu.pdu_header_decode(bytes)
  if string.len(bytes) ~= 16 then
    return nil, "invalid input. expected only 16 bytes"
  end
  local len, id, sts, seq_num = struct.unpack(">IIII", bytes)
  local ret_val = {
    command_length = len,
    command_id = id,
    command_status = sts,
    sequence_number = seq_num
  }
  return ret_val, nil
end


-- Bind PDUs

-- Generic functions to encode and decode the following PDUs
-- * `bind_transmitter` and `bind_transmitter_resp`
-- * `bind_receiver` and `bind_receiver_resp`
-- * `bind_transceiver` and `bind_transceiver_resp`

function pdu.bind_request_encode(bind_data, command_id, sequence_number)
  local system_id = bind_data.system_id or ""
  local password = bind_data.password or ""
  local system_type = bind_data.system_type or ""
  local addr_ton = bind_data.addr_ton or 0x00
  local addr_npi = bind_data.addr_npi or 0x00
  local address_range = bind_data.address_range or ""
  local tmp_pdu = struct.pack(">IIIIsssBBBs", 0, command_id, 0x00, sequence_number,
                              system_id, password, system_type, 0x34, addr_ton, addr_npi, address_range)
  return struct.pack(">I", #tmp_pdu) .. string.sub(tmp_pdu, 5)
end


function pdu.bind_request_decode(bytes)
  local buf_len = string.len(bytes)
  if buf_len < 16 then
    return nil, nil, "invalid input. need at least 16 bytes"
  end
  local len, id, sts, seq = struct.unpack(">IIII", bytes)
  if len ~= buf_len then
    return nil, nil, "invalid input. corrupted packet"
  end

  if id ~= pdu.BIND_TRANSMITTER_CMD and id ~= pdu.BIND_RECEIVER_CMD and id ~= pdu.BIND_TRANSCEIVER_CMD then
    local pdu_header = {
      command_length = len,
      command_id = id,
      command_status = sts,
      sequence_num = seq
    }
    return nil, pdu_header, nil
  end

  local sys_id, pass, sys_type, ver, ton, npi, range = struct.unpack(">sssBBBs", bytes, 17)
  local ret_val = {
    command_length = len,
    command_id = id,
    command_status = sts,
    sequence_number = seq,
    system_id = sys_id,
    password = pass,
    system_type = sys_type,
    interface_version = ver,
    addr_ton = ton,
    addr_npi = npi,
    address_range = range
  }
  return ret_val, nil, nil
end


function pdu.bind_response_encode(command_id, command_status, system_id, sequence_number)
  local pdu_len = 16 + string.len(system_id) + 1 -- plus on for null terminator
  return struct.pack(">IIIIs", pdu_len, command_id, command_status, sequence_number, system_id)
end


function pdu.bind_response_decode(bytes)
  local buf_len = string.len(bytes)
  if buf_len < 16 then
    return nil, nil, "invalid input. need at least 16 bytes"
  end
  local len, id, sts, seq = struct.unpack(">IIII", bytes)
  if len ~= buf_len then
    return nil, nil, "invalid input. corrupted packet"
  end

  if id ~= pdu.BIND_TRANSMITTER_RESP_CMD and id ~= pdu.BIND_RECEIVER_RESP_CMD and id ~= pdu.BIND_TRANSCEIVER_RESP_CMD then
    local pdu_header = {
      command_length = len,
      command_id = id,
      command_status = sts,
      sequence_num = seq
    }
    return nil, pdu_header, nil
  end

  local system_id = struct.unpack(">s", bytes, 17)
  local ret_val = {
    command_id = id,
    command_status = sts,
    sequence_number = seq,
    system_id = system_id
  }
  return ret_val, nil, nil
end


-- submit_sm & deliver_sm PDUs

-- Those two PDUs has the same structure but a different semantic
-- Use submit_sm for for message sending
-- Use deliver_sm for deliver reports (see short_message field)


local function submit_deliver_request_encode(message_data, command_id, sequence_number)
  local service_type = message_data.service_type or ""
  local source_addr_ton = message_data.source_addr_ton or 0x00
  local source_addr_npi = message_data.source_addr_npi or 0x00
  local source_addr = message_data.source_addr
  local dest_addr_ton = message_data.dest_addr_ton or 0x00
  local dest_addr_npi = message_data.dest_addr_npi or 0x00
  local destination_addr = message_data.destination_addr
  local esm_class = message_data.esm_class or 0x00
  local schedule_delivery_time = message_data.schedule_delivery_time or ""
  local registered_delivery = message_data.registered_delivery or 0x00
  local data_coding = message_data.data_coding or 0x00
  local short_message = message_data.short_message or ""
  local sm_length = string.len(short_message)
  local tlvs = message_data.tlvs

  local tmp_pdu = struct.pack(">IIIIsBBsBBsBBBssBBBBBc" .. sm_length,
                              0x00, command_id, 0x00, sequence_number, -- header
                              service_type, source_addr_ton, source_addr_npi, source_addr,
                              dest_addr_ton, dest_addr_npi, destination_addr, esm_class,
                              0x00, 0x00, schedule_delivery_time, "", registered_delivery,
                              0x00, data_coding, 0x00, sm_length, short_message)

  -- append optional params
  if tlvs ~= nil then
    local tlvs_buf = {}
    for k, v in pairs(tlvs) do
      local l = string.len(v)
      local tlv = struct.pack(">HHc" .. l, k, l, v)
      tlvs_buf[#tlvs_buf + 1] = tlv
    end
    tmp_pdu = tmp_pdu .. table.concat(tlvs_buf)
  end

  return struct.pack(">I", #tmp_pdu) .. string.sub(tmp_pdu, 5)
end


local function submit_deliver_request_decode(bytes)
  local buf_len = string.len(bytes)
  
  if buf_len < 16 then
    return nil, nil, "invalid input. need at least 16 bytes"
  end
  
  local len, id, sts, seq = struct.unpack(">IIII", bytes)

  if buf_len ~= len then
    return nil, nil, "invalid input. corrupted packet"
  end

  if not (id == pdu.SUBMIT_SM_CMD or id == pdu.DELIVER_SM_CMD) then
    local pdu_header = {
      command_length = len,
      command_id = id,
      command_status = sts,
      sequence_num = seq
    }
    return nil, pdu_header, nil
  end

  local srv_type, src_ton, src_npi, src_addr, dest_ton, dest_npi, dest_addr = struct.unpack(">sBBsBBs", bytes, 17)
  -- calc next position. len of service_type, src_addr, dest_addr, ton, npi and pdu header
  local next_pos = string.len(srv_type) + string.len(src_addr) + string.len(dest_addr) + 24
  local esm, _, _, sched, validity, deliv, _, coding, _, sm_len = struct.unpack(">BBBssBBBBB", bytes, next_pos)
  next_pos = next_pos + string.len(sched) + string.len(validity) + 10
  local msg = struct.unpack("c" .. sm_len, bytes, next_pos)

  next_pos = next_pos + sm_len
  local tlvs = {}

  while next_pos < buf_len do
    local tlv_key, tlv_len = struct.unpack(">HH", bytes, next_pos)
    -- +4 for key and len fields
    local tlv_val = struct.unpack(">c" .. tlv_len, bytes, next_pos + 4)
    tlvs[tlv_key] = tlv_val
    next_pos = next_pos + tlv_len + 4
  end

  local ret_val = {
    command_id = id,
    command_status = sts,
    sequence_number = seq,
    service_type = srv_type,
    source_addr_ton = src_ton,
    source_addr_npi = src_npi,
    source_addr = src_addr,
    dest_addr_ton = dest_ton,
    dest_addr_npi = dest_npi,
    destination_addr = dest_addr,
    esm_class = esm,
    schedule_delivery_time = sched,
    registered_delivery = deliv,
    data_coding = coding,
    short_message = msg,
    tlvs = tlvs
  }
  return ret_val, nil, nil
end


function pdu.submit_sm_encode(message_data, sequence_number)
  return submit_deliver_request_encode(message_data, pdu.SUBMIT_SM_CMD, sequence_number)
end


function pdu.submit_sm_decode(bytes)
  return submit_deliver_request_decode(bytes)
end


function pdu.deliver_sm_encode(message_data, sequence_number)
  return submit_deliver_request_encode(message_data, pdu.DELIVER_SM_CMD, sequence_number)
end


function pdu.deliver_sm_decode(bytes)
  return submit_deliver_request_decode(bytes)
end


-- SumitSmResp and DeliverSmsResp PDUs


local function submit_deliver_response_encode(command_id, command_status, message_id, sequence_number)
  local pdu_length = 16 + string.len(message_id) + 1 -- plus 1 for null terminator
  return struct.pack(">IIIIs", pdu_length, command_id, command_status, sequence_number, message_id)
end


local function submit_deliver_response_decode(bytes)
  local buf_len = string.len(bytes)
  if buf_len < 16 then
    return nil, nil, "invalid input. need at least 16 bytes"
  end

  local len, id, sts, seq = struct.unpack(">IIII", bytes)

  if buf_len ~= len then
     return nil, nil, "invalid input. corrupted packet"
  end

  if id ~= pdu.SUBMIT_SM_RESP_CMD and id ~= pdu.DELIVER_SM_RESP_CMD then
    local pdu_header = {
      command_length = len,
      command_id = id,
      command_status = sts,
      sequence_num = seq
    }
    return nil, pdu_header, nil
  end

  local mess_id = struct.unpack(">s", bytes, 17)

  local ret_val = {
    command_id = id,
    command_status = sts,
    sequence_number = seq,
    message_id = mess_id
  }
  return ret_val, nil, nil
end


function pdu.submit_sm_resp_encode(command_status, message_id, sequence_number)
  return submit_deliver_response_encode(pdu.SUBMIT_SM_RESP_CMD, command_status, message_id, sequence_number)
end


function pdu.submit_sm_resp_decode(bytes)
  return submit_deliver_response_decode(bytes)
end


function pdu.deliver_sm_resp_encode(command_status, message_id, sequence_number)
  return submit_deliver_response_encode(pdu.DELIVER_SM_RESP_CMD, command_status, message_id, sequence_number)
end


function pdu.deliver_sm_resp_decode(bytes)
  return submit_deliver_response_decode(bytes)
end


return pdu

