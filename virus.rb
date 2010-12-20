require 'tentacle'

class Virus

  attr_accessor :x, :y, :team, :start, :tentacles
  attr_reader :life, :max, :max_t

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
    update
  end

  def update_tentacles
    @tentacles.each { |t|
      t.update
      }
  end

  def update
    @life = @max if @life > @max
    @ellipse.x1 = @x-20
    @ellipse.x2 = @x+20
    @ellipse.y1 = @y-20
    @ellipse.y2 = @y+20
    if @team == :neutral
      @lifetext.markup = @contamination.round.to_s
    else
      @lifetext.markup = @life.round.to_s
    end
    update_tentacles
  end

  def add_tentacle(destination_virus)
    return if find_all(destination_virus)
    #return if destination_virus.find(self)
    s = occupied_tentacles.size
    return if s >= @max_t
    if @tentacles.size >= @max_t
      find_next_hidden.deploy(destination_virus)
    else
      @tentacles << Tentacle.new(@canvas, self, destination_virus)
    end
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
        @contamination = 1
        @contaminate_team = team
      end
    end
  end

  def remove_life(l)
    @life -= l
    @life = 1 if @life < 1
    yield self if block_given?
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
    @team = team
    @life = @start
    @ellipse.fill_color_rgba = Colors[team]
    active_tentacles.each { |t|
      t.change_team(team)
      }
  end

  # make an "intelligent" action
  def play
    # attack if attacked
    if @receiving_tentacles.size > 0 and occupied_tentacles.size < @max_t
      ennemies_tentacles.each { |t|
        add_tentacle(t.from)
        }
    end

    # do nothing if life is too small
    return if life <= 5

    # attack neutral
    if occupied_tentacles.size < @max_t
      @board.virus.select { |v| v.team == :neutral }.each { |v|
        add_tentacle(v)
        }
    end

    # retract tentacle if not attacked and life is inferior
    #active_tentacles.each { |t|
    #  t.retract if t.to.team !=:neutral and t.to.team != @team and !t.to.find(self) and @life+1 < t.to.life
    #  }

    # attack nearest ennemy with less life
    if occupied_tentacles.size < @max_t
      # TODO: take into account the life we need to deploy
      e = nearest_ennemy_not_attacked
      add_tentacle(e) if e
    end

    # remove useless tentacles: to same team not attacked
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      t.retract if t.to.team != :neutral and t.to.team == @team and t.to.ennemies_tentacles.size == 0
      }

  end

  def nearest_ennemy_not_attacked
    rv = nil
    nd = 1000
    @board.virus.select{|v| v.team != :neatral and v.team != @team}.each { |v|
      d = distance(self.x, self.y, v.x, v.y)
      rv = v and nd = d if d < nd
      }
    rv
  end

  def ennemies_tentacles
    @receiving_tentacles.select { |t| t.from.team != @team }
  end

end

