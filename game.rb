require "pstore"
require "net/http"

class Game

  def initialize
    @scores = PStore.new("scores.pstore")
    @name = "Player"
    get_name
  end

  def get_name
    @name = ARGV[0] if ARGV[0]
  end

  def save_score(level, score, computer=nil)
    if computer
      name = "Computer (player lost)"
    else
      name = @name
    end
    @scores.transaction do
      @scores[level] = Array.new if not @scores[level]
      @scores[level] << [name, score] if not @scores[level].include?([name, score])
    end
    begin
      Net::HTTP.post_form(URI.parse('http://highscores.protaskm.com/highscores/create'), {'game'=>'virus-war', 'level'=>level, 'player'=>name, 'score'=>score})
    rescue Exception => e
      puts "Could not sve your highscore (e.message)"
    end
    get_pos_and_print(level, score)
  end

  def has?(level, score)
    @scores.transaction(true) do  # begin read-only transaction, no changes allowed
      @scores[level].each { |arr|
        return arr if arr[1] == score
        }
      return nil
    end
  end

  def get_pos_and_print(level, score)
    raise "no score for #{score}" if not arr = has?(level, score)
    @scores.transaction(true) do  # begin read-only transaction, no changes allowed
      sorted = @scores[level].sort_by { |arr| arr[1] }
      pos = sorted.index(arr) +1
      return [pos, sorted]
    end
  end

end

