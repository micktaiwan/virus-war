#!/usr/bin/env ruby

# sudo apt-get install ruby-gnome2
# See Sounds instructions in player.rb

# Search todos: grep -r TODO *
# TODO: level selector

require 'board'
require 'utils'
require 'player'

@@player = Player.new(SOUNDS)

class Viewer < Gtk::Window
  def initialize(board)
    super()
    set_title("Virus Wars")
    signal_connect("delete_event") { |i,a| board.destroy }
    set_default_size(600,600)
    add(board)
    show()
  end
end


Gtk.init()
board = Board.new
view = Viewer.new(board)
view.show
board.level.markup = (board.current_level+1).to_s
loop {
  #t =Time.now
  board.iterate

  # end game
  if board.virus.select{ |v| v.team != :green and v.team != :neutral}.size == 0
    while (Gtk.events_pending?)
      Gtk.main_iteration
    end
    sleep(1)
    board.start_next_level
  elsif board.virus.select{ |v| v.team == :green}.size == 0
    @@player.play(:lost)
    while (Gtk.events_pending?)
      Gtk.main_iteration
    end
    sleep(3)
    board.level.markup = (board.current_level+1).to_s
    board.load_level
  end

  #board.draw
  while (Gtk.events_pending?)
    Gtk.main_iteration
  end
  break if board.destroyed?
  #board.level.markup = ((Time.now - t)*10000).to_i.to_s
  }


@@player.quit
#Gtk.main_quit

