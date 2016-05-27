#!/bin/bash
set -e
set -o pipefail

if [ "$EUID" -ne 1000 ]
  then echo "build requires non root user access"
  exit
fi

GDAL_VER=2.1.0
GEOS_VER=3.5.0
PY_VER=2.7.11
PROJ_VER=4.9.2
KML_VER=1.3.0
PG_VER=9.5.3

export PATH="/app/.heroku/vendor/bin:/app/.heroku/python/bin":"${PATH}"
export LD_LIBRARY_PATH="/app/.heroku/vendor/lib/:/app/.heroku/python/lib/":"{$LD_LIBRARY_PATH}"
export LIBRARY_PATH="/app/.heroku/vendor/lib/:/app/.heroku/python/lib/":"${LIBRARY_PATH}"
export INCLUDE_PATH="/app/.heroku/vendor/include/":"${INCLUDE_PATH}"
export PKG_CONFIG="/app/.heroku/vendor/lib/pkgconfig/":"${PKG_CONFIG}"
export CPATH="${INCLUDE_PATH}"
export CPPPATH="${INCLUDE_PATH}"
export LIBKML_CFLAGS="${INCLUDE_PATH}"
export LIBKML_LIBS="${LIBRARY_PATH}"

sudo apt-get update -y
sudo apt-get install -y build-essential \
                   cmake \
                   libexpat1-dev \
                   libffi-dev \
                   libfreetype6-dev \
                   libjpeg-dev \
                   libldap2-dev \
                   libsasl2-dev \
                   libssl-dev \
                   libsqlite3-dev \
                   libxml2-dev \
                   libxslt1-dev \
                   tk-dev \
                   zlib1g-dev \
                   unzip \
                   wget

if [ -d /app ]; then
    sudo rm -fr /app
fi
sudo mkdir -p /app/.heroku && sudo chmod -R 777 /app
pushd /app/.heroku
wget https://s3.amazonaws.com/boundlessps-public/cf/raster-vendor-libs.zip
unzip raster-vendor-libs.zip && rm raster-vendor-libs.zip
pushd vendor/lib
ln -s libNCSCnet.so.0.0.0 libNCSCnet.so
ln -s libNCSCnet.so.0.0.0 libNCSCnet.so.0
ln -s libNCSEcwC.so.0.0.0 libNCSEcwC.so
ln -s libNCSEcwC.so.0.0.0 libNCSEcwC.so.0
ln -s libNCSEcw.so.0.0.0 libNCSEcw.so
ln -s libNCSEcw.so.0.0.0 libNCSEcw.so.0
ln -s libNCSUtil.so.0.0.0 libNCSUtil.so
ln -s libNCSUtil.so.0.0.0 libNCSUtil.so.0
ln -s libltidsdk.so.8 libltidsdk.so
ln -s liblti_lidar_dsdk.so.1 liblti_lidar_dsdk.so
popd
popd

pushd ~

if [ ! -f postgresql-$PG_VER.tar.gz ]; then
    wget https://ftp.postgresql.org/pub/source/v$PG_VER/postgresql-$PG_VER.tar.gz
fi
tar xf postgresql-$PG_VER.tar.gz
pushd postgresql-$PG_VER
sed --in-place '/fmgroids/d' src/include/Makefile
./configure --prefix=/app/.heroku/vendor --without-readline
make -C src/bin install
make -C src/include install
make -C src/interfaces install
make -C doc install
popd

if [ ! -f $KML_VER.tar.gz ]; then
    wget https://github.com/libkml/libkml/archive/1.3.0.tar.gz
fi
tar xf $KML_VER.tar.gz
mkdir -p libkml-$KML_VER/build
pushd libkml-$KML_VER/build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/app/.heroku/vendor ..
make && make install
popd && rm -fr libkml-$KML_VER

if [ ! -f geos-$GEOS_VER.tar.bz2 ]; then
    wget http://download.osgeo.org/geos/geos-$GEOS_VER.tar.bz2
fi
tar xf geos-$GEOS_VER.tar.bz2
pushd geos-$GEOS_VER/
./configure --prefix=/app/.heroku/vendor/
make && make install
popd && rm -fr geos-$GEOS_VER

if [ ! -f proj-$PROJ_VER.tar.gz ]; then
    wget http://download.osgeo.org/proj/proj-$PROJ_VER.tar.gz
fi
tar xf proj-$PROJ_VER.tar.gz
pushd proj-$PROJ_VER/
./configure --prefix=/app/.heroku/vendor/
make && make install
popd && rm -fr proj-$PROJ_VER

if [ ! -f gdal-$GDAL_VER.tar.gz ]; then
    wget http://download.osgeo.org/gdal/$GDAL_VER/gdal-$GDAL_VER.tar.gz
fi
tar xf gdal-$GDAL_VER.tar.gz
pushd gdal-$GDAL_VER/
./configure --prefix=/app/.heroku/vendor/ \
    --with-jpeg \
    --with-png=internal \
    --with-geotiff=internal \
    --with-libtiff=internal \
    --with-libz=internal \
    --with-curl \
    --with-gif=internal \
    --with-geos=/app/.heroku/vendor/bin/geos-config \
    --without-expat \
    --with-threads \
    --with-ecw=/app/.heroku/vendor \
    --with-mrsid=/app/.heroku/vendor \
    --with-mrsid_lidar=/app/.heroku/vendor \
    --with-libkml=/app/.heroku/vendor \
    --with-libkml-inc=/app/.heroku/vendor/include/kml \
    --with-pg=/app/.heroku/vendor/bin/pg_config

make && make install
popd && rm -fr gdal-$GDAL_VER/
popd
if [ -d vendor/include/boost ]; then
    rm -fr vendor/include/boost
fi
pushd /app/.heroku/
if [ -f /vagrant/vendor.tar.gz ]; then
    rm -f /vagrant/vendor.tar.gz
fi
tar -zcf vendor.tar.gz vendor/ && mv vendor.tar.gz /vagrant/
popd

pushd ~
if [ ! -f Python-$PY_VER.tgz ]; then
    wget https://www.python.org/ftp/python/$PY_VER/Python-$PY_VER.tgz
fi
tar xfz Python-$PY_VER.tgz
pushd Python-$PY_VER
./configure --prefix /usr/local --enable-ipv6
make && sudo make install
popd && rm -fr Python-$PY_VER
popd


curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo /usr/local/bin/python
sudo /usr/local/bin/pip install virtualenv
pushd /app/.heroku/
/usr/local/bin/virtualenv python
source python/bin/activate
/usr/local/bin/pip wheel --wheel-dir=/vagrant/wheels -r /vagrant/pip_dep.txt
