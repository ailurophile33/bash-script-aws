#!/bin/bash

amazon-linux-extras install nginx1.12 -y

systemctl enable nginx --now

wget -O /usr/share/nginx/html/alexabuy.jpg https://i.redd.it/v7exkf93r34z.jpg

cat << EOF | tee /usr/share/nginx/html/index.html
<html>
<img src="alexabuy.jpg" alt="Alexa Buy Whole Foods">
</html>
EOF