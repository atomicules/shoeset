Shoes.setup do
	gem 'flickraw'
end

require 'flickraw'
require 'yaml'
require 'cloud'

	
Shoes.app :title => "Shoeset" do

	
	KEYFILE = "keys.yml"
	KEYS = YAML::load(File.read(KEYFILE))
	FlickRaw.api_key=KEYS["api_key"]
	FlickRaw.shared_secret=KEYS["shared_secret"]
	TOKENFILE = ENV['HOME']+"\\.shoeset.yml"



	#Need to improve GUI feedback/responsive on opening. Thread??
	def login
		if File.exists?(TOKENFILE) #Load token if it exists
					$SETTINGS = YAML::load(File.read(TOKENFILE))
					@token = $SETTINGS["Token"]
					@auth = flickr.auth.checkToken :auth_token => @token
					@login = flickr.test.login
					@container.clear{ui} #draw ui 		
		else
			frob = flickr.auth.getFrob
			auth_url = FlickRaw.auth_url :frob => frob, :perms => 'read'
		
			para "Click to ", link("authorise", :click =>auth_url), " with Flickr."
			para "Click OK when you are finished."
			@okbutton = button "OK" do
				begin
					@auth = flickr.auth.getToken :frob => frob
					$SETTINGS = { "Token" => @auth.token }
					f = File.open(TOKENFILE, 'w')
					f.write(YAML.dump $SETTINGS)
					f.close
					@login = flickr.test.login
					@container.clear{ui} #draw ui
				rescue FlickRaw::FailedResponse => e
					para "Authentication failed : #{e.msg}"
				end
			end
		end
	end


	def ui
		flow do
			para "You are logged in as "
			para link(@login.username){@token.toggle}
			button "Logout", :displace_left => 10 do
				logout
			end
		end
		@token = para "Token: #{@auth.token}"
		@token.hide
		@setlist = []
		@loadingsetlist = para "Loading sets..."
		@animatelist = animate(5) do |frame|
			weight = ["bold", "normal"]
			@loadingsetlist.style(:weight => weight[frame&1])
		end
		@photosetlist = flickr.photosets.getList.each do |set|
			@setlist << set["title"]
		end
		@animatelist.stop
		@loadingsetlist.hide
		flow do
			para "Pick a set to generate Tag Cloud: "
			@listbox = list_box :items => @setlist do |set|
					if $p.nil? or $p.fraction() == 1.0 	#because this is threaded, must check to see if already running
						@currentset = set.text
						fluffygen(set)
					else #if user picks another set, put selected back to original choice if running.
						#debug(@currentset)
						@listbox.choose(@currentset) #Set to 
					end
				end
		end #flow
		@tagcloud = flow do #if this is a stack then clearing it goes crazy
			para ""
		end #set-up placeholder for tag cloud
	end
	

	def logout
		#remove token file
		File.delete(TOKENFILE)
		#clear window and restart
		@container.clear
		login
	end

	
	def fluffygen(set)
		@tagcloud.clear #is this because it's on a global variable that it clears everything???? Nope
		$p = progress :width => 0.8, :displace_left => 10
		#debug(set.text)
		photosetinfo = @photosetlist.select {|s| s["title"] == set.text}
		#debug(photosetinfo)
		count = photosetinfo[0]["photos"].to_f
		counter = 0.0
		#debug photosetinfo[0]["id"].to_s #it's an array of a hash. Even though just one
		photosetphotos = flickr.photosets.getPhotos(:photoset_id => photosetinfo[0]["id"] )
		#debug(photosetphotos["photo"])
		$array = []
		Thread.new do
			photosetphotos["photo"].each do |photo|
				#debug flickr.tags.getListPhoto(:photo_id => photo["id"])
				temp = flickr.tags.getListPhoto(:photo_id => photo["id"])
				temp["tags"].each do |tags| #should be an array
					$array << tags["_content"]
				end
				#debug $array
				sleep(1) # Sleep interval between calls.
				counter += 1.0
				$p.fraction = counter/count
				#debug (counter/count)
				# Caching - anyway? Could cache list of photos from set, but then what about if updated?
			end
			#debug $array
			cloud = TagCloud.new($array.join(" "))
			$p.hide
			#debug cloud.build
			@tagcloud.clear{eval cloud.build}
		end
	end

	

	@container = stack do
		@loading = para "Loading..."
	end
	@animate = animate(5) do |frame|
		weight = ["bold", "normal"]
		@loading.style(:weight => weight[frame&1])
	end
	Thread.new do 
		login
	end

end



