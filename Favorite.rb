#
#  Favorite.rb
#  flickrViewer2
#
#  Created by Nicholas Chen on 7/12/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'PhotoNode'

class Favorite < PhotoNode
  
  MAX_PHOTOS = 30

  attr_accessor :username, :userid, :photosets, :cached, :total

  def initUsername_userid(username, userid)
		init
		
    @username = username
    @userid = userid
    @photosets = Array.new
		
		return self
  end
   
  def == (object)
    return false unless object.class == self.class
    @username == object.username && @userid == object.userid
  end
	
	def to_simple_yaml
		yaml = Hash.new
		yaml[:username] = @username
		yaml[:userid] = @userid
		yaml[:photosets] = Array.new
		yaml[:cached] = @cached
		yaml[:total] = @total
		
		@photosets.each do |photoset|
			yaml[:photosets] << photoset.to_simple_yaml
		end
		
		return yaml
	end
	
	def from_simple_yaml(yaml)
		@username = yaml[:username]
		@userid = yaml[:userid]
		@cached = yaml[:cached]
		@total = yaml[:total]
		@photosets = Array.new
		
		photosets_array = yaml[:photosets]
		
		photosets_array.each do |element|
			photoset = PhotoSet.alloc.init
			photoset.from_simple_yaml(element)
			@photosets << photoset
		end
	end
	
	def expandable?
		@photosets.size > 0
	end
	
	def displayName
		@username.to_s
	end
	
	def children
		@photosets.size
	end
	
	def childAt(index)
		@photosets[index]
	end
	
	def removeFrom(aCollection)
	  # Remove folder from disk
	  directory = FileLocations.favorites_directory(@username)
	  FileUtils.remove_dir(directory, true)
	  
	  aCollection.delete(self)
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
		notification_center.postNotificationName_object(NotificationMessages::DELETE_FAVORITE_RELOAD, nil)
	end
	
	def removable?
		true
	end
	
	def local_copy_exists?
		directory = FileLocations.favorites_directory(@username)
		File.exist?(directory)
	end
	
	def refresh_photos_from_web(download_progressbar)		
		begin
			flickr = FlickrConnection.new.flickr
			photos = flickr.people.getPublicPhotos(@userid, nil, MAX_PHOTOS, nil)
		
			# Create the directory
			begin
				directory = FileLocations.favorites_directory(@username)
				Dir.mkdir(directory) unless File.exist?(directory)
				
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
	
	def mark_as_viewed
		list = file_list
		
		list.each do |metadata|
			metadata.status = 'old'
		end
		
		save(list)
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
		notification_center.postNotificationName_object(NotificationMessages::RELOAD_IMAGE_PREVIEW, nil)
	end
	
	def download(photos, download_progressbar)
		Thread.start do
			directory = FileLocations.favorites_directory(@username)
			
			increment = 100.0 / photos.size
			
			download_progressbar.setHidden(false)
			
			photos.each do |photo|
				# This line produces corrupted image files on OSX
				# open(directory + '/' + photo.id + IMAGE_EXTENSION, "wb").write(open(photo.url(PHOTO_PREVIEW_SIZE)).read)
			
				system "curl #{photo.url(PHOTO_PREVIEW_SIZE)} -o \"#{directory + File::SEPARATOR + photo.id + IMAGE_EXTENSION}\""
				download_progressbar.incrementBy(increment)
			end
			
			download_progressbar.setHidden(true)
		end
			
	end
	
	def store_metadata(photos)
		directory = FileLocations.favorites_directory(@username)
		
		metadata = Array.new
	
		begin
			old_list = file_list
		rescue Errno::ENOENT
			old_list = nil
		end

		photos.each do |photo|
			local_url = directory + File::SEPARATOR + photo.id + IMAGE_EXTENSION
			web_url = photo.url
			flickr_photo_url = photo.flickr_url
			metadata << FlickrMetadata.new(local_url, web_url, flickr_photo_url, 'old')
		end
		
		unless old_list.nil?
			diff = find_new_photos(metadata, old_list)
			diff.each { |photo| photo.status = 'new' }
		end
		
		save(metadata)
	end
	
	def save(metadata)
    File.open(FileLocations.favorites_directory_metadata(@username), "w") { |file| YAML.dump(metadata, file)}
  end
	
	def file_list
	  directory = FileLocations.favorites_directory(@username)
	  YAML::load(File.open(FileLocations.favorites_directory_metadata(@username)))
	end

	# Doing new_list - old_list with Array::- did not work
	def find_new_photos(new_list, old_list)
		new_list.reject do |photo|
			old_list.include?(photo)
		end
	end
	
end