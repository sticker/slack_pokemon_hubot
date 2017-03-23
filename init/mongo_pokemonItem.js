db.brain.remove( { key: "pokemonItem"} );
db.brain.insert( { key: "pokemonItem", type: "_private", value: [ { "id" : 1, "name" : "スーパーボール", "price" : 4, "img" : "https://raw.githubusercontent.com/sticker/slack_pokemon/master/images/super_ball.png", "note" : "モンスターボールより少し性能がいい" }]} );
