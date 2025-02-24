require 'selenium-webdriver'
require 'rspec'
require 'dotenv'
require 'browserstack/local'

Dotenv.load

RSpec.describe 'Google Maps Route Planner', type: :feature do
  before(:each) do
    # Start BrowserStack Local
    @bs_local = BrowserStack::Local.new
    bs_local_args = { "key" => ENV['BROWSERSTACK_ACCESS_KEY'] ,
      "force" => "true",
      "onlyAutomate" => "true",
      "verbose" => "true",
      "localIdentifier" => "test123"
    }
    @bs_local.start(bs_local_args)

    # Wait for BrowserStack Local to be up and running
    sleep(2) until @bs_local.isRunning
    raise 'BrowserStack Local is not running' unless @bs_local.isRunning
    # Set up BrowserStack capabilities
      options = Selenium::WebDriver::Chrome::Options.new
      options.browser_version = 'latest'
      options.platform_name = 'Windows 10'
      options.add_option('bstack:options', {
        "os" => "Windows",
        "osVersion" => "10",
        "buildName" => "MapProject-Build-1",
        "sessionName" => "Google Maps Route Planner Test",
        "local" => "true",
        "seleniumVersion" => "4.8.0"
      })


    # Set up WebDriver for BrowserStack
    @driver = Selenium::WebDriver.for(:remote,
      url: "https://#{ENV['BROWSERSTACK_USERNAME']}:#{ENV['BROWSERSTACK_ACCESS_KEY']}@hub.browserstack.com/wd/hub",
      capabilities: [options])

    # Maximize window
    @driver.manage.window.maximize
  end

  it 'displays the correct route between two points' do
    @driver.navigate.to 'http://127.0.0.1:3000'

    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    wait.until { @driver.execute_script("return document.readyState") == "complete" }

    add_button = wait.until { @driver.find_element(:css, 'button.add-destination') }
    add_button.click

    inputs = wait.until { @driver.find_elements(:css, 'input.location-input') }
    
    if inputs.length >= 2
      # Disable the submit button before interaction
      submit_button = wait.until { @driver.find_element(:css, 'button[type="submit"]') }
      @driver.execute_script("arguments[0].disabled = true;", submit_button)

      # Origin - Sydney
      inputs[0].clear
      inputs[0].send_keys('Sydney, Australia')

      # Target the first pac-container for the first input
      wait.until {
        dropdowns = @driver.find_elements(:css, '.pac-container')
        dropdowns[0].displayed?
      }
      sleep(1) # Ensure dropdown is populated

      # Use Arrow Down and Enter to select the first item
      inputs[0].send_keys(:arrow_down)
      inputs[0].send_keys(:enter)

      # Confirm that data-place-id is set
      wait.until { inputs[0].attribute('data-place-id').to_s.strip != '' }
      @driver.execute_script("arguments[0].blur();", inputs[0])

      # Log input values to check the result
      log_input_values(inputs)

      # Move to the second input using Tab
      inputs[0].send_keys(:tab)
      sleep(1) # Small delay to ensure focus is set

      # Destination - Melbourne
      inputs[1].send_keys('Melbourne, Australia')

      # Target the second pac-container for the second input
      wait.until {
        dropdowns = @driver.find_elements(:css, '.pac-container')
        dropdowns[1].displayed?
      }
      sleep(1) # Ensure dropdown is populated

      # Use Arrow Down and Enter to select the first item
      inputs[1].send_keys(:arrow_down)
      inputs[1].send_keys(:enter)

      # Confirm that data-place-id is set
      wait.until { inputs[1].attribute('data-place-id').to_s.strip != '' }
      @driver.execute_script("arguments[0].blur();", inputs[1])

      # Log input values again after entering second input
      log_input_values(inputs)

      # Re-enable the submit button after both inputs are filled
      @driver.execute_script("arguments[0].disabled = false;", submit_button)
    else
      raise "Not enough input fields found"
    end

    # Wait until all inputs are filled before clicking the submit button
    wait.until {
      inputs.all? { |input| input.attribute('value').to_s.strip != '' }
    }

    # Log final input values before clicking submit
    log_input_values(inputs)

    # Click Generate Plan
    wait.until { submit_button.enabled? }
    submit_button.click
    # Wait for the route and map to be displayed
    directions_panel = wait.until { @driver.find_element(:id, 'directions-panel') }
    map = wait.until { @driver.find_element(:id, 'map') }
    sleep(10)
    # Check for expected elements and set the test status on BrowserStack
    if directions_panel.displayed? && map.displayed?
    @driver.execute_script('browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"passed", "reason": "Multiple waypoints displayed as expected"}}')
    else
    @driver.execute_script('browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"failed", "reason": "Waypoints or map not displayed"}}')
    end
  end

  it 'displays route for multiple waypoints' do
  @driver.navigate.to 'http://127.0.0.1:3000'
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  wait.until { @driver.execute_script("return document.readyState") == "complete" }

  add_button = wait.until { @driver.find_element(:css, 'button.add-destination') }
  # Add multiple waypoints
  2.times { add_button.click }

  inputs = wait.until { @driver.find_elements(:css, 'input.location-input') }
  
  # Ensure at least 3 input fields are present
  if inputs.length >= 3
    # Disable the submit button before interaction
    submit_button = wait.until { @driver.find_element(:css, 'button[type="submit"]') }
    @driver.execute_script("arguments[0].disabled = true;", submit_button)

    # Waypoint 1 - Sydney
    inputs[0].clear
    inputs[0].send_keys('Sydney NSW, Australia')

    # Target the first pac-container for the first input
    wait.until {
      dropdowns = @driver.find_elements(:css, '.pac-container')
      dropdowns[0].displayed?
    }
    sleep(1) # Ensure dropdown is populated

    # Use Arrow Down and Enter to select the first item
    inputs[0].send_keys(:arrow_down)
    inputs[0].send_keys(:enter)

    # Confirm that data-place-id is set
    wait.until { inputs[0].attribute('data-place-id').to_s.strip != '' }
    @driver.execute_script("arguments[0].blur();", inputs[0])

    # Log input values to check the result
    log_input_values(inputs)

    # Move to the next input using Tab
    inputs[0].send_keys(:tab)
    sleep(1) # Small delay to ensure focus is set

    # Waypoint 2 - Canberra
    inputs[1].clear
    inputs[1].send_keys('Canberra ACT, Australia')

    # Target the second pac-container for the second input
    wait.until {
      dropdowns = @driver.find_elements(:css, '.pac-container')
      dropdowns[1].displayed?
    }
    sleep(1) # Ensure dropdown is populated

    # Use Arrow Down and Enter to select the first item
    inputs[1].send_keys(:arrow_down)
    inputs[1].send_keys(:enter)

    # Confirm that data-place-id is set
    wait.until { inputs[1].attribute('data-place-id').to_s.strip != '' }
    @driver.execute_script("arguments[0].blur();", inputs[1])

    # Log input values to check the result
    log_input_values(inputs)

    # Move to the next input using Tab
    inputs[1].send_keys(:tab)
    sleep(1) # Small delay to ensure focus is set

    # Waypoint 3 - Melbourne
    inputs[2].clear
    inputs[2].send_keys('Melbourne VIC, Australia')

    # Target the third pac-container for the third input
    wait.until {
      dropdowns = @driver.find_elements(:css, '.pac-container')
      dropdowns[2].displayed?
    }
    sleep(1) # Ensure dropdown is populated

    # Use Arrow Down and Enter to select the first item
    inputs[2].send_keys(:arrow_down)
    inputs[2].send_keys(:enter)

    # Confirm that data-place-id is set
    wait.until { inputs[2].attribute('data-place-id').to_s.strip != '' }
    @driver.execute_script("arguments[0].blur();", inputs[2])

    # Log input values again after entering third input
    log_input_values(inputs)

    # Re-enable the submit button after all inputs are filled
    @driver.execute_script("arguments[0].disabled = false;", submit_button)
  else
    raise "Not enough input fields found"
  end

  # Wait until all inputs are filled before clicking the submit button
  wait.until {
    inputs.all? { |input| input.attribute('value').to_s.strip != '' }
  }

  # Log final input values before clicking submit
  log_input_values(inputs)

  # Click Generate Plan
  wait.until { submit_button.enabled? }
  submit_button.click

  # Wait for the route and map to be displayed
  directions_panel = wait.until { @driver.find_element(:id, 'directions-panel') }
  map = wait.until { @driver.find_element(:id, 'map') }

  sleep(10)
  # Check for expected elements and set the test status on BrowserStack
  if directions_panel.displayed? && map.displayed?
    @driver.execute_script('browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"passed", "reason": "Multiple waypoints displayed as expected"}}')
  else
    @driver.execute_script('browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"failed", "reason": "Waypoints or map not displayed"}}')
  end
end


  after(:each) do
      @driver.quit if @driver
      if @bs_local && @bs_local.isRunning
        @bs_local.stop
        end   
      end
end


def log_input_values(inputs)
  inputs.each_with_index do |input, index|
    value = input.attribute('value').to_s.strip
    puts "Input ##{index + 1} value: '#{value}'"
  end
end
