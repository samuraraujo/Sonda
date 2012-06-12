################################
class AttributeQuery
  attr_reader :attribute_alignment, :threshold, :qtype
  def initialize(attribute_alignment, threshold , type )
    @attribute_alignment=attribute_alignment
    @threshold=threshold
    @qtype=type
  end
end



######################################

class ClassQuery
  attr_reader :attribute, :value
  def initialize(attribute, value)
    @attribute=attribute
    @value=value
  end
end 
class TransitionHistory
  @@global=0
  
  attr_accessor :time, :cardinality, :total, :success, :failure, :tokens, :vocabulary, :lastelapsetime
  def initialize ()
    @time=0.0
    @cardinality=0.0
    @total=0.0
    @success=0.0
    @failure=0.0
    @tokens=[]
  # @vocabulary=[]
  end
def self.reset()
   @@global=0
end
  def addToken(token)
    @tokens << token
  # @vocabulary = @vocabulary + token.split("")
  end

  def vocabulary_similarity(token)
    # v=  jaccard(@vocabulary, token.split(""))
    return  0 if @vocabulary.size == 0
    v=  cosine_wrapper(@vocabulary, token.split(""))
    # puts "Vocabulary"
    # puts v
    # (1-v) + cost
    v= 0 if v.nan?
    1-v
  end

  def probability_success()
    @success.to_f / @@global .to_f
  end

  def timecost
    @time/(@total+1)
  end

  def cost
    Math.sqrt((@time/(@total+1))**2 + (1-((@success).to_f/(@cardinality+1).to_f))**2 )
    # Math.sqrt((@time/(@total+1))**2 + (1-((@success).to_f/(@cardinality+1).to_f))**2 + (1-probability_success())**2)
    #Math.sqrt((@time/(@total+1))**2   + (1-probability_success())**2)
  end

  def update(elapsetime,card)
    @lastelapsetime=elapsetime
    @time=@time + elapsetime
    @cardinality=@cardinality + card
    @total=@total + 1
    @@global+=1
    if card > 0
    @success=@success + 1
    else
    @failure=@failure + 1
    end
  end

  def failure_ratio
    ((@failure+1).to_f/(@total+1).to_f)
  end

  def to_s
    # puts "VOCABULARY"
    # puts @vocabulary.sort.join(",")
    puts "TIME: "+@time.to_s
    puts "CARDINALITY: "+@cardinality.to_s
    puts "TOTAL: "+@total.to_s
    puts "SUCCESS: "+ @success.to_s
    puts "FAILURES: " + @failure.to_s
    puts "GLOBAL SUCESS CHANCE: " + probability_success().to_s

    puts "Elapse time: " + (@time/(@total+1)).to_s
    puts "Cardinality Ratio: " + (1 - ((@success).to_f/(@cardinality+1).to_f)).to_s
    puts "Failure Ratio: " + failure_ratio.to_s
    puts "Cost: " + cost.to_s

  end
end



##########################################
class TransitionQuery
  attr_reader :qa,:qc, :weight, :history
  def initialize (qa,qc)
    @qa =qa
    @qc =qc
    @history=TransitionHistory.new()
  end

  def qtype()
    @qa.qtype
  end

  def query (instance)
    t0=Time.now
    cardinality=0
    c=nil
    #iterate over all tokens for this specific predicate.

    c = CandidateSet.new(self,instance)
    cardinality = c.elements.map{|s,o| s}.uniq.size

    elapsetime = Time.now - t0
    @history.update(elapsetime,cardinality)
    c
  end

  def >=(n)
    self.qa.qtype >= n.qa.qtype && self.qa.attribute_alignment == n.qa.attribute_alignment
  end

  def >(n)
    self.qa.qtype > n.qa.qtype && self.qa.attribute_alignment == n.qa.attribute_alignment
  end

  def to_s()
    if qc != nil
      qa.attribute_alignment.to_s + " " + qa.threshold.to_s + " " + qtype.to_s + " AND " + qc.attribute + " " + qc.value + " " + @weight.to_s
    else
      qa.attribute_alignment.to_s + " " + qa.threshold.to_s + " " + qtype.to_s + " " + @weight.to_s
    end
  end
end



#############
class XSearch
  def initialize(instances,alignments,solver,ranker , selector, learning=0.01,failurerate=0.1)
    puts ""
    puts "###########################################################################"
    puts "######################## START SEARCH ###########################"
    puts "###########################################################################"
    TransitionHistory.reset()
    XNode.solver=solver
    XNode.searcher=self
    XNode.transitions=transitions(alignments)
    XNode.selector=eval(selector).new()
    XNode.instances=instances
    XNode.ranker=ranker
    XNode.learningsize=learning * instances.size
    XNode.failurerate=  failurerate  * instances.size
    puts "LEARNING SIZE: " + XNode.learningsize.to_s

  end

  def search()
    puts "SEARCH SHOULD BE IMPLEMENTED"
  end

  def transitions(alignments)
    xtransitions =[]
    alignments.each{|alignment|
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::EXACTLANG),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::EXACT),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::BIF),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::AND),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::OR),nil)
    }
    xtransitions
  end

  def update_transitions()
    path = local_path()

    return if path == nil
    return if $tupdated || path.size < 3
    $tupdated=true
    puts "SOLVING ON HEURISTIC... "
    data = path.map{|x| x.candidate.elements}
    solution  = XNode.solver.solve(data,path.map{|x| x.instance})
    qc =  XNode.solver.class_queries(solution,data, EuclidianClassSolver.new)
    newtransitions=[]

    XNode.transitions.delete_if{|x| x.qc != nil} if qc.size > 0
    qc.uniq.each{|q|
      XNode.transitions.each{|t|
        newtransitions << TransitionQuery.new(t.qa,q)
      }
    }
    if $qconly
      XNode.transitions = newtransitions
    else
      XNode.transitions = newtransitions + XNode.transitions
    end

XNode.learningsize +=XNode.learningsize
  end

end



class NormalizeExactToken
  @token_function=0
  def token_function_counter(token,value)
    token_function_counter(token,0) if transition.qtype == QueryType::EXACT
    if value == 0
      @token_function=QueryType::NONE
    end
    @token_function=QueryType::CAPITALIZE   if (token == capitalize(token))
    @token_function=QueryType::UPCASE   if (token == token.upcase)
    @token_function=QueryType::DOWNCASE   if (token == token.downcase)
  end

  def capitalize(token)
    token.split(" ").map{|x| x.capitalize}.join(" ")
  end

  def transform_token(token)

    f= @token_function

    if  f ==QueryType::CAPITALIZE
      return capitalize(token)
    elsif f == QueryType::UPCASE
    return  (token.upcase)
    elsif f == QueryType::DOWNCASE
    return  (token.downcase)
    end
    return token
  end
end

