require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'
require 'net/http'


module Common
  extend self

  def loadCommonWords(file = File.join(File.dirname(File.expand_path(__FILE__)), "/unigram_freq.csv"))
    table = CSV.open(file, headers: true)
    tableHash = {}
    table.each do |r|
      tableHash[r["word"]] = r["count"].to_i
    end
    return tableHash
  end


# Source: https://stackoverflow.com/questions/9675146/how-to-get-words-frequency-in-efficient-way-with-ruby
  def count_words(string)
    text = string&.scan(/[-'\w]+/)
    if (text != nil)
      text = clean_up_array text
      text.reduce(Hash.new(0)) {|res, w| res[w.downcase] += 1; res}
    end

  end

  def clean_up_array(array)
    # Remove numbers
    array.each do |k|
      if /\A\d+\z/.match(k)
        array.delete(k)
      end
    end

    # Discard words with special chars
    array.each do |k|
      special = "?<>,?[]}{=-)(*&^%$#`~{}"
      regex = /[#{special.gsub(/./) {|char| "\\#{char}"}}]/
      if (k =~ regex)
        array.delete(k)
      end
    end
    # Short words (less or eq 2 in length) dont have much semantics in english or maybe single letter (I, we, of, my...)
    array.delete_if {|k| k.length <= 2}
    # Delete strange blank char
    array.delete("x200b")
    # Clean URLS
    array.delete_if {|k| k.start_with?("http")}
    # Filter StopWords
    filter = Stopwords::Snowball::Filter.new "en"
    array = filter.filter array
    array
  end

  def downloadPushShift(subreddit, size)
    uri = URI("https://elastic.pushshift.io/rs/submissions/_search/?q=(subreddit:#{subreddit})&size=#{size}&sort=created_utc:desc&_source_includes=selftext")
    res = Net::HTTP.get_response(uri)
    puts "#{size} Reddit Posts downloaded"
    JSON.parse(res.body)
  end

  def clean_text(text)
    text&.downcase!
    text&.gsub!(/[^a-z' ]/, ' ')
    # text&.gsub!(/[']/, "")
    text&.gsub!(/\s+/, " ")
  end

  def loadPushShift(subreddit, size)
    initialHash = {}
    json = downloadPushShift(subreddit, size)
    json["hits"]["hits"].each do |i|
      text = count_words(clean_text(i["_source"]["selftext"]))
      count_hash = text.nil? ? {} : text
      initialHash.merge!(count_hash) {|k, a_value, b_value| a_value + b_value}
    end
    return initialHash
  end

  def readRedditJSON
    fileStr = File.read("first1000depression.json")
    jsonFile = JSON.parse(fileStr)
    initialHash = {}
    puts jsonFile["data"].count
    jsonFile["data"].each do |i|
      text = self.count_words(i["selftext"])
      count_hash = text.nil? ? {} : text
      initialHash.merge!(count_hash) {|k, a_value, b_value| a_value + b_value}
    end
    return initialHash
  end


end