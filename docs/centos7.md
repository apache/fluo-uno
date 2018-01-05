#install stuff
sudo yum install java-1.8.0-openjdk maven git openssh-server wget perl-Digest-SHA
sudo yum group install "Development Tools"

#setup passwordless ssh 
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#add java home to your env by appending this line to ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

#optional: set OS limits - requires restart
cat <<EOF | sudo tee -a /etc/security/limits.conf > /dev/null 
* hard nproc 65536
* soft nproc 65536
* hard nofile 65536
* soft nofile 65536
EOF
