#!/bin/bash

# Copyright 2014 Fluo authors (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

rm -f $DOWNLOADS/*.asc
rm -f $DOWNLOADS/*.md5

ACCUMULO_PATH=accumulo/$ACCUMULO_VERSION
if [ -f "$DOWNLOADS/$ACCUMULO_TARBALL" ]; then
  echo "$ACCUMULO_TARBALL already exists in downloads/"
else
  wget -P $DOWNLOADS $APACHE_MIRROR/$ACCUMULO_PATH/$ACCUMULO_TARBALL
fi

HADOOP_PATH=hadoop/common/hadoop-$HADOOP_VERSION
if [ -f "$DOWNLOADS/$HADOOP_TARBALL" ]; then
  echo "$HADOOP_TARBALL already exists in downloads/"
else
  wget -P $DOWNLOADS $APACHE_MIRROR/$HADOOP_PATH/$HADOOP_TARBALL
fi

ZOOKEEPER_PATH=zookeeper/zookeeper-$ZOOKEEPER_VERSION
if [ -f "$DOWNLOADS/$ZOOKEEPER_TARBALL" ]; then
  echo "$ZOOKEEPER_TARBALL already exists in downloads/"
else
  wget -P $DOWNLOADS $APACHE_MIRROR/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL
fi

APACHE=https://www.apache.org/dist

echo -e "\nDownloading files hashes from Apache:"
wget -nv -O $DOWNLOADS/$ACCUMULO_TARBALL.md5 $APACHE/$ACCUMULO_PATH/MD5SUM
wget -nv -P $DOWNLOADS $APACHE/$HADOOP_PATH/$HADOOP_TARBALL.md5
wget -nv -P $DOWNLOADS $APACHE/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL.md5

echo -e "\nPlease confirm that the file hashes below match:"
echo -e "\nActual hashes generated from files using '$MD5':\n"
$MD5 $DOWNLOADS/*.tar.gz
echo -e "\nExpected hashes from Apache:\n"
cat $DOWNLOADS/*.md5

if hash gpg 2>/dev/null; then
  echo -e "\nDownloading signatures from Apache:"
  wget -nv -P $DOWNLOADS $APACHE/$ACCUMULO_PATH/$ACCUMULO_TARBALL.asc
  wget -nv -P $DOWNLOADS $APACHE/$HADOOP_PATH/$HADOOP_TARBALL.asc
  wget -nv -P $DOWNLOADS $APACHE/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL.asc

  echo -e "\nVerifying the authenticity of tarballs using gpg and downloaded signatures:"
  echo -e "\nVerifying $ACCUMULO_TARBALL" 
  gpg --verify $DOWNLOADS/$ACCUMULO_TARBALL.asc $DOWNLOADS/$ACCUMULO_TARBALL
  echo -e "\nverifying $HADOOP_TARBALL" 
  gpg --verify $DOWNLOADS/$HADOOP_TARBALL.asc $DOWNLOADS/$HADOOP_TARBALL
  echo -e "\nVerifying $ZOOKEEPER_TARBALL" 
  gpg --verify $DOWNLOADS/$ZOOKEEPER_TARBALL.asc $DOWNLOADS/$ZOOKEEPER_TARBALL
else
  echo -e "\nERROR - The command 'gpg' is NOT installed!  Please install to verify signatures of downloaded tarballs."
fi
