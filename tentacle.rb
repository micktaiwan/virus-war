require 'utils'
require 'sucker'

class Tentacle

  attr_reader :from, :to, :state, :length, :distance, :sucker_nb, :retract_length, :send_length, :anim_pos
  # DEPLOYING = 'zipper.wav'

  def initialize(canvas, from, to)
    raise "tentacle initialize: from == to" if from == to
    @canvas, @from, @to = canvas, from, to
    @suckers = [] # a pool of suckers
    @sucker_nb = 0
    @state    = :created
    @length   = 0.0
    @distance = 0.0
    @anim_pos = 0.0
    deploy(to)
  end

  def factor
    return 1 if @nb==0
    1 + (@from.life/@nb)/25
  end

  def update(time)
    @time = time
    @nb = @from.active_tentacles.size
    @this_length = @time * GrowSpeed

    case @state
    when :deploying
      animate_deploy
      update_suckers
    when :active
      @anim_pos += @this_length*factor/2
      @anim_pos = 0.0 if @anim_pos > @sucker_nb*Sucker::Size
      if @to.team == @from.team
        @to.add_life(time*factor)
        retract if @from.life <= 1
      elsif @to.team != :neutral
        @to.remove_life(time*factor, @from.team)
      else # neutral
        @to.contaminate(time*factor, @from.team)
      end
      if duel?
        deploy_to_dist(@distance/2)
      elsif @length < @distance
        # if the duel just finished
        if @from.enough_life?(@to)
          @state = :deploying
        else
          retract
        end
      end
      update_suckers
    when :retracting
      @length -= @this_length*RetractFactor
      hide if @length <= 0
      @from.add_life(@this_length*RetractFactorxLengthFactor)
      #puts "Adding life: #{@this_length*RetractFactorxLengthFactor}, len=#{@length}, retracting" if @from.team == :green
      update_suckers
    when :cut
      if @retract_length > 0
        @retract_length -= @this_length*CutFactor
        @retract_length  = 0 if @retract_length <= 0
        @from.add_life(@this_length*CutFactorxLengthFactor)
        #puts "Adding life: #{@this_length*CutFactorxLengthFactor}, len=#{@length}, cutting r" if @from.team == :green
      end
      if @send_length > 0
        @send_length    -= @this_length*CutFactor
        @send_length     = 0 if @send_length <= 0
        if @to.team == @from.team
          @to.add_life(@this_length*CutFactorxLengthFactor)
          #puts "Adding life: #{@this_length*CutFactorxLengthFactor}, len=#{@length}, cutting s" if @from.team == :green
        elsif @to.team == :neutral
          @to.contaminate(@this_length*CutFactorxLengthFactor, @from.team)
        else # ennemy
          @to.remove_life(@this_length*CutFactorxLengthFactor, @from.team)
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

  def deploy(to)
    @@player.play(:deploying)
    @to       = to
    @distance = utils_distance(@from.x, @from.y, @to.x, @to.y)
    raise "deploy(to): @distance == 0" if @distance == 0
    set_color(Colors[(@from.team.to_s+"_deploy").to_sym])
    @state    = :deploying
    @to.receive_tentacle(self)
  end

  def duel?
    return(duel != nil)
  end

  def duel
    @to.find_all(@from)
  end

  def retract
    return if state == :retracting
    # first, give enough life to regain life
    if @from.life < 1 and @length*LengthFactor > 1-@from.life
      diff = 1-@from.life
      @length -= diff*LengthFactor
      @from.add_life(diff)
    end
    @to.detach_tentacle(self) if @state == :active
    set_color(Colors[(@from.team.to_s+"_deploy").to_sym])
    @state = :retracting
  end

  def change_team(team)
    #@from.remove_life(@length*LengthFactor, team)
    hide
    update_suckers
  end

#  def hide_all_suckers
#    @suckers.each { |s|
#      s.hide
#      }
#  end

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

  def redeploy
    @state    = :deploying
  end

  def life
    @length * LengthFactor
  end

private

  def hide
    @state  = :hidden
    @length = 0
  end

  def animate_deploy
    t = duel
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
    if @length > dist
      @length -= @this_length
      stop_deploy(dist) if @length <= dist
      @from.add_life(@this_length*LengthFactor)
      #puts "Adding life: #{@this_length*LengthFactor}, len=#{@length}, dist=#{dist}" if @from.team == :green
    else
      @length += @this_length
      stop_deploy(dist) if @length >= dist
      @from.remove_life(@this_length*LengthFactor, @from.team)
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

