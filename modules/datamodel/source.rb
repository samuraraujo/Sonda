require  File.dirname(__FILE__)+"/./datasource.rb"
require 'date'
 
module SourceInstance  
  def valid_date?( str)
    Date.strptime(str,"%m/%d/%Y" ) rescue Date.strptime(str,"%Y-%m-%d" )  rescue false
  end
   def get_tokens(labelproperty)
    s = self
    keywords= []
    begin
      keywords = keywords + Query.new.adapters($session[:origin]).sparql("select distinct ?o where { #{s} #{labelproperty} ?o. }").execute.flatten.compact
    rescue Exception => e
      puts "Exception for: select distinct ?o where { #{s} #{labelproperty} ?o. }"
      keywords = keywords + Query.new.adapters($session[:origin]).sparql("select distinct ?o where { #{s} #{labelproperty} ?o. }").execute.flatten.compact
    end
   
    keywords.compact!
    keywords.delete_if {|b| b.to_s.size > 150 } # eliminates text
    keywords.delete_if {|b| b.class.to_s == 'BNode' } # eliminates text
    keywords.delete_if {|b| valid_date?(b.to_s) != false } # eliminates date
    keywords=keywords.map {|b| b.split("(")[0].to_s.rstrip } # eliminates everything between parenteses.
    
    keywords.uniq
  end
end
################################ DATA SOURCE ##################################### 
class Source
  attr_accessor :instances
  include DataSourceModule
  def initialize(params)
    connect(params)
    end 
  def set_instances(klass, limit)
    t0 =  Time.now
    instances = []
    orderbyclause = "}"
    orderbyclause = $orderbyclause if $experiment && $orderbyclause != nil
    orderby = $orderby if $experiment && $orderby != nil
    count =  Query.new.adapters($session[:origin]).sparql("select distinct count(distinct ?s) where {?s ?p #{klass} . #{orderbyclause} ").execute[0][0].to_i
    retrieved = 0
    limit = count if limit == nil
    while retrieved < count && retrieved < limit
      results = Query.new.adapters($session[:origin]).sparql("select distinct ?s where {?s ?p #{klass} .   #{orderbyclause} #{orderby} offset #{retrieved } limit #{limit }" ).execute
      retrieved  = retrieved + results.size
      instances = instances + results.map{|x| x.to_s}
    end
    instances.uniq!
    
    instances.map{|x| x.extend(SourceInstance)} #adds extra methods to this instances
    
    puts "Elapsed time"
    puts Time.now - t0
    @instances = instances
  end
  def get_clusters(cluster,klass)
  clusters =  Query.new.adapters($session[:origin]).sparql("select distinct ?o where {?s #{cluster} ?o .}  ").execute
  clusters.map{|c| " #{klass} ?s #{cluster} #{c} "}
  end
  def sort_discriminative_instance(attribute)
    @instances
  end   
end
