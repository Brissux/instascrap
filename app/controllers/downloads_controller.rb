require 'net/http'
require 'json'
require 'open-uri'
require 'zip'

class DownloadsController < ApplicationController
  def index
  end

  def download
    username = params[:username]

    if username.present?
      # Construire l'URL pour l'API
      url = URI("https://instagram-scraper-2022.p.rapidapi.com/ig/posts_username/?user=#{username}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["x-rapidapi-key"] = ENV['RAPIDAPI_KEY']
      request["x-rapidapi-host"] = 'instagram-scraper-2022.p.rapidapi.com'

      response = http.request(request)
      json_data = JSON.parse(response.body)

      images = extract_images(json_data)

      if images.any?
        zip_file_path = create_zip_file(images, username)

        send_file zip_file_path, type: 'application/zip', disposition: 'attachment'
      else
        redirect_to root_path, alert: "Aucune image trouvée pour l'utilisateur #{username}."
      end
    else
      redirect_to root_path, alert: "Veuillez entrer un nom d'utilisateur."
    end
  end

  private

  def extract_images(json_data)
    images = []
    edges = json_data.dig('data', 'xdt_api__v1__feed__user_timeline_graphql_connection', 'edges') || []

    edges.each do |edge|
      node = edge['node']

      if node['carousel_media_count'].nil?
        url = node.dig('image_versions2', 'candidates', 0, 'url')
        images << url if url
      else
        node['carousel_media'].each do |carousel_item|
          url = carousel_item.dig('image_versions2', 'candidates', 0, 'url')
          images << url if url
        end
      end
    end

    images
  end

  def create_zip_file(images, username)
    # Créer un fichier ZIP en mémoire
    zip_file_path = Rails.root.join('tmp', "#{username}_images.zip")

    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      images.each_with_index do |url, index|
        filename = "#{username}_image_#{index}.jpg"
        downloaded_image = URI.open(url).read

        zipfile.get_output_stream(filename) { |f| f.write(downloaded_image) }
      end
    end

    zip_file_path
  end
end
