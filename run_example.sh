rm -r ~/.nimble/pkgs2/meira*
nimble install
# nim c examples/static_files.nim && ./examples/static_files
# nim c examples/url_params.nim && ./examples/url_params
# nim c examples/submit_forms.nim && ./examples/submit_forms
# nim c examples/submit_json.nim && ./examples/submit_json
# nim c examples/middleware.nim && ./examples/middleware
nim c examples/file_sessions.nim && ./examples/file_sessions


