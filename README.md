![Uno][logo]
---
[![Apache License][li]][ll]

A command-line tool for running [Apache Fluo][fluo] or [Apache Accumulo][accumulo] on a single
machine for development. This tool is designed for developers who need to frequently upgrade and
test their code, and do not care about preserving data. While Uno makes it easy to setup a dev stack
running Fluo or Accumulo, it also makes it easy clear your data and setup your dev stack again. To
avoid inadvertent data loss, Uno should not be used in production.

## Installation

First, clone the uno repo on a local disk with enough space to run Hadoop, Accumulo, etc:

    git clone https://github.com/astralway/uno.git

The `uno` command uses `conf/env.sh.example` for its default configuration which should be
sufficient for most users.

Optionally, you can customize this configuration by creating an `env.sh` file and modifying it for
your environment:

```bash
cd conf/
cp env.sh.example env.sh
vim env.sh
```

Uno can optionally setup a metrics/monitoring tool (i.e Grafana+InfluxDB) that can be used to
monitor your Fluo applications. This setup does not occur with the default configuration. You must
set `SETUP_METRICS` to `true` in your `env.sh`.

All commands are run using the `uno` script in `bin/`. Uno has a command that helps you
configure your shell so that you can run commands from any directory and easily set common
environment variables in your shell for Uno, Hadoop, Zookeeper, Fluo, and Spark. Run the
following command to print this shell configuration. You can also add `--paths` or `--vars` to the
command below to limit output to PATH or environment variable configuration:

    uno env

You can either copy and paste this output into your shell or add the following (with a correct path)
to your ~/.bashrc automatically configure every new shell.

```bash
eval "$(/path/to/uno/bin/uno env)"
```

With `uno` script set up, you can now use it to download, configure, and run Fluo and its
dependencies.

## Fetch command

The `uno fetch` command fetches the binary tarball dependencies of Fluo and Accumulo. By
default, it will download these tarballs. However, you can configure the `fetch` command to build
them from a local git repo by setting `FLUO_REPO` or `ACCUMULO_REPO` in `env.sh`.

If `uno fetch all` is run, all depedencies will be either downloaded or built. If you would
like, to only fetch certain dependencies, run `uno fetch` to see a list of possible
dependencies.

After the `fetch` command is run for the first time, it only needs to run again if you upgrade
software and need to download/build the latest version.

## Setup command

The `setup` command will install the downloaded tarballs to the directory set by `$INSTALL` in your
env.sh and run you local development cluster. The command can be run in several different ways:

1. Set up Accumulo and its dependencies of Hadoop, Zookeeper. This starts all processes and will
   wipe Accumulo/Hadoop if this command was run previously.  This command also sets up Spark and
   starts Spark's History Server (set `START_SPARK_HIST_SERVER=false` in your env.sh to turn off).

   This command is useful if you are using Uno for Accumulo development.

        uno setup accumulo

2. Sets up Fluo along with Accumulo (and its dependencies). It also sets up a metrics server for
   Fluo consisting of InfluxDB & Grafana if `SETUP_METRICS` is set to true in env.sh. This command
   will wipe your cluster. While Fluo is set up, it does not start any Fluo applictions.

        uno setup fluo

3. Sets up Fluo only. This will stop any previously running Fluo applcations but it will not wipe
   your cluster. If you want upgrade Fluo without wiping your cluster, run `uno fetch fluo`
   before running this command.

        uno setup fluo-only

You can confirm that everything started by checking the monitoring pages of below:

 * [Hadoop NameNode](http://localhost:50070/)
 * [Hadoop ResourceManager](http://localhost:8088/)
 * [Accumulo Monitor](http://localhost:50095/)
 * [Spark HistoryServer](http://localhost:18080/)
 * [Grafana](http://localhost:3000/) (optional)
 * [InfluxDB Admin](http://localhost:8083/) (optional)

You can verify that Fluo was installed by correctly by running the `fluo` command which you can use
to administer Fluo:

    ./install/fluo-1.0.0-beta-1/bin/fluo

If you run some tests and then want a fresh cluster, run `uno setup all` command again which will
kill all running processes, clear any data and logs, and restart your cluster.

## Running Fluo applications

Before running a Fluo application, it is recommended that you configure your shell using
`uno env`. If this is done, many Fluo example applications (such as [Webindex] and
[Phrasecount]) can be run by simply cloning their repo and executing their start scripts (which will
use environment variables set in your shell by `uno env`).

If you want to create your own Fluo application, you should mimic the scripts of example Fluo
applications or follow the instructions starting at the [Configure a Fluo application][configure]
section of the Fluo install instructions. These instructions will guide you through the process of
configuring, initializing, and starting your application.

[fluo]: http://fluo.apache.org/
[accumulo]: http://accumulo.apache.org/
[mirrors]: http://www.apache.org/dyn/closer.cgi
[Webindex]: https://github.com/astralway/webindex
[Phrasecount]: https://github.com/astralway/phrasecount
[configure]: https://github.com/apache/fluo/blob/master/docs/install.md#configure-a-fluo-application
[li]: http://img.shields.io/badge/license-ASL-blue.svg
[ll]: https://github.com/astralway/uno/blob/master/LICENSE
[logo]: contrib/uno-logo.png
