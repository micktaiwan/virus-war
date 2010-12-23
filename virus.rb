require 'tentacle'

class Virus

  attr_accessor :x, :y, :team, :start, :tentacles
  attr_reader :life, :max, :max_t, :ellipse, :lifetext

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
    @ellipse = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[@team]})
    @lifetext = Gnome::CanvasText.new(@canvas.root, {
      :x => @x,
      :y => @y,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => @life.to_s})
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
        # TODO: if life < 1, first retract tentacles before changing team
      else # neutral
        t.to.contaminate(time*factor(@life, nb), @team)
      end
      }
  end

  def add_tentacle(destination_virus)
    # check for walls
    return false if @board.check_walls(@x,@y, destination_virus.x, destination_virus.y)

    # check if already exists
    return false if find_all(destination_virus)

    #return if destination_virus.find(self)
    s = occupied_tentacles.size
    return false if s >= @max_t
    if @tentacles.size >= @max_t
      find_next_hidden.deploy(destination_virus)
    else
      @tentacles << Tentacle.new(@canvas, self, destination_virus)
    end
    # if same team and connected already
    if destination_virus.team == @team and t = destination_virus.find_all(self)
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
      if(team == @team)
        puts "#{team} impossible?"
      else
        change_team(team)
      end   
    end
    #yield self if block_given?
  end

  def active_tentacles
    @tentacles.select { |t| t.state == :active}
  end

  def occupied_tentacles
    @tentacles.select { |t| t.state != :hidden}
  end

  def find(to)
    active_tentacles.each { |t|
      return t if t.from == self and t.to == to
      }
    return nil
  end

  def find_all(to)
    occupied_tentacles.each { |t|
      return t if t.from == self and t.to == to
      }
    return nil
  end


  def change_team(team)
    @@player.play(:change)
    @team = team
    @life += @start
    puts team
    @ellipse.fill_color_rgba = Colors[team]
    @tentacles.each { |t|
      t.change_team(team)
      }
  end

  # make an "intelligent" action
  def play

    # attack if attacked
    if @receiving_tentacles.size > 0 and occupied_tentacles.size < @max_t
      ennemies_tentacles.each { |t|
        add_tentacle(t.from) if(enough_life?(t.from, :half))
        }
      return
    end

    # retract tentacle if not attacked and life is inferior
    #active_tentacles.each { |t|
    #  t.retract if t.to.team !=:neutral and t.to.team != @team and !t.to.find(self) and @life+10 < t.to.life
    #  }

    # remove useless tentacles: to same team not attacked
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      t.retract if t.to.team != :neutral and t.to.team == @team and t.to.ennemies_tentacles.size == 0
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
    if occupied_tentacles.size < @max_t
      n = nearest { |v| v.team == :neutral }
      if enough_life?(n)
        add_tentacle(n)
        return
      end
    end

    # do nothing else if life is too small
    return if life <= 5

    # attack nearest ennemy with less life
    if occupied_tentacles.size < @max_t
      e = nearest { |v| v.team != :neutral and v.team != @team }
      if e.life < @life and enough_life?(e)
        add_tentacle(e)
        return
      end
    end

    # TODO: nothing else to d: recharge friends
  end

  def enough_life?(v, length=:full)
    return false if not v
    (utils_distance(@x,@y, v.x,v.y)*LengthFactor+1) / (length==:half ? 2 : 1) < @life
  end

  def nearest
    rv = nil
    nd = 1000
    @board.virus.select{|v| block_given? ? (yield v) : true }.each { |v|
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
    @lifetext.destroy
  end

end

