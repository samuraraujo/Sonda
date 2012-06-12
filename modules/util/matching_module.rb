#Serimi Functionalities.
#it implements string matching functions used to filter the candidate resources.
#Author: Samur Araujo
#Date: 10 september 2011.
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
 def jaccard(x,y)
    return 1.0 if x.size ==0 and y.size ==0
    (((x&y).size.to_f))/(((x+y).uniq.size.to_f))
  end

  def dice(x,y)
    ((2*(x&y).size.to_f))/((x).size.to_f+(y).size.to_f)
  end

  def betha(x,y)
    1 / (1 + ((x&y).size.to_f))
  end

  def betha2(x,y)
    1 /  (((x+y).size.to_f))
  end

  def tversky(x,y,alpha,betha)
    #   (((x&y).size.to_f) )/ (((x&y).size.to_f) + (alpha.to_f*(x-y).size.to_f) + (betha.to_f*(y-x).size.to_f))
    (((x&y).size.to_f) - (alpha.to_f*(x-y).uniq.size.to_f) - (betha.to_f*(y-x).uniq.size.to_f))
  end
 def ratiotversky(x,y)
   a = betha2(x,y)
  ratio(x,y,a,a)
  end
  def ratio(x,y,alpha,betha)
   (((x&y).size.to_f) ) / (((x&y).size.to_f) + (alpha.to_f*(x-y).size.to_f) + (betha.to_f*(y-x).size.to_f))
  end

def median(x)
  sorted = x.sort
  mid = x.size/2
  sorted[mid]
end

def mean(array)
  array.inject(0) { |sum, x| sum += x } / array.size.to_f
end

def mean_and_standard_deviation(array)
  m = mean(array)
  variance = array.inject(0) { |variance, x| variance += (x - m) ** 2 }
  return m, Math.sqrt(variance/(array.size))
end

def bigram_matching(a,b)
  s1 = a.keyword_normalization.removeaccents
  s2 = b.keyword_normalization.removeaccents

  s1_aa=(s1.split(" "))
  s2_aa=(s2.split(" "))

  s1_a=(s1_aa-$stopwords)
  s2_a=(s2_aa-$stopwords)
  
  s1_nsw= s1_a.join(" ")
  s2_nsw= s2_a.join(" ")
  ba = s1_nsw.downcase.scan(/.{2}/)
  bb = s2_nsw.downcase.scan(/.{2}/)
  
  jaccard(a,b)
  
end
def advanced_string_matching(a,b)
  
  # score = a.jarowinkler_similar(b) 
  # return score
  
  s1 = a.keyword_normalization.removeaccents
  s2 = b.keyword_normalization.removeaccents

  s1_aa=(s1.split(" "))
  s2_aa=(s2.split(" "))

  s1_a=(s1_aa-$stopwords)
  s2_a=(s2_aa-$stopwords)

  #it is importante to add a measure that does not consider order and it very sensitive to dissimilarity.
  #for this reason we added the jaccard similarity between the token after the stop words.

  ######
  s1_nsw= s1_a.join(" ")
  s2_nsw= s2_a.join(" ")

  score=0

  #match normally both strings
  
  # return ratiotversky(s1_aa,s2_aa).to_f

  score1 =  [xmatch_with_expansion(s1,s2).to_f,jaccard(s1_aa,s2_aa).to_f ].max
  # puts score1
  score = score1
  #match without stopwords
  if s1_nsw.size > 0 and s2_nsw.size > 0
    score2 = xmatch_with_expansion(s1_nsw,s2_nsw).to_f
    # puts score2
    score3= jaccard(s1_a,s2_a)
    # puts score3
    score = (score1 + ([score2,score3].max))/2
  end
  # puts "score"
  # puts score

  return score.to_f
end
 

def fmeasure(a,b)
  return 0.0 if a == 0 || b == 0
  2.0 * (a * b)  / (a+b)
end



def serimi_string_matching(a,b)
  # puts a
  # puts b
  aa = a.split(" ")
  bb = b.split(" ")

  expanded = expander(expander_aux(aa,bb) )
  _a = []
  _a << a
  expanded.each{|x|
    if x.instance_of? Array
      x.each{|s| _a << s
      }
    else
    _a << x
    end
  }

  aa = a.split(" ")
  bb = b.split(" ")

  expanded = expander( expander_aux(bb,aa) )
  _b = []
  _b << b
  expanded.each{|x|
    if x.instance_of? Array
      x.each{|s|
        _b << s
      }
    else
    _b << x
    end
  }
  _a.map!{|x| x.to_s.split(" ").sort.join(" ")}
  _b.map!{|x| x.to_s.split(" ").sort.join(" ")}

  _a.uniq!
  _b.uniq!

  max_jaro = 0
  _a.each{|x|
    _b.each{|y|
      ry=y.split(" ").reverse.join(" ")
      rx=x.split(" ").reverse.join(" ")
      score = x.jarowinkler_similar(y)
      max_jaro = score if max_jaro < score

      score = x.jarowinkler_similar(ry)
      max_jaro = score if max_jaro < score

      score = rx.jarowinkler_similar(y)
      max_jaro = score if max_jaro < score

      score = rx.jarowinkler_similar(ry)
      max_jaro = score if max_jaro < score
    }
  }
  max_jaro

end



def expander_aux(aa,bb)
  aa.map!{|x|
    if x.size == 1
      expand_x=[]
      bb.each{|y|
        if y[0] == x[0]
        expand_x << y
        end
      }
      if expand_x.size > 0
      expand_x
      else
      x
      end
    else
    x
    end
  }

  aa

end



def expand_word(aa,b)
  hash_expanded=Hash.new
  bb = b.split(" ")
  aa.each{|x|
    bb.each{|y|
      if y[0] == x[0]
        hash_expanded[x]=[] if hash_expanded[x] ==nil
      hash_expanded[x]<< y
      end
    }
  }
  hash_expanded

end



def expander(a)

  arrays = nil
  expanded  = []
  idx = 0
  a.each_index{|x|
    if a[x].instance_of? Array
    arrays = a[x]
    idx =x
    end
  }

  if arrays == nil
    return  a.join(" ").to_s
  end

  a.delete_at(idx)

  arrays.each{|x|
    expanded << expander(a + [x])
  }
  return expanded
end

####################################################################################

def xmatch_with_expansion(a,b)
  # puts "xmatch_with_expansion"
  # puts a
  # puts b
  return 1.0 if a.size == 0 and b.size == 0

  a1=a.split(" ")
  b1=b.split(" ")
  aa = a1.map{|x| x if x.size == 1}.compact
  bb = b1.map{|x| x if x.size == 1}.compact
  hash_expanded=Hash.new
  if (aa.size == 0 && bb.size == 0) || (a1.size > 4 || b1.size > 4)
  return a.xmatch(b)
  elsif aa.size > 0
    phrases = permute_expansion(a.split(" "),expand_word(aa,b))
    phrases.map{|x|

      [x.join(" ").xmatch(b1.join(" ")),
        x.reverse.join(" ").xmatch(b1.join(" ")),
        x.reverse.join(" ").xmatch(b1.reverse.join(" ")),
        x.join(" ").xmatch(b1.reverse.join(" "))
      ].max

    }.max
  else
    phrases = permute_expansion(b.split(" "),expand_word(bb,a))
    phrases.map{|x|
      [x.join(" ").xmatch(a1.join(" ")),
      x.reverse.join(" ").xmatch(a1.join(" ")),
      x.reverse.join(" ").xmatch(a1.reverse.join(" ")),
      x.join(" ").xmatch(a1.reverse.join(" "))
      ].max
    }.max
  end

end



def permute_expansion(a,hash_expanded)
  c = a.map{|x|
    if hash_expanded[x] != nil
    hash_expanded[x]
    else
      [x]
    end
  }

  c=c.permutation.delete_if{|x| x.size!=a.size}

  # c.map!{|x| x.join(" ")}
  # puts "permutation"
  # puts a.size
  # puts c
  # puts "---"
  c
end 

# $stopwords=["gold" ,"and" ,"silver" ,"corporation","theather","energy" ]
# puts  advanced_string_matching("Mesquite Generating Station", "MESQUITE POWER" )
# puts "end"