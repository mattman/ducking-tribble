#!/usr/bin/env ruby

# data.vic.gov.au scraper
# Author: Matt Didcoe <matt@mattdidcoe.com>
# Last update: 23 June 2013

# Usage: datavic-scraper.rb query
# Output: JSON to STDOUT (pipe it into a file yourself)

require 'open-uri'
require 'uri'
require 'nokogiri'
require 'json'
require 'shellwords'

# setup some base variables that I might reuse throughout
# (or at least I'll have them handy if they change them)
BASE_URI = "http://www.data.vic.gov.au"
ERRORS = []

# Define a 'data' (record) class
class GovData < Struct.new(:name, :agency, :agency_url, :url_page, :url_file, :format, :license, :keywords, :tags, :description)
  def json
    {'name' => name, 'agency' => {'name' => agency, 'url' => agency_url}, 'url' => url_page, 'file' => {'url' => url_file, 'format' => format}, 'license' => license, 'keywords' => keywords, 'tags' => tags}.to_json
  end
end

def fetch(query, output)
  doc = Nokogiri::HTML(open(BASE_URI+"/search?q=#{URI.encode(query)}"))
  pages = []
  a = doc.css("div.tags ul a")
  if !a.empty?
    a.each do |p|
      pages << p["href"]
    end
  else
    pages << "/search?q=#{URI.encode(query)}"
  end
  pages.each do |p|
    get_page(p,output)
#    sleep(3)
  end
  output
end

def get_page(url,output)
  search_page = Nokogiri::HTML(open(BASE_URI+url))
  records = []
  search_page.css("a.more").each do |a|
    records << a["href"]
  end
  records.each do |r|
    get_record(r,output)
  end
end

def get_record(url,output)
  begin
    record_page = Nokogiri::HTML(open(url))
    name = record_page.css("h1.rawdatah1").first.content
    agency = (record_page.css(".contributordescription")/:a).first.content
    agency_url = (record_page.css(".contributordescription")/:a).first["href"]
    url_file = record_page.xpath("//meta[@name='DCTERMS.Source']").first["content"]
    format = record_page.xpath("//meta[@name='DCTERMS.Format']").first["content"]
    license = record_page.xpath("//meta[@name='DCTERMS.License']").first["content"]
    keywords = record_page.xpath("//meta[@name='DCTERMS.keywords']").first["content"].split(',')
    tags = []
    # loop and add tags to array
    record_page.css(".tags a").each do |t|
      tags << t.content
    end
    description = record_page.xpath("//dd[@property='dc:description']").first.content.strip
    output << GovData.new(name,agency,agency_url,url,url_file,format,license,keywords,tags,description).json
  rescue OpenURI::HTTPError
    ERRORS << url
  end
end

output = []
fetch(ARGV[0],output)
puts '{"results":['+output.join(",")+']}'
