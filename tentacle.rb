#require 'player'
require 'utils'

class Tentacle

  attr_reader :from, :to, :state, :length, :line
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
        t = @to.find_all(@from)
        if t
          if t.length > @distance / 2
            dist = @distance/2
          else
            dist = @distance - t.length
          end
        else
          dist = @distance
        end
        @length += GrowSpeed
        if @length >= dist
          @length = dist
          @state  = :active
          @line.fill_color_rgba = Colors[@from.team]
        end
        @from.remove_life(GrowSpeed*LengthFactor)
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
        @length -= GrowSpeed * 3
        if @length <= 0
          @length  = 0
          hide
        end
        @from.add_life((GrowSpeed*3)*LengthFactor)
        update_line
      when :cutted

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
    @line.fill_color_rgba = Colors[:grey]
    @state    = :deploying
    @to.receive_tentacle(self)
    #@player.play(DEPLOYING)
  end

  def redeploy
    @state    = :deploying
  end

  def duel?
    return(duel != nil)
  end

  def duel
    @to.find(@from)
  end

  def retract
    return if state == :retracting
    @to.detach_ennemy_tentacle(self)
    @line.fill_color_rgba = Colors[:grey]
    @state = :retracting
  end

  def change_team(team)
    @line.fill_color_rgba = Colors[team]
    retract
  end

  def quick_retract
    @state = :hidden
    @line.hide
  end

  def cut(point)
    return if @state == :retracting
    d = duel
    if @state == :deploying or d
      retract
      d.redeploy if d
    end

    if @state == :active
      quick_retract
      retract_length = distance(@from.x, @from.y, point.x, point.y)
      send_length    = distance(@to.x, @to.y, point.x, point.y)

      puts "r: #{retract_length}, s: #{send_length}, d: #{distance(@to.x, @to.y, @from.x, @from.y)}"

      @from.add_life(retract_length*LengthFactor)
      if @to.team == @from.team
        @to.add_life(send_length*LengthFactor)
      elsif @to.team == :neutral
        @to.contaminate(send_length*LengthFactor, @from.team)
      else
        @to.remove_life(send_length*LengthFactor)
      end
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

