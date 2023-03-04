# Meira

Meira is a web framework written in Nim.

It is a modified version of [Mummy](https://github.com/guzba/mummy), a
multi-threaded HTTP 1.1 and WebSocket server by Ryan Oldenburg, and also
includes pieces of code from the Jester web framework that have been adapted to
work with Mummy.

The word Meira (ミイラ) means "mummy" in Japanese.

This is currently a hobby project under development, and is not
production-ready.

## Documentation

See [docs and examples](./examples/README.md).

## Progress

- [ ] Static file serving
  - [X] Add initial code
  - [X] Add documentation on serving static files from a directory
  - [ ] Add tests
  - [ ] Add code to display a single static file behind a route
- [X] Route variables
  - [X] Add initial code
  - [X] Add tests
- [ ] Query (GET) parameter handling
  - [ ] Add code on query parameter handling
  - [ ] Add docs on how to handle query params
- [ ] POST handling
  - [ ] POST payload handling
  - [ ] File upload
- [ ] Cookie management
  - [ ] Add code for cookie handling
  - [ ] Add documentation/examples for handling cookies/logins
- [ ] Middleware
  - [ ] Add initial code

## Contact

If you'd like to discuss anything about the project, feel free to contact me
on [Twitter](https://twitter.com/jasonprogrammer) or [Mastodon](https://mastodon.social/@jasonprogrammer).
