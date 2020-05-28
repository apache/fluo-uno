Ubuntu 18.04 prep
-----------------

The following commands are one possible way to quickly prepare an instance of
Ubuntu 18.04 for Uno.

```bash
#install stuff
sudo apt install openjdk-11-jdk maven git openssh-server wget libxml2-utils make g++ libsnappy1v5

#setup passwordless ssh
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#add java home before interactive section, will take effect on shell restart
#this may not work properly in your environment, looks for phrase in stock ubuntu .bashrc
sed -i '/# for examples/a export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' ~/.bashrc

#set java home in current shell
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Optional: set OS limits.  Could do this with an editor. Could replace * with user running Uno.  
cat <<EOF | sudo tee -a /etc/security/limits.conf > /dev/null 
* hard nproc 65536
* soft nproc 65536
* hard nofile 65536
* soft nofile 65536
EOF

```
