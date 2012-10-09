#
#  FlickrConnection.rb
#  FlickrViewer
#
#  Created by Nicholas Chen on 7/11/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'FileLocations'

class FlickrConnection
	
	attr_accessor :flickr
	
	def initialize
		application_directory = File.expand_path(FileLocations::FOLDER)
				
		FileUtils.mkdir_p(application_directory) unless File.exist?(application_directory)
		
		@flickr = Flickr.new(FileLocations::TOKEN_CACHE)

    unless flickr.auth.token
      flickr.auth.getFrob
      url = flickr.auth.login_link('read')

			choice = OSX::NSRunAlertPanel("Authorization Required", "This application requires your authorization before it can read photos on Flickr. Please visit %@ in your browser and then click Done.\n\n Click Cancel to termiante this applicaton.", "Done", "Cancel", nil, url)
			
			if(choice == OSX::NSAlertAlternateReturn)
				OSX::NSApp.terminate(true)
			end
			
      flickr.auth.getToken
      flickr.auth.cache_token
    end
	end
	
end
