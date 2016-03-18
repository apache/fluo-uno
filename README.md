fluo-dev
========

A command-line tool for running Fluo on a single machine for development.  This tool is designed for 
developers who need to frequently upgrade Fluo, test their code, and do not care about preserving 
data.  While fluo-dev makes it easy to setup a cluster running Fluo, it also makes it easy clear 
your data and setup a new cluster.  To avoid inadvertent data loss, the fluo-dev tool should not 
be used in production. 

Installation
------------

First, clone the fluo-dev repo on a local disk with enough space to run Hadoop, Accumulo, etc:

    git clone https://github.com/fluo-io/fluo-dev.git

The `fluo-dev` command uses `conf/env.sh.example` for its default configuration which should
be sufficient for most users.

Optionally, you can customize this configuration by creating an `env.sh` file and modifying it
for your environment:

```bash
cd conf/
cp env.sh.example env.sh
vim env.sh
```

Fluo-dev can optionally setup a metrics/monitoring tool (i.e Grafana+InfluxDB) that can be used 
to monitor your Fluo applications.  This setup does not occur with the default configuration. You 
must set `SETUP_METRICS` to `true` in your `env.sh`.

Fluo-dev can build a Fluo tarball from a local Fluo git repo by setting `FLUO_TARBALL_REPO` in 
`env.sh` to the location of your local Fluo clone.  You should  also modify `FLUO_VERSION` to 
use the version in the checked out branch of your local Fluo clone (i.e `1.0.0-beta-2-SNAPSHOT`) 
rather than the last release version (i.e `1.0.0-beta-1`).  This option lets users build and 
run the latest Fluo code from master or lets Fluo developers test their changes made to their 
local clone before submitting pull requests.

All commands are run using the `fluo-dev` script in `bin/`.  If want to run fluo-dev, accumulo, 
hadoop, zookeeper, fluo, and spark commands from any directory, you can optionally execute the 
following command :

```bash
export PATH=`./bin/fluo-dev paths`:$PATH
```

With `fluo-dev` script set up, you can now use it to download, configure, and run Fluo and 
its dependencies.

Download command
----------------

The `download` command needs to be run first.  It will download the binary tarballs of software needed
by fluo-dev (i.e Accumulo, Hadoop, Zookeeper, Spark, etc). If the software is an Apache project, it will
use the Apache download mirror specified by `APACHE_MIRROR` in env.sh.  Other mirrors can be chosen from
[this website][1].  This command will verify that the MD5 hashes of the downloaded tarballs match the
expected MD5 hashes set in your `env.sh`.  If any don't match, the command will fail and error message
will be printed.  

    fluo-dev download

After this command is run for the first time, it only needs to run again if you upgrade
software and need to download the latest version.

Setup command
-------------

The `setup` command will install the downloaded tarballs to the directory set by `$INSTALL` in
your env.sh and run you local development cluster.  It will always configure and run Hadoop, Zookeeper 
and Accumulo.  If you have a Fluo tarball location specified in `conf/env.sh`, it will setup Fluo but not 
run an application.  If you don't want Fluo set up, you should make sure all the bash variables in the 
'Fluo Tarball' section are commented out. If you have `SETUP_METRICS` set to `true`, this command will 
also set up InfluxDB and Grafana.

    fluo-dev setup

Confirm that everything started by checking the monitoring pages of Hadoop & Accumulo:
 * [Hadoop NameNode](http://localhost:50070/)
 * [Hadoop ResourceManager](http://localhost:8088/)
 * [Accumulo Monitor](http://localhost:50095/)
 * [Spark HistoryServer](http://localhost:18080/)
 * [Grafana](http://localhost:3000/) (optional)
 * [InfluxDB Admin](http://localhost:8083/) (optional)

You can verify that Fluo was installed by correctly by running the `fluo` command which you can use
to adminster Fluo:

    ./install/fluo-1.0.0-beta-1/bin/fluo

If you run some tests and then want a fresh cluster, run `setup` command again which kill all
running processes, clear any data and logs, and restart your cluster.

Redeploy command
----------------

The 'redeploy' command allows you to make changes to the Fluo codebase and redeploy Fluo without 
setting up a new cluster:

    fluo-dev redeploy

Running Fluo applications
-------------------------

There are two ways to run Fluo applications using `fluo-dev`:

1. Run pre-built Fluo applications like [fluo-stress] that are listed and configured 
   in `conf/applications.props` and can be run by a single command.

    ```
    fluo-dev run stress
    ```

   The `run` command will clone the application's repo to `install/fluo-app-repos/`.  It will
   run the commands specified in `applications.props` to initialize and run the application 
   which will remain running unless you stop it using `fluo stop <app>`.  The run command will
   pass any additional arguments after the application name to the commands specified in 
   `applications.props`.  For example, the phrasecount application requires an additional
   argument that specifies a directory containing text documents to index:

    ```
    fluo-dev run phrasecount /path/to/txt/docs
    ```

2. Configure, initialize, and start your own Fluo application by following instructions starting at
   the [Configure a Fluo application][2] section of the Fluo production setup instructions.

The `fluo-dev` commands above are designed to be repeated.  If Hadoop or Accumulo become unstable, run
`fluo-dev setup` to setup Hadoop/Accumulo again and then `fluo-dev deploy` to redeploy Fluo.

[1]: http://www.apache.org/dyn/closer.cgi
[2]: https://github.com/fluo-io/fluo/blob/master/docs/prod-fluo-setup.md#configure-a-fluo-application
[fluo-stress]: https://github.com/fluo-io/fluo-stress
