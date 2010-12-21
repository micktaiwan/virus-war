Colors = {
  :red      => 0xAA3333FF,
  :green    => 0x33AA33FF,
  :black    => 0x000000FF,
  :reddeploy      => 0xFF8888FF,
  :greendeploy    => 0x88FF88FF,
  :blackdeploy    => 0x555555FF,
  :neutral  => 0x999999FF
  }

GrowSpeed = 200
LengthFactor = 1.0/15
GrowSpeedxLengthFactor = GrowSpeed*LengthFactor

SOUNDS = {
  :deploying => 'deploying.wav',
  :active => 'charge.wav',
  :start => 'bulles.wav',
  :cut => 'throw.wav',
  :change => 'axe_throw.wav',
  :lost => 'lost.wav'
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
  Math.sqrt( (((x-a)**2) + ((y-b)**2)).abs )
end

