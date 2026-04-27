FROM ruby:3.3.11

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends libpq-dev \
  && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
ARG BUNDLE_WITH=""
ENV BUNDLE_WITH=${BUNDLE_WITH}

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["sh", "docker/entrypoint.sh"]
