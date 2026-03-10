ARG BUILD_FROM=ruby:3.4.3-slim
FROM ${BUILD_FROM}

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git libffi-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 4

COPY . .

ENV RAILS_ENV=production
ENV PORT=8099

EXPOSE 8099

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
