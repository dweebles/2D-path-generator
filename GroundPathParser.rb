#!/usr/bin/ruby
#
require 'rubygems'
require 'xml'
require 'builder'

# Array of parameters from command line call
parameters = ARGV

# Make sure that the number of parameters passed is greater than two
if parameters.count  == 4
	flag = 0
	svgFilename = ""
	plistOutputFilename = ""
	screenHeightValue = ""
	# help = ""
	parameters.each_with_index { | parameter, index |
		realIndex = index + 1
		if realIndex.even?
			# puts flag
			if flag == "-o" or flag == "--output"
				plistOutputFilename = parameter
				flag = 0
			elsif flag == "-i" or flag == "--input"
				svgFilename = parameter
				flag = 0
			elsif flag == "-y" or flag == "--height"
				screenHeightValue = parameter.to_i
				flag = 0
			end
		else
			flag = parameter.to_s
		end
	}

	xmlSource = XML::Parser.file(svgFilename)
	xmlContent = xmlSource.parse

	# Obtain chaser parameters
	chaserInitialPos = xmlContent.root['sf_chaserInitialPos']
	chaserMaxDistance = xmlContent.root['sf_chaserMaxDistance']
	chaserSpeed = xmlContent.root['sf_chaserSpeed']

	# Obtain star objective requirements
	star1Requirement = xmlContent.root['sf_star1_requirement']
	star2Requirement = xmlContent.root['sf_star2_requirement']
	star3Requirement = xmlContent.root['sf_star3_requirement']

	# Obtain path coordinates
	svgPath = xmlContent.root.find(".//svg:path/@d")
	svgPathContent = svgPath.first.value
	svgPathArray = svgPathContent.split(' ')

	#Obtain inverted path coodinates
	svgInvertPath = xmlContent.root.find(".//svg:path/@d")
	svgInvertPathContent = svgInvertPath.last.value
	svgInvertPathArray = svgInvertPathContent.split(' ')

	# Text node value
	gameObjects = xmlContent.root.find("svg:text")

	x = 0
	y = xmlContent.root['height'].to_i

    	state = 0
    
    	def is_upper?(string)
        		string == string.upcase
    	end
    
	if (svgPathArray.first.upcase == "M")
        
        		if (is_upper?(svgPathArray.first))
            		state = 1
        		end
		
		# Use of builder gem to create plist file        
		plistDocument = Builder::XmlMarkup.new( :indent => 3 )
		plistDocument.instruct!
		plistDocument.declare! :DOCTYPE, :plist, :PUBLIC, "-//Apple//DTD PLIST 1.0//EN", "http://www.apple.com/DTDs/PropertyList-1.0.dtd"
		plistDocument.plist("version" => "1.0") {

			# Creates root parent under dict, adds key for game objects
			plistDocument.dict{

				# Chaser values
				plistDocument.key "chaserInitialPos"
				plistDocument.real chaserInitialPos

				plistDocument.key "chaserMaxDistance"
				plistDocument.real chaserMaxDistance

				plistDocument.key "chaserSpeed"
				plistDocument.real chaserSpeed

				# Star requirements
				plistDocument.key "star1Requirement"
				plistDocument.real star1Requirement

				plistDocument.key "star2Requirement"
				plistDocument.real star2Requirement

				plistDocument.key "star3Requirement"
				plistDocument.real star3Requirement

				# Creates an array to store game objects
				plistDocument.key "pathObjects"
				plistDocument.array {

					# Loops through game objects
					gameObjects.each_with_index {| gObject, index|

					# X attribute of text nodes
					xNode = gObject['x'].to_i
					hashTable = {gObject => xNode}
					# puts hashTable.values.sort {|k, v| k[1] <=> v[1]}
					# puts hashTable.values.sort_by {|k,v| v}

					# Y attribute of text nodes
					yNode = gObject['y'].to_i
					yNode =  y - yNode

					# Type attribute
					textVal = gObject.content

						# Creates new xml node with text node value, x and y coordinates
						pathDictionary = plistDocument.dict {
							plistDocument.key "x"
                                    				plistDocument.integer xNode
                                    				plistDocument.key "y"
                                    				plistDocument.integer yNode
                                    				plistDocument.key "type"
                                    				plistDocument.string textVal
                                    			}
					}
				}

				plistDocument.key "path"
				# plistDocument.array {
					# Creates an array to store path coordinates, creates key for path objects
					plistDocument.array {
						svgPathArray.each_with_index { | pathComponent, index |
							if (index > 0)
	                            					coords = pathComponent.split(',')
	                            
								if (coords.first.upcase == "L")
	                                						if (is_upper?(coords.first))
	                                    						state = 1
	                                						else
	                                    						state = 0
	                                						end
								else
	                                						if (state == 1)
	                                    						y = 640
	                                    						x = 0
									end

	                                						x = coords.first.to_i + x
	                                						y = y - coords.last.to_i

	                                						# puts y

	                                						# Adds x and y values to path dictionary
	                                						pathDictionary = plistDocument.dict {
	                                    						plistDocument.key "x"
	                                    						plistDocument.real x
	                                    						plistDocument.key "y"
	                                    						plistDocument.real y
	                                						}
	                            					end
							end
						}
					}
					# Started inverted level creation
					# 
					# 
					# plistDocument.array {
					# 	svgInvertPathArray.each_with_index { | pathComponent, index |
					# 		if (index > 0)
	    #                         					coords = pathComponent.split(',')
	                            
					# 			if (coords.first.upcase == "L")
	    #                             						if (is_upper?(coords.first))
	    #                                 						state = 1
	    #                             						else
	    #                                 						state = 0
	    #                             						end
					# 			else
	    #                             						if (state == 1)
	    #                                 						y = 640
	    #                                 						# x = 0
					# 				end

	    #                             						x = coords.first.to_i + x
	    #                             						y = y - coords.last.to_i

	    #                             						# puts x

	    #                             						# Adds x and y values to path dictionary
	    #                             						pathDictionary = plistDocument.dict {
	    #                                 						plistDocument.key "x"
	    #                                 						plistDocument.real (x - 19000)
	    #                                 						plistDocument.key "y"
	    #                                 						plistDocument.real y
	    #                             						}
	    #                         					end
					# 		end
					# 	}
					# }
				# }
			}
		}
		plistDocumentFilename = File.open(plistOutputFilename, "w")
		plistDocumentFilename << plistDocument.target!
		plistDocumentFilename.close

	else
		# TODO: Fail gracefully
        		puts "failed"
	end
else
	# Display warning for missing parameters
	puts "GroundPathParser expects at least four parameters."
end
