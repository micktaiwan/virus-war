require 'utils'
require 'sucker'

class Tentacle

  attr_reader :from, :to, :state, :length, :distance, :sucker_nb, :retract_length, :send_length
  # DEPLOYING = 'zipper.wav'

  def initialize(canvas, from, to)
    raise "tentacle initialize: from == to" if from == to
    @canvas, @from, @to = canvas, from, to
    @suckers = [] # a pool of suckers
    @sucker_nb = 0
    @state    = :created
    @length   = 0.0
    @distance = 0.0
    deploy(to)
  end

  def update(time)
    @time = time
    this_length = @time * GrowSpeed
    #puts @state.to_s + ' ' + Time.now.to_s
    case @state
      when :deploying
        animate_deploy
        update_suckers
      when :active
        if @to.find_all(@from)
          deploy_to_dist(@distance/2)
        else
          @state = :deploying if @length < @distance
        end
        update_suckers
      when :retracting
        @length -= this_length*RetractFactor
        if @length <= 0
          @length  = 0
          hide
        end
        @from.add_life(this_length*RetractFactorxLengthFactor)
        update_suckers
      when :cut
        if @retract_length > 0
          @retract_length -= this_length*CutFactor 
          @retract_length  = 0 if @retract_length <= 0
          @from.add_life(this_length*CutFactorxLengthFactor)
        end
        if @send_length > 0
          @send_length    -= this_length*CutFactor  
          @send_length     = 0 if @send_length <= 0
          if @to.team == @from.team
            @to.add_life(this_length*CutFactorxLengthFactor)
          elsif @to.team == :neutral
            @to.contaminate(this_length*CutFactorxLengthFactor, @from.team)
          else # ennemy
            @to.remove_life(this_length*CutFactorxLengthFactor, @from.team)
          end       
        end
        update_suckers
        hide if @retract_length == 0 and @send_length == 0
      when :hidden
      when :created
        # nothing
      else
        raise "unknown state: #{state.to_s}"
    end
  end

  def update_suckers
    update_sucker_pool
    @suckers.each { |s| s.update }
    #(0..@sucker_nb-1).each { |i| @suckers[i].update } if @sucker_nb > 0
    #@suckers[@sucker_nb-1].update if @sucker_nb > 0
  end

  def update_sucker_pool
    @sucker_nb = (@length / Sucker::Size).to_i
    while @suckers.size < @sucker_nb
      @suckers << Sucker.new(@canvas, self, @suckers.size+1)
    end
#    if @suckers.size > @sucker_nb
#      (@sucker_nb..@suckers.size-1).each { |i| @suckers[i].hide }
#    end
  end

  def hide
    #@line.hide
    @state = :hidden
    @length = 0
  end

  def deploy(to)
    @@player.play(:deploying)
    @to       = to
    @distance = utils_distance(@from.x, @from.y, @to.x, @to.y)
    raise "deploy(to): @distance == 0" if @distance == 0 
    set_color(Colors[(@from.team.to_s+"deploy").to_sym])
    @state    = :deploying
    @to.receive_tentacle(self)
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
    set_color(Colors[(@from.team.to_s+"deploy").to_sym])
    @state = :retracting
  end

  def change_team(team)
    retract
  end

  def hide_all_suckers
    @suckers.each { |s|
      s.hide
      }
  end

  #def quick_retract
  #  @state = :hidden
  #  @length = 0
  #  update_suckers
  #end

  def cut(point)
    return if @state == :retracting
    d = duel
    if @state == :deploying or d
      retract
      d.redeploy if d
    end
    return if @state != :active

    @@player.play(:cut)
    @retract_length = utils_distance(@from.x, @from.y, point.x, point.y)
    @send_length    = utils_distance(@to.x, @to.y, point.x, point.y)
    @state          = :cut
  end

  def destroy
    @suckers.each { |s|
      s.destroy
      }
  end

private

  def animate_deploy
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
    deploy_to_dist(dist)
  end

  def deploy_to_dist(dist)
    return if @length == dist
    #@state = :deploying
    #set_color(Colors[(@from.team.to_s+"deploy").to_sym])
    this_length = @time * GrowSpeed
    if @length > dist
      @length -= this_length
      stop_deploy(dist) if @length <= dist
      @from.add_life(this_length*LengthFactor)
    else
      @length += this_length
      stop_deploy(dist) if @length >= dist
      @from.remove_life(this_length*LengthFactor, @from.team)
      retract if @from.life <= 1
    end
  end

  def stop_deploy(dist)
    @@player.play(:active)
    @length = dist
    @state  = :active
    set_color(Colors[@from.team])
  end

  def set_color(c)
    @suckers.each { |s|
      s.set_color(c)
      }
  end

end

