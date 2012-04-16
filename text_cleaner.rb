def clean_line line
  for i in 0...line.length
    if line[i] == "."
      for j in i...line.length
        if /[a-z]/i.match line[j]
          line[j] = line[j].upcase
          break
        end
      end
    end
  end
end

#---------------
text = ""

File.new("rachel.txt", "r").each_line do |line|
  clean_line line
  text += line
end

File.open("rachel_clean.txt", "w") do |f|
  f.write(text)
end