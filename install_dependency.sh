#!/bin/bash
set -e

echo "Download meta core"
rm -rf clash.meta
mkdir clash.meta
cd clash.meta
curl -s https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/latest | grep -wo "https.*darwin.*.gz" > meta.txt
cat meta.txt
wget -i meta.txt
echo "Unzip core files"
gzip -d *.gz
echo "Create Universal core"
lipo -create -output com.metacubex.ClashX.ProxyConfigHelper.meta Clash.Meta-darwin-amd64* Clash.Meta-darwin-arm64*
chmod +x com.metacubex.ClashX.ProxyConfigHelper.meta

echo "Update meta core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q com.metacubex.ClashX.ProxyConfigHelper.meta)/g" ../ClashX/AppDelegate.swift
sed -n '20p' ../ClashX/AppDelegate.swift

echo "Gzip Universal core"
gzip com.metacubex.ClashX.ProxyConfigHelper.meta
cp com.metacubex.ClashX.ProxyConfigHelper.meta.gz ../ClashX/Resources/
cd ..

echo "Pod install"
pod install
echo "delete old files"
rm -f ./ClashX/Resources/Country.mmdb
rm -f ./ClashX/Resources/geosite.dat
rm -f ./ClashX/Resources/geoip.dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
gzip Country.mmdb
mv Country.mmdb.gz ./ClashX/Resources/Country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./ClashX/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./ClashX/Resources/geoip.dat.gz
echo "install dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/haishanh/yacd.git dashboard
