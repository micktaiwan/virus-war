require 'gnomecanvas2'
require 'boards'
require 'virus'
require 'brain'
require 'utils'

class Board < Gtk::VBox

  attr_reader :virus
  attr_accessor :fps

  def read_board
    @virus = []
    Board1[:virus].each { |v|
      @virus << Virus.new(@canvas, v, self)
      }
  end

  #def draw(resize=false)
  #  return false if destroyed?
  #  #if resize
  #  #end
  #  false
  #end

  def get_virus(x,y, team)
    @rv   = nil
    @dist = 10000
    @virus.each { |v|
      d = distance(v.x, v.y, x, y)
      if d < 30 and d < @dist # and (team==:all or v.team == team)
        @rv = v
        @dist = d
      end
      }
     @rv
  end

  def initialize()
    super()
    @box = Gtk::EventBox.new
    pack_start(@box)
    set_border_width(@pad = 0)
    set_size_request((@width = 48)+(@pad*2), (@height = 48)+(@pad*2))
    @canvas = Gnome::Canvas.new(true)
    @box.add(@canvas)
    #@board_number = 1
    read_board()
    @fps = Gnome::CanvasText.new(@canvas.root, {
      :x => 20,
      :y => 5,
      :fill_color=>"white",
      :family=>"Arial",
      :markup => "FPS"})
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
        @selection.add_tentacle(end_v)
      elsif @cut.x
        cut(@cut.x, @cut.y, ev.x, ev.y)
      end
      @selection  = nil
      @cut.x      = nil
      @line.hide if @line
      false
    end

    #@box.signal_connect('expose_event') do |owner, ev|
    #  draw_board
    #end

    #signal_connect_after('show') {|w,e| start() }
    #signal_connect_after('hide') {|w,e| stop() }

    @canvas.show()
    @box.show()
    show()

  end

  def start
  	#@tid= Gtk::timeout_add(1000) { draw_board(); true }
  end

  def stop
	  Gtk::timeout_remove(@tid) if @tid
	  @tid = nil
  end

  def cut(a,b,x,y)
    @virus.each { |v|
      next if v.team != :green
      v.occupied_tentacles.each { |t|
        next if t.state == :retracting
        p = get_intersection(t, a,b,x,y)
        next if not p
        t.cut(p)
        }
      }
  end

  # thanks to http://alienryderflex.com/intersect/
  def get_intersection(t, cx, cy, dx, dy)
    ax = t.from.x
    ay = t.from.y
    bx = t.to.x
    by = t.to.y

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

