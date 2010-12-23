require 'tentacle'

class Virus

  attr_accessor :x, :y, :team, :start, :tentacles
  attr_reader :life, :max, :max_t, :ellipse, :lifetext

  BorderSize = 3

  def initialize(canvas, h, board)
    @board = board
    @canvas = canvas
    @x      = h[:x]
    @y      = h[:y]
    @team   = h[:team]
    @start  = h[:start].to_f
    if @team == :neutral
      @life = 0
      @contamination    = 0
      @contaminate_team = :none
    else
      @life = @start
    end
    @max    = h[:max]
    @max_t  = h[:max_t]
    @tentacles    = []
    @receiving_tentacles = []
    @border = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[("dark_"+@team.to_s).to_sym]})
    @ellipse = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[@team]})
    @lifetext = Gnome::CanvasText.new(@canvas.root, {
      :x => @x,
      :y => @y,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => @life.to_s})
    @border.raise_to_top
    @ellipse.raise_to_top
    @lifetext.raise_to_top
    @size_factor = 20
    update(0)
  end

  def update(time)
    update_life(time)
    update_pos
    update_tentacles(time)
    update_size
  end

  def update_tentacles(time)
    occupied_tentacles.each { |t|
      t.update(time)
      }
  end

  def update_pos
    @life = @max if @life > @max
    @border.x1 = @x-@size_factor-BorderSize
    @border.x2 = @x+@size_factor+BorderSize
    @border.y1 = @y-@size_factor-BorderSize
    @border.y2 = @y+@size_factor+BorderSize
    @ellipse.x1 = @x-@size_factor
    @ellipse.x2 = @x+@size_factor
    @ellipse.y1 = @y-@size_factor
    @ellipse.y2 = @y+@size_factor
    if @team == :neutral
      @lifetext.markup = @contamination.to_i.to_s
    else
      @lifetext.markup = @life.to_i.to_s
    end
  end

  def retract_to_survive
    rv = false
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      t.retract
      rv = true
      }
    rv  
  end

  def update_life(time)
    # time life
    add_life(time*TimeFactor) if @team != :neutral

    # tentacles life
    nb = active_tentacles.size
    active_tentacles.each { |t|
      if t.to.team == @team
        t.to.add_life(time*factor(@life,nb))
        t.retract if @life <= 1
      elsif t.to.team != :neutral
        t.to.remove_life(time*factor(@life, nb), t.from.team)
      else # neutral
        t.to.contaminate(time*factor(@life, nb), @team)
      end
      }
  end

  def add_tentacle(destination_virus)
    puts "same virus" and return if self == destination_virus

    # check for walls
    return false if @board.check_walls(@x,@y, destination_virus.x, destination_virus.y)
    
    # check if tentacle already exists
    return false if find_all(destination_virus)

    # check if available tentacles
    return false if occupied_tentacles.size >= @max_t
    
    if @tentacles.size >= @max_t
      find_next_hidden.deploy(destination_virus)
    else
      @tentacles << Tentacle.new(@canvas, self, destination_virus)
    end
    # if same team and connected already
    if destination_virus.team == @team and t = destination_virus.find_all(self) and t
      t.retract 
    end
    return true
  end

  def occupied_tentacles
    @tentacles.select { |t| t.state != :hidden}
  end

  def find_next_hidden
    @tentacles.each { |t|
      return t if t.state == :hidden
      }
    nil
  end

  def receive_tentacle(t)
    @receiving_tentacles << t
  end

  def detach_ennemy_tentacle(t)
    @receiving_tentacles.delete(t)
  end

  #def retract(t)
  #  #@life += t.length
  #  t.retract
  #end

  def add_life(l)
    @life += l
    @life = @max if @life > @max
    yield self if block_given?
  end

  def contaminate(l, team)
    if @contaminate_team == team
      @contamination += l
      if @contamination >= @start
        change_team(team)
      end
    else
      @contamination -= l
      if @contamination <= 0
        @contamination = -@contamination
        @contaminate_team = team
      end
    end
  end

  def remove_life(l, team)
    @life -= l
    if @life < 1 and not retract_to_survive
      change_team(team)
    end
    #yield self if block_given?
  end

  def active_tentacles
    @tentacles.select { |t| t.state == :active}
  end

  def occupied_tentacles
    @tentacles.select { |t| t.state != :hidden}
  end

  def find(to) # TODO add a block to filter virus found
    active_tentacles.each { |t|
      return t if t.from == self and t.to == to
      }
    return nil
  end

  def find_all(to) # TODO no more needed if added filter with block to "find"
    occupied_tentacles.each { |t|
      return t if t.from == self and t.to == to
      }
    return nil
  end


  def change_team(team)
    @@player.play(:change)
    @team = team
    @life += @start
    @ellipse.fill_color_rgba = Colors[team]
    @border.fill_color_rgba = Colors[("dark_"+@team.to_s).to_sym]
    @tentacles.each { |t|
      t.change_team(team)
      }
  end

  # make an "intelligent" action
  def play

    ots = occupied_tentacles.size
    ets = ennemies_tentacles.size
    ats = active_tentacles.size
    
    # attack if attacked
    if ets > 0 and ots < @max_t and ots == ats
      ennemies_tentacles.each { |t|
        return if enough_life?(t.from, :half) and add_tentacle(t.from)
        }
    end

    # retract tentacle if not attacked and life is inferior
    #active_tentacles.each { |t|
    #  t.retract if t.to.team !=:neutral and t.to.team != @team and !t.to.find(self) and @life+10 < t.to.life
    #  }

    # remove useless tentacles: to same team not attacked with more life (attention to rule below when connecting friends with less life)
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      t.retract if t.to.team == @team and t.to.life > @life and t.to.ennemies_tentacles.size == 0
      }

    # remove useless tentacles: from neutral when attacked
    if @receiving_tentacles.size > 0  and occupied_tentacles.size >= @max_t
      occupied_tentacles.each { |t|
        if t.to.team == :neutral
          t.retract
          break
        end
        }
    end

    # attack neutral
    if ots < @max_t
      n = nearest { |v| v.team == :neutral }
      return if n and enough_life?(n) and add_tentacle(n)
    end

    # attack nearest ennemy with less life
    if ots < @max_t
      e = nearest { |v| v.team != @team and v.team != :neutral }
      return if e and e.life < @life and enough_life?(e) and add_tentacle(e)
    end

    # recharge friends
    if ots < @max_t and @tentacles.select { |t| t.state==:deploying }.size == 0 # if deploying then life is less than displayed
      e = nearest { |v| v.team == @team and v != self }
      if e and e.life < (@life-deploy_cost(e))-1#and enough_life?(e)
        add_tentacle(e)
        return
      end
    end
    
  end

  def deploy_cost(v)
    utils_distance(@x,@y, v.x,v.y)*LengthFactor
  end
  
  def enough_life?(v, length=:full)
    raise "no virus" if not v
    (deploy_cost(v) / (length==:half ? 1.95 : 1))+1 < @life # +1 as virus are dead if life < 1
  end

  def nearest
    rv = nil
    nd = 1000
    @board.virus.select{|v| block_given? ? (yield v) : (v==self ? false : true) }.each { |v|
      d = utils_distance(self.x, self.y, v.x, v.y)
      rv = v and nd = d if d < nd
      }
    rv
  end

  def ennemies_tentacles
    @receiving_tentacles.select { |t| t.from.team != @team }
  end

  def update_size
    if @team != :neutral
      @size_factor = Math.cos(Time.now.to_f*3) + 20 + @life/5
    else
      @size_factor = 20 + @start/5
    end
  end

  def destroy
    @ellipse.destroy
    @border.destroy
    @lifetext.destroy
  end

end

