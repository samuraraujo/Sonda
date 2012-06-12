##########################################################################
class HierarchicalClusterAligner < XAligner
 

def assingment(a,b)
  a= preparedata(a)
  b= preparedata(b)
  alignment = []
  d1 = entropy_based(a,b) 
  d2 = vocabulary_based(a,b)
  # d3 = syntax(a,b)
  
  m1 = d1[2] #normalize NXN matrix of scores
  m2 = d2[2] #normalize NXN matrix of scores
  # m3 = d3[2] #normalize NXN matrix of scores
  
  data=[]
  
  rows = d1[0].size - 1
  cols = d1[1].size - 1
  
  puts rows
  puts cols
 
  data << [0,0]
  data << [0,1]
  data << [1,0]
  data << [1,1]     
  
  for i in 0..rows
    for j in 0..cols
        data << [m1[i][j],m2[i][j]]  
      end
  end   
  data.uniq!
  puts data.map{|x| x.join(" ") }  
   
   data_set = Ai4r::Data::DataSet.new(:data_items=>data)
   centroidlinkage = Ai4r::Clusterers::CompleteLinkage.new.build(data_set,4).clusters
   puts "checking points"
   count=0
   centroidlinkage.each{|z|
     puts "######### cluster"
     puts count+=1
   puts z.data_items.sort.map{|x| x.join(", ")}
  }
  puts "LIST PAIRS"
  centroidlinkage.each{|x|
    if x.data_items.include?([0,0])
      puts "ELEMENTS ON CLUSTER"
      puts x.data_items.size
    x.data_items.sort.each{|point| 
     for i in 0..rows
    for j in 0..cols
      if m1[i][j] == point[0] and m2[i][j] == point[1]
          alignment << AttributeAlignment.new(d1[0][i].to_s, d1[1][j] .to_s)
      end
  end 
end 
    } 
    end
    } 
    # puts "ALIGNMENT"
    # puts alignment.size
    # puts alignment.uniq
   
  return alignment.compact.uniq
end
end
 
#  
# require 'rubygems'
# require 'ai4r'

# DATA_ITAMS = [
# [0,0],[0,2],[2,0],[1,1],
 # [0.3,0.3],[0.4,2], [0.0,0.2]
# ]
# DATA_Il = [
# [1,1],[2,2],[3,3],[4,4],
 # [5,5],[6,6], [7,7]
# ]
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/naive_bayes'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/data/data_set'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/id3'
# # require 'benchmark'
# 
   # data_set = Ai4r::Data::DataSet.new(:data_items=>DATA_ITAMS )
   # centroidlinkage = Ai4r::Clusterers::CentroidLinkage.new.build(data_set,4).clusters
   # puts "checking points"
   # puts "-"
   # puts centroidlinkage[0].data_items.map{|x| x.class}
   # puts centroidlinkage[0].data_items.map{|x| centroidlinkage[0].data_items.get_index(x)}
   # puts centroidlinkage[0].data_items.map{|x| x.join(",")}
   # puts "-"
   # puts centroidlinkage[1].data_items.map{|x| x.join(",")}
  # puts "-"
  # puts centroidlinkage[2].data_items.map{|x| x.join(",")}
  # puts "-"
  # puts centroidlinkage[3].data_items.map{|x| x.join(",")}
#  
# # id3.get_probability_map((['New York', '<30',])).each{|x| puts x.join(", ")}