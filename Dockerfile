FROM ruby:2.2.2-wheezy

MAINTAINER Darren Oakley <darren.oakley@macmillan.com>

# Install PhantomJS and its dependencies - needed for the test suite
RUN apt-get update && \
  apt-get install -y build-essential chrpath libssl-dev libxft-dev && \
  apt-get install -y libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev && \
  cd /usr/local/share && \
  export PHANTOM_JS="phantomjs-1.9.8-linux-x86_64" && \
  wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 && \
  tar xvjf $PHANTOM_JS.tar.bz2 && \
  ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/share/phantomjs && \
  ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin/phantomjs && \
  ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/bin/phantomjs

# Copy Bandiera to the container
COPY . /usr/src/app
WORKDIR /usr/src/app

# Update bundler
RUN gem install bundler

# Throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle install

EXPOSE 5000

CMD [ "bundle exec puma -C config/puma.rb config.ru" ]
