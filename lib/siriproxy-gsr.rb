require 'cora'
require 'siri_objects'
require 'rubygems'
require 'mechanize'

#######
# SiriIMDB is a Siri Proxy plugin that allows Siri to book you a Group Study Room.
# Check the readme file for more detailed usage instructions.
# Created by Matt Parmett  - you are free to use, modify, and redistribute as you like, as long as you give the original author credit.
######

class SiriProxy::Plugin::GSR < SiriProxy::Plugin
  attr_accessor :username
  attr_accessor :password

  def initialize(config = {})
	self.username = config['username']
	self.password = config['password']
  end


  
listen_for /reserve a GSR on ([a-z]*) ([0-9,]*[0-9]) at ([0-9,]*[0-9]):([0-9,]*[0-9]) ([a-z]*) for ([0-9,]*[0-9]) minutes/i do |month, day, hour, minutes, half, duration|

    #Make Siri acknowledge request
    #add_views = SiriAddViews.new
    #add_views.make_root(last_ref_id)
    #utterance = SiriAssistantUtteranceView.new("Please wait while I reserve your GSR...")
    #add_views.views << utterance
    #send_object add_views

    #Properly convert month to numerical string
    if month == 'January'
	m = '01'
    elsif month == 'February'
	m = '02'
    elsif month == 'March'
	m = '03'
    elsif month == 'April'
	m = '04'
    elsif month == 'May'
	m = '05'
    elsif month == 'June'
	m = '06'
    elsif month == 'July'
	m = '07'
    elsif month == 'August'
	m = '08'
    elsif month == 'September'
	m = '09'
    elsif month == 'October'
	m = '10'
    elsif month == 'November'
	m = '11'
    elsif month == 'December'
	m = '12'
    end
    
    #Convert day and duration to proper format
    day = day.to_s()
    duration = duration.to_i

    #Convert hour to proper format
    hour = hour.to_i
    if (hour < 10)
    	hour = hour.to_s()
    	hour = '0' + hour
    else
    	hour = hour.to_s()
    end

    #Convert AM/PM to proper format
    half = half.upcase

    #Send update
    puts "logging in to spike..."

    #Go to spike mobile site and log in
    agent = Mechanize.new
    login = agent.get('http://spike.wharton.upenn.edu/m/gsr.cfm?logout=true') #Go to login page
    loginform = agent.page.forms.first #Select login form
    loginform.username = self.username #Set username
    loginform.password = self.password #Set password

    #Submit login form and go to GSR page
    object = SiriAddViews.new
    object.make_root(last_ref_id)
    answer = SiriAnswer.new("", [SiriAnswerLine.new("Booking your GSR...")])
    object.views << SiriAnswerSnippet.new([answer])
    send_object object

    gsr = agent.submit(loginform, loginform.buttons.first) #Submit form and log in

    puts "Logged In.  Booking a room..."

    gsrform = gsr.form_with(:action => 'https://spike.wharton.upenn.edu/m/gsr.cfm') #Select GSR form

    puts "GSR page accessed. Setting reservation info..."

    #Input GSR info
    gsrform.preferred_floor = 'A' #Choose GSR floor
    gsrform.start_date = m + '/' + day #Choose GSR date
    gsrform.start_time = hour + ':' + minutes + half #Choose GSR time
    gsrform.duration = duration #Choose GSR length

    puts "GSR info set.  Submitting reservation..."

    submit = agent.submit(gsrform, gsrform.buttons.first) #Book the GSR

    puts "Reservation made."
    say "Reservation made for " + month + " " + day + " at " + hour + ":" + minutes + " " + half + " for " + duration.to_s() + " minutes."

    request_completed
end


listen_for /cancel my gsr/i do
    print "Logging in to spike..."

    #Go to spike mobile site and log in
    agent = Mechanize.new
    login = agent.get('http://spike.wharton.upenn.edu/m/gsr.cfm?logout=true') #Go to login page
    loginform = agent.page.forms.first #Select login form
    loginform.username = self.username #Set username
    loginform.password = self.password #Set password

    #Submit login form and go to GSR page
    print "Logging in and accessing GSR page"
    gsr = agent.submit(loginform, loginform.buttons.first) #Submit form and log in

    print "Logged In.  Cancelling your room..."

    #Click cancel link, if it exists
    cancel = gsr.link_with(:text => 'Cancel')
    if (cancel.nil?)
	say "You have no GSR reservation to cancel."
    else
	gsr = cancel.click
    	say "Your GSR reservation has been cancelled."
    end
  
    request_completed

    end
end
