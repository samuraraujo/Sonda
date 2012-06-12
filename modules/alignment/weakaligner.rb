##########################################################################
class WeakAligner < XAligner
 

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
 
  for i in 0..rows
    for j in 0..cols 
        if m1[i][j] <=0.5 and  m2[i][j] <= 0.5
           alignment << AttributeAlignment.new(d1[0][i].to_s, d1[1][j] .to_s)
        end
      end
  end   
    
   puts alignment
    exit
  return alignment.compact
end
end
class CustomCentroid
  attr_accessor :position
  def initialize(position); @position = position; end
  def reposition(nodes, centroid_positions); end
end
 