# canvas button
class Button

  def initialize(file, canvas, x, y)
    @x, @y    = x, y
    pixbuf    = Gdk::Pixbuf.new(file)
    image     = Gtk::Image.new(pixbuf)
    event_box = Gtk::EventBox.new.add(image)
    event_box.set_visible_window(@canvas)
    if block_given?
      event_box.signal_connect("button_press_event") do
        yield
      end
    end
    canvas.put(event_box, @x, @y)
  end

end

