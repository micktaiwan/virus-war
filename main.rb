#!/usr/bin/env ruby
require 'board'

class Viewer < Gtk::Window
  def initialize(board)
    super()
    set_title("Virus Wars")
    signal_connect("delete_event") { |i,a| board.destroy }
    set_default_size(400,400)
    add(board)
    show()
  end
end

Gtk.init()

board = Board.new
view = Viewer.new(board)
view.show
brain = Brain.new(board.virus)

loop {
  t =Time.now
  brain.iterate
  #board.draw
  while (Gtk.events_pending?)
    Gtk.main_iteration
  end
  break if board.destroyed?
  board.fps.markup = ((Time.now - t)*10000).to_i.to_s
  }

