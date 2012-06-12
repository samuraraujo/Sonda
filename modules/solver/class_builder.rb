#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 March 2012
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require  File.dirname(__FILE__)+'/./solver.rb' 

class SimpleClassSolver < ClassSolver
  def solve(positive,negative)
    classqueries=[]
    criterias =  frequent_predicates( positives.map{|s,p,o| [p,o]} - negatives.map{|s,p,o| [p,o]})

    criterias[0..4].each {|criteria|
      classqueries << ClassQuery.new(criteria[0][0],criteria[0][1])
    }
    return classqueries
  end

  def frequent_predicates(triples)
    triples.map!{|p,o| [p.to_s,o.to_s]}
    #computes the frequency of the predicate/value pair and select the 3 mostfrequency to build the class queries.
    freq = triples.inject(Hash.new(0)) { |h,v| h[v] += 1; h } #computes the frequency
    freq =  freq.sort {|a,b| b[1]<=>a[1]} # select a the most frequent
  end
end 
class EuclidianClassSolver < ClassSolver
  def solve(positive,negative)
    puts "EUCLIDIAN SOLVER"

    classqueries=[]
    pf = frequent_predicates( positive.map{|s,p,o| [p,o]} )
    nf = frequent_predicates( negative.map{|s,p,o| [p,o]} )

    pf = Hash[pf]
    nf = Hash[nf]

    pf.delete_if {|key, value| value == 1 }

    pf.keys.each{|x|
      n = nf[x]
      n = 0 if n == nil
      
      pf[x] = pf[x]^2 - n^2
    }
    
    puts pf.size
    puts nf.size
    puts "SELECTED PREDICATES / VALUE"

    pf.sort {|a,b| b[1]<=>a[1]}[0..4].each {|criteria|
      puts criteria
      classqueries << ClassQuery.new(criteria[0][0],criteria[0][1])
    }

    return classqueries
  end

  def frequent_predicates(triples)
    triples.map!{|p,o| [p.to_s,o.to_s]}
    #computes the frequency of the predicate/value pair and select the 3 mostfrequency to build the class queries.
    freq = triples.inject(Hash.new(0)) { |h,v| h[v] += 1; h } #computes the frequency
    freq =  freq.sort {|a,b| b[1]<=>a[1]} # select a the most frequent
  end
end

# a=[["a",1],["d",43]]
# puts Hash[a].size