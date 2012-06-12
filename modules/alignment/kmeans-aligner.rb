##########################################################################
class KMeansAligner < XAligner
 

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
  indexes = Hash.new
  min=1
  min_index=0
  for i in 0..rows
    for j in 0..cols
        data << [2*m1[i][j],2*m2[i][j]]
         # puts "ALL"
           # puts  m1[i][j]
           # puts  m2[i][j]
           # puts d1[0][i] 
           # puts d1[1][j] 
        if min > m1[i][j]+m2[i][j]#+m3[i][j]
          min=m1[i][j]+m2[i][j]#+m3[i][j]
          min_index=data.size-1  
           # puts "MIN"
           # puts  m1[i][j]
           # puts  m2[i][j]
           # puts d1[0][i] 
           # puts d1[1][j]  
        end
        indexes[data.size-1]=[i,j]
      end
  end   
  puts data.map{|x| x.join(" ") }
  require 'k_means' 
   
  centroids = 2 #d1[0].size 
  puts "CENTROIDS"
  puts centroids 
  #Looking for per of predicates close to the zero coordenate
  kmeans = KMeans.new(data, :custom_centroids => [CustomCentroid.new([0,0]),CustomCentroid.new([2,2])])
  puts "INSPECTING KMEANS POINTS"
  puts kmeans.inspect   # Use kmeans.view to get hold of the un-inspected array
  puts "LIST PAIRS"
  kmeans.view.each{|x|
    if x.include?(min_index)
    x.each{|y|
      alignment << AttributeAlignment.new(d1[0][indexes[y][0]].to_s, d1[1][indexes[y][1]] .to_s)
      puts y
      puts d1[0][indexes[y][0]] 
      puts d1[1][indexes[y][1]] 
    } 
    end
    } 
    # puts "ALIGNMENT"
    # puts alignment
    exit
  return alignment.compact
end
end
class CustomCentroid
  attr_accessor :position
  def initialize(position); @position = position; end
  def reposition(nodes, centroid_positions); end
end
 