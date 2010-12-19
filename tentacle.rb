require 'utils'

class Tentacle

  attr_reader :from, :to, :state, :length

  def initialize(canvas, from, to)
    @canvas, @from, @to = canvas, from, to
    @line =     Gnome::CanvasLine.new(@canvas.root,
      :fill_color => "#FF0000",
      :width_pixels => 4.0)
    @line.lower_to_bottom
    @line.raise(1)
    @state    = :created
    @length   = 0.0
    @distance = 0.0
    deploy(to)
  end

  def update
    #puts @state.to_s + ' ' + Time.now.to_s
    case @state
      when :deploying
        @length += 0.07
        if @length >= @distance
          @length = @distance
          @state  = :active
        end
        @from.remove_life(0.003)
        retract if @from.life <= 1
        update_line
      when :active
        # nothing
      when :retracting
        @length -= 0.07
        if @length <= 0
          @length  = 0
          hide
        end
        @from.add_life(0.003)
        update_line
      when :hidden
      when :created
        # nothing
      else
        raise "unknown state: #{state.to_s}"
    end
  end

  def update_line
    x = @from.x + (@to.x-@from.x)*(@length/@distance)
    y = @from.y + (@to.y-@from.y)*(@length/@distance)
    @line.points = [[@from.x, @from.y], [x, y]]
  end

  def hide
    @line.hide
    @state = :hidden
  end

  def deploy(to)
    @to       = to
    @distance = distance(@from.x, @from.y, to.x, to.y)
    @line.show
    @state    = :deploying
  end

  def retract
    @state = :retracting
  end

end

