#!/bin/bash
set -euo pipefail

 
# Проверка,установлен ли easy-rsa
if ! command -v easy-rsa &>/dev/null; then
    echo
"Installing Easy-RSA..."
    sudo aptupdate && sudo apt install easy-rsa -y
fi

 
# Каталог для CA
CA_DIR=~/easy-rsa-ca
mkdir -p "$CA_DIR"
cd "$CA_DIR"
 
# Проверка,существует ли уже CA
if [ -f "$CA_DIR/pki/ca.crt" ]; then
    echo
"CA already exists at $CA_DIR/pki/ca.crt"
    exit 1
fi
 
# Копируем шаблоны Easy-RSA
cp -r /usr/share/easy-rsa/* .
 
# Инициализация PKI
./easyrsa init-pki
 
# Созданиекорневого сертификата
echo -e "\n\n\n\n\n\n" | ./easyrsa build-ca
nopass
 
# Проверкауспешного создания
if [ -f "$CA_DIR/pki/ca.crt" ]; then
    echo
"CA successfully created: $CA_DIR/pki/ca.crt"
else
    echo"Error: CA creation failed!"
    exit 1
fi
