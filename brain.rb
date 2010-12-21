class Brain

  TimeFactor    = 0.5
  GrowFactor    = 2
  GiveFactor    = 0.2
  AttackFactor  = 1

  def initialize(all_virus)
    @virus = all_virus
    @time = Time.now
  end

  def iterate
    update_virus
    play_ennemies
  end

private

  def update_virus
    time = Time.now - @time
    @virus.each{ |v|
      # time life
      v.add_life(time*TimeFactor) if v.team != :neutral

      # tentacles life
      nb = v.active_tentacles.size
      v.active_tentacles.each { |t|
        v.remove_life(time*GiveFactor*nb/2)  { |v| t.retract if v.life <= 1 }
        if t.to.team == v.team
          t.to.add_life(time*GrowFactor*factor(v))
          t.retract if v.life <= 1
        elsif t.to.team != :neutral
          t.to.remove_life(time*AttackFactor*factor(v)){ |to| to.change_team(v.team) if to.life <= 1 }
        else # neutral
          t.to.contaminate(time*AttackFactor*factor(v), v.team)
        end
        }

      # virus size
      v.update_size

      # virus animation
      v.update(time)
      }
    @time = Time.now
  end

  def factor(v)
    v.life/150+1
  end

  def play_ennemies
    @virus.each { |v|
      next if v.team == :neutral or v.team == :green
      #next if rand(1000) != 0
      v.play
      }
  end

end

