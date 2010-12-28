#!/usr/bin/env ruby

# sudo apt-get install ruby-gnome2
# See Sounds instructions in player.rb

# Search todos: grep -r TODO *
# TODO: level selector

if not ARGV[0]
  puts 'puts your name after "main.rb", like "main.rb MickTaiwan"'
  exit
end

require 'board'
require 'utils'
require 'player'
require 'game'

@@player = Player.new(SOUNDS)

Gtk.init()
game  = Game.new
board = Board.new
view  = Viewer.new(board)
view.show
board.level.markup = (board.current_level+1).to_s
loop {
  board.iterate

  # end game
  if board.virus.select{ |v| v.team != :green and v.team != :neutral}.size == 0
    pos, scores = game.save_score(board.current_level+1, board.get_score)
    puts "===== LEVEL #{board.current_level+1} ======================"
    puts "you scored #{board.get_score}, you are ##{pos}"
    scores.each_with_index { |arr, i|
      puts "#{i+1}) #{arr[0]}: #{arr[1]}"
      }
    sleep(1)
    board.start_next_level
  elsif board.virus.select{ |v| v.team == :green}.size == 0
    @@player.play(:lost)
    sleep(3)
    board.load_level
  end

  break if board.destroyed?
  }

@@player.quit
#Gtk.main_quit

