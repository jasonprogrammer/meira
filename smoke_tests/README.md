Note: This fuzzing section was copied verbatim from
[the Mummy docs](https://github.com/guzba/mummy/blob/master/README.md).

## Fuzzing

A fuzzer has been run against Mummy's socket reading and parsing code to ensure
Mummy does not crash or otherwise misbehave on bad data from sockets. You can
run the fuzzer any time by running `nim c -r tests/fuzz_recv.nim`.
