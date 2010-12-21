#!/usr/bin/ruby -w

# ================================
# sudo apt-get install libsdl1.2-dev
# sudo apt-get install libsdl-mixer1.2-dev
# sudo gem install rubysdl
# ================================

require 'rubygems'
require 'sdl'

class Player

  def initialize(sounds)
    SDL::init(SDL::INIT_AUDIO)
    SDL::Mixer.open(22050,SDL::Mixer::FORMAT_S16,2,4096)
    SDL::Mixer.set_volume_music(255)
    @sounds = Hash.new
    sounds.each_pair { |id, file|
      print "loading #{id}... "
      @sounds[id] = SDL::Mixer::Wave.load("sounds/"+file)
      puts 'ok'
      }
  end

  def play(id)
    SDL::Mixer.play_channel(-1,@sounds[id],0)
  end

  def quit
    SDL::quit
  end

end

#Player.new.play('axe_throw.wav')

