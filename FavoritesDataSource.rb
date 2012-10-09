#
#  FavoritesDataSource.rb
#  FlickrViewer
#
#  Created by Nicholas Chen on 7/11/07.
#  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'yaml'
require 'FileLocations'
require 'NotificationMessages'

class FavoritesDataSource < OSX::NSObject

  ib_action :show_add_menu
  ib_action :add_user
  ib_action :remove
  ib_action :save
	ib_action :mark_selected_viewed
  
  ib_outlet :add_favorite_panel
  ib_outlet :username_textfield
  ib_outlet :warning_textfield
  ib_outlet :outline_view
	ib_outlet :download_progressbar
	ib_outlet :remove_button
  
  def init
    super_init
    @flickr = FlickrConnection.new.flickr
    read_stored_favorites
    return self
  end
	
	def awakeFromNib
		@download_progressbar.setUsesThreadedAnimation(true)
	end
  
  def read_stored_favorites
  
    @favorites = Array.new
    
    if File.exists?(FileLocations::FAVORITES_FILE)
      favorites_array = YAML::load(File.open(FileLocations::FAVORITES_FILE))
			
			favorites_array.each do |element|
				favorite = Favorite.alloc.init
				favorite.from_simple_yaml(element)
				@favorites << favorite
			end
			
    end
  end
  
  def show_add_menu
    OSX::NSLog("Adding new user...")
  
    # Reset string values
    @username_textfield.setStringValue("") 
    @warning_textfield.setStringValue("")
    @add_favorite_panel.makeKeyAndOrderFront(self)
  end
  
  def add_user(username = nil)
    if(username.nil?)
			newUser = @username_textfield.stringValue.to_s
		else
			newUser = username
		end
    
    begin
      person = @flickr.people.findByUsername(newUser)
      add_to_favorites(person)
      @add_favorite_panel.orderOut(self) # hide the panel
    
    rescue SocketError
      @warning_textfield.setStringValue("No network connection.")
    rescue XMLRPC::FaultException
      @warning_textfield.setStringValue("No such user.")
    rescue DuplicateUserException
      @warning_textfield.setStringValue("User already added.")
    end
    
  end
  
  def add_to_favorites(person)
    favorite = Favorite.alloc.initUsername_userid(person.username, person.nsid)
  
    addPhotoSetsFrom_to(person, favorite)
    
    raise DuplicateUserException if @favorites.include?(favorite)
    
    @favorites << favorite
    
    @outline_view.reloadData
  end
  
  def addPhotoSetsFrom_to(person, favorite)
    photosets = @flickr.photosets.getList(person)
    photosets.each do |set|
      photoset = PhotoSet.alloc.initTitle_id_username_userid(set.title, set.id, favorite.username, favorite.userid)
      
      favorite.photosets << photoset
    end
  end
  
  def remove
    OSX::NSLog("Removing user...")
		
    item = @outline_view.itemAtRow(@outline_view.selectedRow)
		
		configure_remove_undo(item)
    
    item.removeFrom(@favorites)
    save
    @outline_view.reloadData
  end
	
	def configure_remove_undo(item)
		undo_manager = request_undoManager
		(undo_manager.prepareWithInvocationTarget(self)).add_user(item.username)
		OSX::NSLog(item.username)
		
		unless undo_manager.isUndoing?
			undo_manager.setActionName("Remove #{item.username}")
		end
	end
	
	def request_undoManager
		OSX::NSApp.mainWindow.undoManager
	end
  
  def save
		yaml = Array.new
		
		@favorites.each do |favorite|
			yaml << favorite.to_simple_yaml
		end
		
    File.open(FileLocations::FAVORITES_FILE, "w") { |file| YAML.dump(yaml, file)}
  end
	
	def mark_selected_viewed
		item = @outline_view.itemAtRow(notification.object.selectedRow)
		item.mark_as_viewed
	end
	
	def force_refresh
		OSX::NSLog("Favorite list selection changed")
    
    item = @outline_view.itemAtRow(@outline_view.selectedRow)
    
    unless item.nil?			   			
			@download_progressbar.setDoubleValue(0.0)
      item.refresh_photos_from_web(@download_progressbar)
		end 
    
    save #automatically saves
	end
  
  #
  # Data source methods
  #
  
  def outlineView_child_ofItem(outlineView, index, item)
    item == nil ? @favorites[index] : item.childAt(index)
  end
    
  def outlineView_isItemExpandable(outlineView, item)
    return item.expandable?
  end
    
  def outlineView_numberOfChildrenOfItem(outlineView, item)
    item == nil ? @favorites.size : item.children
  end
    
  def outlineView_objectValueForTableColumn_byItem(outlineView, tableColumn, item)
    return item.displayName 
  end
  
  def outlineView_setObjectValue_forTableColumn_byItem(outlineView, object, tableColoumn, item)
  
  end  
  
  #
  # Delegate nethods
  #
  
  def selectionShouldChangeInOutlineView(notification)
    true
  end
	
	def outlineView_willDisplayCell_forTableColumn_item(outlineView, cell, tableColumn, item)
		
  end
	
  def outlineViewSelectionDidChange(notification)
    OSX::NSLog("Favorite list selection changed")
    
    item = @outline_view.itemAtRow(notification.object.selectedRow)
    
    unless item.nil?			
      item.load_photos_from_disk(@download_progressbar)
			@remove_button.setEnabled(item.removable?)
    end 
    
    save
		
		notification_center = OSX::NSNotificationCenter.defaultCenter
		notification_center.postNotificationName_object(NotificationMessages::BLANK_IMAGE_RELOAD, self) 
	end
	
end

class DuplicateUserException < Exception
end


