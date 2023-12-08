#!/bin/bash
source util.sh

gateway_url=${1:-https://localhost:9443}
echo "Gateway url: $gateway_url"
let "identifier=$RANDOM*$RANDOM"
username=user${identifier}
password=pwd${identifier}

wait_app_ready $gateway_url/api/health/ready $gateway_url/api/accounts/ $username $password

statusCode=$(curl -X 'POST' \
  "$gateway_url/api/auth/login" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "'$username'",
    "password": "'$password'"
  }' \
  --insecure \
  --write-out '%{http_code}' --silent --output response.txt)
assert_equals $statusCode 200
accessToken=$(cat response.txt | jq -r .access_token)

statusCode=$(curl -X 'GET' \
  "$gateway_url/api/accounts/current" \
  -H 'accept: */*' \
  -H "Authorization: Bearer ${accessToken}" \
  --insecure --write-out '%{http_code}' --silent --output response.txt)
assert_equals $statusCode 200
response=$(cat response.txt)
assert_equals "$(get_json_value "$response" ".name")" "$username"
assert_equals "$(get_json_value "$response" ".saving.amount")" 0
assert_equals "$(get_json_value "$response" ".saving.capitalization")" false
assert_equals "$(get_json_value "$response" ".saving.currency")" "USD"
assert_equals "$(get_json_value "$response" ".saving.deposit")" false
assert_equals "$(get_json_value "$response" ".saving.interest")" 0

statusCode=$(curl -X 'PUT' \
  "$gateway_url/api/accounts/current" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${accessToken}" \
  -d '{"incomes":[{"income_id":1,"title":"salary","icon":"wallet","currency":"USD","period":"MONTH","amount":"1000","converted":"1000.000"}],"expenses":[{"expense_id":1,"title":"traffic","icon":"cart","currency":"USD","period":"MONTH","amount":"300","converted":"300.000"}],"saving":{"amount":600,"capitalization":true,"deposit":true,"currency":"USD","interest":"30"}}' \
  --insecure --write-out '%{http_code}' --silent)
assert_equals $statusCode 200

statusCode=$(curl -X 'GET' \
  "$gateway_url/api/accounts/current" \
  -H 'accept: */*' \
  -H "Authorization: Bearer ${accessToken}" \
  --insecure --write-out '%{http_code}' --silent --output response.txt)
assert_equals $statusCode 200
response=$(cat response.txt)
assert_equals "$(get_json_value "$response" ".expenses[0].amount")" 300
assert_equals "$(get_json_value "$response" ".expenses[0].currency")" "USD"
assert_equals "$(get_json_value "$response" ".expenses[0].icon")" "cart"
assert_equals "$(get_json_value "$response" ".expenses[0].period")" "MONTH"
assert_equals "$(get_json_value "$response" ".expenses[0].title")" "traffic"
assert_equals "$(get_json_value "$response" ".incomes[0].amount")" 1000
assert_equals "$(get_json_value "$response" ".incomes[0].currency")" "USD"
assert_equals "$(get_json_value "$response" ".incomes[0].icon")" "wallet"
assert_equals "$(get_json_value "$response" ".incomes[0].period")" "MONTH"
assert_equals "$(get_json_value "$response" ".incomes[0].title")" "salary"
assert_equals "$(get_json_value "$response" ".name")" "$username"
assert_equals "$(get_json_value "$response" ".saving.amount")" 600
assert_equals "$(get_json_value "$response" ".saving.capitalization")" true
assert_equals "$(get_json_value "$response" ".saving.currency")" "USD"
assert_equals "$(get_json_value "$response" ".saving.deposit")" true
assert_equals "$(get_json_value "$response" ".saving.interest")" 30

statusCode=$(curl "$gateway_url/api/statistics/rates" \
  -H 'Accept: */*' \
  --insecure --write-out '%{http_code}' --silent --output response.txt)
assert_equals $statusCode 200
response=$(cat response.txt)
assert_equals "$(get_json_value "$response" ".EUR")" 0.934425
assert_equals "$(get_json_value "$response" ".RUB")" 96.564977
assert_equals "$(get_json_value "$response" ".USD")" 1

rm -rf response.txt
