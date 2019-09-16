FROM ruby:2.4.1-stretch
MAINTAINER Qiscus <contact.us@qiscus.com>

# Create app directory
RUN mkdir -p /usr/src/app

# Add Gemfile and Gemfile.lock first for caching
# COPY Gemfile* /usr/src/app

WORKDIR /usr/src/app

# Install app dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apt-utils libicu-dev nodejs ruby-dev
COPY . /usr/src/app
RUN gem install bundler -v 1.15.2
RUN bundle install

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
