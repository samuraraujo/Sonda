require 'matrix'
require  File.dirname(__FILE__) +'/../search/branch_and_bound.rb'
require  File.dirname(__FILE__) +'/../search/baseline.rb'
require  File.dirname(__FILE__) +'/hungarian.rb'
require  File.dirname(__FILE__)+ "/../util/extension_module.rb" 
################################
class AttributeAlignment
  attr_reader :source,:target
  def initialize (a,b)
    @source=a
    @target=b
  end

  def to_s
    "[#{@source}=#{@target}]"
  end
end

#############################################

class XAligner
   include Serimi_Module
  def alignment_algorithm(instances)
    sourcedata =[]
    targetdata =[]
    tmp2=[]
    limit = instances.size * $learning #can be too many elements

    entitylabels = source_entity_labels(instances[0..limit]).uniq

    puts "LIMIT"
    puts limit

    instances[0..limit].each {|s|
      tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
      tmp.each {|p,o| sourcedata << [s,p,o] }
      entitylabels.each{|pre|
        t = TransitionQuery.new(AttributeQuery.new(AttributeAlignment.new(pre,"?p"),0.6,QueryType::OR),nil)

        tmp2 = tmp2 + t.query(s).elements

        targetdata = targetdata + tmp2
      }
      break if targetdata.map{|s,p,o| s}.uniq.size > 20
    }

    targetdata.uniq!

    if targetdata.size == 0
      puts "COULD NOT FIND THE ENTITY LABELS FOR THE GIVEN SAMPLE. INCREASE THE LEARNING THRESHOLD."
      exit
    end
    puts "END DATA"
    entitylabels.map!{|x,y| x.to_s}
    puts "BEFORE ALIGNMENT SOURCE ENTITY LABELS "
    puts entitylabels
    puts "#####################################"
    alignments = assingment(sourcedata,targetdata)
    alignments.delete_if{|x| !entitylabels.include?(x.source)}
    alignments.delete_if{|x| x.target == ""}
    alignments.sort!{|a,b| entitylabels.index(a.source)<=>entitylabels.index(b.source)}
    alignments
  end
  def preparedata(a)
  a.delete_if {|s,p,o| o.instance_of?(RDFS::Resource) }
   textp = get_text_properties([a])
  a.delete_if {|s,p,o| textp.include?(p) }
  return a
end
#computes the jaro similarity between two predicate string.
def syntax(a,b)
  puts "SYNTAX"
  ps=select_predicates(a).sort
  pt=select_predicates(b).sort
   
  m = ps.map{|x|
    pt.map{|y| 
          # puts x
      # puts y
      a =    1 - x.jarowinkler_similar(y)
      # puts a
     a  
    }
  }
  # puts m
  return [ps,pt,normalize_matrix(m)]
end
#computes the similarity based on the entropy of the predicates
def entropy_based(a,b)
  puts "ENTROPY BASED"
  entropya= entropy_computation([a])
  entropyb= entropy_computation([b])
  ea= entropya[1]
  eb= entropyb[1] 
  # pred_entropya = entropya[0].map{|x| x.to_s}
  # pred_entropyb = entropyb[0].map{|x| x.to_s}
  ps=select_predicates(a).sort
  pt=select_predicates(b).sort
   ea =Hash[ea.map {|k, v| [k.to_s, v] }] #make the keys a string
   eb =Hash[eb.map {|k, v| [k.to_s, v] }]
  
  m = ps.map{|x| 
    pt.map{|y|        
      if ea[x] == nil || eb[y] == nil
        a=1.0
      else
        a =  (ea[x] - eb[y]).abs
      end
        
      # puts a
  a   
    }    
  }
  
  return  [ps,pt,normalize_matrix(m)]
end
#computes the similarity based on the vocabulary used in their values
def vocabulary_based(a,b)
  puts "VOCABULARY BASED"
  ps=select_predicates(a).sort
  pt=select_predicates(b).sort

  va= vocabulary(a)
  vb= vocabulary(b)
   
  m = ps.map{|x| 
    pt.map{|y| 
      # puts x
      # puts va[x.to_s].uniq.join(", ")
      # puts y
      # puts vb[y.to_s].uniq.join(", ")
      
      a = 1.0 - object_distance(va[x.to_s],vb[y.to_s])
      # puts a
      a = 1 if a.nan?
      a  
    }    
  }
  
  return  [ps,pt,normalize_matrix(m)]
end

def object_distance(x,y)
  x = x.uniq
  y=y.uniq
  return  (((x&y).size.to_f))/ [x.size,y.size].min.to_f
  # return    jaccard(x.uniq,y.uniq)
  # return "". get_similarity(x.join(""),y.join(""),"LEVENSHTEIN")
  
  all = (x + y).uniq.sort
  
  a = all.map{|c| x.grep(c).size }
  b = all.map{|c| y.grep(c).size }
   
  c = cosine(a,b)
  c = 0 if c.nan?
  # puts c
  return c
  
end
def sum_arrays_normalizing *a
    
  arr = []
  a[0].each_index do |r|       # iterate through rows
    row = []
    a[0][r].each_index do |c|  # iterate through columns
      # get sum at these co-ordinates, and add to new row
      row << a.inject(0) { |sum,e| sum += e[r][c] }.to_f / a.size.to_f
    end
    arr << row  # add this row to new array
  end
  # puts arr
  arr # return new array
end
def normalize_matrix(matrix)
  max = [matrix[0].size,matrix.size].max-1
  puts "MAX"
  puts max
  #Normalizing matrix
  m=Array.new(max)
  for i in 0..max
    m[i]=Array.new(max)
    for j in 0..max
      if matrix[i]==nil || matrix[i][j]==nil
      m[i][j]=1.0
      else
      m[i][j]=matrix[i][j]
      end
    end
  end
  return m
end
def  vocabulary(a)
  va = Hash.new
  pa = select_predicates(a)

  pa.each{|x|
    o = select_object_vocabulary(a,x)
    va[x]=o
  }
  return va
end

def select_predicates(instances)
  pre = instances.map{|s,p,o| p.to_s}.uniq
  return pre
end

def select_object_vocabulary(instances,pre)
  # return instances.map{|s,p,o| o.to_s.downcase.split("") if p.to_s == pre.to_s}.compact.flatten
  return instances.map{|s,p,o| o.to_s.downcase.scan(/.{2}/)  if p.to_s == pre.to_s}.compact.flatten
 
end

 
end

##########################################################

def cosine_wrapper(a,b)
  c =  a.uniq.map{|x| a.find_all{|s| s==x}.size}
  d= a.uniq.map{|x| b.find_all{|s| s==x}.size}
  cosine(c,d)
end

def cosine(a,b)
  #DO NOT UNCOMENT THIS. DO THIS OPERATION OUTSIDE
  # c =  a.uniq.map{|x| a.find_all{|s| s==x}.size}
  # d= a.uniq.map{|x| b.find_all{|s| s==x}.size}
  prod=0
  c=a
  d=b
  c.each_index{|i| prod = prod + c[i]*d[i]}
  d1 =  (c.map{|i| i*i}.inject {|sum, n| sum + n })
  d2 = (d.map{|i| i*i}.inject {|sum, n| sum + n })

  prod.to_f / Math.sqrt(d1 * d2)
end
require  File.dirname(__FILE__) +'/hierarchicalcluster-aligner.rb'
require  File.dirname(__FILE__) +'/weakaligner.rb'
require  File.dirname(__FILE__) +'/noaligner.rb'
require  File.dirname(__FILE__) +'/serime-aligner.rb'
require  File.dirname(__FILE__) +'/kmeans-aligner.rb'
require  File.dirname(__FILE__) +'/DezhaoSong-aligner.rb'