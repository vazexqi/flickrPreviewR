# http://rubyforge.org/projects/rflickr/
# Removed folder structure so that it works nicely with RubyCocoa

require 'base'

class Flickr::Transform < Flickr::APIBase
	def rotate(photo,degrees)
		photo = photo.id if photo.class == Flickr::Photo
		@flickr.call_method('flickr.photos.transform.rotate',
			'photo_id' => photo, 'degrees' => degrees)
	end
end
