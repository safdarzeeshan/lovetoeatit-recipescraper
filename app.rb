# myapp.rb

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'open-uri'
require 'hangry'
require 'json'
require 'ingreedy'
require 'sinatra/cross_origin'
require 'nokogiri'
require 'fastimage'


configure do
  enable :cross_origin
end

get '/' do

    recipe_url = params['url']
    recipe_html_string = open(recipe_url).read
    puts 'recipe url read'
    recipe = Hangry.parse(recipe_html_string)

    #error if recipe blog url cannot be parsed
    if recipe.canonical_url == nil

        puts 'recipe url cannot be parsed'
        status 400
        content_type :json
        { :recipe_url => recipe_url, :error => 'Unable to get recipe information form this URL.'}.to_json

    # recipe blog can be parsed
    else

        ingedient_list = Array.new

        for i in recipe.ingredients
            # ingedient_n = Array.new
            begin
            ingredient = Ingreedy.parse(i)
            rescue
                puts 'error ' + i.to_s + ' cannot be parsed'
                ingedient_list.push({:ingredient => {:name => i}, :amount => '' })
                next
            end

            ingedient_list.push({:ingredient => {:name => ingredient.ingredient}, :amount => to_frac(ingredient.amount.to_s).to_s + ' ' + ingredient.unit.to_s})
        end

        # check recipe image_url resolution
        if recipe.image_url != nil
            puts recipe.image_url
            image_size =  FastImage.size(recipe.image_url, :http_header => {'User-Agent' => 'Fake Browser'})
            puts image_size
            if (image_size[0] < 400) || (image_size[1] < 400)
                recipe.image_url = get_new_image(recipe_url)
            end

        elsif recipe.image_url == nil
            recipe.image_url = get_new_image(recipe_url)
        end

        content_type :json
        { :url => recipe.canonical_url, :name => recipe.name, :time => recipe.cook_time, :snippet => recipe.description, :image_url => recipe.image_url, :serving_size => recipe.yield, :ingredients => ingedient_list}.to_json

    end
end

def to_frac(value)
    numerator, denominator = value.split('/').map(&:to_f)

    if denominator !=1
        return value
    end

    if denominator ==1
        return numerator.to_i
    end

end

def get_new_image (recipe_url)
    page = Nokogiri::HTML(open(recipe_url))
    image_urls = page.search('img').map{ |img| img['src'] }

    puts 'get new image'
    puts image_urls

    for image_url in image_urls

        puts image_url

        begin
            #check resolution
            image_type = FastImage.type(image_url)
            image_size =  FastImage.size(image_url, :http_header => {'User-Agent' => 'Fake Browser'})
            if (image_type != 'gif') && (image_size[0] > 400) && (image_size[1] > 400)
                return image_url
            end
        rescue
            puts 'error'
            next
        end
    end

    return nil
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept,  x-csrftoken, authorization"
  200
end

