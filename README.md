fluo-dev
==========

Scripts and configuration designed to simplify the running of Fluo infrastructure
during development.  While these scripts make it easy to deploy Fluo, they can wipe
the underlying data off your cluster.  Therefore, they should not be used in production.
They are designed for developers who need to frequently upgrade Fluo, test their code,
and do not care about preserving data.

Installing fluo-dev
-------------------

First, clone the fluo-dev repo on a local disk with enough space to run Hadoop, Accumulo, etc:

```
git clone https://github.com/fluo-io/fluo-dev.git
```

Create `env.sh` from the example.  This file is used to configure fluo-dev for your environment.

```
cd conf/
cp env.sh.example env.sh
vim env.sh
```

If you have not already, clone the Fluo repo and set `FLUO_REPO` in env.sh to this directory:

```
git clone https://github.com/fluo-io/fluo.git
```

All commands are run using the `fluo-dev` script in `bin/`.  If want to run this script from 
any directory, you can optionally add the following to your `~/.bashrc`:

```
export PATH=/path/to/fluo-dev/bin:$PATH
```

Running Fluo dependencies
-------------------------

With `fluo-dev` script set up, you can now use it to download, configure, and run Fluo and 
its dependencies.

First, run the command below to download the binary tarballs of Fluo's dependencies (i.e Accumulo, Hadoop, 
and Zookeeper) and their corresponding file hashes and signatures. It will use the Apache download 
mirror specified by `APACHE_MIRROR` in env.sh.  Other mirrors can be chosen from [this website][1].
This command will also output hashes and signatures (if you have `gpg` installed) of the downloaded
software. It is important to inspect this output before installing the software.

```
fluo-dev download
```

Next, run the following command to setup Fluo's dependencies (Hadoop, Zookeeper, & Accumulo):

```
fluo-dev setup
```

The `setup` command will install the downloaded tarballs to the directory set by `$INSTALL` in
your env.sh.  It will then configure and run Hadoop, Zookeeper, & Accumulo.  

Confirm that everything started by checking the monitoring pages of Hadoop & Accumulo:
 * [Hadoop NameNode](http://localhost:50070/)
 * [Hadoop ResourceManager](http://localhost:8088/)
 * [Accumulo Monitor](http://localhost:50095/)

If you run some tests and then want a fresh cluster, run `setup` command again which kill all
running processes, clear any data and logs, and restart your cluster.

Deploying Fluo
--------------

With its dependencies running, Fluo can be be built and deployed to your `install/` directory
using the command below:

```
fluo-dev deploy
```

This command will modify the configuration of your Fluo installation to work with the Accumulo cluster
created by the `setup` command.  The `deploy` can be run again if you want to test out changes made to
your Fluo repo or if you just want just want a fresh install.  To view your installation:

```
cd install/fluo-1.0.0-beta-1-SNAPSHOT
```

From here you can run the `fluo` command to administer Fluo.

```
bin/fluo
```

With Fluo deployed, you can now follow the Fluo production installation [instructions][2] to set
up Fluo.

The commands above are designed to be repeated.  If Hadoop or Accumulo become unstable, run
`fluo-dev setup` to setup Hadoop/Accumulo again and then `fluo-dev deploy` to redeploy Fluo.
If you make any code changes to Fluo and want to test them, run `fluo-dev deploy` which builds 
the latest in your cloned Fluo repo and deploys it.

[1]: http://www.apache.org/dyn/closer.cgi
[2]: https://github.com/fluo-io/fluo/blob/master/docs/production-install.md
