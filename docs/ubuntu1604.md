Ubuntu 16.04 prep
-----------------

The following commands are one possible way to quickly prepare an instance of
Ubuntu 16.04 for Uno.

```bash
#install stuff
sudo apt install openjdk-8-jdk maven git openssh-server wget

#setup passwordless ssh
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#add java home before interactive section, will take effect on shell restart
#this may not work properly in your environment, looks for phrase in stock ubuntu .bashrc
sed -i '/# for examples/a export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64' ~/.bashrc

#set java home in current shell
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
```
