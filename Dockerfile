FROM ruby:4.0.2-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential git libffi-dev libyaml-dev \
      chromium imagemagick \
      libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 \
      libdrm2 libgbm1 libnspr4 libnss3 libx11-xcb1 \
      libxcomposite1 libxdamage1 libxrandr2 libxshmfence1 \
      fonts-liberation \
      postgresql postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4

COPY . .

RUN mkdir -p /data

ENV RAILS_ENV=production
ENV PORT=8099

EXPOSE 8099

CMD ["./script/docker-start"]
