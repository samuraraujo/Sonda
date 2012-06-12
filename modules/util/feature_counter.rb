class FeatureCounter
  attr_accessor :negative_queries, :positive_queries
  def initialize ()
    @negative_queries=0 # number of queries that were performed but the match was not found or does not exist. All queries were useless
    @positive_queries=0 # number of queries performed to find a correct match, including queries that dont not retrieve the match. Some queries use usefull
  end
end