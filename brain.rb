class Brain

  TimeFactor    = 0.5

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
        #v.remove_life(time*factor(v,nb)*nb)  { |v| t.retract if v.life <= 1 }
        if t.to.team == v.team
          t.to.add_life(time*factor(v,nb))
          t.retract if v.life <= 1
        elsif t.to.team != :neutral
          t.to.remove_life(time*factor(v, nb)){ |to| to.change_team(v.team) if to.life <= 1 }
          # TODO: if life < 1, first retract tentacles before changing team
        else # neutral
          t.to.contaminate(time*factor(v, nb), v.team)
        end
        }

      # virus animation
      v.update(time)
      }
    @time = Time.now
  end

  def factor(v,tnb)
    1 + (v.life/tnb)/25
  end

  def play_ennemies
    @virus.each { |v|
      next if v.team == :neutral or v.team == :green
      #next if rand(1000) != 0
      v.play
      }
  end

end

