# Bandiera

Bandiera is a simple, stand-alone feature flagging service that is not tied to
any existing web framework or language as all communication is via a simple
REST API.  It also has a simple web interface for setting up and configuring
flags.

# Bandiera Client Libraries

* **Ruby** - [https://github.com/nature/bandiera-client-ruby](https://github.com/nature/bandiera-client-ruby)
* **Node** - [https://github.com/nature/bandiera-client-node](https://github.com/nature/bandiera-client-node)
* **PHP** - [https://github.com/nature/bandiera-client-php](https://github.com/nature/bandiera-client-php)

# Getting Started (Developers)

There are two ways you can work with/develop the Bandiera code-base - locally
on your own machine (connected to your own database etc.); or within docker
containers.

We prefer the docker setup as this is most likely closer to a production setup
than your local machine (unless you run the same OS and setup as your
production boxes).

## Docker Setup

To get started, you will need to install [docker](https://www.docker.com/) and
[fig](http://www.fig.sh/) - see the quick install instructions below for your
OS.

Then run the following command:

```
fig build
fig up db
```

Hit Ctrl+C, now:

```
fig run app bundle exec rake db:migrate
fig up app db
```

This builds the docker containers for Bandiera, sets up your development
database, and then starts the service.

You can now visit the web interface at
[http://127.0.0.1:5000](http://127.0.0.1:5000) if you are on Linux, or
[http://192.168.59.103:5000](http://192.168.59.103:5000) on Mac OS X (if this
doesn't work check the IP of your boot2docker server with `boot2docker ip`).

You're all set to develop Bandiera now!

You can also run the test suite within a docker container, simply run the
following command in another terminal (or tab):

```
fig up test
```

This uses [Guard](https://github.com/guard/guard) and will run the test suite
every time you update one of the files.

### Mac OS X

First, install [homebrew](http://brew.sh/) - then run the following commands:

```
brew install docker boot2docker fig
```

There, will be some environment variables you need to configure - the
instructions for this will be printed into your terminal now.  After that,
you're ready to go.

### Linux

Install docker following the instructions
[here](https://docs.docker.com/installation/#installation).

Install fig following the instructions [here](http://www.fig.sh/install.html)

You're now ready to go.

### Windows

Sorry, you're going to have to go for the local setup - it looks like fig
doesn't support Windows as yet...

## Local Setup

First, you will need the version of Ruby defined in the
[.ruby-version](.ruby-version) file and [bundler](http://bundler.io/)
installed.  You will also need to install [phantomjs](http://phantomjs.org/) as
this is used by the test suite for integration tests.

After that, set up your database (MySQL or PostgreSQL) ready for
Bandiera (just an empty schema for now), and setup an environment variable
with a [Sequel connection
string](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)
i.e.

```
export DATABASE_URL='postgres://bandiera:bandiera@localhost/bandiera'
```

Now install the dependencies, setup the database and run the app server:

```
bundle install
bundle exec rake db:migrate
bundle exec shotgun -p 5000 -s puma
```

You can now visit the web interface at
[http://127.0.0.1:5000](http://127.0.0.1:5000).

Use this command to run the test suite:

```
bundle exec rspec
```

Or if you prefer to use [Guard](https://github.com/guard/guard):

```
bundle exec guard -i -p -l 1
```

Now you're ready to go.

# Other Documentation

All other documentation can be found on the [Bandiera
Wiki](https://github.com/nature/bandiera/wiki)

# License

[&copy; 2015, Macmillan Publishers](LICENSE.txt).

Bandiera is licensed under the [GNU General Public License 3.0][gpl].

[gpl]: http://www.gnu.org/licenses/gpl-3.0.html

