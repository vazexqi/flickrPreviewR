#
#  PhotoSet.rb
#  flickrViewer2
#
#  Created by Nicholas Chen on 7/12/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'PhotoNode'

class PhotoSet < PhotoNode
  
  IMAGE_EXTENSION = '.jpg'
  
  attr_accessor :title, :photosetid, :username, :userid, :cached, :total
	
  def initTitle_id_username_userid(title, photosetid, username, userid)
		init
		
    @title = title
    @photosetid = photosetid
    @username = username
    @userid = userid
		
		return self
  end
	
	def to_simple_yaml
		yaml = Hash.new
		yaml[:title] = @title
		yaml[:photosetid] = @photosetid
		yaml[:username] = @username
		yaml[:userid] = @userid
		yaml[:cached] = @cached
		yaml[:total] = @total
		
		return yaml
	end
	
	def from_simple_yaml(yaml)
		@title = yaml[:title]
		@photosetid = yaml[:photosetid]
		@username = yaml[:username]
		@userid = yaml[:userid]
		@cached = yaml[:cached]
		@total = yaml[:total]
	end
	
	def expandable?
		false
	end
	
	def displayName
		@title.to_s
  end
	
	def children
		0
	end
	
	def childAt(index)
		self
	end
	
	def local_copy_exists?
		photoset_directory = FileLocations.photoset_directory(@username, @photosetid)
		
		File.exist?(photoset_directory)
	end
	
	def refresh_photos_from_web(download_progressbar)		
		begin
			flickr = FlickrConnection.new.flickr
			photos = flickr.photosets.getPhotos(@photosetid)
		
			# Create the directory
			begin
		    photoset_directory = FileLocations.photoset_directory(@username, @photosetid)
				
				FileUtils.mkdir_p(photoset_directory) unless File.exist?(photoset_directory)
				
				store_metadata(photos)
				download(photos, download_progressbar)
				
				@cached = true
			rescue SystemCallError
				OSX::NSLog("Directory cannot be created")
			end
			
		rescue SocketError
			OSX::NSLog("Cannot establish connection")
		end
	end
	
	def download(photos, download_progressbar)
		Thread.start do
			photoset_directory = FileLocations.photoset_directory(@username, @photosetid)
			
			increment = 100.0 / photos.size
			
			download_progressbar.setHidden(false)
			
			photos.each do |photo|
				# This line produces corrupted image files on OSX
				# open(photoset_directory + File::SEPARATOR + photo.id + IMAGE_EXTENSION, "wb").write(open(photo.url(PHOTO_PREVIEW_SIZE)).read)
				
				system "curl #{photo.url(PHOTO_PREVIEW_SIZE)} -o \"#{photoset_directory + File::SEPARATOR + photo.id + IMAGE_EXTENSION}\""
				download_progressbar.incrementBy(increment)
			end
			
		 	download_progressbar.setHidden(true)
		end
	end
	
	def store_metadata(photos)
		photoset_directory = FileLocations.photoset_directory(@username, @photosetid)
		
		metadata = Array.new

		photos.each do |photo|
			local_url = photoset_directory + File::SEPARATOR + photo.id + IMAGE_EXTENSION
			web_url = photo.url
			flickr_photo_url = "http://www.flickr.com/photos/#{@userid}/#{photo.id}"
			metadata << FlickrMetadata.new(local_url, web_url, flickr_photo_url, 'old')
		end
		
		save(metadata)
	end
	
	def save(metadata)
    File.open(FileLocations.photoset_directory_metadata(@username, @photosetid), "w") { |file| YAML.dump(metadata, file)}
  end
	
	def file_list
	  photoset_directory = FileLocations.favorites_directory(@username)
	  list = YAML::load(File.open(FileLocations.photoset_directory_metadata(@username, @photosetid)))
	end
	
end