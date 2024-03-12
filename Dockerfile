ARG ruby_version="latest"

FROM ruby:${ruby_version}

SHELL ["/bin/bash", "-c"]

WORKDIR /app

COPY VERSION Gemfile ezid-client.gemspec ./

RUN gem install bundler -v '~>2.0' && bundle install

COPY . .
