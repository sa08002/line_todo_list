class LineBotController < ApplicationController
  require "line/bot"

  protect_from_forgery with: :null_session

  def callback
    # LINEで送られてきたメッセージのデータを取得
    body = request.body.read

    # LINE以外からリクエストが来た場合 Error を返す
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request and return
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)

    events.each do |event|
      # LINE からテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        message = event["message"]["text"]
    
        text =
          case message
          when "一覧" # タスクの一覧を出力する
            tasks = Task.all
    
            # タスクの数ぶん繰り返し指定する
            # 配列の文字列を改行 \n で連結して1つの長い文字列とする
            tasks.map.with_index(1) { |task, index| "#{index}: #{task.body}" }.join("\n")
          when /削除+\d/
            # 送られてきたメッセージから id を取り出す
            # 「削除 3」 のように間にスペースがあっても問題ないように調整
            index = message.gsub(/削除*/, "").strip.to_i
            tasks = Task.all.to_a
            task = tasks.find.with_index(1) { |_task, _index| index == _index }
            task.destroy!
            "タスク #{index}: 「#{task.body}」 を削除しました！"
          else
            Task.create!(body: message)
            "タスク: 「#{message}」 を登録しました！"
          end
    
        reply_message = {
          type: "text",
          text: text
        }
        client.reply_message(event["replyToken"], reply_message)
      end
    end

    # LINE の webhook API との連携をするために status code 200 を返す
    render json: { status: :ok }
  end

  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end
end
