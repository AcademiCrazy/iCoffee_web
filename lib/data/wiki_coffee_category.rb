require 'rubygems'
require 'mechanize'
require 'json'
require 'pp'

class WikiCoffee

  ####################################################################################
  # Initialize Method
  #
  #
  ####################################################################################
  def initialize
    @agent = Mechanize.new
    @agent.user_agent = 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1468.0 Safari/537.36'
    puts "Generate the mechanize agent successful"
  end

  ####################################################################################
  # Main Method
  #
  #
  ####################################################################################
  def run
    url = "http://en.wikipedia.org/wiki/List_of_coffee_varieties"
    result = {}

    begin
      page = @agent.get(URI::escape(url))
    rescue Mechanize::ResponseCodeError => e
      unless e.message =~ /404/
        retry_count = (retry_count || 0) + 1
        if retry_count <= RETRY_LIMIT
          sleep(1)
          retry
        end
      end
      raise e
    end

    html = Nokogiri::HTML(page.body)
    coffee_types = html.at_css('table.wikitable').elements

    coffee_types.each {|type|
      coffee_item = type.elements.to_a
      name = coffee_item[0].text
      category =  coffee_item[1].text
      regions =  coffee_item[2].text
      desc = coffee_item[3].text
      result[name] = {
                          'name' => name,
                          'category' => category,
                          'regions'  => regions,
                          'desc' => desc,
                          'rate' => 0,
                          'image' => "http://d1hekt5vpuuw9b.cloudfront.net/assets/8677e851aed9f5d14dd636b35b4a253f_decaf-coffee-300x300_gallery.jpg"
                     }

    }

    result_json = result.to_json

    File.open("coffee_category.json", "w") do |f|
      f.write(result_json)
    end
  end

  ####################################################################################
  # Crawl Method
  #
  #
  ####################################################################################





  ####################################################################################
  # Parse Method
  #
  #
  ####################################################################################
  def parse
  end


end

obj = WikiCoffee.new
obj.run
