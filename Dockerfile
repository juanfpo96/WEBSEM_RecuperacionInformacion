# Generated by Cloud66 Starter
FROM ruby:2.5

RUN apt-get update -qq && apt-get install -y build-essential git nano

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN gem install bundler
RUN bundle install

ADD . $APP_HOME
