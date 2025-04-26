Example of how to daisy-chain two WG interfaces. Implements the following setup:
`clients` -> `wg0` -> `wg-warp` -> `internet`

Useful commands:
`docker exec wireguard-server /app/show-peer <1|2|..>`
`docker exec wireguard-server wg show [iface]`
