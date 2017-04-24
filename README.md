![Uno][logo]
---
[![Apache License][li]][ll]

**Uno automates setting up [Apache Accumulo][accumulo] or [Apache Fluo][fluo] (and their dependencies) on a single machine.**

Uno makes it easy for a developer to experiment with Accumulo or Fluo in a realistic environment.
Uno is designed for developers who need to frequently upgrade and test their code, and do not care
about preserving data. While Uno makes it easy to setup a dev stack running Fluo or Accumulo, it
also makes it easy clear your data and setup your dev stack again. To avoid inadvertent data loss,
Uno should not be used in production.

Checkout [Muchos] for setting up Accumulo or Fluo on multiple machines.

## Requirements

Uno requires the following software to be installed on your machine.

* Java - JDK 8 is required for running Fluo.
* wget - Needed for `fetch` command to download tarballs.
* Maven - Only needed if `fetch` command builds tarball from local repo.

You should also be able to [ssh to localhost without a passphrase][ssh-docs].
The following instructions can help you setup these requirements in your
environment :

 * [Ubuntu 16.04](/docs/ubuntu1604.md)

## Quickstart

The following commands will get you up and running with an Accumulo instance if you
have satisfied the requirements mentioned above.  Replace `accumulo` with `fluo` to
setup a Fluo instance.

```bash
git clone https://github.com/astralway/uno.git
cd uno
./bin/uno fetch accumulo            # Fetches binary tarballs of Accumulo and its dependencies
./bin/uno setup accumulo            # Sets up Accumulo and its dependencies (Hadoop & Zookeeper)
eval "$(./bin/uno env)"             # Bash-specific command that sets up current shell
```

Accumulo is now ready to use. Verify your installation by checking the [Accumulo Monitor](http://localhost:9995/)
and [Hadoop NameNode](http://localhost:50070/) status pages. For a more complete understanding of Uno,
please continue reading.

## Installation

First, clone the Uno repo on a local disk with enough space to run Hadoop, Accumulo, etc:

    git clone https://github.com/astralway/uno.git

The `uno` command uses `conf/uno.conf` for its default configuration which should be
sufficient for most users.

Optionally, you can customize this configuration by modifying the `uno.conf` file for
your environment. Inside this script the variable `UNO_HOME` defaults to the root of the Uno repository. 

```bash
vim conf/uno.conf
```

All commands are run using the `uno` script in `bin/`. Uno has a command that helps you configure
your shell so that you can run commands from any directory and easily set common environment
variables in your shell for Uno, Hadoop, Zookeeper, Fluo, and Spark. Run the following command to
print this shell configuration. You can also add `--paths` or `--vars` to the command below to limit
output to PATH or environment variable configuration:

    uno env

You can either copy and paste this output into your shell or add the following (with a correct path)
to your ~/.bashrc automatically configure every new shell.

```bash
eval "$(/path/to/uno/bin/uno env)"
```

With `uno` script set up, you can now use it to download, configure, and run Fluo's dependencies.

## Fetch command

The `uno fetch <component>` command fetches the tarballs of a component and its dependencies for later
use by the `setup` command. By default, the `fetch` command downloads tarballs but you can configure it
to build Fluo or Accumulo from a local git repo by setting `FLUO_REPO` or `ACCUMULO_REPO` in `uno.conf`.

If `uno fetch all` is run, all possible components will be either downloaded or built. If you
would like to only fetch certain components, run `uno fetch` to see a list of possible components.

After the `fetch` command is run for the first time, it only needs to run again if you want to
upgrade components and need to download/build the latest version.

## Setup command

The `setup` command will install the downloaded tarballs to the directory set by `$INSTALL` in your
`uno.conf` and run you local development cluster. The command can be run in several different ways:

1. Sets up Apache Accumulo and its dependencies of Hadoop, Zookeeper. This starts all processes and
   will wipe Accumulo/Hadoop if this command was run previously.

        uno setup accumulo

2. Sets up Apache Fluo along with Accumulo (and its dependencies). This command will wipe your
   cluster. While Fluo is set up, it does not start any Fluo applications.

        uno setup fluo

3. For Fluo & Accumulo, you can setup the software again without wiping/setting up their underlying
   dependencies. You can upgrade Accumulo or Fluo by running `uno fetch` before running this command.

        uno setup fluo --no-deps
        uno setup accumulo --no-deps

4. Sets up metrics service (InfluxDB + Grafana).

        uno setup metrics

5. Sets up Apache Spark and starts Spark's History Server.

        uno setup spark

6. Sets up all components (Fluo, Accumulo, Hadoop, Zookeeper, Spark, metrics service).

        uno setup all

You can confirm that everything started by checking the monitoring pages below:

 * [Hadoop NameNode](http://localhost:50070/)
 * [Hadoop ResourceManager](http://localhost:8088/)
 * [Accumulo Monitor](http://localhost:9995/)
 * [Spark HistoryServer](http://localhost:18080/)
 * [Grafana](http://localhost:3000/) (optional)
 * [InfluxDB Admin](http://localhost:8083/) (optional)

You can verify that Fluo was installed correctly by running the `fluo` command which you can use
to administer Fluo:

    ./install/fluo-1.0.0-beta-1/bin/fluo

If you run some tests and then want a fresh cluster, run the `setup` command again which will
kill all running processes, clear any data and logs, and restart your cluster.

## Running Apache Fluo applications

Before running an Apache Fluo application, it is recommended that you configure your shell using
`uno env`. If this is done, many Fluo example applications (such as [Webindex] and [Phrasecount])
can be run by simply cloning their repo and executing their start scripts (which will use
environment variables set in your shell by `uno env`).

If you want to create your own Fluo application, you should mimic the scripts of example Fluo
applications or follow the instructions starting at the [Configure a Fluo application][configure]
section of the Fluo install instructions. These instructions will guide you through the process of
configuring, initializing, and starting your application.

[fluo]: http://fluo.apache.org/
[accumulo]: http://accumulo.apache.org/
[zookeeper]: http://zookeeper.apache.org/
[hadoop]: http://hadoop.apache.org/
[mirrors]: http://www.apache.org/dyn/closer.cgi
[Webindex]: https://github.com/astralway/webindex
[Phrasecount]: https://github.com/astralway/phrasecount
[configure]: https://github.com/apache/fluo/blob/master/docs/install.md#configure-a-fluo-application
[li]: http://img.shields.io/badge/license-ASL-blue.svg
[ll]: https://github.com/astralway/uno/blob/master/LICENSE
[logo]: contrib/uno-logo.png
[Muchos]: https://github.com/astralway/muchos
[ssh-docs]: https://hadoop.apache.org/docs/r2.7.2/hadoop-project-dist/hadoop-common/SingleCluster.html#Setup_passphraseless_ssh
