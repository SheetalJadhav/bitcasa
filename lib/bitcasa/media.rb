require_relative 'file.rb'
module Bitcasa
		
	# Photo class initializes the type of the file
	class Photo < File; end

	# Video class initializes the type of the file
	class Video < File; end

	# Audio class initializes the type of the file
	class Audio < File; end

	# Document class initializes the type of the file
	class Document < File; end

end
