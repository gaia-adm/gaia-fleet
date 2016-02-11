#!/bin/sh

cp ./dex-worker.service.TEMPLATE ./dex-worker.service

sed -i s/GCI_TEMPLATE/$(echo $GOOGLE_CLIENT_ID)/g ./dex-worker.service
sed -i s/GCS_TEMPLATE/$(echo $GOOGLE_CLIENT_SECRET)/g ./dex-worker.service
sed -i s/MPuK_TEMPLATE/$(echo $MAILGUN_PRIVATE_KEY)/g ./dex-worker.service
sed -i s/MPrK_TEMPLATE/$(echo $MAILGUN_PUBLIC_KEY)/g ./dex-worker.service
sed -i s/MD_TEMPLATE/$(echo $MAILGUN_DOMAIN)/g ./dex-worker.service

# Example with replacing slash to something else
# sed -i s/GCI_TEMPLATE/$(echo $DEX_OVERLORD_ADMIN_API_SECRET | tr '/' '_')/ dex-worker.service
