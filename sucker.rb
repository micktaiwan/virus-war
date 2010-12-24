require 'utils'

# A sucker is a tentacle part
class Sucker

  Size      = 12
  Sizeby2   = Size/2
  SinSize   = 1
  SinSpeed  = 4

  def initialize(canvas, tentacle, pos)
    @canvas, @tentacle, @pos = canvas, tentacle, pos
    @color = Colors[(@tentacle.from.team.to_s+"_deploy").to_sym]
    @ellipse = Gnome::CanvasEllipse.new(@canvas.root, {
      :fill_color_rgba => @color})
    @ellipse.lower_to_bottom
    @ellipse.raise(1)
    update
  end

  def update
    # TODO: calculate fixed @x once for all when tentacle is deployed
    @x = @tentacle.from.x + (@tentacle.to.x-@tentacle.from.x)*(@pos*Size / @tentacle.distance)
    @y = @tentacle.from.y + (@tentacle.to.y-@tentacle.from.y)*(@pos*Size / @tentacle.distance)

    # see if cut and if it needs to be hidden
    if @tentacle.state == :cut
      # see if sucker pos is out of two lines
      if (utils_distance(@x, @y, @tentacle.from.x, @tentacle.from.y) > @tentacle.retract_length and utils_distance(@x, @y, @tentacle.to.x, @tentacle.to.y) > @tentacle.send_length)
        @ellipse.hide
      else
        @ellipse.show
        update_pos
      end
    else
      if(utils_distance(@x, @y, @tentacle.from.x, @tentacle.from.y) > @tentacle.length)
        @ellipse.hide
      else
        @ellipse.show
        update_pos
      end
    end   

  end

  def set_color(c)
    return if @ellipse.destroyed?
    @color = c
    @ellipse.fill_color_rgba = c
  end

  def hide
    return if @ellipse.destroyed?
    @ellipse.hide
  end

  def destroy
    return if @ellipse.destroyed?
    @ellipse.destroy
  end
  
private
 
  def update_pos
    t = (Time.now.to_f)*SinSpeed
    @ellipse.x1 = @x-Sizeby2 + Math.cos(t+@pos)*SinSize
    @ellipse.x2 = @x+Sizeby2 + Math.cos(t+@pos)*SinSize
    @ellipse.y1 = @y-Sizeby2 + Math.sin(t+@pos)*SinSize
    @ellipse.y2 = @y+Sizeby2 + Math.sin(t+@pos)*SinSize
    if (@pos*Size - @tentacle.anim_pos).abs < Sizeby2
       @ellipse.fill_color_rgba = 0xDDDD00FF 
    else
      @ellipse.fill_color_rgba = @color
    end
  end

end

