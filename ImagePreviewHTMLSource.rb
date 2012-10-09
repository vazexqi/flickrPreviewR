
#  ImagePreviewHTMLSource.rb
#  flickrViewer2
#
#  Created by Nicholas Chen on 7/14/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

class ImagePreviewHTMLSource < OSX::NSObject

	FLICKR_REQUEST = 'flickr'.freeze
	SPINNER_IMAGE = 'spinner_mid.gif'.freeze

	ib_outlet :image_preview
	
	attr_accessor :photos
  
  @@image_preview_template = <<-END_OF_STRING
    <html>
			<head>
				<style type="text/css">
					img#new {
						border-left-color: #98cb67;
						border-left-style: solid;
					} 
					img#old {}
			</style>
			</head>
      <body bgcolor="black">
				<center>
        <% @photos.each do |photo| %>
          <a href="flickr://<%=photo.web_url%>***<%=photo.flickr_photo_url%>"><img id="<%=photo.status %>" src="<%= photo.local_url%>" /></a>
          <br />
          <br />
        <% end %>
				</center>
      </body>
    </html>
  END_OF_STRING
	
	def init
		super_init
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
    notification_center.addObserver_selector_name_object(self, :blank_view, NotificationMessages::DELETE_FAVORITE_RELOAD, nil)
		
		return self
	end
  
  def preview_html
    html = ERB.new(@@image_preview_template)
    html.result(binding)
  end
	
	def	default_html
		html = <<-END_OF_STRING
			<html>
				<body bgcolor="black" />
			</html>
		END_OF_STRING
	end
	
	def loading_html
		path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
		@spinner_url = path + File::Separator + SPINNER_IMAGE
		
		html = <<-END_OF_STRING
			<html>
				<body bgcolor="black">
					<center>
					<br /> <br /> <br /> <br />
					<br /> <br /> <br /> <br />
					<br /> <br /> <br /> <br />
					<br /> <br /> <br /> <br />
					<img src="#{@spinner_url}" />
					</center>
				</body>
			</html>
		END_OF_STRING
	end
	
	def refresh_view(photos)
	  @photos = photos
	  
	  url = OSX::NSURL.URLWithString("/")
    @image_preview.mainFrame.loadHTMLString_baseURL(preview_html, url)
	end
	
	def show_downloading
		url = OSX::NSURL.URLWithString("/")
    @image_preview.mainFrame.loadHTMLString_baseURL(loading_html, url)
	end
	
	def blank_view(notification)
		url = OSX::NSURL.URLWithString("/")
    @image_preview.mainFrame.loadHTMLString_baseURL(default_html, url)
	end
	
	# policyDelegate
	# See http://developer.apple.com/documentation/Cocoa/Conceptual/DisplayWebContent/Tasks/PolicyDecisions.html
	
	def webView_decidePolicyForNavigationAction_request_frame_decisionListener(sender, actionInformation, request, frame, listener)
		if (request.URL.scheme.to_s == FLICKR_REQUEST)

		  urls = request.URL.path.to_s.split('***')
		  
		  photo_request = Hash.new
			photo_request[:http_request] = "http:" + urls[0]
			photo_request[:original_site] = urls[1]
			
			notification_center = OSX::NSNotificationCenter.defaultCenter
			notification_center.postNotificationName_object(NotificationMessages::RELOAD_IMAGE_VIEW, photo_request)
		else
			listener.use
		end
	end
    
end