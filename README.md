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

You will need to invoke the `fluo` command using `fluo-dev fluo` as `fluo-dev` will set up
the correct Hadoop environment variables for the `fluo` command.  To avoid using `fluo-dev fluo`
every time, add the following alias to your `~/.bashrc`:

```
alias fluo='fluo-dev fluo'
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

The `setup` command will install the downloaded tarballs to the directory set by `SOFTWARE` in 
your env.sh.  It will then configure and run Hadoop, Zookeeper, & Accumulo.  

Confirm that everything started by checking the monitoring pages of Hadoop & Accumulo:
 * [Hadoop NameNode](http://localhost:50070/)
 * [Hadoop ResourceManager](http://localhost:8088/)
 * [Accumulo Monitor](http://localhost:50095/)

If you run some tests and then want a fresh cluster, run `setup` command again which kill all
running processes, clear any data and logs, and restart your cluster.

Running Fluo
------------

With its dependencies running, Fluo can now be started.  If you want to run Fluo with observers,
you should create a file called `observer.props` in `conf/` by copying the example:

```
cp conf/observer.props.example conf/observer.props
vim conf/observer.props
```

The example `observer.props` file is configured to run the [fluo-stress][stress] example application.  
The observer jar for [fluo-stress][stress] can be obtained by cloning and building its repo using the
the steps below:

```
git clone https://github.com/fluo-io/fluo-stress.git
cd fluo-stress/
mvn package
ls target/fluo-stress-*.jar
```

Copy your observer JAR for your application to `conf/fluo/observers`.  All jars in this directory will
be include on the classpath when you deploy Fluo.

```
cp /path/to/observer.jar conf/fluo/observers/
```

Deploy Fluo using the command below which will remove any existing install, rebuild fluo, install it, 
and configure it using your configuration in `conf/fluo`:

```
fluo-dev deploy
```

Finally, run the command below to confirm that Fluo is running:

```
fluo yarn status
```

The commands above are designed to be repeated.  If Hadoop or Accumulo become unstable, run
`fluo-dev setup` and then `fluo-dev deploy` to setup Hadoop/Accumulo again and redeploy Fluo.
If you make any code changes to Fluo and want to test them, run `fluo-dev deploy` which builds 
the latest in your cloned Fluo repo and deploys it.

Updating observers
------------------

If you want to update your obsever code, remove any old jars from `fluo-dev/conf/fluo/observers`
and copy your updated jar to the directory:

```
rm conf/fluo/observers/*.jar
cp /path/to/observer.jar conf/fluo/observers/
```

If it is OK to clear your cluster, run the command below to redeploy fluo:

```
fluo-dev deploy
```

If you want to save the data on your cluster, follow the commands below to update the observers in 
your deployment and start/stop fluo without losing data:

```
rm software/fluo-1.0.0-beta-1-SNAPSHOT/lib/observers/*.jar
cp /path/to/observer.jar software/fluo-1.0.0-beta-1-SNAPSHOT/lib/observers
fluo yarn stop
fluo yarn start
```

[1]: http://www.apache.org/dyn/closer.cgi
[stress]: https://github.com/fluo-io/fluo-stress
