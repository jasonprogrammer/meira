rm -r ~/.nimble/pkgs2/meira*
nimble install
# nim c examples/static_files.nim && ./examples/static_files
# nim c examples/url_params.nim && ./examples/url_params
nim c examples/submit_forms.nim && ./examples/submit_forms


