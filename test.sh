#!/bin/bash

# 设置变量
app_id="102809211"
app_secret="OyY8iJuV6hItV7jLxZBoR4hKxaDrV9nR"
url="https://bots.qq.com/app/getAppAccessToken"

# 使用curl发送请求
# 将响应结果存入response变量，同时将HTTP状态码存入status_code变量
response=$(curl --silent --location --write-out "%{http_code}" --output - \
--header 'Content-Type: application/json' \
--data '{
  "appId": "'"$app_id"'",
  "clientSecret": "'"$app_secret"'"
}' "$url")

# 从response中提取HTTP状态码（最后3个字符）
http_code="${response: -3}"

# 判断请求是否成功（根据HTTP状态码，例如200表示成功）
if [ "$http_code" -eq 200 ]; then
    echo "请求成功！"
    # 输出响应体（去掉最后3个字符的状态码）
    echo "响应内容：${response%???}"
else
    echo "请求失败，HTTP状态码：$http_code"
    echo "错误信息：$response"
    exit 1 # 脚本异常退出
fi
