class Brain

  GrowFactor    = 0.5
  GiveFactor    = 0.25 # TODO: to multiply by the number of virus we give

  def initialize(all_virus)
    @virus = all_virus
    @time = Time.now
  end

  def iterate
    update_life_points
    play_ennemies
  end

private

  def update_life_points
    time = Time.now - @time
    @virus.each{ |v|
      if v.team != :neutral
        v.add_life(time*GrowFactor)
      end

      v.active_tentacles.each { |t|

        if t.to.team == v.team
          t.to.add_life(time*factor(v))
          v.remove_life(time*GiveFactor)
          t.retract if v.life <= 1

        elsif t.to.team != :neutral
          t.to.remove_life(time*factor(v)){ |to| to.change_team(v.team) if to.life <= 1 }
          v.remove_life(time*GiveFactor)  { |v| t.retract if v.life <= 1 }
        else # neutral
          t.to.contaminate(time*factor(v), v.team)
        end
        }

      v.update
      }
    @time = Time.now
  end

  def factor(v)
    v.life/100+1
  end

  def play_ennemies
    @virus.each { |v|
      next if v.team == :neutral or v.team == :green
      v.play
      }
  end

end

