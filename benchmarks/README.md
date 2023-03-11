Note: This benchmarks section was copied verbatim from
[the Mummy benchmarks](https://github.com/guzba/mummy/blob/master/README.md).

## Benchmarks

Benchmarking was done on an Ubuntu 22.04 server with a 4 core / 8 thread CPU.

The tests/wrk_ servers that are being benchmarked attempt to simulate requests that take ~10ms to complete.

All benchmarks were tested by:

`wrk -t10 -c100 -d10s http://localhost:8080`

The exact commands for each server are:

### Mummy

`nim c --mm:orc --threads:on -d:release -r tests/wrk_mummy.nim`

Requests/sec: 9,547.56

### AsyncHttpServer

`nim c --mm:orc --threads:off -d:release -r tests/wrk_asynchttpserver.nim`

Requests/sec: 7,979.67

### HttpBeast

`nim c --mm:orc --threads:on -d:release -r tests/wrk_httpbeast.nim`

Requests/sec: 9,862.00

### Jester

`nim c --mm:orc --threads:off -d:release -r tests/wrk_jester.nim`

Requests/sec: 9,692.81

### Prologue

`nim c --mm:orc --threads:off -d:release -r tests/wrk_prologue.nim`

Requests/sec: 9,749.22

### NodeJS

`node tests/wrk_node.js`

Requests/sec:   8,544.60

### Go

`go run tests/wrk_go.go`

Requests/sec:   9,171.55
