require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end


get '/actors' do

      @actors = db_connection do |conn|
        conn.exec("SELECT id,name FROM actors LIMIT 100")
      end

      erb :actors

end



get '/movies' do

      @movies = db_connection do |conn|
        conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating ,studios.name AS studio, genres.name AS genre FROM movies JOIN studios ON movies.studio_id = studios.id JOIN genres ON movies.genre_id = genres.id")
      end

      @movies_sort = @movies.sort_by { |k| k["title"] }

      erb :movies

end


get '/actors/:id' do

      @details_id = params[:id]

      from_db = db_connection do |conn|
        conn.exec_params("SELECT name FROM actors WHERE ($1) = id", [@details_id])
      end

      from_db.each do |actor|
        @details_name = actor["name"]
      end

      @actor_movies = db_connection do |conn|
        conn.exec_params("SELECT movies.id AS idmovie, movies.title, cast_members.character FROM movies JOIN cast_members ON cast_members.movie_id = movies.id WHERE ($1) = cast_members.actor_id", [@details_id])
      end

      erb :actor_details

end

# Visiting /movies/:id will show the details for the movie.
# This page should contain information about the movie (including genre and studio) as well as a list of all of the actors and their roles.
# Each actor name is a link to the details page for that actor.

get '/movies/:id' do

      @details_id = params[:id]

      from_db = db_connection do |conn|
        conn.exec_params("SELECT title FROM movies WHERE ($1) = id", [@details_id])
      end

      from_db.each do |movie|
        @details_title= movie["title"]
      end

      @movie_details = db_connection do |conn|
        conn.exec_params("SELECT actors.id, genres.name AS genre, studios.name AS studio, actors.name AS actor, cast_members.character FROM movies JOIN genres ON movies.genre_id = genres.id JOIN studios ON movies.studio_id = studios.id JOIN cast_members ON cast_members.movie_id = movies.id JOIN actors ON cast_members.actor_id = actors.id WHERE ($1) = movies.id", [@details_id])
      end

      erb :movie_details

end
