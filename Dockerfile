ARG ruby_version="latest"

FROM ruby:${ruby_version}

SHELL ["/bin/bash", "-c"]

RUN gem install bundler -v '~>2.0'

WORKDIR /app

COPY . .

RUN bundle install
