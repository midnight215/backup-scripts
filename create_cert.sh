#!/bin/bash
set -euo pipefail

 
# Проверкааргумента
if [ -z "${1:-}" ]; then
    echo
"Usage: $0 <client_name>"
    exit 1
fi
 
CLIENT_NAME="$1"
CA_DIR=~/easy-rsa-ca
 
# Проверка наличия CA
if [ ! -d "$CA_DIR/pki" ] || [ ! -f "$CA_DIR/pki/ca.crt"
] || [ ! -f "$CA_DIR/pki/private/ca.key" ]; then
    echo"CA not found! Run setup_ca.sh first."
    exit 1

fi
 
cd "$CA_DIR"
 
# Созданиеклиентского запроса и подпись
./easyrsa gen-req "$CLIENT_NAME" nopass
./easyrsa sign-req client "$CLIENT_NAME"
 
# Проверка файлов
if [ -f
"$CA_DIR/pki/private/$CLIENT_NAME.key" ] && [ -f"$CA_DIR/pki/issued/$CLIENT_NAME.crt" ]; then
    echo
"Client certificate for '$CLIENT_NAME' created successfully:"
    echo"  Key:
$CA_DIR/pki/private/$CLIENT_NAME.key"
    echo"  Cert:
$CA_DIR/pki/issued/$CLIENT_NAME.crt"
else
    echo"Error: Failed to create client certificate!"
    exit 1
fi
