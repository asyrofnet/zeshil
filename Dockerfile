FROM telkomindonesia/alpine:ruby-2.6

ARG DO_PRECOMPILE_ASSETS
ARG RAILS_SECRET_KEY_BASE=b761071c220a622cf65b33a62424a23afe8d0ba375efe71a37485fd642138b6ea562a11f0b88568727ac07d8be7b0699709d6474fd93847cacef9ffdfd476334

ENV SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE}

WORKDIR /usr/src/app

COPY Gemfile* ./

RUN apk add --no-cache --update --virtual .build-deps \
      linux-headers \
      build-base \
      ruby-dev \
      curl-dev \
    && apk add --no-cache --update \
        icu-dev \
        postgresql-dev \
        postgresql-client \
    && mv /etc/apk/repositories /etc/apk/repositories.original \
    && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.6/main' > /etc/apk/repositories \
    && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.6/community' >> /etc/apk/repositories \
    && apk add --no-cache --update \
        nodejs \
    && mv /etc/apk/repositories.original /etc/apk/repositories \
    && bundle install \
    && apk del .build-deps

COPY . .
RUN chmod -R 755 scripts \
    && ./scripts/precompile.sh $DO_PRECOMPILE_ASSETS \
    && chmod -R 777 storage \
    && chmod -R 777 log \
    && chmod -R 777 tmp

EXPOSE 3000

CMD ["./scripts/start.sh"]
