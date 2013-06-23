#!/usr/local/bin/ruby
# Selenium script to scrape the WA Police Crime Statistics search
# Author: Matt Didcoe <matt@mattdidcoe.com>
# Last Modified: 2013-05-16 18:39
# Input: CSV file of ABS suburbs
# Output: JSON of ABS Suburb Code, Suburb Name and year summary statistics

require 'rubygems'
require 'logger'
require 'csv'
require 'json'
require 'selenium-webdriver'
require 'nokogiri'

logger = Logger.new('crimestats.log')

def fetch_suburb(suburb_name, logger)
  url = "http://www.police.wa.gov.au/Aboutus/Statistics/Searchcrimestatistics/tabid/998/Default.aspx"
  
  begin
    driver = Selenium::WebDriver.for :firefox
    # Fetch the page
    driver.get url
    # Define the elements we want to manipulate
    suburb = driver.find_element :name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$suburb"
    startMonth = driver.find_element :name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$startmonth"
    startYear = driver.find_element :name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$startyear"
    endMonth = driver.find_element :name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$EndMonth"
    endYear = driver.find_element :name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$EndYear"
    # Get the selects
    suburb_dropdown = Selenium::WebDriver::Support::Select.new(suburb)
    startMonth_dropdown = Selenium::WebDriver::Support::Select.new(startMonth)
    startYear_dropdown = Selenium::WebDriver::Support::Select.new(startYear)
    endMonth_dropdown = Selenium::WebDriver::Support::Select.new(endMonth)
    endYear_dropdown = Selenium::WebDriver::Support::Select.new(endYear)
    # Change the selects by value (rather than option text)
    suburb_dropdown.select_by(:value, suburb_name)
    startMonth_dropdown.select_by(:value, "1")
    startYear_dropdown.select_by(:value, "2012")
    endMonth_dropdown.select_by(:value, "12")
    endYear_dropdown.select_by(:value, "2012")
    # Submit the page and wait one second to allow it to catch-up
    driver.find_element(:name => "dnn$ctr2675$ViewSuburbCrimeStatsSearch$btnSearch").click
    sleep(1)
    # Change to the pop-up the stats are actually in - this works on the assumption the popup is at location [1] in the array, safe enough (for now)given it starts from scratch each time
    driver.switch_to.window(driver.window_handles[1])

    source = driver.page_source
    
    stats = []
    # Parse the page with Nokogiri and dump into a hash
    page = Nokogiri::HTML(source)
    summary_stats = ((page/:tr).last/:td)[1..-1]
    stats = {:assault => summary_stats[0].text.to_i, :burglary_dwelling => summary_stats[1].text.to_i,	:burglary_other => summary_stats[2].text.to_i, :graffiti => summary_stats[3].text.to_i, :robbery => summary_stats[4].text.to_i, :steal_motor_vehicle => summary_stats[5].text.to_i}
    # Close the webdriver
    driver.quit
  
    return stats
    
  rescue Exception => e
    logger.error("Could not get results for suburb: #{suburb_name}. You will need to complete this task manually or investigate the error further. For reference, the error was #{e.message}")
    driver.quit
  end
  
end

crime_statistics = []

CSV.foreach("/Users/mattdidcoe/Desktop/Geospatial\ Data/suburbs-2011-abs.csv") do |row|
  suburb_code = row[0]
  suburb_name = row[1]
  stats = fetch_suburb(suburb_name.upcase, logger) # Change to upper-case as WAPOL site uses it (why?)
  results = {:suburb => {:name => suburb_name, :suburb_code => suburb_code, :statistics => stats}}
  crime_statistics << results
  logger.info("Successfully retrieved statistics for #{suburb_name}")
  sleep(2) # Provide some relief to the WAPOL servers
end

puts JSON.generate(crime_statistics)
