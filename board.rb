require 'gnomecanvas2'
require 'boards'
require 'virus'
require 'brain'
require 'utils'

class Board < Gtk::VBox

  attr_reader :virus

  def read_board
    @virus = []
    Board1[:virus].each { |v|
      @virus << Virus.new(@canvas, v)
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
      false
    end

    @box.signal_connect('motion_notify_event') do |item,  event|
      if @selection
        @line = Gnome::CanvasLine.new(@canvas.root,
          :fill_color => "#FFFFFF",
          :width_pixels => 2.0) if not @line
        @line.raise_to_top
        @line.points = [[@selection.x, @selection.y], [event.x, event.y]]
        #@box.queue_draw
      end
      false
    end

    @box.signal_connect('button-release-event') do |owner, ev|
      end_v = get_virus(ev.x,ev.y, :all)
      if @selection and end_v
        @selection.add_tentacle(end_v)
      end
      @selection = nil
      @line.lower_to_bottom
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

end



