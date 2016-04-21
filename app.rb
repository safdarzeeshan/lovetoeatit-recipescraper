# myapp.rb
require 'sinatra'
require 'open-uri'
require 'hangry'
require 'json'
require 'ingreedy'
require 'sinatra/cross_origin'

configure do
  enable :cross_origin
end

get '/' do

    recipe_url = params['url']
    recipe_html_string = open(recipe_url).read
    puts 'recipe url read'
    recipe = Hangry.parse(recipe_html_string)

    puts recipe.canonical_url
    # puts recipe.to_h.to_json.fetch('author')


    # url give no information

    # if recipe.canonical_url == nil
    #     puts 'recipe url cannot be parsed'
    #     content_type :json
    #     { :recipe_url => recipe_url, :error => 'no information available'}.to_json

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
                # {ingedient_n.push(}:name => i)
                ingedient_list.push({:ingredient => {:name => i}, :amount => '' })
                next
            end

            ingedient_list.push({:ingredient => {:name => ingredient.ingredient}, :amount => to_frac(ingredient.amount.to_s).to_s + ' ' + ingredient.unit.to_s})
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
