terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  auth_url    = "http://10.128.0.37/identity/v3"
  tenant_name = "admin"
  user_name   = "admin"
  password    = "nav+sanjeev"
}

resource "null_resource" "hadoop_pseudo_setup" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = "10.10.0.60"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y openjdk-11-jdk wget ssh rsync",
      "wget https://downloads.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz",
      "tar -xvzf hadoop-3.3.5.tar.gz",
      "sudo mv hadoop-3.3.5 /usr/local/hadoop",
      
      # Set environment variables
      "echo 'export HADOOP_HOME=/usr/local/hadoop' >> ~/.bashrc",
      "echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc",
      "echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc",
      "source ~/.bashrc",

      # Setup SSH for Hadoop (only generate key if it does not exist)
      "[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''",
      "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",

      # Format HDFS
      "/usr/local/hadoop/bin/hdfs namenode -format"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
        cat <<EOL >
            /usr/local/hadoop/etc/hadoop/core-site.xml
            <configuration>
                <property>
                    <name>fs.defaultFS</name>
                    <value>hdfs://10.0.0.17:9000</value>
                </property>
            </configuration>
            EOL
        EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
        cat <<EOL >
            /usr/local/hadoop/etc/hadoop/hdfs-site.xml
            <configuration>
                <property>
                    <name>dfs.replication</name>
                    <value>1</value>
                </property>
                <property>
                    <name>dfs.datanode.data.dir</name>
                    <value>file:///usr/local/hadoop_data</value>
                </property>
                <property>
                    <name>dfs.namenode.name.dir</name>
                    <value>file:///tmp/hadoop-ubuntu/dfs/name</value>
                </property>
                <property>
                    <name>dfs.namenode.edits.dir</name>
                    <value>file:///tmp/hadoop-ubuntu/dfs/name/current</value>
                </property>
            </configuration>
            EOL
        EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
        cat <<EOL >
            /usr/local/hadoop/etc/hadoop/yarn-site.xml
            <configuration>
                <property>
                    <name>yarn.resourcemanager.hostname</name>
                    <value>10.0.0.17</value>
                </property>
                <property>
                    <name>yarn.resourcemanager.address</name>
                    <value>10.0.0.17:8032</value>
                </property>
                <property>
                    <name>yarn.resourcemanager.scheduler.address</name>
                    <value>10.0.0.17:8030</value>
                </property>
                <property>
                    <name>yarn.resourcemanager.resource-tracker.address</name>
                    <value>10.0.0.17:8031</value>
                </property>
                <property>
                    <name>yarn.resourcemanager.webapp.address</name>
                    <value>10.0.0.17:8088</value>
                </property>
                <property>
                    <name>yarn.nodemanager.aux-services</name>
                    <value>mapreduce_shuffle</value>
                </property>
            </configuration>
            EOL
        EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
        cat <<EOL >
            /usr/local/hadoop/etc/hadoop/mapred-site.xml
            <configuration>
                <property>
                    <name>mapreduce.framework.name</name>
                    <value>yarn</value>
                </property>
                <property>
                    <name>yarn.app.mapreduce.am.env</name>
                    <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
                </property>
                <property>
                    <name>mapreduce.map.env</name>
                    <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
                </property>
                <property>
                    <name>mapreduce.reduce.env</name>
                    <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
                </property>
            </configuration>
            EOL
        EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo groupadd hdfs",
      "sudo useradd -g hdfs hdfs",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /usr/local/hadoop_data",
      "sudo chown hdfs:hdfs /usr/local/hadoop_data",
      "sudo chmod 755 /usr/local/hadoop_data"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # Start Hadoop services
      "/usr/local/hadoop/sbin/start-dfs.sh",
      "/usr/local/hadoop/sbin/start-yarn.sh"
    ]
  }
}