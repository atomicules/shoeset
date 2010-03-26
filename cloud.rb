# Taken from http://snippets.dzone.com/posts/show/6027
# Tweaked to return values suitable for Shoes (lines 38-40, etc)
class TagCloud
    

  def initialize(words)
    @wordcount = count_words(words)
  end
  

  def count_words(words)
    wordcount = {}
    words.split(/\s/).each do |word| 
      word.downcase!
      if word.strip.size > 0
        unless wordcount.key?(word.strip)
          wordcount[word.strip] = 0
        else
          wordcount[word.strip] = wordcount[word.strip] + 1
        end
      end
    end
    wordcount
  end
  

  def font_ratio(wordcount={})
    min, max = 1000000, -1000000
    wordcount.each_key do |word|
      max = wordcount[word] if wordcount[word] > max
      min = wordcount[word] if wordcount[word] < min
    end
    18.0 / (max - min)
  end
  

  def build
    cloud = String.new
    ratio = font_ratio(@wordcount)
	ratio = 1 if ratio.infinite?
	debug(ratio) #Need to fix for infinity
	color = ["steelblue", "deeppink"]
    @wordcount.each_key do |word|
      font_size = (10 + (@wordcount[word] * ratio)).round #must round for shoes since pixels
	  cloud << %Q{para "#{word}", :size => #{font_size}, :stroke => #{color[0]}; }
	  color.reverse! #alternate between colours
    end
    cloud
	#debug cloud
  end


end


