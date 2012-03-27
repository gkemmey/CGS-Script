#order the list of words so look at top 50--preserve the count
#exclude common words
#score every sentence--a point for each occurence of the top 50 words
#find 50 sentences with highest score
#output those

class DataSet
  MAX_TO_SAVE = 3
  COMMON_WORDS_TO_REMOVE = ["my", "i", "the", "to"]
  
	attr_accessor :word_counts, :text, :bigrams, :sorted_counts
	
	def initialize(file_name)
		@word_counts = {}
		@bigrams = {}
		@text = ""
		@sorted_counts = nil
		
		File.new(file_name, "r").each_line do |line|
			@text = @text + " " + line.chomp
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
  NUMBER_TO_OUTPUT = 3
  
  attr_accessor :date_groups, :date_and_sentences, :set
  
  def initialize(file_name, set)
    @set = set
    @date_groups = []
    @date_and_sentences = []
    date_regex = /\d\d.*\w.*\d\d\d\d/
    
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
  end
  
  
  def split_sentences
    @date_groups.each do |group|
      date = group[0]
      
      entry = [date, []]

      #regex from http://stackoverflow.com/questions/860809/how-do-you-parse-a-paragraph-of-text-into-sentences-perferrably-in-ruby
      sentences = group[1].split(/(?:(?<=\.|\!|\?)(?<!Mr\.|Dr\.)(?<!U\.S\.A\.)\s+(?=[A-Z]))/)
   
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
        sentence[0] = sentence[0] + " " + element[0]
        collection_of_sentences << sentence
      end
    end
    
    collection_of_sentences.sort!{ |a, b| a[1] <=> b[1] }
    collection_of_sentences.reverse!
    
    for i in 0...NUMBER_TO_OUTPUT
      puts collection_of_sentences[i][0]
    end
  end 
end

#-------------begin--------------

analyzer = SentenceAnalyzer.new("test.txt", DataSet.new("test.txt"))

puts
puts "Word Counts:"
print analyzer.set.word_counts
puts
puts
puts "Sorted Counts:"
print analyzer.set.sorted_counts
puts
puts
puts "Date_Sentences:"
print analyzer.date_and_sentences
puts
puts
puts "Results:"
analyzer.output_best
