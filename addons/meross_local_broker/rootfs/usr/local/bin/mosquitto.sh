#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json
MQTT_CERTS_FOLDER_PATH=/data/mqtt/certs
MQTT_CA_KEY_PATH="$MQTT_CERTS_FOLDER_PATH/ca.key"
MQTT_CA_CRT_PATH="$MQTT_CERTS_FOLDER_PATH/ca.crt"
MQTT_SERVER_KEY_PATH="$MQTT_CERTS_FOLDER_PATH/server.key"
MQTT_SERVER_CRT_PATH="$MQTT_CERTS_FOLDER_PATH/server.crt"
MQTT_CA_KEY_SECRET=notasecret
MQTT_CA_CONFIG_PATH=/etc/mosquitto/certs/ca.conf
MQTT_SERVER_CONFIG_PATH=/etc/mosquitto/certs/server.conf
MQTT_MOSQUITTO_CONF_PATH=/etc/mosquitto/mosquitto.conf

# Generate mosquitto certificates
bashio::log.info "Checking for RSA keys..."
if [[ ! -d $MQTT_CERTS_FOLDER_PATH ]]; then
  mkdir -p $MQTT_CERTS_FOLDER_PATH
fi
if [[ ! -f $MQTT_CA_KEY_PATH ]] || [[ ! -f $MQTT_CA_CRT_PATH ]] || [[ ! -f $MQTT_SERVER_KEY_PATH ]] || [[ ! -f $MQTT_SERVER_CRT_PATH ]]; then
  bashio::log.warning "One or more certificate files are not present on the system. Generating certificates from scratch..."
  rm -R $MQTT_CERTS_FOLDER_PATH
  mkdir -p $MQTT_CERTS_FOLDER_PATH

  openssl genrsa -des3 -out $MQTT_CA_KEY_PATH -passout pass:$MQTT_CA_KEY_SECRET 2048
  openssl req -new -x509 -days 3600 -key $MQTT_CA_KEY_PATH -out $MQTT_CA_CRT_PATH -passin pass:$MQTT_CA_KEY_SECRET -config $MQTT_CA_CONFIG_PATH
  openssl genrsa -out $MQTT_SERVER_KEY_PATH 2048
  openssl req -new -out /tmp/server.csr -key $MQTT_SERVER_KEY_PATH -config $MQTT_SERVER_CONFIG_PATH
  openssl x509 -req -in /tmp/server.csr -CA $MQTT_CA_CRT_PATH -CAkey $MQTT_CA_KEY_PATH -CAcreateserial -out $MQTT_SERVER_CRT_PATH -days 3600 -passin pass:$MQTT_CA_KEY_SECRET
else
  bashio::log.info "All certificate files seems present."
fi

bashio::log.info "Starting mosquitto..."
mosquitto -c $MQTT_MOSQUITTO_CONF_PATH