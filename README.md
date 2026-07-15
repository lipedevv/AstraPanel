![Astra Panel](public/assets/svgs/astra.svg)

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/pterodactyl/panel/ci.yaml?label=Tests&style=for-the-badge&branch=1.0-develop)
![Discord](https://img.shields.io/discord/122900397965705216?label=Discord&logo=Discord&logoColor=white&style=for-the-badge)
![GitHub Releases](https://img.shields.io/github/downloads/pterodactyl/panel/latest/total?style=for-the-badge)
![GitHub contributors](https://img.shields.io/github/contributors/pterodactyl/panel?style=for-the-badge)

# Astra Panel

## Instalacao no GitHub Codespaces

O **Astra Panel** e uma distribuicao do Pterodactyl v1.14.1 preparada para GitHub Codespaces. Ele mantem a base solida
do projeto original e adiciona identidade Astra, portugues do Brasil como idioma padrao, espanhol e ingles, alem de
instalacao, atualizacao, banco MariaDB, Redis e primeiro administrador totalmente automatizados.

Em um Codespace vazio, execute somente:

```bash
curl -fsSL https://raw.githubusercontent.com/lipedevv/AstraPanel/master/install.sh | bash
```

Ao terminar, o terminal mostra a URL, o e-mail e a senha do administrador. As mesmas informacoes ficam salvas, com
permissividade restrita, em `.codespaces/credentials.txt` dentro do clone (por padrao,
`/workspaces/AstraPanel/.codespaces/credentials.txt` para o comando acima).

Para escolher o e-mail ou a senha antes da primeira instalacao:

```bash
curl -fsSL https://raw.githubusercontent.com/lipedevv/AstraPanel/master/install.sh \
  | PTERO_ADMIN_EMAIL=voce@example.com PTERO_ADMIN_PASSWORD='SuaSenhaForte!' bash
```

Para consultar os containers e logs depois da instalacao:

```bash
cd /workspaces/AstraPanel
docker compose --env-file .codespaces/.env -f docker-compose.codespaces.yml ps
docker compose --env-file .codespaces/.env -f docker-compose.codespaces.yml logs -f panel
```

### Node Wings opcional

Depois que o Panel estiver instalado, o comando abaixo registra um node basico, inicia o Wings oficial e cria as
allocations `25565-25575`:

```bash
cd /workspaces/AstraPanel
git pull --ff-only
bash scripts/install-node-codespaces.sh
```

O script usa os recursos disponiveis no Codespace, configura a porta HTTPS do Wings e valida a conexao autenticada
entre o Panel e o node. A porta `8081` precisa ficar publica para que o Panel consiga acessar o Wings; o instalador
tenta fazer isso automaticamente com o GitHub CLI. Se a visibilidade voltar para privada depois de reiniciar o
Codespace, execute o mesmo script novamente.

As allocations podem executar containers de jogos. Para acessar uma porta TCP somente do seu computador, use o
GitHub CLI local, mantendo o comando aberto, e conecte o jogo em `localhost`:

```bash
gh codespace ports forward 25565:25565 -c NOME_DO_CODESPACE
```

Jogadores externos e jogos que dependem de UDP ainda precisam de um tunel apropriado ou de uma VPS.

### Atualizacao segura

O atualizador verifica o repositorio, cria um backup compactado do banco, baixa a versao nova, reconstroi a interface
e recria Panel e Wings sem apagar os volumes. Ele tambem reaplica a configuracao do node e repara os diretorios de
runtime usados pelos containers dos jogos:

```bash
cd /workspaces/AstraPanel
bash scripts/update-codespaces.sh
```

Ou, de qualquer terminal do Codespace, execute o atualizador mais recente em uma unica linha:

```bash
curl -fsSL https://raw.githubusercontent.com/lipedevv/AstraPanel/master/update.sh | bash
```

Os backups ficam em `.codespaces/backups` e os logs detalhados em `.codespaces/logs`. Use `ASTRA_VERBOSE=1` antes do
comando para acompanhar toda a saida em vez dos indicadores de carregamento.

> **Importante:** esta configuracao e indicada para desenvolvimento, demonstracao e testes do **Panel e Wings**. O GitHub
> Codespaces pode suspender a maquina e seu encaminhamento de portas nao substitui um servidor publico permanente.
> Para hospedar servidores de jogos com Wings em producao, use uma VPS ou servidor Linux compativel com os requisitos
> oficiais do Pterodactyl.

---

Pterodactyl® is a free, open-source game server management panel built with PHP, React, and Go. Designed with security
in mind, Pterodactyl runs all game servers in isolated Docker containers while exposing a beautiful and intuitive
UI to end users.

Stop settling for less. Make game servers a first class citizen on your platform.

![Image](https://cdn.pterodactyl.io/site-assets/pterodactyl_v1_demo.gif)

## Documentation

* [Panel Documentation](https://pterodactyl.io/panel/1.0/getting_started.html)
* [Wings Documentation](https://pterodactyl.io/wings/1.0/installing.html)
* [Community Guides](https://pterodactyl.io/community/about.html)
* Or, get additional help [via Discord](https://discord.gg/pterodactyl)

## Sponsors

I would like to extend my sincere thanks to the following sponsors for helping fund Pterodactyl's development.
[Interested in becoming a sponsor?](https://github.com/sponsors/pterodactyl)

| Company                                                                           | About                                                                                                                                                                                                                                           |
|-----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [**Aussie Server Hosts**](https://aussieserverhosts.com/)                         | No frills Australian Owned and operated High Performance Server hosting for some of the most demanding games serving Australia and New Zealand.                                                                                                 |
| [**BisectHosting**](https://www.bisecthosting.com/)                               | BisectHosting provides Minecraft, Valheim and other server hosting services with the highest reliability and lightning fast support since 2012.                                                                                                 |
| [**MineStrator**](https://minestrator.com/)                                       | Looking for the most highend French hosting company for your minecraft server? More than 24,000 members on our discord trust us. Give us a try!                                                                                                 |
| [**HostEZ**](https://hostez.io)                                                   | US & EU Rust & Minecraft Hosting. DDoS Protected bare metal, VPS and colocation with low latency, high uptime and maximum availability. EZ!                                                                                                     |
| [**Blueprint**](https://blueprint.zip/?utm_source=pterodactyl&utm_medium=sponsor) | Create and install Pterodactyl addons and themes with the growing Blueprint framework - the package-manager for Pterodactyl. Use multiple modifications at once without worrying about conflicts and make use of the large extension ecosystem. |
| [**indifferent broccoli**](https://indifferentbroccoli.com/)                      | indifferent broccoli is a game server hosting and rental company. With us, you get top-notch computer power for your gaming sessions. We destroy lag, latency, and complexity--letting you focus on the fun stuff.                              |

### Supported Games

Pterodactyl supports a wide variety of games by utilizing Docker containers to isolate each instance. This gives
you the power to run game servers without bloating machines with a host of additional dependencies.

Some of our core supported games include:

* Minecraft — including Paper, Sponge, Bungeecord, Waterfall, and more
* Rust
* Terraria
* Teamspeak
* Mumble
* Team Fortress 2
* Counter Strike: Global Offensive
* Garry's Mod
* ARK: Survival Evolved

In addition to our standard nest of supported games, our community is constantly pushing the limits of this software
and there are plenty more games available provided by the community. Some of these games include:

* Factorio
* San Andreas: MP
* Pocketmine MP
* Squad
* Xonotic
* Starmade
* Discord ATLBot, and most other Node.js/Python discord bots
* [and many more...](https://pterodactyleggs.com)

## License

Pterodactyl® Copyright © 2015 - 2022 Dane Everitt and contributors.

Code released under the [MIT License](./LICENSE.md).
