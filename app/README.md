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

Para usar o botão "Buscar no TMDB" ao adicionar um título, você precisa de uma
API Key (v3 auth) gratuita: crie uma conta em https://www.themoviedb.org/ e
gere a chave em Configurações > API da sua conta.

Duas formas de configurar, sem nunca versionar a chave no git:

1. **Arquivo `.env` (padrão do projeto)** — copie `.env.example` para `.env`
   na raiz de `app/` e preencha `TMDB_API_KEY=sua_chave_aqui`. O arquivo
   `.env` está no `.gitignore` e nunca é commitado. O app carrega essa chave
   automaticamente ao iniciar.
2. **Tela de Configurações no app** — abra o ícone de engrenagem na tela
   inicial e cole sua chave lá. Fica salva no armazenamento local do
   dispositivo (`shared_preferences`) e tem prioridade sobre o `.env`.

Sem nenhuma chave configurada, o cadastro continua funcionando normalmente
com upload manual de pôster.

## Estrutura

- `lib/models` — modelo de dados (`TitleItem`, `TitleType`, `WatchStatus`)
- `lib/data` — acesso ao banco SQLite (`DatabaseHelper`)
- `lib/providers` — estado da aplicação (`TitlesProvider`, via `provider`)
- `lib/services` — integrações externas (`TmdbService`, `SettingsService`)
- `lib/screens` — telas (lista principal, adicionar/editar, configurações)
- `lib/widgets` — componentes reutilizáveis (card de título, estrelas, busca TMDB)
