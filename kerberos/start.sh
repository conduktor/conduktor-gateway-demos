#!/bin/bash

generate_certificate_user() {
    local user=$1

    local log_file="certs-create-$user.log"

    # Create host keystore
    keytool -genkey -noprompt \
                -alias $user \
                -dname "CN=$user,OU=TEST,O=CONDUKTOR,L=LONDON,C=UK" \
                            -ext "SAN=dns:$user,dns:localhost" \
                -keystore kafka.$user.keystore.jks \
                -keyalg RSA \
                -storepass conduktor \
                -keypass conduktor \
                -storetype pkcs12 &> $log_file

    # Create the certificate signing request (CSR)
    keytool -keystore kafka.$user.keystore.jks -alias $user -certreq -file $user.csr -storepass conduktor -keypass conduktor -ext "SAN=dns:$user,dns:localhost" >> $log_file
    #openssl req -in $user.csr -text -noout

    DNS_ALT_NAMES=$(printf '%s\n' "DNS.1 = $user" "DNS.2 = localhost")

    # Sign the host certificate with the certificate authority (CA)
    # Set a random serial number (avoid problems from using '-CAcreateserial' when parallelizing certificate generation)
    CERT_SERIAL=$(awk -v seed="$RANDOM" 'BEGIN { srand(seed); printf("0x%.4x%.4x%.4x%.4x\n", rand()*65535 + 1, rand()*65535 + 1, rand()*65535 + 1, rand()*65535 + 1) }')
    openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in $user.csr -out $user-ca1-signed.crt -sha256 -days 365 -set_serial ${CERT_SERIAL} -passin pass:conduktor -extensions v3_req -extfile <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = $user
[v3_req]
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
$DNS_ALT_NAMES
EOF
) >> $log_file
    #openssl x509 -noout -text -in $user-ca1-signed.crt

    # Sign and import the CA cert into the keystore
    keytool -noprompt -keystore kafka.$user.keystore.jks -alias snakeoil-caroot -import -file snakeoil-ca-1.crt -storepass conduktor -keypass conduktor >> $log_file
    #keytool -list -v -keystore kafka.$user.keystore.jks -storepass conduktor

    # Sign and import the host certificate into the keystore
    keytool -noprompt -keystore kafka.$user.keystore.jks -alias $user -import -file $user-ca1-signed.crt -storepass conduktor -keypass conduktor -ext "SAN=dns:$user,dns:localhost" >> $log_file
    #keytool -list -v -keystore kafka.$user.keystore.jks -storepass conduktor

    # Create truststore and import the CA cert
    keytool -noprompt -keystore kafka.$user.truststore.jks -alias snakeoil-caroot -import -file snakeoil-ca-1.crt -storepass conduktor -keypass conduktor >> $log_file

    # Save creds
    echo "conduktor" > ${user}_sslkey_creds
    echo "conduktor" > ${user}_keystore_creds
    echo "conduktor" > ${user}_truststore_creds

    # Create pem files and keys used for Schema Registry HTTPS testing
    #   openssl x509 -noout -modulus -in client.certificate.pem | openssl md5
    #   openssl rsa -noout -modulus -in client.key | openssl md5
    #   echo "GET /" | openssl s_client -connect localhost:8085/subjects -cert client.certificate.pem -key client.key -tls1
    keytool -export -alias $user -file $user.der -keystore kafka.$user.keystore.jks -storepass conduktor 2>> $log_file
    openssl x509 -inform der -in $user.der -out $user.certificate.pem 2>> $log_file
    keytool -importkeystore -srckeystore kafka.$user.keystore.jks -destkeystore $user.keystore.p12 -deststoretype PKCS12 -deststorepass conduktor -srcstorepass conduktor -noprompt 2>> $log_file
    openssl pkcs12 -in $user.keystore.p12 -nodes -nocerts -out $user.key -passin pass:conduktor 2>> $log_file

}

generate_certificate() {
  (cd security; generate_certificate_user "$1")
}

clean_certificates() {
  (cd security; rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12 *.log *.keytab)
}

generate_ca_cert() {
  (cd security; openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.conduktor.io/OU=TEST/O=CONDUKTOR/L=LONDON/C=UK' -passin pass:conduktor -passout pass:conduktor)
}


clean_certificates
generate_ca_cert

for user in kafka-1.kerberos-demo.local kafka-2.kerberos-demo.local kafka-3.kerberos-demo.local
do
    generate_certificate $user
done

docker compose build

echo "Starting KDC"
docker compose up -d kdc --wait

echo "Creating keytabs"
### Create the required identities:
# Kafka service principal:
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey kafka/kafka-1.kerberos-demo.local@TEST.CONDUKTOR.IO"
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey kafka/kafka-2.kerberos-demo.local@TEST.CONDUKTOR.IO"
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey kafka/kafka-3.kerberos-demo.local@TEST.CONDUKTOR.IO"

# Zookeeper service principal:
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey zookeeper/zookeeper.kerberos-demo.local@TEST.CONDUKTOR.IO"

# Create a principal with which to connect to Zookeeper from brokers - NB use the same credential on all brokers!
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey zkclient@TEST.CONDUKTOR.IO"

# Create an admin principal for the cluster, which we'll use to setup ACLs.
# Look after this - its also declared a super user in broker config.
docker exec -ti kdc kadmin.local -w password -q "add_principal -randkey admin/for-kafka@TEST.CONDUKTOR.IO"

# Create keytabs to use for Kafka
docker exec -ti kdc rm -f "/etc/kafka/secrets/*.keytab" 2>&1

docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/kafka-1.keytab -norandkey kafka/kafka-1.kerberos-demo.local@TEST.CONDUKTOR.IO "
docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/kafka-2.keytab -norandkey kafka/kafka-2.kerberos-demo.local@TEST.CONDUKTOR.IO "
docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/kafka-3.keytab -norandkey kafka/kafka-3.kerberos-demo.local@TEST.CONDUKTOR.IO "
docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/zookeeper.keytab -norandkey zookeeper/zookeeper.kerberos-demo.local@TEST.CONDUKTOR.IO "
docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/zookeeper-client.keytab -norandkey zkclient@TEST.CONDUKTOR.IO "
docker exec -ti kdc kadmin.local -w password -q "ktadd  -k /etc/kafka/secrets/kafka-admin.keytab -norandkey admin/for-kafka@TEST.CONDUKTOR.IO "
# change permissions
docker exec -ti kdc bash -c 'chmod a+r /etc/kafka/secrets/*.keytab'


docker compose up --detach --wait

