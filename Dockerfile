FROM ruby:alpine
MAINTAINER Darren Oakley <daz.oakley@gmail.com>

RUN apk add --update --no-cache build-base ruby-dev libxml2-dev libxslt-dev postgresql-dev mysql-dev openssl-dev

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --retry 10 --jobs 4 --without test

COPY . .

EXPOSE 5000

CMD "puma"
