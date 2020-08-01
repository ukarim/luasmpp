# luasmpp

SMPP 3.4 implementation in pure Lua.

### Supported PDUs

* `bind_transmitter` and `bind_transmitter_resp`
* `bind_receiver` and `bind_receiver_resp`
* `bind_transceiver` and `bind_transceiver_resp`
* `unbind` and `unbind_resp`
* `submit_sm` and `submit_sm_resp`
* `deliver_sm` and `deliver_sm_resp`
* `enquire_link` and `enquire_link_resp`
* `generic_nack`

### Todo

* Tlv support
* Time formatter
* Delivery Receipt formatter, parser
* Better error handling in decoders

### Dependencies

* lua-struct (runtime)
* luaunit (test)

