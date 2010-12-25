Colors = {
  :red            => 0xAA3333FF,
  :green          => 0x33AA33FF,
  :black          => 0x111111FF,
  :dark_red       => 0x770000FF,
  :dark_green     => 0x007700FF,
  :dark_black     => 0x000000FF,
  :dark_neutral   => 0x444444FF,
  :red_deploy      => 0xFF8888FF,
  :green_deploy    => 0x88AA88FF,
  :black_deploy    => 0x555555FF,
  :red_contaminate      => 0xAA8888FF,
  :green_contaminate    => 0x88AA88FF,
  :black_contaminate    => 0x555555FF,
  :neutral        => 0x999999FF
  }

GrowSpeed     = 200
LengthFactor  = 1.0/15
RetractFactor = 3
CutFactor     = 6
TimeFactor    = 0.5
RetractFactorxLengthFactor  = RetractFactor * LengthFactor
CutFactorxLengthFactor      = CutFactor * LengthFactor
GrowSpeedxLengthFactor      = GrowSpeed * LengthFactor

SOUNDS = {
  :deploying  => 'deploying.wav',
  :active     => 'charge.wav',
  :start      => 'bulles.wav',
  :cut        => 'throw.wav',
  :change     => 'axe_throw.wav',
  :lost       => 'lost.wav',
  :not_enough_life => 'error.wav',
  :error      => 'error.wav'
  }

class Point

  attr_accessor :x, :y

  def initialize(x=0,y=0)
    @x, @y = x, y
  end
  def to_p
   [x,y]
  end
  def -(p)
    [x-p.x, y-p.y]
  end
end

def utils_distance(a,b,x,y)
    Math.sqrt( (((x-a)*(x-a)) + ((y-b)*(y-b))).abs )
end

