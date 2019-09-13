#!/bin/bash

if [[ -a /tmp/server.pid ]]; then
	rm -f /tmp/server.pid
fi

rails server -b 0.0.0.0 -P /tmp/server.pid
