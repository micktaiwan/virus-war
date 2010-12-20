Colors = {
  :red      => 0xAA3333FF,
  :green    => 0x33AA33FF,
  :black    => 0x000000FF,
  :neutral  => 0x999999FF
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


def distance(a,b,x,y)
  Math.sqrt( (((x-a)**2) + ((y-b)**2)).abs )
end

