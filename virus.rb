require 'tentacle'

class Virus

  attr_accessor :x, :y, :team, :start, :tentacles
  attr_reader :life, :max, :max_t, :ellipse, :lifetext, :contamination

  BorderSize      = 3
  NbTDisplaySize  = 6
  NbTDisplaySizeBy2 = NbTDisplaySize / 2

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
    @nb_t_displays = []  
    @tentacles    = []
    @receiving_tentacles = []
    @border = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[("dark_"+@team.to_s).to_sym]})
    @ellipse = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[@team]})
    @lifetext = Gnome::CanvasText.new(@canvas.root, {
      :x => @x,
      :y => @y-5,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => @life.to_s})
    # TODO: nb of tentacles display  
    @border.raise_to_top
    @ellipse.raise_to_top
    @lifetext.raise_to_top
    set_nb_tentacles
    @size_factor = 20
    update(0)
  end
  
  def set_nb_tentacles
    old, @nb_t = @nb_t, nb_tentacles
    update_nb_t_display if old != @nb_t and @team != :neutral
  end

  def nb_tentacles
    rv = 0
    if @life >= 15
      rv = 2
    elsif @life >= 100
      rv = 3
    else
      rv = 1
    end  
    rv = @max_t if rv > @max_t
    rv
  end
  
  def update_nb_t_display
    if @nb_t > @nb_t_displays.size
      (0..@nb_t-1).each {
        @nb_t_displays << (n = Gnome::CanvasEllipse.new(@canvas.root, {
        :fill_color => "white"}))
        n.raise_to_top
        }
    end
    (0..@nb_t-1).each { |i|
      @nb_t_displays[i].show
      @nb_t_displays[i].x1 = @x-NbTDisplaySizeBy2       - i*NbTDisplaySize*1.5 + (@nb_t-1)*NbTDisplaySizeBy2*1.5
      @nb_t_displays[i].y1 = @y-NbTDisplaySizeBy2 + 12
      @nb_t_displays[i].x2 = @x+NbTDisplaySizeBy2       - i*NbTDisplaySize*1.5 + (@nb_t-1)*NbTDisplaySizeBy2*1.5
      @nb_t_displays[i].y2 = @y+NbTDisplaySizeBy2 + 12  
      }
    (@nb_t..@nb_t_displays.size-1).each { |i|
      @nb_t_displays[i].hide
      }
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
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      next if t.duel?
      t.retract
      return true
      }
    return false
  end

  # maybe put this in tentacles ?
  def update_life(time)
    add_life(time*TimeFactor) if @team != :neutral
  end

  def add_tentacle(destination_virus)
    puts "same virus" and return if self == destination_virus

    # check for walls
    return false if @board.check_walls(@x,@y, destination_virus.x, destination_virus.y)
    
    # check if tentacle already exists
    return false if find_all(destination_virus)

    # check if available tentacles
    return false if occupied_tentacles.size >= @nb_t
    
    if @tentacles.size >= @nb_t
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

  def detach_tentacle(t)
    @receiving_tentacles.delete(t)
  end

  #def retract(t)
  #  #@life += t.length
  #  t.retract
  #end

  def add_life(l)
    @life += l
    @life = @max if @life > @max
    set_nb_tentacles
    yield self if block_given?
  end

  def contaminate(l, team)
    if @contaminate_team == team
      @contamination += l
      if @contamination >= @start
        change_team(team)
        @nb_t = 0
        set_nb_tentacles
      end
    else
      @contamination -= l
      if @contamination <= 0
        @contamination = -@contamination
        @contaminate_team = team
        set_contaminate_color(team)
      end
    end
  end

  def remove_life(l, team)
    @life -= l
    if @life < 1 and not retract_to_survive
      change_team(team)
    end
    set_nb_tentacles
    #yield self if block_given?
  end

  def active_tentacles
    @tentacles.select { |t| t.state == :active}
  end

  def occupied_tentacles
    @tentacles.select { |t| t.state != :hidden}
  end

  def find_all(to)
    find_tentacle_if { |t| t.to==to}
  end

  def find_tentacle_if
    raise "must have a block" if not block_given?
    occupied_tentacles.each { |t|
      return t if yield t
      }
    return nil
  end


  def change_team(team)
    @@player.play(:change)
    @team = team
    @life = -@life + @start
    set_color(@team)
    @tentacles.each { |t|
      t.change_team(team)
      }
  end

  def set_color(team)
    @ellipse.fill_color_rgba = Colors[team]
    @border.fill_color_rgba = Colors[("dark_"+team.to_s).to_sym]
  end

  def set_contaminate_color(team)
    @ellipse.fill_color_rgba = Colors[(team.to_s+"_contaminate").to_sym]
    @border.fill_color_rgba = Colors[(team.to_s).to_sym]
  end

  # make an "intelligent" action
  def play

    # TODO: for all loops below, precalculate all the sums, instead of looping them

    # if deploying, do nothing else
    @tentacles.each { |t| return if t.state==:deploying }
    
    ots = occupied_tentacles.size
    ets = ennemies_tentacles.size
    ats = active_tentacles.size
    
    # remove useless tentacles: to same team not attacked with more life (attention to rule below when connecting friends with less life)
    occupied_tentacles.each { |t|
      next if t.state == :retracting
      t.retract if t.to.team == @team and t.to.life+t.to.tentacles_life > @life+tentacles_life+deploy_cost(t.to) and t.to.ennemies_tentacles.size == 0
      }

    # remove useless tentacles: from neutral when attacked
    if ennemies_tentacles.size > 0  and occupied_tentacles.size >= 0
      ennemies_tentacles.each { |t|
        return if not t.duel? and remove_neutral 
        }
    end

    # attack if attacked
    if ets > 0 and ots < @nb_t and ots == ats
      ennemies_tentacles.each { |t|
        return if enough_life?(t.from, :half) and add_tentacle(t.from)
        }
    end

    # attack neutral
    if ots < @nb_t
      n = nearest { |v| v.team == :neutral }
      return if n and enough_life?(n) and add_tentacle(n)
    end

    # attack nearest ennemy #with less life
    if ots < @nb_t
      e = nearest { |v| v.team != @team and v.team != :neutral and # and v.life+v.tentacles_life < (@life+tentacles_life-deploy_cost(v))-1}
        @life-deploy_cost(v)>1 }
      return if e and add_tentacle(e)
    end

    # recharge friends
    if ots < @nb_t
      e = nearest { |v| v.team == @team and v != self and not find_all(v) and v.life < (@life-deploy_cost(v))-1 }
      return if e and add_tentacle(e)
    end
    
  end

  def remove_neutral
    t = find_tentacle_if {|t| t.to.team == :neutral}
    if t
      t.retract
      return true
    end
    return false  
  end

  def deploy_cost(v)
    utils_distance(@x,@y, v.x,v.y)*LengthFactor
  end
  
  def enough_life?(v, length=:full)
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

  def tentacles_life
    occupied_tentacles.inject(0) { |sum, t| sum += t.life}
  end

  def destroy
    @ellipse.destroy
    @border.destroy
    @lifetext.destroy
    @nb_t_displays.each { |ellipse|
      ellipse.destroy
      }
  end

end

