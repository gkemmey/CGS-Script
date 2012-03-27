class DataSet
  attr_accessor :table, :word_counts, :words, :name


  def initialize(files, name)
    @name = name
    @words = []
    @word_counts = {}
    @table = {}

    for i in 0...files.length
      File.open(files[i], "r").each_line do |line|
        line.downcase.scan(/\w+/) do |word|
          @words << word
        end
      end
    end

    create_table
  end


  def add_word (word, next_word)
    @table[word] ||= {}
    @table[word][next_word] ||=0
    @table[word][next_word] +=1
    @word_counts[word] ||= 0
    @word_counts[word] += 1
  end


  def create_table
    for i in 0...@words.length - 1
      add_word(@words[i], @words[i + 1])
    end

    add_word(@words.last, :end_file)
  end


  def percent_error(other_set)
    total = 0.0
    @table.keys.each do |k|
      
      if(other_set.table[k] == nil)
        total += 1.0

      else  
        this_prob = @word_counts[k].to_f/@words.length
        other_prob = other_set.word_counts[k].to_f/other_set.words.length       

        total += ((other_prob-this_prob.to_f)/this_prob).abs
      end
    end

    return total
  end
end

#----------begin---------
files = []
files << "test.txt"

test_set = DataSet.new(files, "test")
puts test_set.word_counts
