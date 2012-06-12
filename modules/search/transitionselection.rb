require 'rubygems'
require 'ai4r'



include Ai4r::Classifiers
include Ai4r::Data

##################################################

## Explore the transitions until get a 1 element set or all transitions were explored.
## It is used together with a time based transition rank.
class CardinalityBasedTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()
  end

  def restart()
    @previous_node = nil
  end

  def process(node)

    if @previous_node == nil
    @previous_node = node
    return true
    end

    if @previous_node.cost == XNode::MAX_COST
      if @previous_node > node
      return false
      else
      @previous_node = node
      return true
      end
    elsif @previous_node.cost == 1
    return false
    elsif @previous_node.cost > 1 && @previous_node >= node
    @previous_node = node
    return true
    end
    return false
  end
end



##################################################
## Only explore the transition until a set retrieve a non-empty set
class BasicTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()
  end

  def restart()
    @previous_node == nil
  end

  def process(node)
    if @previous_node == nil
    @previous_node = node
    return true
    end
    if @previous_node.cost == XNode::MAX_COST
    @previous_node = node
    return true
    elsif @previous_node.cost > 1

    return false
    end
  end
end



##################################################

## Execute all
class GreedyTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()

  end

  def restart()
    @previous_node == nil
  end

  def process(node)
    return true
  end
end



##################################################
class NaiveBayesClassifier
    attr_accessor :previous_node
  def initialize()
    @classifier=nil
    @previous= nil
    @sample=[]
    @tmp=[]
    @@attributes =   ["Previous", "Previous Cost",  "Current","Sucess"]
  end
  #creates an array representing the query data
  #[t1...tn,q,failure]
  def add_sample(a,b)
    # puts a
    # puts b
    row = []
    if a == nil
    row << -1 #no query performed yet
    row << false
    # row << false
    # row << false
    else
      row <<  a.transition.object_id
      row << (a.nodecost != 0 and a.nodecost != XNode::MAX_COST)
    # row << (a.passby ? false : (a.cost == 0))
    # row << (a.passby ? false : (a.cost == 1))
    end
    row << b.transition.object_id

    if (a == nil)
      if (b.cost == XNode::MAX_COST)
      row << 0
      else
      row << 1
      end
    elsif  a.cost <= b.cost
    row << 0
    else
    row << 1
    end
    # puts "ADDING SAMPLE Q2Q"
    # puts  a.transition.qtype if a!=nil
    # puts  b.transition.qtype
    # puts row.join(", ")
    @tmp << row.map{|x| x.to_s}
  end

  #build vector to add in the tree or to predict
  def row_prediction(a,b)
    row = []
    if a == nil
    row << -1 #no query performed yet
    row << false
    else
      row << a.transition.object_id
      row << (a.nodecost != 0 and a.nodecost != XNode::MAX_COST)
    end
    row <<  b.transition.object_id
    return row.map{|x| x.to_s}
  end

  def predict (a,b)
    return true if b.number < XNode.learningsize
    row = row_prediction(a,b)

    # puts "PREDICT Q2Q"
    # puts row.join(", ")
    if @classifier == nil
      data_set = Ai4r::Data::DataSet.new(:data_items=>@sample, :data_labels=>@@attributes)
      @classifier = Ai4r::Classifiers::NaiveBayes.new.build(data_set)
    end

    decision = @classifier.eval(row) == "1"

    # puts "Predicted: #{decision} ...";
    # @@tree.get_probability_map(row).each{|x| puts x.join(", ")}
    return decision
  end

  def restart()
    @previous= nil
    @tmp=[]
  end

  def commit()
    @sample = @sample + @tmp
  end

  def process(node)
    prediction = true
    if  node.number < XNode.learningsize
      add_sample(@previous,node)
    else
      prediction = predict(@previous,node)
    end
    @previous = node
    return prediction
  end
end



class DecisionTreeSelectionAlgorithm 
  def initialize() 
    @predictors = Hash.new
  end 
  #create and process one classfier per alignment
  def process(node)
   
    @predictors[node.transition.qa.attribute_alignment.target] =  NaiveBayesClassifier.new() if @predictors[node.transition.qa.attribute_alignment.target] == nil
    prediction = true
    # puts "################ PROCESSING #############"
    # puts @previous_reduction
    # puts node
    prediction=@predictors[node.transition.qa.attribute_alignment.target].process(node)
    # prediction=reduction(node) if prediction
    return prediction
  end
  def commit()
     @predictors.values.each{|x| x.commit()} if @predictors.size > 0
  end
def restart()
     @predictors.values.each{|x| x.restart()} if @predictors.size > 0
  end
end

# DATA_LABELS = [ 'city', 'age_range', 'gender', 'marketing_target'  ]
#
# DATA_ITAMS = [
# ['New York',  '<30',      'M', 'Y'],
# ['Chicago',     '<30',      'M', 'Y'],
# ['Chicago',     '<30',      'F', 'Y'],
# ['New York',  '<30',      'M', 'N'],
# ['New York',  '<30',      'M', 'Y'],
# ['Chicago',     '[30-50)',  'M', 'Y'],
# ['New York',  '[30-50)',  'F', 'N'],
# ['Chicago',     '[30-50)',  'F', 'Y'],
# ['New York',  '[30-50)',  'F', 'N'],
# # ['Chicago',     '[50-80]', 'M', 'N'],
# ['New York',  '[50-80]', 'F', 'N'],
# ['New York',  '[50-80]', 'M', 'N'],
# ['Chicago',     '[50-80]', 'M', 'N'],
# ['New York',  '[50-80]', 'F', 'N'],
# ['Chicago',     '>80',      'F', 'Y']
# ]
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/naive_bayes'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/data/data_set'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/id3'
# # require 'benchmark'
#
#
# data_set = Ai4r::Data::DataSet.new(:data_items=>DATA_ITAMS, :data_labels=>DATA_LABELS)
# id3 = NaiveBayes.new.build(data_set)
#
# puts id3.eval(['New York', '<20' ])
# # id3.get_probability_map((['New York', '<30',])).each{|x| puts x.join(", ")}

