require File.dirname(__FILE__) + '/../../../config/environment'
require 'spokes/mechanize'

class WikiLastNameExtract

  SQL_RETRY_PERIOD = 1
  SEARCH_PERIOD = 1
  RETRY_LIMIT = 3


  def initialize
    @agent = Mechanize.new
    @agent.user_agent = 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1468.0 Safari/537.36'
  end


  def run(skip = 0)
    count = 0
    f = File.new("/var/tmp/wiki_last_name_log.txt", "a")
    begin
      File.open("test_last_names.txt").each {|line|
        last_name = normalize_name(line)
        count += 1

        if count > skip && last_name

          begin
            unless WikipediaLastNameEntry.find_by_last_name(last_name)
              desc, meaning, origin = parse(last_name)
              if desc
                WikipediaLastNameEntry.create(:last_name => last_name, :meaning => meaning, :origin => origin, :description => desc, :created_at => Time.now, :updated_at => Time.now) unless desc.nil?
              end
            end
          rescue Exception => e
            #sql, active record problems
            #parse function problems
            #others problems
            f.puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            f.puts "#{count} #{last_name} Crawl Failed"
            f.puts e.class
            f.puts e.message
            f.puts e.backtrace
          end
        end
      }
    rescue Exception => e
      f.puts "File Reading/Write Error"
      f.puts "Failed at line #{count}"
      f.puts e.class
      f.puts e.message
      f.puts e.backtrace
    end

    f.close
  end

  def normalize_name str
    last_name = str.downcase.strip
    return last_name
  end

  def parse(last_name)
    url = "http://en.wikipedia.org/wiki/#{last_name}_(surname)"

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
    desc = html.at_css('div#mw-content-text > p').text.gsub(/\[.+?\]/,'').gsub(/Notable people with the surname include\:/, '')
    meaning = nil
    origin = nil

    info_box = html.css('div#mw-content-text table.infobox tr')
    info_box.each{ |tr|
      th = tr.xpath('th').text rescue nil
      td = tr.xpath('td').text rescue nil

      if th == 'Meaning'
        meaning = td
      elsif th == 'Region of origin'
        origin = td
      elsif th == 'Language(s)'
        origin = td
      end
    }

    return desc, meaning, origin
  end

  def pause(sleep_length)
    timer = 0.0
    while @running && timer < sleep_length.to_f
      timer += 0.1
      sleep 0.1
    end
  end

end


#WikiLastName.readFile
obj = WikiLastNameExtract.new
#obj.parse('chen')
obj.run
