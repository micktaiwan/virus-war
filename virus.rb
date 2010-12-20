require 'tentacle'

class Virus

  attr_accessor :x, :y, :team, :start, :tentacles
  attr_reader :life, :max, :max_t

  def initialize(canvas, h)
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
    return if find(destination_virus)
    #return if destination_virus.find(self)
    s = occupied_tentacles.size
    return if s >= @max_t
    if @tentacles.size >= @max_t
      @tentacles[s].deploy(destination_virus)
    else
      @tentacles << Tentacle.new(@canvas, self, destination_virus)
    end
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

  def change_team(team)
    @team = team
    @life = @start
    @ellipse.fill_color_rgba = Colors[team]
    active_tentacles.each { |t|
      t.change_team(team)
      }
  end

end

