# Minha Watchlist

App Flutter pessoal (single-user, sem login) para controlar filmes, séries,
animes e desenhos que você quer ver, está vendo ou já viu.

## Funcionalidades

- Cadastro de título com pôster, tipo (filme/série/anime/desenho)
- Status: quero ver / assistindo / visto
- Controle de temporada e episódio atual, com botão de "próximo episódio"
- Avaliação por estrelas (1 a 5)
- Busca por nome e filtros por status/tipo na tela inicial
- Busca automática no TMDB (pôster + sinopse) ao cadastrar um título, ou
  upload manual de foto da galeria
- Dados salvos localmente no dispositivo (SQLite via `sqflite`) — funciona 100% offline

## Rodando

```bash
flutter pub get
flutter run
```

Requer um emulador Android/iOS conectado ou dispositivo físico.

### Busca automática (TMDB)

Para usar o botão "Buscar no TMDB" ao adicionar um título:

1. Crie uma conta gratuita em https://www.themoviedb.org/
2. Gere uma API Key (v3 auth) em Configurações > API da sua conta TMDB
3. No app, abra o ícone de engrenagem na tela inicial e cole a chave

Sem a chave configurada, o cadastro continua funcionando normalmente com
upload manual de pôster.

## Estrutura

- `lib/models` — modelo de dados (`TitleItem`, `TitleType`, `WatchStatus`)
- `lib/data` — acesso ao banco SQLite (`DatabaseHelper`)
- `lib/providers` — estado da aplicação (`TitlesProvider`, via `provider`)
- `lib/services` — integrações externas (`TmdbService`, `SettingsService`)
- `lib/screens` — telas (lista principal, adicionar/editar, configurações)
- `lib/widgets` — componentes reutilizáveis (card de título, estrelas, busca TMDB)
