#!/bin/bash
set -e

echo "Pod install"
pod install
echo "delete old files"
rm -f ./ClashX/Resources/geosite.db
rm -f ./ClashX/Resources/geoip.db
rm -rf ./ClashX/Resources/dashboard
echo "install geosite"
curl -LO https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db
gzip geosite.db
mv geosite.db.gz ./ClashX/Resources/geosite.db.gz
echo "install geoip"
curl -LO https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db
gzip geoip.db
mv geoip.db.gz ./ClashX/Resources/geoip.db.gz
echo "install dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/haishanh/yacd.git dashboard
