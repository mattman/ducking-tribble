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
    pages << p.attributes["href"].value
  end
end

def page(url)
  
end

def get_record(url)
  record_page = Nokogiri::HTML(open(url))
  name = record_page.css("h1.rawdatah1").first.content
  agency =
  url_file = doc.xpath("//meta[@name='DCTERMS.Source']").first.attributes["content"].value
  format = doc.xpath("//meta[@name='DCTERMS.Format']").first.attributes["content"].value
  license = doc.xpath("//meta[@name='DCTERMS.License']").first.attributes["content"].value
  keywords = doc.xpath("//meta[@name='DCTERMS.ketwords']").first.attributes["content"].value
  description
  rec = Data.new(name,agency,url,url_file,format,license,keywords,description)
  # TODO : Send the struct somewhere useful
  puts rec
end

puts "Fetching results for: #{ARGV[0]}"
fetch(ARGV[0])