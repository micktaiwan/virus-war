require 'gnomecanvas2'
require 'boards'
require 'virus'
#require 'brain'
require 'wall'
require 'utils'


# TODO: teams force indicator


class Board < Gtk::VBox

  attr_reader :virus
  attr_accessor :level, :current_level


  def initialize()
    super()
    @virus          = []
    @walls          = []
    @current_level  = 1
    @box = Gtk::EventBox.new
    pack_start(@box)
    set_border_width(@pad = 0)
    set_size_request((@width = 48)+(@pad*2), (@height = 48)+(@pad*2))
    @canvas = Gnome::Canvas.new(true)
    @box.add(@canvas)
    @level = Gnome::CanvasText.new(@canvas.root, {
      :x => 20,
      :y => 10,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => "level"})
    @force = Gnome::CanvasText.new(@canvas.root, {
      :x => 100,
      :y => 10,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => "Force"})
    @line = Gnome::CanvasLine.new(@canvas.root,
      :width_pixels => 2.0)
    @line.hide
    @cut = Point.new

    @box.signal_connect('size-allocate') { |w,e,*b|
      @width, @height = [e.width,e.height].collect{|i|i - (@pad*2)}
      @canvas.set_size(@width,@height)
      @canvas.set_scroll_region(0,0,@width,@height)
      @bg = Gnome::CanvasRect.new(@canvas.root, {
        :x1 => 0,
        :y1 => 0,
        :x2 => @width,
        :y2 => @height,
        :fill_color_rgba => 0x333333FF})
      @bg.lower_to_bottom
      false
      }

    @box.signal_connect('button-press-event') do |owner, ev|
      @selection = get_virus(ev.x,ev.y, :green)
      @line.points = [[ev.x, ev.y], [ev.x, ev.y]]
      if @selection
        @line.fill_color = "#FFFFFF"
      else
        @cut.x, @cut.y = ev.x, ev.y
        @line.fill_color = "#FF0000"
      end
      false
    end

    @box.signal_connect('motion_notify_event') do |item,  event|
      if @selection
        @line.show
        @line.points = [[@selection.x, @selection.y], [event.x, event.y]]
      elsif @cut.x
        @line.show
        @line.points = [[@cut.x, @cut.y], [event.x, event.y]]
      end
      false
    end

    @box.signal_connect('button-release-event') do |owner, ev|
      end_v = get_virus(ev.x,ev.y, :all)
      if @selection and end_v
        #if not @selection.enough_life?(end_v)
        #  @@player.play(:not_enough_life)
        #else
          if end_v == @selection
            @@player.play(:error)
          else
            @selection.add_tentacle(end_v)
          end
        #end 
      elsif @cut.x
        cut(@cut.x, @cut.y, ev.x, ev.y)
      end
      @selection  = nil
      @cut.x      = nil
      @line.hide if @line
      false
    end

    signal_connect_after('show') {|w,e| start() }
    signal_connect_after('hide') {|w,e| stop() }

    @canvas.show()
    @box.show()
    show()
    load_level()
    @time = Time.now
  end
  
  def iterate
    update_virus
    play_ennemies
    sleep(0.01)
  end
  
  def load_level
    clear_game
    Boards[@current_level][:virus].each { |v|
      @virus << Virus.new(@canvas, v, self)
      } if Boards[@current_level][:virus]

    Boards[@current_level][:walls].each { |v|
      @walls << Wall.new(@canvas, v, self)
      } if Boards[@current_level][:walls]
  end

  def clear_game
    @virus.each { |v|
      v.tentacles.each { |t|
        t.destroy
        }
      v.destroy
      }
    @virus.clear
    @walls.each { |w|
      w.destroy
      }
    @walls.clear
  end

  def get_virus(x,y, team)
    @rv   = nil
    @dist = 10000
    @virus.each { |v|
      d = utils_distance(v.x, v.y, x, y)
      if d < 30 and d < @dist and (team==:all or v.team == team)
        @rv = v
        @dist = d
      end
      }
     @rv
  end

  def start
    @@player.play(:start)
  	@started = true
  end

  def stop
  	@started = false
  end

  def cut(a,b,x,y)
    @virus.each { |v|
      next if v.team != :green
      v.occupied_tentacles.each { |t|
        next if t.state == :retracting
        p = get_intersection(t.from.x,t.from.y, t.to.x,t.to.y, a,b, x,y)
        next if not p
        t.cut(p)
        }
      }
  end

  def check_walls(x1,y1, x2,y2)
    @walls.each { |w| return true if get_intersection(w.x1,w.y1, w.x2,w.y2, x1,y1, x2,y2) }
    return false
  end
  
  def update_virus
    time = Time.now - @time
    total, mine = 0, 0
    @virus.each{ |v|
      v.update(time)
      total += v.life + v.tentacles_life if v.team != :neutral
      mine  += v.life + v.tentacles_life if v.team == :green
      }
    @force.markup = (mine*100/total).to_i.to_s + "%"
    @time = Time.now
  end

  def play_ennemies
    @virus.each { |v|
      next if v.team == :neutral or v.team == :green
      #next if rand(1000) != 0
      v.play
      }
  end

  # thanks to http://alienryderflex.com/intersect/
  def get_intersection(ax,ay, bx,by, cx,cy, dx,dy)

    #  Fail if either line segment is zero-length.
    return nil if ((ax==bx and ay==by) or (cx==dx and cy==dy))

    #  Fail if the segments share an end-point.
    return nil if (ax==cx and ay==cy or bx==cx and by==cy or  ax==dx and ay==dy or bx==dx and by==dy)

    #  (1) Translate the system so that point A is on the origin.
    bx -= ax; by -= ay
    cx -= ax; cy -= ay
    dx -= ax; dy -= ay

    #  Discover the length of segment A-B.
    distAB = Math.sqrt(bx*bx + by*by)

    #  (2) Rotate the system so that point B is on the positive X axis.
    theCos  = bx/distAB
    theSin  = by/distAB
    newX    = cx*theCos+cy*theSin
    cy      = cy*theCos-cx*theSin
    cx      = newX
    newX    = dx*theCos+dy*theSin
    dy      = dy*theCos-dx*theSin
    dx      = newX

    #  Fail if segment C-D doesn't cross line A-B.
    return nil if (cy<0 and dy<0) or (cy>=0 and dy>=0)

    #  (3) Discover the position of the intersection point along line A-B.
    abpos = dx + (cx-dx)*dy/(dy-cy)

    #  Fail if segment C-D crosses line A-B outside of segment A-B.
    return nil if (abpos < 0 or abpos > distAB)

    #  (4) Apply the discovered position to line A-B in the original coordinate system.
    x = ax + abpos*theCos
    y = ay + abpos*theSin

    #  Success
    return Point.new(x,y)
  end

end

