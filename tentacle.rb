#require 'player'
require 'utils'

class Tentacle

  attr_reader :from, :to, :state, :length
  DEPLOYING = 'zipper.wav'

  def initialize(canvas, from, to)
    @canvas, @from, @to = canvas, from, to
    @line =     Gnome::CanvasLine.new(@canvas.root,
      :width_pixels => 4.0)
    @line.lower_to_bottom
    @line.raise(1)
    @state    = :created
    @length   = 0.0
    @distance = 0.0
    #@player = Player.new
    deploy(to)
  end

  def update
    #puts @state.to_s + ' ' + Time.now.to_s
    case @state
      when :deploying
        if @to.find_all(@from)
          dist = @distance/2
        else
          dist = @distance
        end
        @length += 0.07
        if @length >= dist
          @length = dist
          @state  = :active
        end
        @from.remove_life(0.003)
        retract if @from.life <= 1
        update_line
      when :active
        if @to.find_all(@from)
          @length = @distance/2
          update_line
        else
          if @length < @distance
            @state = :deploying
          end
        end
      when :retracting
        @length -= 0.14
        if @length <= 0
          @length  = 0
          hide
        end
        @from.add_life(0.006)
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
    @line.fill_color_rgba = Colors[@from.team]
    @state    = :deploying
    @to.receive_tentacle(self)
    #@player.play(DEPLOYING)
  end

  def retract
    return if state == :retracting
    @to.detach_ennemy_tentacle(self)
    @state = :retracting
  end

  def change_team(team)
    @line.fill_color_rgba = Colors[team]
    retract
  end

  def cut(point)
    return if @state == :retracting
    if @state == :deploying or @state == :active
      retract
    end
=begin
    Gnome::CanvasEllipse.new(@canvas.root, {
      :x1 => point.x-3,
      :x2 => point.x+3,
      :y1 => point.y-3,
      :y2 => point.y+3,
      :fill_color => "red"})
=end
  end

end

