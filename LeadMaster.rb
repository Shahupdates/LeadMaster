# LeadMaster
# ==========================================
# Author: Love Shah
# Date: 05.30.2023
# Title: LeadMaster
# Description: LeadMaster is a comprehensive lead management program that automates the process of finding and organizing contact information for potential prospects. By leveraging various tools and platforms, LeadMaster streamlines lead research and data collection. Here's the refactored code:

require "google_drive"
require "watir-webdriver"
#require "timeout"

# Your configuration - Provide LeadMaster with the necessary details
@your_config = {
  email_hunter_email: "",
  email_hunter_password: "",
  voila_norbert_email: "",
  voila_norbert_password: "",
  find_that_email_email: "",
  find_that_email_password: "",
  google_sheet_key: "",
}

# Email Hunter configuration
@email_hunter = {
  url: "https://hunter.io/users/sign_in",
  email_field: "user[email]",
  password_field: "user[password]",
  login_button: "Log in »",
  website_field: 'domain-field',
  button: 'search-btn',
  pattern_result_div: '/html/body/div[3]/div/div[2]/div[1]/div[1]/div/div/div[1]/div',
  email_result_div: '.search.index .search-results .result .email'
}

# Voila Norbert configuration
@voila_norbert = {
  url: "https://app.voilanorbert.com/#!/auth/login",
  email_field: "email",
  password_field: "password",
  login_button: "Let's do this, Norbert!",
  name_field: 'name',
  website_field: 'domain',
  button: 'Go ahead, Norbert!',
  email_result_div: '.contact-list'
}

# Find That Email configuration
@find_that_email = {
  url: "https://findthat.email/sign-in/",
  email_field: "email",
  password_field: "password",
  login_button: "t_sign_submit",
  first_name_field: 'first_name',
  last_name_field: 'last_name',
  website_field: 'company_domain',
  button: 't_home_sumbit',
  answer_div: '//*[@id="t_d_search_log_box"]/div/div[1]/div'
}

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
session = GoogleDrive::Session.from_config("gdrive_config.json")

# Go to the spreadsheet
ws = session.spreadsheet_by_key(@your_config[:google_sheet_key]).worksheets[0]

# To-do
# Replace sleep with wait timeouts
# https://ruby-doc.org/stdlib-2.4.1/libdoc/timeout/rdoc/Timeout.html

def open_browser
  # Open a new browser
  browser = Watir::Browser.new :phantomjs

  # Maximize the browser
  browser.driver.manage.window.maximize

  # Return the browser
  return browser
end

def email_hunter(browser, first_name, last_name, domain)
  return "Email Hunter login details missing." if @your_config[:email_hunter_email].nil? || @your_config[:email_hunter_password].nil?

  browser.goto(@email_hunter[:url])
  sleep 10
  browser.text_field(:name => @email_hunter[:email_field]).set @your_config[:email_hunter_email]
  browser.text_field(:name => @email_hunter[:password_field]).set @your_config[:email_hunter_password]
  browser.button(:value => @email_hunter[:login_button]).click
  sleep 30 # Wait for it to set the session
  browser.text_field(:id => @email_hunter[:website_field]).set domain
  browser.button(:id => @email_hunter[:button]).click
  sleep 20

  # Get the email pattern
  # Replace the pattern with available details
  if browser.div(:xpath => @email_hunter[:pattern_result_div]).exists?
    pattern = browser.div(:xpath => @email_hunter[:pattern_result_div]).text.split('Most common pattern: ')[-1]
    pattern_replacement = pattern.gsub('{first}', first_name.downcase).gsub('{f}', first_name[0].downcase).gsub('{last}', last_name.downcase).gsub('{l}', last_name[0].downcase)
  else
    pattern = 'Not found'
    pattern_replacement = 'Not found'
  end

  # Get the returned email
  if browser.div(:css => @email_hunter[:email_result_div]).exists?
    email_gotten = browser.div(:css => @email_hunter[:email_result_div]).text
  else
    email_gotten = 'Not found'
  end

  return "Pattern: #{pattern}\nPattern replacement: #{pattern_replacement}\nEmail from source: #{email_gotten}"
end

def voila_norbert(browser, first_name, last_name, domain)
  return "Voila Norbert login details missing" if @your_config[:voila_norbert_email].nil? || @your_config[:voila_norbert_password].nil?

  browser.goto(@voila_norbert[:url])
  sleep 10
  browser.text_field(:name => @voila_norbert[:email_field]).set @your_config[:voila_norbert_email]
  browser.text_field(:name => @voila_norbert[:password_field]).set @your_config[:voila_norbert_password]
  browser.element(:css => "input[type=submit]").click
  sleep 30 # Wait for it to set the session
  browser.text_field(:name => @voila_norbert[:name_field]).set "#{first_name} #{last_name}"
  browser.text_field(:name => @voila_norbert[:website_field]).set domain
  browser.button(:value => @voila_norbert[:button]).click
  sleep 40
  contact_list = browser.ul(:css => @voila_norbert[:email_result_div])
  contact_list.lis.each do |li|
    if li.text.include?("#{first_name} #{last_name}")
      return li.text
      break
    end
  end
  return "Not found"
end

def find_that_email(browser, first_name, last_name, domain)
  return "Find that email login details missing" if @your_config[:find_that_email_email].nil? || @your_config[:find_that_email_password].nil?

  browser.goto(@find_that_email[:url])
  browser.text_field(:name => @find_that_email[:email_field]).set @your_config[:find_that_email_email]
  browser.text_field(:name => @find_that_email[:password_field]).set @your_config[:find_that_email_password]
  browser.execute_script('$("#t_sign_submit").click()')
  sleep 30
  browser.text_field(:name => @find_that_email[:first_name_field]).set first_name
  browser.text_field(:name => @find_that_email[:last_name_field]).set last_name
  browser.text_field(:name => @find_that_email[:website_field]).set domain # Can't use xpath because id changes
  sleep 5
  browser.execute_script('$("#t_my_app_add_button").click()')
  sleep 30
  if browser.div(:xpath => @find_that_email[:answer_div]).exists?
    return browser.div(:xpath => @find_that_email[:answer_div]).text.strip
  else
    return ''
  end
end

def whois(browser, first_name, last_name, domain)
  browser.goto('https://www.whoisxmlapi.com/?domainName=' + domain + '&outputFormat=xml')
  sleep 30
  content = browser.div(:id => 'wa-tab-content-whoislookup').text
  r = Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
  emails = content.scan(r).uniq
  unless emails.nil?
    return emails.first
  else
    return 'Not Found'
  end
end

def with_error_handling
  yield
rescue => e
  return e
end

# Main function
# Get all rows in the spreadsheet
(2..ws.num_rows).each do |row|
  # Skip the current row if the first name, last name, or domain is missing
  next if ws[row, 1].nil? || ws[row, 2].nil? || ws[row, 3].nil?

  browser = open_browser

  # Step 1: Email Hunter
  email_hunter_result = with_error_handling { email_hunter(browser, ws[row, 1], ws[row, 2], ws[row, 3]) }
  ws[row, 4] = email_hunter_result

  # Step 2: Voila Norbert
  voila_norbert_results = with_error_handling { voila_norbert(browser, ws[row, 1], ws[row, 2], ws[row, 3]) }
  ws[row, 5] = voila_norbert_results

  # Step 3: Find That Email
  find_that_email_result = with_error_handling { find_that_email(browser, ws[row, 1], ws[row, 2], ws[row, 3]) }
  ws[row, 6] = find_that_email_result

  # Step 4: Whois
  whois_result = with_error_handling { whois(browser, ws[row, 1], ws[row, 2], ws[row, 3]) }
  ws[row, 7] = whois_result

  ws.save
  browser.close
  sleep 10
end
