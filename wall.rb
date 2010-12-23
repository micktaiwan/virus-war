class Wall

  attr_accessor :x1, :y1, :x2, :y2
  attr_reader :line

  def initialize(canvas, h, board)
    @board = board
    @canvas = canvas
    @x1, @y1, @x2, @y2 = h[0],h[1],h[2],h[3]
    @line =     Gnome::CanvasLine.new(@canvas.root,
      :points => [[@x1, @y1], [@x2, @y2]],
      :fill_color => "black",
      :width_pixels => 4.0)
    @line.lower_to_bottom
    @line.raise(1)
  end

  def destroy
    @line.destroy
  end

end

