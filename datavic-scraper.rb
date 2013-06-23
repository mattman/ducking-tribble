#!/usr/bin/env ruby

# data.vic.gov.au scraper
# Author: Matt Didcoe <matt@mattdidcoe.com>
# Last update: 23 June 2013

# Usage: datavic-scraper.rb query
# Returns: [TODO] SOMETHING USEFUL

require 'open-uri'
require 'nokogiri'

# setup some base variables that I might reuse throughout
# (or at least I'll have them handy if they change them)
BASE_URI = "http://www.data.vic.gov.au"
PAGINATE_CLASS = "div.tags ul a" # The links inside the .tags ul element

# Define a 'data' (record) class
Data = Struct.new(:name, :agency, :url_page, :url_file, :format, :license, :keywords, :description)

def fetch(query)
  pages = []
  doc = Nokogiri::HTML(open(BASE_URI+"/search?q=#{query}"))
  doc.css(PAGINATE_CLASS).each do |p|
    pages << p["href"]
  end
end

def page(url)
  
end

def get_record(url)
  record_page = Nokogiri::HTML(open(url))
  name = record_page.css("h1.rawdatah1").first.content
  agency = (record_page.css(".post")/:p/:a).first.content
  url_file = record_page.xpath("//meta[@name='DCTERMS.Source']").first["content"]
  format = record_page.xpath("//meta[@name='DCTERMS.Format']").first["content"]
  license = record_page.xpath("//meta[@name='DCTERMS.License']").first["content"]
  keywords = record_page.xpath("//meta[@name='DCTERMS.ketwords']").first["content"]
  description = record_page.xpath("//dd[@property='dc:description']").first.content.strip
  rec = Data.new(name,agency,url,url_file,format,license,keywords,description)
  # TODO : Send the struct somewhere useful
  puts rec
end

puts "Fetching results for: #{ARGV[0]}"
fetch(ARGV[0])