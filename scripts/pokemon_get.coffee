# Description:
#   Pokemon Get!
#
# Commands:
#   pokemon get/list/rank/evo/bye

request = require('request')

# 定義
config =
       api: "http://pokeapi.co/api/v1/pokemon/" # ポケモン情報取得APIベース（後ろにIDを付加する必要あり）
#       max: 718
       max: 151      # 対象とするポケモンIDのMAX値
       gif: "https://www.pkparaiso.com/imagenes/xy/sprites/animados/" # ポケモンgifのURLベース（後ろにファイル名を付加する必要あり）
       ball: 3       # 1日に補充されるモンスターボールの個数
       cpMax: 3000   # 捕獲できるポケモンの最大CP
       cpMin: 1      # 捕獲できるポケモンの最小CP
       evo: 1        # 1日に進化させることができる回数
       cpEvoMax: 700 # 進化時の最大増加CP
       cpEvoMin: 200 # 進化時の最小増加CP

##############################################################
# グローバル関数定義
##############################################################

# sleep関数
sleep = (ms) ->
  start = new Date().getTime()
  continue while new Date().getTime() - start < ms

# CP順にsortする関数
compareCp = (a, b) ->
  b.cp - a.cp
# ID順にsortする関数
compareId = (a, b) ->
  b.id - a.id

# 今日の日付文字列(yyyymmdd)を取得する関数
getToday = () ->
  d = new Date
  year  = d.getFullYear()     # 年（西暦）
  month = ("0"+(d.getMonth() + 1)).slice(-2) # 月（0埋め）
  date  = ("0"+d.getDate()).slice(-2)     # 日（0埋め）
  return "#{year}#{month}#{date}"

# 連想配列のコピー
clone = (src) ->
  dst = {}
  for k, v of src
      dst[k] = src[k]
  return dst


##############################################################
# モジュール登録
##############################################################
module.exports = (robot) ->

  ######################################
  # コマンド一覧
  ######################################
  robot.respond /pokemon help/, (res) ->
    usage  = "`@kakinbot pokemon help` : このメッセージを表示する\n"
    usage += "`@kakinbot pokemon get` : モンスターボールを1つ消費してポケモンを捕獲する\n"
    usage += "`@kakinbot pokemon list` : 捕獲したポケモンの一覧をID付きで表示する\n"
    usage += "`@kakinbot pokemon rank` : 捕獲したポケモンの合計CPが大きい順にランキングを表示する\n"
    usage += "`@kakinbot pokemon evo [pokemonID]` : 指定したIDのポケモンを進化させる\n"
    usage += "`@kakinbot pokemon bye [pokemonID]` : 指定したIDのポケモンを野生に返す\n"
    usage += "`@kakinbot pokemon shop [ItemID]` : 指定したIDのアイテムを購入する\n"
    res.send usage

  ######################################
  # ポケモンゲット
  ######################################
  robot.respond /pokemon get/, (res) ->

    # 1日にゲットできる回数上限チェック
    key_pokeball = "pokeball_" + res.message.user.name
    ballData = robot.brain.get(key_pokeball) ? {}
    if `ballData.pokeball == null`
        ballData.pokeball = "000000000" # nullの場合は初回アクセスなので0にリセットしておく

    # 現在保持しているモンスターボールの個数
    pokeballNow = parseInt(ballData.pokeball) - parseInt(getToday()+"0")

    if pokeballNow == 0
        res.send "もうモンスターボールが無いよ...また明日調達してくるね！"
        return
    else if pokeballNow < 0
        # 最後の数値が前日までに残っていた個数 
        pokeballKeep = parseInt(ballData.pokeball[8])
        # 今日分の調達数を足した合計が9個までしか保持できないようにする
        pokeballAll = pokeballKeep + config.ball
        # 9個までしか保持できないようにする
        if pokeballAll > 9
            pokeballAll = 9
       
        ballData.pokeball = getToday() + pokeballAll.toString()
        pokeballNow = pokeballAll
        # 調達後の個数から、前日までに残っていた個数を引けば、今回調達した個数になる
        pokeballPlus = pokeballAll - pokeballKeep
        if pokeballPlus > 0
            res.send "モンスターボールを #{pokeballPlus}個 調達したよ！"

    msg = ""
    for i in [1..pokeballNow]
       msg += ":monster_ball:" 
    res.send "#{msg} よーし、ポケモン捕まえてくるよ！"

    # 数値をランダム生成して、捕まえたポケモンのIDを決定
    pokeSelect = Math.floor(Math.random() * config.max) + 1

    sleep(4000)
    national_id = pokeSelect
    idx = national_id - 1 # 翻訳json用の添字

    # 数値をランダム生成してポケモンの強さ（CP）を定義
    pokeCp = Math.floor(Math.random() * (config.cpMax + 1 - config.cpMin))
    pokeCp += config.cpMin

    # 画像URLのファイル名部分を作成
    img_name = translateData(idx).en.toLowerCase()
    img_name = img_name.replace(/\s/, "_")
    img_name = img_name.replace(/♀/, "_f")
    img_name = img_name.replace(/♂/, "_m")
    img_name = img_name.replace(/\.$/, "")

    pokeData =
        id: national_id
        name: translateData(idx).ja # 翻訳jsonから該当するポケモンの日本語名を取得します
        img: config.gif + img_name + ".gif" # 返却値のnameをもとにして、画像URLをつくります
        cp: pokeCp

    #res.send "<@#{res.message.user.name}> `CP:#{pokeData.cp}` の #{pokeData.name} を捕まえたよ！\n#{pokeData.img}?#"+ (new Date/1000|0).toString()
    res.send "<@#{res.message.user.name}> `CP:#{pokeData.cp}` の #{pokeData.name} を捕まえたよ！"
    attachments = []
    attachment =
          fallback: "<@#{res.message.user.name}> ポケモン捕まえたよ！"
          title: "#{pokeData.name}"
          title_link: "#{pokeData.img}?#"+ (new Date/1000|0).toString()
          text: "`CP:#{pokeData.cp}`"
          image_url: "#{pokeData.img}?#"+ (new Date/1000|0).toString()
          mrkdwn_in: ["text"]
    attachments.push(attachment)
    data = 
        #text: "<@#{res.message.user.name}> `CP:#{pokeData.cp}` の #{pokeData.name} を捕まえたよ！"
        channel: res.envelope.room
        attachments: attachments
    robot.emit "slack.attachment", data

    # もしCPがcpMax-100よりも上だったら驚いてくれます
    if pokeCp > (config.cpMax - 100)
        res.send "コイツは手ごわかった！！"

    # mongodbに保存する
    key = "pokemon_" + res.message.user.name
    pokeList = robot.brain.get(key) ? []
    pokeList.push(pokeData)
    # すでに6匹以上捕まえていたら一番弱いポケモンを捨てる！（デッキは6匹まで）
    while pokeList.length > 6
        # CPの大きい順にソートする
        pokeList.sort compareCp
        remove = pokeList.pop() # 一番最後（CPが小さい）を取得して削除
        res.send "#{remove.name} `CP:#{remove.cp}` は野生に返すね！"
        if remove.name is pokeData.name and remove.cp is pokeData.cp
            res.send "今捕まえたばっかりだけど！"
    # ポケモンを保存
    robot.brain.set key, pokeList
    # モンスターボールの個数を更新
    ballData.pokeball = getToday() + (pokeballNow - 1).toString()
    robot.brain.set key_pokeball, ballData


  ######################################
  # 取得したポケモンの一覧を表示
  ######################################
  robot.respond /pokemon list/, (res) ->
    # mongodbから取得
    key = "pokemon_" + res.message.user.name
    pokeList = robot.brain.get(key) ? []

    if pokeList.length == 0
        res.send "<@#{res.message.user.name}> は、まだ一匹も捕まえていないみたい。"
    else
        message = "オッケー、捕まえたポケモンの一覧を作成するよ。"
        res.send message
        # CP値で降順ソート
        pokeList.sort compareCp
        attachments = []
        for pokemon, index in pokeList
            id = index + 1
            #message = "#{pokemon.name} `CP:#{pokemon.cp}`\n"
            attachment =
                fallback: "<@#{res.message.user.name}> が捕まえたポケモンの一覧だよ！"
                title: "[#{id}] #{pokemon.name}"
                title_link: "#{pokemon.img}?#"+ (new Date/1000|0).toString()
                text: "`CP:#{pokemon.cp}`"
                image_url: "#{pokemon.img}?#"+ (new Date/1000|0).toString()
                mrkdwn_in: ["text"]
            attachments.push(attachment)
        data = 
            text: "<@#{res.message.user.name}> が捕まえたポケモンの一覧だよ！"
            channel: res.envelope.room
            attachments: attachments
        robot.emit "slack.attachment", data
            

  ######################################
  # 取得したポケモンのCP合計が高い人ランキングを表示
  ######################################
  robot.respond /pokemon rank/, (res) ->
    # mongodbから取得
    data = clone(robot.brain.data._private)
    #delete data["pokemonName"]
    # ランキング情報としてCP合計値を保持
    rankList = []
    for key, value of data
        if key[0..7] != "pokemon_"
            continue
        rank = {}
        rank.name = key[8..] # 先頭の"pokemon_"を除去するとSlackアカウントになる
        rank.cp = 0
        value.sort compareCp # CP順にソートしておく
        for pokemon, index in value
            rank.cp += pokemon.cp
            # 各ユーザの最強CPポケモンを登録しておく
            if index == 0
                rank.topName = pokemon.name
                rank.topCp = pokemon.cp

        rankList.push(rank)

    # CP合計値で降順ソート
    rankList.sort compareCp

    message = "現在のランキングだよ！\n"
    top = {}
    for user, index in rankList
        ranking = index + 1
        message += "#{ranking}位　#{user.name}　`CP合計:#{user.cp}` 【最強ポケモン: #{user.topName} `CP:#{user.topCp}`】\n"
        if ranking == 1
            top.name = user.name

    message += "一番強いのは <@#{top.name}> だ！おめでとう！ :tada:"
    res.send message

  ######################################
  # 指定したポケモンを進化させる
  ######################################
  robot.respond /pokemon evo/, (res) ->

    target_text = /(\d+)/.exec(res.message.text)
    if `target_text == null` or parseInt(target_text[1]) < 1 or parseInt(target_text[1]) > 6
        res.send "IDは1～6の数字で選択してね！IDは `pokemon list` でわかるよ！"
        return
    target = target_text[1] - 1

    # mongodbから現在捕獲しているポケモンを取得
    key = "pokemon_" + res.message.user.name
    pokeList = robot.brain.get(key) ? []
    # CP値で降順ソート
    pokeList.sort compareCp

    if pokeList.length < target_text[1]
        res.send "ID:#{target_text[1]}のポケモンはいないよ！"
        return


    # 1日に進化できる回数上限チェック
    key_evolution = "evolution_" + res.message.user.name
    evoData = robot.brain.get(key_evolution) ? {}
    if `evoData.count == null`
        evoData.count = 0 # nullの場合は初回アクセスなので0にリセットしておく

    # 現在の進化可能な回数を取得
    evoNow = parseInt(evoData.count) - parseInt(getToday()+"0")

    if evoNow == 0
        res.send "今日はもう進化できるパワーが無いよ...また明日ね！"
        return
    else if evoNow < 0
        evoData.count = getToday() + "#{config.evo}"
        evoNow = config.evo

    res.send "#{pokeList[target].name} `CP:#{pokeList[target].cp}` を進化させるよ！"
  
    # リクエストデータ作成 
    options =
      url: config.api + pokeList[target].id + '/'
      json: true

    # APIにリクエスト
    request.get options, (err, response, body) ->
      if response.statusCode == 200
          sleep(4000)
          # 進化情報を取得
          if body.evolutions.length == 0
              res.send "#{pokeList[target].name} は進化できないみたい..."
              return

          evolutions = []
          for evolution, index in body.evolutions
              # megaは進化対象外
              continue if evolution.detail == "mega"
              # APIのバグで進化先になってるものを除外
              evo_id_exp = /\/api\/v1\/pokemon\/(\d+)\//.exec(evolution.resource_uri)
              evo_id = evo_id_exp[1]
              # アーボック(id:24)　->　ピカチュウ(id:25)
              continue if pokeList[target].id == "24" and evo_id == "25"
              # ニドキング(id:34)　->　ピッピ(id:35)
              continue if pokeList[target].id == "34" and evo_id == "35"
              # キュウコン(id:38)　->　プリン(id:39)
              continue if pokeList[target].id == "38" and evo_id == "39"
              # ガラガラ(id:105)　->　サワムラー(id:106)
              continue if pokeList[target].id == "105" and evo_id == "106"
              # サイドン(id:112)　->　ラッキー(id:113)
              continue if pokeList[target].id == "112" and evo_id == "113"
              # ストライク(id:123)　->　ルージュラ(id:124)
              continue if pokeList[target].id == "123" and evo_id == "124"
              # ルージュラ(id:124)　->　エレブー(id:125)
              continue if pokeList[target].id == "124" and evo_id == "125"
              # プテラ(id:142)　->　カビゴン(id:143) 
              continue if pokeList[target].id == "142" and evo_id == "143"

              evolutions.push(evolution)

          if evolutions.length == 0
              res.send "#{pokeList[target].name} は進化できないみたい..."
              return
                  
          # 進化先をランダム選択
          evo_num = Math.floor(Math.random() * evolutions.length)
          evo = evolutions[evo_num]
          evo_to = evo.to ? ""
          if evo_to == ""
              res.send "#{pokeList[target].name} は進化できないみたい..."
              return

          evo_id_exp = /\/api\/v1\/pokemon\/(\d+)\//.exec(evo.resource_uri)
          evo_id = evo_id_exp[1]
          idx = evo_id - 1 # 翻訳json用の添字

          # 増加させるCP値をランダム取得
          cpEvo = Math.floor(Math.random() * (config.cpEvoMax + 1 - config.cpEvoMin) )
          cpEvo += config.cpEvoMin

          pokeData =
              id: evo_id
              name: translateData(idx).ja # 翻訳jsonから該当するポケモンの日本語名を取得します
              img: config.gif + evo_to.toLowerCase() + ".gif" # 返却値のnameをもとにして、画像URLをつくります
              cp: parseInt(pokeList[target].cp) + cpEvo
 
          #res.send "<@#{res.message.user.name}> #{pokeList[target].name} が進化して `CP:#{pokeData.cp}` の #{pokeData.name} になったよ！\n#{pokeData.img}"
          attachments = []
          attachment =
                fallback: "<@#{res.message.user.name}> ポケモンが進化したよ！"
                title: "#{pokeData.name}"
                title_link: "#{pokeData.img}?#"+ (new Date/1000|0).toString()
                text: "`CP:#{pokeData.cp}`"
                image_url: "#{pokeData.img}?#"+ (new Date/1000|0).toString()
                mrkdwn_in: ["text"]
          attachments.push(attachment)
          data = 
              text: "<@#{res.message.user.name}> #{pokeList[target].name} が進化して `CP:#{pokeData.cp}` の #{pokeData.name} になったよ！"
              channel: res.envelope.room
              attachments: attachments
          robot.emit "slack.attachment", data

          # mongodbに保存する
          # 進化元のポケモンは捨てる！
          pokeList.splice(target, 1)
          # ポケモンを保存
          pokeList.push(pokeData)
          robot.brain.set key, pokeList
          # 進化可能回数を更新
          evoData.count = getToday() + (evoNow - 1).toString()
          robot.brain.set key_evolution, evoData
      else
          # APIエラーだった場合は、進化失敗
          res.send "<@#{res.message.user.name}> 進化に失敗したよ。。"

  ######################################
  # ポケモンを野生に返す
  ######################################
  robot.respond /pokemon bye/, (res) ->
    target_text = /(\d+)/.exec(res.message.text)
    if `target_text == null` or parseInt(target_text[1]) < 1 or parseInt(target_text[1]) > 6
        res.send "IDは1～6の数字で選択してね！IDは `pokemon list` でわかるよ！"
        return
    target = target_text[1] - 1

    # mongodbから現在捕獲しているポケモンを取得
    key = "pokemon_" + res.message.user.name
    pokeList = robot.brain.get(key) ? []
    # CP値で降順ソート
    pokeList.sort compareCp

    if pokeList.length < target_text[1]
        res.send "ID:#{target_text[1]}のポケモンはいないよ！"
        return

    target_name = pokeList[target].name
    target_cp = pokeList[target].cp

    # mongodbに保存する
    # 指定したポケモンを削除
    pokeList.splice(target, 1)
    robot.brain.set key, pokeList

    res.send "#{target_name} `CP:#{target_cp}` を野生に返したよ！"

  ######################################
  # アイテムショップ
  ######################################
  robot.respond /pokemon shop/, (res) ->
    target_text = /(\d+)/.exec(res.message.text)

    # mongodbからアイテムリストを取得
    key = "pokemonItem"
    itemList = robot.brain.get(key) ? []
    # ID値で降順ソート
    itemList.sort compareId

    if `target_text == null`
        # アイテムリストを表示
        for item, index in itemList
            attachments = []
            attachment =
                fallback: "アイテム一覧だよ！"
                title: "[#{item.id}] #{item.name}"
                title_link: "#{item.img}?#"+ (new Date/1000|0).toString()
                text: "#{item.note}\n `購入に必要なモンスターボール数: #{item.price}` "
                image_url: "#{item.img}?#"+ (new Date/1000|0).toString()
            attachments.push(attachment)
        data = 
            text: "購入できるアイテムの一覧だよ！"
            channel: res.envelope.room
            attachments: attachments
        robot.emit "slack.attachment", data
        return
        
    if parseInt(target_text[1]) < 1 or parseInt(target_text[1]) > itemList.length
        res.send "ItemIDは `pokemon shop` で確認してね！"
        return
    target = parseInt(target_text[1])

    # スーパーボールを購入した場合
    if target == 1
        res.send "スーパーボールを購入しました！"


##############################################################
# モジュール内 関数定義
##############################################################
  # ポケモンの名前翻訳json
  translateData = (idx) ->
    # mongodbから取得
    pokeName = robot.brain.get("pokemonName") ? []
    pokeName[idx]
