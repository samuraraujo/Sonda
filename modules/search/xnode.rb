##################################################
class XNode   
   MAX_COST=10000 
   attr_reader :name,:transition,:instance,:solver,:candidate,:nodecost,:token
   attr_accessor :number, :chance, :passby
   alias_method :inspect, :name
   @@instances=nil
   @@transitions=nil
   @@solver=nil    
   @@ranker=nil   
   @@searcher=nil   
   @@learningsize=0.01 #verify all transitions before apply any selection algoritm
   @@failurerate=0.1 #remove all transtions that reach a failure rate of 100% after a certain percetange of the instances have been processed.
   
  def initialize(source_instance,transition)     
   @number=0 
   @nodecost=0
   @passby=false
    @instance=source_instance
    @transition=transition
    @neighbours=[]
    
    @name = "NODE " +source_instance  + " - " + transition.to_s    
    
  end
  def connect(node)
    @neighbours << node
  end
  def guess_distance(other) 
    1
  end
  def neighbors
     return @neighbours if @neighbours.size > 0
     puts "Getting Neighbour for " + to_s 
    # if @neighbours.size == 0
    # $distribution << (@@transitions.map{|h|(h.history.success+1) / (@number+1)  }) if @neighbours.size ==0
    node_expander()        
    # end
    # puts @neighbours.size
    # puts @neighbours
    @neighbours.compact!   
    @neighbours
  end
  def cost()
    return @nodecost if @nodecost != 0
    puts "LEARNING PHASE" if @number < @@learningsize 
    puts "#### CURRENT TRANSITION: " + @number.to_s
    puts transition.to_s
    
    @candidate= transition.query(@instance)
    @nodecost  = @candidate.elements.map{|s,p,o| s}.uniq.size
    puts "COST: " + @nodecost.to_s 
    if @nodecost == 0
      @nodecost  = XNode::MAX_COST 
      $featurecounter.negative_queries=$featurecounter.negative_queries+1
    else 
     $featurecounter.positive_queries=$featurecounter.positive_queries+1
    end     
    return @nodecost
  end 
  def movement_cost(node)    
     return 1 if node == XNode.goal() 
     cost= node.cost() 
     cost
  end  
   def node_expander()  
     if @@instances.size == 0         
      return
    end   
    
    source_instance = @@instances.pop   
    puts source_instance 
    if @number < @@learningsize * 0.1
      puts "RANKING"
      @@ranker.rank() 
    end
    # prune_transitions() if @number > @@learningsize  
    @@searcher.update_transitions() if $transitionupdate and @number > @@learningsize  
    puts "TOP 10 TRANSITIONS"
    puts @@transitions[0..10]
    # @@transitions.each{|x| 
      # puts x
      # puts x.history.cost
      # puts x.history.time
      # puts x.history.success
      # puts x.history.cardinality
      # puts x.history.probability_success
      # }
    xneighbours = []
    @@transitions.each{|transition| 
      neighbour = XNode.new(source_instance, transition) 
      neighbour.number=@number+1 
      xneighbours << neighbour
           
    } 
   
    #order the nodes 
    # xneighbours.sort!{|a,b|  a.chance <=> b.chance} if xneighbours.size > 1
    xneighbours.each{|neighbour| 
        self.connect(neighbour)
        }
   
end
 def prune_transitions()
   @@transitions.delete_if{|x|x.history.failure_ratio == 1}
 end
 def >=(n)
    self.transition >= n.transition
  end
 def >(n)
    self.transition > n.transition
  end
def to_s 
  @number.to_s +  " - " + @name
end 

   def XNode.instances=(instances)
     @@instances = instances
   end
   def XNode.transitions=(transitions)
     @@transitions = transitions
   end
   
    def XNode.ranker=(ranker)
     @@ranker = ranker
   end
    def XNode.transitions()
     @@transitions  
   end
   def XNode.solver=(solver)
     @@solver = solver
   end
    def XNode.solver()
     @@solver 
   end
    def XNode.selector=(s)
     @@selector = s
   end
    def XNode.selector()
     @@selector
   end
    def XNode.failurerate=(z)
     @@failurerate= z
   end
    def XNode.learningsize=(z)
     @@learningsize = z
   end
    def XNode.learningsize()
     @@learningsize 
   end
    def XNode.searcher=(z)
     @@searcher = z
   end
    def XNode.searcher()
     @@searcher 
   end
end
########################### RANKING TRANSITIONS ##################################
class SuccessBasedTransitionRanking
  def rank
    XNode.transitions.sort!{|a,b| b.history.success <=> a.history.success} 
  end  
end
##################################################################################
class CostBasedTransitionRanking
  def rank
    XNode.transitions.sort!{|a,b| a.history.cost <=> b.history.cost} 
  end 
end
##################################################################################
class TimeBasedTransitionRanking
  def rank
    XNode.transitions.sort!{|a,b| a.history.timecost <=> b.history.timecost} 
  end 
end
  