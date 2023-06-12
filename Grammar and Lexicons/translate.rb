class Translator

	attr_accessor :lexicon, :grammar

	def initialize(words_file, grammar_file)
				@lexicon = {}
		@grammar = {}
		updateLexicon(words_file)
		updateGrammar(grammar_file)

	end

	def updateLexicon(inputfile)
		File.readlines(inputfile).each do |line|
			if line =~ /^([a-z]+-?[a-z]*), ([A-Z]{3}), (([A-Z][a-z0-9]*:[a-z]+-?[a-z]+, )*[A-Z][a-z0-9]+:[a-z]+-?[a-z]+)$/
				word = $1
				pos = $2
				word_copy = word
				defaultlang = "English"
				if !@lexicon[word]
					@lexicon[word] = {}
				end
				# Check if the part of speech exists for the word
				if !@lexicon[word][pos]
					@lexicon[word][pos] = {}
				end
				# Map the first translation to the default language
				@lexicon[word][pos][defaultlang] = word_copy
								# translations are comma separated LX: blue, L...
				translations = $3.split(', ')
				# for each translation
				translations.each do |translation|
										if translation =~  /^([A-Z][a-z0-9]+):([a-z]+-?[a-z]+)$/
						lang = $1
						wordx = $2
												if !@lexicon[word]
							@lexicon[word] = {}
						end
						if @lexicon[word][pos].nil?
							@lexicon[word][pos] = {}
						end
												@lexicon[word][pos][lang] = wordx
											end
				end
			end
		end
	end

	def updateGrammar(inputfile)

		File.readlines(inputfile).each do |line|
			if line =~ (/^([A-Z][a-z0-9]*)\s*:\s*([A-Z]{3}(\{[1-9]\d*\})?(,\s*[A-Z]{3}(\{[1-9]\d*\})?)*)$/)
								lang = $1
				pos_num = $2.split(',')
								# initializing a hash for the grammar
				if !@grammar[lang]
					@grammar[lang] = []
				end
												pos_arr = Array.new() 
				# adding it to the hash of grammars
				pos_num.each do |pos_num|
					# so it contains {} it means the repeated time of the POS
					#ADJ{#2}, ADJ, #2}
					if pos_num.include?('{')
						# if it contains a {} thus split in 2, one being POS and second being the 'count'
						pos, count = pos_num.split('{')
						# removing the closing bracket
						count = count.delete_suffix('}')
					else
						# no{#}
						pos = pos_num
						# appears once only
						count = 1
					end
					#adding the pos 'count' amount times
					count.to_i.times do |i|
						pos_arr << pos.strip
					end 
				end
				#add it to the language hash in the end
				@grammar[lang] = pos_arr
				# {"German" => ["DET", "ADJ", "ADJ", "NOU", "ADV"]}
							end
		end
	end


	#struct could either be an array of POS or a lanuguage
	def generateSentence(language, struct)
		if @lexicon.empty?
			return nil
		end
				# If struct is a string, use the grammar for that language to determine the POS structure
		if struct.is_a?(String)
			#struct is now an array of POS(from the struct)
			return nil unless @grammar[struct]
			struct = @grammar[struct]
		end

		# If struct is an array, use it as a collection of POS to generate the sentence
		sentence = ""
		# For each POS in the struct
		# Check if the POS exists in the language's grammar

		struct.each do |pos|
			words = find_translation(language, pos)

			if words.empty?
				return nil
			end
			word = words.length == 1 ? words[0] : words.sample

			sentence += " " + word

								end
		# Remove leading/trailing spaces and returning the sentence 
		return sentence.strip

	end
	
	def checkGrammar(sentence, language)
		return false if sentence.nil? || sentence.empty?
		return false unless @grammar[language]

		arr_sentence = sentence.split(' ')
		#getting the grammar structure

		pos_struct = @grammar[language]

		return false unless arr_sentence.length == pos_struct.length

		#for each parts of speec get all the possible set of lexicon match
						(0...arr_sentence.length).each do |i|
			pos = pos_struct[i]
			word = arr_sentence[i]
			translations = find_translation(language, pos)
			#if out of all the possble translations for the given pos, if the arr_sentence is one of it continue with the next index
			return false unless translations.include?(word)
		end
		return true
	end

	#A helper method that given a language and a pos it returns an array of its translation 
	def find_translation(language, pos)
		translations = []

		@lexicon.each do |word, word_hash|
			if word_hash.key?(pos) && word_hash[pos].key?(language)
				translations << word_hash[pos][language]
			end
		end
		return translations
	end

	def changeGrammar(sentence, struct1, struct2)

		#we are gonna assume that if it is a string then it is a language  name
		#retrive the POS
		return nil if sentence.nil? || struct1.nil? || struct2.nil?

		if struct1.is_a?(String)
			return nil if !@grammar[struct1]
			struct1 = @grammar[struct1]
		end
		if struct2.is_a?(String)
			return nil if !@grammar[struct2]
			struct2 = @grammar[struct2]
		end 

		#Struct2 must contain all the POS tags of struct1 and their length should match
		if struct1.is_a?(Array) && struct2.is_a?(Array)
			return nil unless struct1.length == struct2.length
			return nil unless struct1.all? { |element| struct2.include?(element) }
			return nil unless struct2.all? { |element| struct1.include?(element) }
		end
		map_word = {}

		#store it the same way as the grammar structtures so duplicate keys are handled
		#el , el , camion
		#DET DET NOU
		#{el[DET DET]}
		#so we can delte it every occurance 

		sentence.split.each_with_index do |word, i|
			pos = struct1[i]
			if map_word[word].nil?
				map_word[word] = [pos]
			else
				map_word[word] << pos
			end
		end

		sentence_new = []
		struct2.each do |pos|

			word = map_word.find { |word, pos_array| pos_array.include?(pos) }

			if word.nil?
				return nil
			else
				sentence_new << word[0]
				pos_index = word[1].index(pos)
				word[1].delete_at(pos_index)
				#unnescary but just delete the word
				map_word.delete(word[0]) if word[1].empty?
			end
		end
		return sentence_new.join(' ')
	end


	
	# part 3
	#Note: we dont care about the grammar structure of language2 so just go off of language1's POS tags

	def changeLanguage(sentence, language1, language2)
		if sentence.nil?
			return nil
		end
		words = sentence.split(" ")
		struct = @grammar[language1]
		if struct.nil?
			return nil
		end
		translated_sentence = ""
				words.each_with_index do |word, i|
			pos = struct[i]
			translations = find_translation(language2, pos)
						if translations.empty?
				return nil
			end

			super_key = find_super_key(word, language1)

			translated_word = nil
			translations.each do |translation|
				translated_super_key = find_super_key(translation, language2)
				if super_key == translated_super_key
					translated_word = translation
					break
				end
			end

			if translated_word.nil?
				return nil
			end

			translated_sentence += translated_word
			translated_sentence += " "
		end
				return translated_sentence.strip
	end

	#A helper method that finds the super key of a word given a language
	def find_super_key(word, language)
		lexicon.each do |key, value|
			if value.any? { |pos, translations| translations[language] == word }
				return key
			end
		end
		return nil
	end

	def translate(sentence, language1, language2)

		sentence_i = changeLanguage(sentence, language1,language2)
		final_sentence = changeGrammar(sentence_i, language1, language2 )
		return final_sentence

	end
end