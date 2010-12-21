# tentacle part

require 'utils'

class Sucker

  Size      = 10
  Sizeby2   = Size/2
  Deviation = 1
  SinSpeed  = 4

  def initialize(canvas, tentacle, pos)
    @canvas, @tentacle, @pos = canvas, tentacle, pos
    @x, @y = 0, 0
    @ellipse = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => Colors[@tentacle.from.team]})
    @ellipse.lower_to_bottom
    @ellipse.raise(1)
    update
  end

  def update
    @ellipse.show
    line = [@tentacle.from.x, @tentacle.from.y, @tentacle.to.x, @tentacle.to.y]
    @x = @tentacle.from.x + (@tentacle.to.x-@tentacle.from.x)*(@pos*Size / @tentacle.distance)
    @y = @tentacle.from.y + (@tentacle.to.y-@tentacle.from.y)*(@pos*Size / @tentacle.distance)
    t = (Time.now.to_f)*SinSpeed
    @ellipse.x1 = @x-Sizeby2+Math.cos(t+@pos)*Deviation
    @ellipse.x2 = @x+Sizeby2+Math.cos(t+@pos)*Deviation
    @ellipse.y1 = @y-Sizeby2+Math.sin(t+@pos)*Deviation
    @ellipse.y2 = @y+Sizeby2+Math.sin(t+@pos)*Deviation
  end

  def set_color(c)
    @ellipse.fill_color_rgba = c
  end

  def hide
    @ellipse.hide
  end

  def destroy
    @ellipse.destroy
  end

end

