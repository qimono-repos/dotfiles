#!/bin/bash

curl -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-X POST -d '{
    "image": "linode/ubuntu24.10",
    "private_ip": false,
    "region": "au-mel",
    "type": "g6-nanode-1",
    "label": "sat-lino-au",
    "tags": [
        "saturno"
    ],
    "root_pass": $PASSWORD_LINODE
}' https://api.linode.com/v4/linode/instances
