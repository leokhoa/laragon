[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C  = SG
ST = Singapore
L  = Singapore
O  = Laragon
OU = IT
CN = laragon

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost

# You can another DNS below. For example:
# DNS.2 = xxx
# DNS.3 = yyy
