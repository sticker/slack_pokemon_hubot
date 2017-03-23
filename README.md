# Pokemon Get for Slack's hubot

## Install

~~~
$ git clone https://github.com/sticker/slack_pokemon.git
$ mongo hubot-brain --quiet slack_pokemon/init/mongo_pokemonName.js
$ mongo hubot-brain --quiet slack_pokemon/init/mongo_pokemonItem.js
$ cp -p slack_pokemon/scripts/pokemon_get.coffee $HUBOT_HOME/scripts/
~~~

