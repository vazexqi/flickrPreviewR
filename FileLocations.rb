#
#  FileLocations.rb
#  FlickrViewer
#
#  Created by Nicholas Chen on 7/11/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

module FileLocations
	FOLDER = '~/Library/Application Support/flickrPreviewR/'
	FAVORITES_FILE = File.expand_path(FOLDER + 'favorites.yaml')
	TOKEN_CACHE = File.expand_path(FOLDER + 'token_cache')
	FLICKR_METADATA = '.flickr_metadata'
	
	def FileLocations.favorites_directory(username)
	  File.expand_path(FOLDER + username)
  end
	
	def FileLocations.favorites_directory_metadata(username)
		File.expand_path(File.join(FOLDER, username, FLICKR_METADATA))
	end
  
  def FileLocations.photoset_directory(username, photosetid)
    user_directory = FileLocations.favorites_directory(username)
		File.expand_path(File.join(user_directory, photosetid))
  end
	
	def FileLocations.photoset_directory_metadata(username, photosetid)
		user_directory = FileLocations.favorites_directory(username)
		File.expand_path(File.join(user_directory, photosetid, FLICKR_METADATA))
	end
end
