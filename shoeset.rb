Shoes.setup do
	gem 'flickraw'
end

require 'flickraw'
require 'yaml'
require 'cloud'


Shoes.app do

	FlickRaw.api_key=""
	FlickRaw.shared_secret=""
	
	TOKENFILE = ENV['HOME']+"\\.shoeset.yml"
	#Load token if it exists
	if File.exists?(TOKENFILE)
				$SETTINGS = YAML::load(File.read(TOKENFILE))
				@token = $SETTINGS["Token"]
				auth = flickr.auth.checkToken :auth_token => @token
	else

		frob = flickr.auth.getFrob
		auth_url = FlickRaw.auth_url :frob => frob, :perms => 'read'
	
		para "Click to authorise with Flickr : ", link("Authorise", :click =>auth_url)
		para "Click OK when you are finished."
		@okbutton = button "OK" do
			begin
				auth = flickr.auth.getToken :frob => frob
				
				$SETTINGS = { "Token" => auth.token }
				f = File.open(TOKENFILE, 'w')
				f.write(YAML.dump $SETTINGS)
				f.close

			rescue FlickRaw::FailedResponse => e
				para "Authentication failed : #{e.msg}"
			end
		end
	end
	login = flickr.test.login
	para "You are authenticated as #{login.username} with token #{auth.token}"
	@setlist = []
	@photosetlist = flickr.photosets.getList.each do |set|
		@setlist << set["title"]
	end

	list_box :items => @setlist, 
		:chose => @setlist[0] do |set|
			para set.text
			photosetinfo = @photosetlist.select {|s| s["title"] == set.text}
			debug(photosetinfo)
			debug photosetinfo[0]["id"].to_s #it's an array of a hash. Even though just one
			photosetphotos = flickr.photosets.getPhotos(:photoset_id => photosetinfo[0]["id"] )
			debug(photosetphotos["photo"])
			array = []
			photosetphotos["photo"].each do |photo|
				debug flickr.tags.getListPhoto(:photo_id => photo["id"])
				temp = flickr.tags.getListPhoto(:photo_id => photo["id"])
				temp["tags"].each do |tags| #should be an array
					array << tags["_content"]
				end
				debug array

				# Caching - anyway? Could cache list of photos from set, but then what about if updated?
				# Sleep interval between calls.
			end

		cloud = TagCloud.new(array.join(" "))
		eval cloud.build
		debug cloud.build
		end
	
end



