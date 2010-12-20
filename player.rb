#!/usr/bin/ruby -w

# ================================
# sudo apt-get install libsdl1.2-dev
# sudo apt-get install libsdl-mixer1.2-dev
# sudo gem install rubysdl
# ================================

require 'rubygems'
require 'sdl'

class Player

  def initialize
    SDL::init(SDL::INIT_AUDIO)
    SDL::Mixer.open(22050*2,SDL::Mixer::FORMAT_U8,2,1024)
    SDL::Mixer.set_volume_music(255)
  end

  def play(file)
    puts 'play'
    loops     = 1
    filename  = "sounds/"+file
    @music     = SDL::Mixer::Music.load(filename)
    SDL::Mixer.play_music(@music,loops)
    puts 'ok'
  end

  def quit
    SDL::quit
  end

end

# Player.new.play('bad.wav')

