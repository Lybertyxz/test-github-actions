#!/bin/bash

DEFAULT="\033[0;29m"
INFO="\033[0;34m"
SUCCESS="\033[0;32m"
ERROR="\033[0;31m"

function LOG() {
    echo -e $1$2$DEFAULT
}

###
### Environment and constants
###
LOG $INFO "Initializing development environment"

# Docker compose
LOG_LEVEL=0
export LOG_LEVEL

# Elasticsearch
ELASTICSEARCH_ADDR="http://localhost:9200"
export ELASTICSEARCH_ADDR

# Gcloud datastore emulator
DATASTORE_EMULATOR_HOST="localhost:8081"
export DATASTORE_EMULATOR_HOST

# Gcloud pubsub emulator
PUBSUB_EMULATOR_HOST="localhost:8085"
export PUBSUB_EMULATOR_HOST

# Memcache redis
MEMCACHE_HOST="localhost"
MEMCACHE_PORT="6379"

for arg in "$@"; do
    if [ $arg == "-v" ]; then
        export LOG_LEVEL=5 #Debug level
    fi
done

###
### Services check
###

# Elasticsearch up check
LOG $INFO "Testing connection to Elasticsearch..."
es_ping_result=$(curl --write-out '%{http_code}' --silent --output /dev/null ${ELASTICSEARCH_ADDR})
if [ $es_ping_result == "200" ]; then
    LOG $SUCCESS "Elasticsearch local cluster found at ${ELASTICSEARCH_ADDR}"
else
    LOG $ERROR "Elasticsearch local cluster not found at ${ELASTICSEARCH_ADDR}"
    exit 1
fi

# Datastore up check
LOG $INFO "Testing connection to Datastore emulator..."
ds_ping_result=$(curl --write-out '%{http_code}' --silent --output /dev/null http://$DATASTORE_EMULATOR_HOST)
if [ $ds_ping_result == "200" ]; then
    LOG $SUCCESS "Datastore emulator found at $DATASTORE_EMULATOR_HOST"
    LOG $DEFAULT "Deleting all Datastore data"
    curl -m 5.0 -s -XPOST "http://$DATASTORE_EMULATOR_HOST/reset"
else
    LOG $ERROR "Datastore emulator not found at $DATASTORE_EMULATOR_HOST"
    exit 1
fi

# Pubsub up check
LOG $INFO "Testing connection to PubSub emulator..."
ds_ping_result=$(curl --write-out '%{http_code}' --silent --output /dev/null http://$PUBSUB_EMULATOR_HOST)
if [ $ds_ping_result == "200" ]; then
    LOG $SUCCESS "PubSub emulator found at $PUBSUB_EMULATOR_HOST"
else
    LOG $ERROR "PubSub emulator not found at $PUBSUB_EMULATOR_HOST"
    exit 1
fi

# Memcache check
LOG $INFO "Testing connection to Memcache service..."
mem_ping_result=$(printf "PING\r\n" | nc localhost 6379)
if [[ $mem_ping_result == *"PONG"* ]]; then
    LOG $SUCCESS "Memcache service found at $MEMCACHE_HOST:$MEMCACHE_PORT"
    LOG $DEFAULT "Deleting all Cached data"
    redis-cli -h $MEMCACHE_HOST -p $MEMCACHE_PORT FLUSHALL
else
    LOG $ERROR "Memcache service not found at $MEMCACHE_HOST:$MEMCACHE_PORT"
    exit 1
fi