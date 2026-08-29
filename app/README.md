# Minha Watchlist

App Flutter pessoal (single-user, sem login) para controlar filmes, séries,
animes e desenhos que você quer ver, está vendo ou já viu.

## Funcionalidades

- Cadastro de título com pôster (foto da galeria), tipo (filme/série/anime/desenho)
- Status: quero ver / assistindo / visto
- Controle de temporada e episódio atual, com botão de "próximo episódio"
- Filtros por status e tipo na tela inicial
- Dados salvos localmente no dispositivo (SQLite via `sqflite`) — funciona 100% offline

## Rodando

```bash
flutter pub get
flutter run
```

Requer um emulador Android/iOS conectado ou dispositivo físico.

## Estrutura

- `lib/models` — modelo de dados (`TitleItem`, `TitleType`, `WatchStatus`)
- `lib/data` — acesso ao banco SQLite (`DatabaseHelper`)
- `lib/providers` — estado da aplicação (`TitlesProvider`, via `provider`)
- `lib/screens` — telas (lista principal, adicionar/editar)
- `lib/widgets` — componentes reutilizáveis (card de título)
