#!/bin/bash

# Build and upload to fpga

echo "Building and uploading to fpga"
cargo build --target armv7-unknown-linux-gnueabihf --release

echo "Uploading to fpga"
scp target/armv7-unknown-linux-gnueabihf/release/mand-cluster-http-proxy fpga:~