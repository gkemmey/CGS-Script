File.new("common_words.txt", "r").each_line do |line|
  puts line.split(' ')[1]
end