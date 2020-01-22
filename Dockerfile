# Step 1 - Build the OTP binary
FROM elixir:1.9.4-alpine AS build

RUN apk update && \
    apk upgrade && \
    apk add -U git

WORKDIR /app

RUN mix local.rebar --force && \
    mix local.hex --force

ARG SECRET_KEY_BASE=123
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

COPY lib lib
COPY priv priv
RUN mix compile

COPY rel rel

RUN mkdir -p /opt/app
RUN mix release
# RUN cp -R _build/prod/rel/talk/* /opt/app

# Step 2 - Build a lean runtime container
FROM alpine:3.9

RUN apk update && \
    apk upgrade && \
    apk add -U bash openssl postgresql-client

WORKDIR /opt/app

# Copy the OTP binary and assets deps from the build step
COPY --from=build /app/_build/prod/rel/talk ./
# COPY --from=build /opt/app .

# Copy the entrypoint script
COPY priv/scripts/start.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/start.sh

# Create a non-root user
RUN adduser -D app && chown -R app: /opt/app

USER app

EXPOSE 443 80 7000

ENTRYPOINT ["start.sh"]
CMD ["start"]
