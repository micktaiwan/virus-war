class Brain

  def initialize(all_virus)
    @virus = all_virus
    @time = Time.now
  end

  def iterate
    update_virus
    play_ennemies
    sleep(0.001)
  end

private

  def update_virus
    time = Time.now - @time
    @virus.each{ |v|
      v.update(time)
      }
    @time = Time.now
  end

  def play_ennemies
    @virus.each { |v|
      next if v.team == :neutral or v.team == :green
      #next if rand(1000) != 0
      v.play
      }
  end

end

