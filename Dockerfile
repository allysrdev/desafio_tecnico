# 1. Estágio de Build (Onde a mágica da compilação acontece)
FROM hexpm/elixir:1.16.0-erlang-26.2.2-debian-bookworm-slim AS builder

RUN apt-get update -y && apt-get install -y build-essential git

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .

# Aqui o Phoenix compila seu CSS (Tailwind) e JS
RUN mix assets.deploy

# Gera a "Release" (um executável que não precisa de Elixir instalado para rodar)
RUN mix compile
RUN mix release --overwrite

# 2. Estágio de Execução (A imagem final, super leve)
FROM debian:bookworm-slim AS release

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/w_core ./w_core

ENV PHOENIX_SERVER=true
ENV PORT=4000
EXPOSE 4000

CMD ["/app/w_core/bin/w_core", "start"]
