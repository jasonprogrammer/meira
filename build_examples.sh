rm -r ~/.nimble/pkgs2/meira*
nimble install
nim c examples/basic.nim
nim c examples/basic_database.nim
nim c examples/basic_websockets.nim
nim c examples/chat.nim
nim c examples/client_headers.nim
nim c examples/logging_file.nim
nim c examples/middleware.nim
nim c examples/routing_variables.nim
nim c examples/static_files.nim
nim c examples/submit_forms.nim
nim c examples/submit_json.nim
nim c examples/url_params.nim


