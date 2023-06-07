#!/bin/bash
set -e

echo "Unzip core files"
cd sing-box.core
ls
tar -xvf sing-box*arm64*
tar -xvf sing-box*amd64*

echo "Create Universal core"
lipo -create -output com.SagerNet.sing-box.ProxyConfigHelper.core sing-box*arm64*/sing-box sing-box*amd64*/sing-box
chmod +x com.SagerNet.sing-box.ProxyConfigHelper.core

echo "Update meta core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q com.SagerNet.sing-box.ProxyConfigHelper.core)/g" ../ClashX/AppDelegate.swift
sed -n '20p' ../ClashX/AppDelegate.swift

echo "Gzip Universal core"
gzip com.SagerNet.sing-box.ProxyConfigHelper.core
cp com.SagerNet.sing-box.ProxyConfigHelper.core.gz ../ClashX/Resources/
cd ..



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
git clone -b gh-pages https://github.com/OstaraYggdrasil/yacd.git dashboard
