require 'RMagick'
require 'httparty'
require 'json'

class SteamcollageController < ApplicationController
  include Magick

  def index
  end

  def generate
    steam_url_base = "http://steamcommunity.com/id/"
    steam_url_games = "/games?tab=all"
    opts = Hash.new(0)
    opts[:download] = true
    steam_url = steam_url_base + params[:steamid] + steam_url_games

    response = HTTParty.get(steam_url)

    json_games = nil

    games_list = response.body.split('\n')
    games_list.each do |line|
      if line=~/var rgGames = (.*);/
        json_games = line.match(/var rgGames = (.*);/).captures[0]
      end
    end

    gamehash = JSON.parse(json_games)

    image = Magick::ImageList.new
    images_skipped, images_cached, images_downloaded = [0, 0, 0]
  
    gamehash.each do |game|
      if opts[:download]
        if File.exists?("images/#{File.basename(game["logo"])}")
          # puts " -- [S] #{game["name"]} - #{File.basename(game["logo"])} exists, skipping."
          images_cached = images_cached + 1
        else
          #puts " -- [D] #{game["name"]} - #{File.basename(game["logo"])}"
          if opts[:download]

            File.open("images/#{File.basename(game["logo"])}", "wb") do |f| 
              f.write HTTParty.get(game["logo"]).parsed_response
            end
            images_downloaded = images_downloaded + 1
          end
        end
      else
        # puts "-- [S] #{game["name"]} - #{File.basename(game["logo"])} --no-download"
        images_skipped = images_skipped + 1
      end
      if opts[:download]
        image.read("images/#{File.basename(game['logo'])}")
      end
    end

    rows = gamehash.count / 7
    rows = rows.to_i
    rows = rows + 1

    coimage = image.montage {
      self.background_color = "black"
      self.border_width = 0
      self.tile = Magick::Geometry.new(7,rows)
      self.geometry = '184x69+0+0'
    }

    coimage.write("assets/#{params[:steamid]}.jpg")
    send_file "assets/#{params[:steamid]}.jpg", :type => 'image/jpeg', :disposition => 'inline'
  end
end
