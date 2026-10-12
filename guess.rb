# === 設定 ===
MIN = 1
HISTORY_FILE = 'history.txt'

# 難易度ごとの範囲と回数制限
DIFFICULTIES = {
  '1' => { name: '易しい', max: 10,   limit: 5 },
  '2' => { name: '普通',   max: 100,  limit: 10 },
  '3' => { name: '難しい', max: 1000, limit: 15 },
}.freeze

# Ctrl + D で入力が終了したことを表す自作の例外
class GameAborted < StandardError; end

# === 1 行入力を受け取る（前後の空白は取り除く）===
def ask(prompt)
  print prompt
  input = gets
  # Ctrl + D で入力が終了すると gets は nil を返す
  raise GameAborted if input.nil?

  input.strip
end

# === 難易度を選ぶ ===
def choose_difficulty
  puts '難易度を選んでください。'
  DIFFICULTIES.each do |key, d|
    puts "  #{key}: #{d[:name]}（#{MIN}〜#{d[:max]}、#{d[:limit]} 回まで）"
  end

  loop do
    choice = ask('番号を入力してください: ')
    return DIFFICULTIES[choice] if DIFFICULTIES.key?(choice)

    puts '1、2、3 のどれかを入力してください'
  end
end

# === 正しい数字が入力されるまで受け取り続ける（不正な入力への対応）===
def read_guess(max)
  loop do
    input = ask('入力してください: ')

    if input.empty?
      puts '数字を入力してください'
      next
    end

    begin
      guess = Integer(input, 10)
    rescue ArgumentError
      puts "「#{input}」は数字ではありません。整数を入力してください"
      next
    end

    unless guess.between?(MIN, max)
      puts "#{MIN} から #{max} の範囲で入力してください"
      next
    end

    return guess
  end
end

# === 正解との差でヒントを変える ===
def hint(guess, answer, max)
  gap = (guess - answer).abs
  # 範囲の 5 分の 1 より離れていれば「かなり」、近ければ「少し」
  degree = gap > max / 5 ? 'かなり' : '少し'

  if guess > answer
    "#{degree}大きいです。もっと小さい数字です"
  else
    "#{degree}小さいです。もっと大きい数字です"
  end
end

# === 結果を history.txt に追記する ===
def save_history(difficulty, result, count, answer)
  time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  line = "#{time} 難易度:#{difficulty[:name]} 結果:#{result} 回数:#{count} 正解:#{answer}"

  File.open(HISTORY_FILE, 'a') do |file|
    file.puts line
  end
rescue SystemCallError => e
  # 書き込みに失敗してもゲーム自体は落とさない
  puts "履歴を保存できませんでした: #{e.message}"
end

# === ゲーム本体 ===
def main
  difficulty = choose_difficulty
  max = difficulty[:max]
  limit = difficulty[:limit]

  answer = rand(MIN..max)
  count = 0

  puts "#{MIN} から #{max} までの数字を当ててください。チャンスは #{limit} 回です。"

  # 回数制限に達するまで繰り返す
  while count < limit
    guess = read_guess(max)
    count += 1

    if guess == answer
      puts "正解！ #{count} 回で当てました"
      save_history(difficulty, '正解', count, answer)
      return
    end

    puts hint(guess, answer, max)
    puts "残り #{limit - count} 回です" if count < limit
  end

  puts "ゲームオーバー！ 正解は #{answer} でした"
  save_history(difficulty, 'ゲームオーバー', count, answer)
rescue GameAborted, Interrupt
  # Ctrl + D または Ctrl + C で中断された場合
  puts
  if answer
    puts "ゲームを中断しました。正解は #{answer} でした"
    save_history(difficulty, '中断', count, answer)
  else
    puts 'ゲームを終了しました'
  end
end

main if __FILE__ == $PROGRAM_NAME
