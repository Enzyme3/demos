# Apigee AppMod Rewind Script
set -e

echo "====Starting Apigee Rewind Script===="
[ -z "$APIGEE_USER" ] && { echo "Need to set APIGEE_USER"; exit 1; }
[ -z "$APIGEE_PW" ] && { echo "Need to set APIGEE_PW"; exit 1; }
[ -z "$APIGEE_ORG" ] && { echo "Need to set APIGEE_ORG"; exit 1; }

APIGEE_ENV=test
PROXY_NAME=catalog
PRODUCT_NAME=catalog-Product
APP_NAME="Product-App"

# Upload New Proxy
echo "====Uploading new proxy 'catalog'===="
uploadResponse=$(curl -X POST --fail -u ${APIGEE_USER}:${APIGEE_PW} -F "file=@apiproxy.zip" "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/apis?action=import&name=${PROXY_NAME}")
revision=$( jq -r  '.revision' <<< "${uploadResponse}" )
echo ""
echo "====Upload complete - revision: ${revision}===="

# Deploy uploaded proxy
echo "====Deploying proxy catalog to org:${APIGEE_ORG} and env:${APIGEE_ENV}===="
curl -X POST --fail -u ${APIGEE_USER}:${APIGEE_PW} --header "Content-Type: application/x-www-form-urlencoded" "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/environments/${APIGEE_ENV}/apis/${PROXY_NAME}/revisions/${revision}/deployments?override=true"
echo ""
echo "====Deployment complete===="

echo "====Cleaning up app, developer, and product===="
curl -X DELETE -u ${APIGEE_USER}:${APIGEE_PW} "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/developers/alice.smith@gmail.com/apps/${APP_NAME}"
curl -X DELETE -u ${APIGEE_USER}:${APIGEE_PW} "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/developers/alice.smith@gmail.com"
curl -X DELETE -u ${APIGEE_USER}:${APIGEE_PW} "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/apiproducts/${PRODUCT_NAME}"
echo "====Cleanup completed===="

# Create Product
echo "====Creating product: ${PRODUCT_NAME}===="
curl -X POST --fail -u ${APIGEE_USER}:${APIGEE_PW} --header "Content-Type: application/json" -d "{
  \"name\" : \"${PRODUCT_NAME}\",
  \"displayName\": \"${PRODUCT_NAME}\",
  \"approvalType\": \"auto\",
  \"attributes\": [],
  \"description\": \"${PRODUCT_NAME}\",
  \"apiResources\": [ \"/\", \"/**\"],
  \"environments\": [ \"test\", \"prod\"],
  \"proxies\": [\"${PROXY_NAME}\"],
  \"quota\": \"3\",
  \"quotaInterval\": \"1\",
  \"quotaTimeUnit\": \"minute\",
    \"scopes\": []
}" "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/apiproducts"
echo ""
echo "====Product created===="

# Create Developer
echo "====Creating developer===="
curl -X POST --fail -u ${APIGEE_USER}:${APIGEE_PW} --header "Content-Type: application/json" -d "{
 \"email\" : \"alice.smith@gmail.com\",
 \"firstName\" : \"Alice\",
 \"lastName\" : \"Smith\",
 \"userName\" : \"alice.smith@gmail.com\",
 \"attributes\" : []
}" "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/developers"
echo ""
echo "====Developer created===="

# Create App
echo "====Creating app: ${APP_NAME}===="
app=$(curl -X POST --fail -u ${APIGEE_USER}:${APIGEE_PW} --header "Content-Type: application/json" -d "{
 \"name\" : \"${APP_NAME}\",
 \"apiProducts\": [ \"${PRODUCT_NAME}\"],
 \"keyExpiresIn\" : -1,
 \"attributes\" : [],
 \"scopes\" : []
}" "https://api.enterprise.apigee.com/v1/organizations/${APIGEE_ORG}/developers/alice.smith@gmail.com/apps")
echo ""
echo "====App Created===="

apikey=$( jq -r  '.credentials[0].consumerKey' <<< "${app}" )
echo ""
echo "==========="
echo "Rewind succeeded"
echo "Save and use the apikey for this lab: ${apikey}"
