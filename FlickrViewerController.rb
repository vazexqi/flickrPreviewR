#
#  FlickrViewerController.rb
#  FlickrViewer
#
#  Created by Nicholas Chen on 7/11/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'erb'
require 'NotificationMessages'
require 'ImagePreviewHTMLSource'
require 'ImageViewHTMLSource'

OSX.require_framework "WebKit"

class FlickrViewerController < OSX::NSObject
	
	ib_outlet :image_preview
	ib_outlet :image_view 
	ib_outlet :favorites_drawer
	ib_outlet :status_textfield
	
	attr_reader :undo_manager
	
	def init
		super_init
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
    notification_center.addObserver_selector_name_object(self, :reload_image_preview, NotificationMessages::RELOAD_IMAGE_PREVIEW, nil)
		notification_center.addObserver_selector_name_object(self, :indicate_downloading, NotificationMessages::DOWNLOADING_INDICATOR, nil)
		
		OSX::NSApp.setDelegate(self)
    
		return self
	end
	
	def dealloc
    OSX::NSNotificationCenter.defaultCenter.removeObserver(self)
    super_dealloc
  end
	
	def reload_image_preview(notification)
		@status_textfield.setStringValue("")
		@image_preview_source_provider.refresh_view(notification.object.file_list)
  end
	
	def	indicate_downloading(notification)
		@image_preview_source_provider.show_downloading
	end
	
	def awakeFromNib
	
		@image_view_source_provider = ImageViewHTMLSource.alloc.init
		@image_view_source_provider.image_view = @image_view
		
		@image_preview_source_provider = ImagePreviewHTMLSource.alloc.init
		@image_preview_source_provider.image_preview = @image_preview
		
		@favorites_drawer.openOnEdge(0) # this is based on the values in NSRectEdge. Had trouble resolving the enum, so used the numbers directly
		
		image_preview_browser = @image_preview.mainFrame
		image_preview_browser.loadHTMLString_baseURL(@image_preview_source_provider.default_html, nil)
		
		image_view_browser = @image_view.mainFrame
		url = OSX::NSURL.URLWithString("/")
    @image_view.mainFrame.loadHTMLString_baseURL(@image_view_source_provider.default_html, url)
	end
	
	#
	# NSApplication Delegate Methods
	#
	
	def applicationShouldTerminateAfterLastWindowClosed(application)
		true
	end
	
	#
	# NSWindow (parent window) delegate
	#
	def windowWillReturnUndoManager(window)
		if(@undo_manager.nil?)
			@undo_manager = OSX::NSUndoManager.alloc.init
		end
			@undo_manager
	end
	
end