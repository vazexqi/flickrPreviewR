#
#  PhotoNode.rb
#  flickrViewer2
#
#  Created by Nicholas Chen on 7/12/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'FileLocations'
require 'fileutils'

# This is the abstract class for the nodes that can be displayed on the outline view
class PhotoNode < OSX::NSObject

  IMAGE_EXTENSION = '.jpg'
	
	# http://www.flickr.com/services/api/misc.urls.html
  PHOTO_PREVIEW_SIZE = 'm' 
	
	def	expandable?
		raise NotImplementedError("Subclass Responsibility")
	end
	
	def displayName
		raise NotImplementedError("Subclass Responsibility")
  end
	
	def children
		raise NotImplementedError("Subclass Responsibility")
	end
	
	def childAt(index)
		raise NotImplementedError("Subclass Responsibility")		
	end
	
	def removeFrom(aCollection)
	  # Does nothing by default
	end
	
	def removable?
		false # by default
	end
	
	def load_photos_from_disk(download_progressbar)
		notification_center = OSX::NSNotificationCenter.defaultCenter
		
		# Checks first if it is cached and then checks if the cache still exists
		unless @cached && local_copy_exists?
			notification_center.postNotificationName_object(NotificationMessages::DOWNLOADING_INDICATOR, self)
			refresh_photos_from_web(download_progressbar)
		else
			notification_center.postNotificationName_object(NotificationMessages::RELOAD_IMAGE_PREVIEW, self)
		end
	end
	
	def local_copy_exists?
		raise NotImplementedError("Subclass Responsibility")
	end
	
	def refresh_photos_from_web(download_progressbar)
		raise NotImplementedError("Subclass Responsibility")
	end
	
	def store_metadata(photos)
		raise NotImplementedError("Subclass Responsibility")
	end
	
	def file_list
    raise NotImplementedError("Subclass Responsibility")
	end
	
	def mark_as_viewed
		# Does nothing by default
	end
end

# Just a wrapper class. Could have used Struct but was not sure of the implications that
# had with RubyCocoa

class FlickrMetadata
	# local_url - where the image is stored locally
	# web_url - where the image is on the server
	# flickr_photo_url - where the photo page is on Flickr
	# status - ('old'|'new')
	attr_reader :local_url, :web_url, :flickr_photo_url
	attr_accessor :status
		
	def initialize(local_url, web_url, flickr_photo_url, status)
	 @local_url = local_url
	 @web_url = web_url
	 @flickr_photo_url = flickr_photo_url
	 @status = status
	end
	
	# Need to do this to enable reserialization
	# RubyCocoa seems to automatically add __slave_nsobj__ to all objects
  def to_yaml(opts = {})
     @__slave_nsobj__= nil
     super
  end
	
	def ==(object)
		return false unless object.class == self.class
    @local_url == object.local_url
	end
	
end