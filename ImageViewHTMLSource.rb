#
#  ImageViewHTMLSource.rb
#  flickrViewer2
#
#  Created by Nicholas Chen on 7/14/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

class ImageViewHTMLSource < OSX::NSObject

	LOGO = 'logo.gif'.freeze
	WEB_REQUEST = 'http'.freeze

	ib_outlet :image_view, :photo_url
	
	@@image_view_template = <<-END_OF_STRING
    <html>
      <body bgcolor="black">
				<center>
				  <br /><br /><br /><br />
					<br /><br /><br />
          <a href="<%=@flickr_photo_url %>"><img src="<%= @photo_url%>" alt="Click to open flickr page in default browser" /></a>
          <br />
          <br />
				</center>
      </body>
    </html>
  END_OF_STRING
	
	@@blank_image_reload = <<-END_OF_STRING
		<html>
			<body bgcolor="black" />
		</html>
	END_OF_STRING
			
	def init
		super_init
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
    notification_center.addObserver_selector_name_object(self, :reload_image_view, NotificationMessages::RELOAD_IMAGE_VIEW, nil)
		notification_center.addObserver_selector_name_object(self, :blank_image_reload, NotificationMessages::BLANK_IMAGE_RELOAD, nil)
		
		return self
	end
	
	def dealloc
    OSX::NSNotificationCenter.defaultCenter.removeObserver(self)
    super_dealloc
  end
  
  def reload_image_view(notification)
    @photo_url = notification.object[:http_request]
    @flickr_photo_url = notification.object[:original_site]
    url = OSX::NSURL.URLWithString("/")
    @image_view.mainFrame.loadHTMLString_baseURL(preview_html, url)
  end
	
	def blank_image_reload(notification)
		url = OSX::NSURL.URLWithString("/")
    @image_view.mainFrame.loadHTMLString_baseURL(@@blank_image_reload, url)
	end
	
	def	default_html
		path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
		logo_url = path + File::Separator + LOGO
		
		html = <<-END_OF_STRING
			<html>
				<body>
					<center>
						<br /><br /><br /><br />
						<br /><br /><br /><br />
						<br /><br /><br /><br />
						<br /><br /><br /><br />
						<img src="#{logo_url}"/>
					</center>
				</body>
			</html>
		END_OF_STRING
  end
  
  def preview_html
    html = ERB.new(@@image_view_template)
    html.result(binding)
  end
  
  # policyDelegate
	# See http://developer.apple.com/documentation/Cocoa/Conceptual/DisplayWebContent/Tasks/PolicyDecisions.html
	
	def webView_decidePolicyForNavigationAction_request_frame_decisionListener(sender, actionInformation, request, frame, listener)
		if (request.URL.scheme.to_s == WEB_REQUEST)
			# Opens this in the default browser
		  OSX::NSWorkspace.sharedWorkspace.openURL(request.URL)
		  listener.ignore
		end
		listener.use
	end
end