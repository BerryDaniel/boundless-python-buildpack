# Cloud Foundry GeoNode Python Buildpack
## (Fork of Python Buildpack)

This is based on the [Heroku buildpack](https://github.com/heroku/heroku-buildpack-python).

This buildpack supports running GeoNode with the following additions:

* geonode compile hook that bootstraps the following vendor and python additions
 * https://s3.amazonaws.com/boundlessps-public/cf/vendor.tar.gz
    * GDAL 2.0.1
    * GEOS 3.5.0
    * PROJ.4 4.9.2
 * https://s3.amazonaws.com/boundlessps-public/cf/python.tar.gz
    * GDAL 2.0.1 python module
    * python-ldap 2.4.25 python module
    * django-auth-ldap 1.2.7 python module
* geonode.sh profile.d script
* required symlinks for GDAL, GEOS and PROJ libraries
* Upgraded Setuptools to 20.2.2
* Upgraded PIP to 8.0.3

## Usage

In order for this buildpack to bootstrap the additions above, a `cf` directory must exist with a `requirements.txt` file
GDAL, python-ldap and django-auth-ldap should not be an entry in `requirements.txt`, since this buildpack will add the required GDAL python module.

1. Use in Cloud Foundry

    Add the geonode-python-buildpack entry in your manifest.yml

    Example:

    ```yml
    ---
    applications:
      - name: cf-geonode
    buildpack: https://github.com/boundlessgeo/geonode-python-buildpack
    command: null
    instances: 1
    memory: 1G
    disk_quota: 2G
    services:
      - geonode_db
    env:
      SECRET_KEY: 'aadc-t8j*i5a7^y9@d^$at#g0!j_h=h++5stj=nb7z8u#l_y#&'
      DEBUG: 'True'
    ```

__Note:__ Although the python buildpack is MIT-licensed, which is compatible with LGPL, the Cloud Foundry product as a whole is licensed under ASF, which is not compatible with LGPL. The custom geonode python buildpack was created from a fork of the python buildpack, which includes GEOS (licensed under the LGPL).
