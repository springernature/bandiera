FROM ruby:alpine
MAINTAINER Darren Oakley <daz.oakley@gmail.com>

RUN apk add --no-cache ruby-dev build-base libxml2-dev libxslt-dev postgresql-dev mysql-dev openssl-dev

ENV APP_HOME /app

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile Gemfile

RUN bundle install --jobs 4 --without test development

COPY . .

EXPOSE 5000

CMD "puma"
