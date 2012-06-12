require    File.dirname(__FILE__) +'/transitionselection.rb'
require    File.dirname(__FILE__) +'/query_components.rb'
require    File.dirname(__FILE__) +'/xnode.rb'
class Baseline < XSearch
 
  def search()
     @@candidates=[]
     @@instances=[]
    start = XNode.new("start",1)
    # @decision = DecisionTreeSelectionAlgorithm.new()
    xsearch(start)
    puts "##############################################"
    puts "TRANSITION HISTORY"
    XNode.transitions.each{|x|
      puts  x.to_s
      puts  x.history.to_s
    }
  end

  def local_path()

  end

  def xsearch(start)
    while(start != nil)
      start = find(start)
      #solve for the instances that have been already found
      if $chunk == @@instances.size
        XNode.solver.solve( @@candidates,@@instances)
      @@candidates=[]
      @@instances=[]
      end
    end
    XNode.solver.solve( @@candidates,@@instances)
    
    return nil
  end

  def find(start)
    children = start.neighbors
    return nil if children.size == 0

    first=children.first

    nodes = []
    XNode.selector.restart()#it saves heap space. Before I create one instance for each xnode. it was too cost. 
    cost = 0

    while children.size > 0
      node = children.first
      puts "COMPUTING COST"
      cost = node.cost()
      nodes << node
      children.delete_at(0)
    end 
    candidates = []
    nodes.each{|x| candidates = candidates + x.candidate.elements}
    @@candidates << candidates
    @@instances << first.instance
    return  first
  end
   def transitions(alignments)
    xtransitions =[]
    alignments.each{|alignment| 
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::OR),nil)
    }
    xtransitions
  end 
end

