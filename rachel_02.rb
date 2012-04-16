#order the list of words so look at top 50--preserve the count
#exclude common words
#score every sentence--a point for each occurence of the top 50 words
#find 50 sentences with highest score
#output those

#Day 115 -sunday -7/10/11
#
#tea;lkfjlaskdjflskadjfl'ksjdf
#
#Day 115 -sunday -7/10/11
#
#lksajdf;lkjsadl;fkjl;skdjf

#date_regex=/day\s\d\d/\i

#---
#title: Rachel's Diary
#in_menu: true
#---
#The actual sentence
#[a link][file_name.page]

class DataSet
  MAX_TO_SAVE = 20
  COMMON_WORDS_TO_REMOVE = []
  
	attr_accessor :word_counts, :text, :bigrams, :sorted_counts
	
	def initialize(file_name)
		@word_counts = {}
		@bigrams = {}
		@text = ""
		@sorted_counts = nil
		
		File.new(file_name, "r").each_line do |line|
			@text = @text + " " + line.chomp
		end
		
		File.new("common_words.txt", "r").each_line do |line|
		  COMMON_WORDS_TO_REMOVE << line.chomp.downcase
		end
		
		create_tables
		sort_counts
	end
	
	
	def create_tables
		words = []
		@text.downcase.scan(/\w+/) {|word| words << word} #adds each word to word array
		
		for i in 0..words.length - 2
			add_word(words[i], words[i + 1], @word_counts, @bigrams)
		end
		
		add_word(words.last, :end_file, @word_counts, @bigrams)
	end
	
	
	def add_word(word, next_word, count_table, bigram_table)
		bigram_table[word] ||= {}
    bigram_table[word][next_word] ||=0
    bigram_table[word][next_word] +=1
    count_table[word] ||= 0
    count_table[word] += 1
	end
	
	
	def sort_counts
	  @sorted_counts = @word_counts.sort{ |a, b| a[1] <=> b[1] }
	  @sorted_counts.delete_if { |e| COMMON_WORDS_TO_REMOVE.include? e[0].downcase }
	  @sorted_counts = @sorted_counts.drop(@sorted_counts.length - MAX_TO_SAVE) unless @sorted_counts.length - MAX_TO_SAVE < 0
	  @sorted_counts.reverse!
  end
end


class SentenceAnalyzer
  NUMBER_TO_OUTPUT = 50
  
  attr_accessor :date_groups, :date_and_sentences, :set, :final_sentences
  
  def initialize(file_name, set)
    @set = set
    @date_groups = []
    @date_and_sentences = []
    @final_sentences = []
    #date_regex = /\d\d.*\w.*\d\d\d\d/
    date_regex=/day\s\d+/i
    
    current_group = []
    
    File.new(file_name, "r").each_line do |line|
      
			if date_regex.match line.chomp
			  @date_groups << Marshal.load(Marshal.dump(current_group)) unless current_group.empty?
			  current_group.clear
			  current_group << line.chomp
			else
			  
			  current_group << line.chomp unless line.chomp.empty?
		  end
		end
		
		@date_groups << Marshal.load(Marshal.dump(current_group))
		
		split_sentences
		score_sentences
		output_best
		create_html_files
  end
  
  
  def split_sentences
    @date_groups.each do |group|
      date = group[0]
      
      entry = [date, []]

      #regex from http://stackoverflow.com/questions/860809/how-do-you-parse-a-paragraph-of-text-into-sentences-perferrably-in-ruby
      #sentences = group[1].split(/(?:(?<=\.|\!|\?)(?<!Mr\. | Dr\. | Ms\.| Mrs\.)(?<!U\.S\.A\.)\s+(?=[A-Z]))/)
      sentences = group[1].split(/(?:(?<=\.|\!|\?)(?<!Mr\.|Dr\.|Ms\.| Mrs\.)(?<!U\.S\.A\.)\s+(?=[A-Z]))/)
   
      sentences.each do |sentence|
        entry[1] << sentence
      end
      
      @date_and_sentences << entry
    end
  end
  
  
  def score_sentences
    #sentences = [[date1, [sentece1, sentence2]], [date2, [sentence1, sentence2]]]
    #counts = [[word1, count], [word2, count]]

    for i in 0...@date_and_sentences.length
      for j in 0...@date_and_sentences[i][1].length
        score = 0

        @date_and_sentences[i][1][j].downcase.scan(/\w+/) do |word|
          set.sorted_counts.each { |e| score += 1 if e.include? word }
        end

        @date_and_sentences[i][1][j] = [@date_and_sentences[i][1][j], score]
      end
    end
  end
  
  
  def output_best
    collection_of_sentences = []
    @date_and_sentences.each do |element|
      element[1].each do |sentence|
        sentence[0] = sentence[0] #+ " " + element[0]
        collection_of_sentences << sentence
      end
    end
    
    collection_of_sentences.sort!{ |a, b| a[1] <=> b[1] }
    collection_of_sentences.reverse!
    
    #print collection_of_sentences
    #puts
    #puts
    #print @date_and_sentences
    #puts
    #puts
    #print @date_groups[0]
    #puts
    #puts
    #print @date_groups[1]
    #puts
    #puts
    #puts @date_groups.length
    
    for i in 0...NUMBER_TO_OUTPUT
      @final_sentences << collection_of_sentences[i][0]
    end
  end
  
  
  def create_html_files
    #sorted_counts = [word, count]
    
    for i in 0...@final_sentences.length
      processed_sentence = process_sentence(@final_sentences[i])
      
      File.open("#{i}.html", "w") do |f|
        f.write("<html><head><style type=\"text/css\">\n")
        f.write("body {\n")
        f.write("background: #111111;\n")
        f.write("font: 60px Helvetica, Arial, sans-serif;\n")
        f.write("letter-spacing: -3px;\n")
        f.write("margin: 60px;\n")
        f.write("color: #5c5c5c;}\n")
        f.write("a {\n")
        f.write("color: #0074ae;\n")
        f.write("font-weight: bold;}\n")
        f.write("</style></head>\n")
        #f.write("<body>")
        f.write(processed_sentence)
        f.write("</html>")
      end
    end
  end
  
  
  def process_sentence(sentence)
    sentence_to_scan = sentence.clone
    
    
    sentence_to_scan.scan(/\w+/) do |word|
      set.sorted_counts.each do |e|
        if e.include? word
          #puts "IN HERE"
          index = find_sentence_with_word(sentence, word)
          #puts "index: #{index}"
          #puts "word: #{word}"
          #puts "e:"
          #print e
          #puts
          
          #puts "sentence before sub:"
          #puts sentence
          sentence.gsub!(word, "<a href=\"#{index}.html\">#{word}</a>")
          #puts "sentence after sub:"
          #puts sentence
        end
      end
    end
    
    return sentence
  end
  
  
  def find_sentence_with_word(sentence, word)
    index = @final_sentences.index sentence
    index += 1
    
    for i in index...@final_sentences.length
      if @final_sentences[i].include? word
        return i unless @final_sentences[i] == sentence
      end
    end
    
    for i in 0...@final_sentences.length
      if @final_sentences[i].include? word
        return i unless @final_sentences[i] == sentence
      end
    end
  end 
end

#-------------begin--------------

analyzer = SentenceAnalyzer.new("rachel_clean.txt", DataSet.new("rachel_clean.txt"))


#puts
#puts "Word Counts:"
#print analyzer.set.word_counts
#puts
#puts "dad: " + analyzer.set.word_counts["dad"].to_s
#puts "mom: " + analyzer.set.word_counts["mom"].to_s
#puts "gray: " + analyzer.set.word_counts["gray"].to_s
#puts "megan: " + analyzer.set.word_counts["megan"].to_s
#puts "suzanne: " + analyzer.set.word_counts["suzanne"].to_s
#puts "rachel: " + analyzer.set.word_counts["rachel"].to_s
#puts "harrison: " + analyzer.set.word_counts["harrison"].to_s
#puts "tanner: " + analyzer.set.word_counts["tanner"].to_s
#puts "bryce: " + analyzer.set.word_counts["bryce"].to_s
#puts "ryan: " + analyzer.set.word_counts["ryan"].to_s
#puts "evan: " + analyzer.set.word_counts["evan"].to_s
#puts "apinya: " + analyzer.set.word_counts["apinya"].to_s
#puts "krista: " + analyzer.set.word_counts["krista"].to_s
#puts "becky: " + analyzer.set.word_counts["becky"].to_s
#puts "school: " + analyzer.set.word_counts["school"].to_s
#puts "text: " + analyzer.set.word_counts["text"].to_s

#puts
#puts "Sorted Counts:"
#print analyzer.set.sorted_counts
#puts
#puts
#puts "Date_Sentences:"
#print analyzer.date_and_sentences
#puts
#puts
#puts "Results:"
#analyzer.output_best
