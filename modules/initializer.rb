#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 April 2011.
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require  File.dirname(__FILE__)+ '/../active_rdf/lib/active_rdf'
require  File.dirname(__FILE__)+'/../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'
require  File.dirname(__FILE__)+'/datamodel/endpoints.rb'
require 'active_support/inflector'

# require "search_module.rb"
require  File.dirname(__FILE__)+"/solver/serimi_module.rb"
require  File.dirname(__FILE__)+"/solver/class_builder.rb"
require  File.dirname(__FILE__)+'/alignment/attribute-assign.rb'
require  File.dirname(__FILE__)+'/datamodel/datasource.rb'
require  File.dirname(__FILE__)+"/datamodel/source.rb"
require  File.dirname(__FILE__)+"/datamodel/target.rb"
require  File.dirname(__FILE__)+"/util/extension_module.rb"
require  File.dirname(__FILE__)+"/util/matching_module.rb"
require  File.dirname(__FILE__)+"/util/feature_counter.rb"


class Initializer
  def initialize(params)
    
    puts "Parameters:"
    $featurecounter = FeatureCounter.new()
    params.each { |k,v| puts "#{k} => #{v}" }
    totallimit=nil
    $stopwords=[]
    $xresults=[]
    $number_homonyms=[]
    $number_subjects=[]
     $tupdated=false
    $limit=0
     
    $list_number_homonyms=[]
    $textp=[]
    $pivot = []
    # $pivot_labels = []
    $pivot_subjects = []
    $aligner = SerimiAligner.new()
    $usepivot=false
    $topk=params[:topk].to_i
    $output=params[:output] if $output == nil
    $format=params[:format]
    $limit=params[:limit]
    $cluster=params[:cluster]
    $chunk=params[:chunk]
    $filter_threshold=params[:stringthreshold]
    $rdsthreshold=params[:rdsthreshold]
    $aligner=eval(params[:aligner]).new() if params[:aligner] != nil
    ranker=eval(params[:ranker]).new() if params[:ranker] != nil
    selector=  params[:selector]
    $usepivot=true if params[:usepivot] ==  'true'
    $blocking=true  if params[:blocking] ==  'true'
    $transitionupdate=true  if params[:transitionupdate] ==  'true'
    $globalrecall=true  if params[:globalrecall] ==  'true'
    $learning= params[:learningpercent]
    $learning= 0.01 if params[:learningpercent] == nil
    $transitionfailurerate= params[:transitionfailurerate]
    $qconly=true  if params[:qconly] ==  'true'

    if params[:append] == 'w'
      File.delete($output) if  File.exist?($output)
    end
    klasses =  [params[:class]]
    klasses =  ["<"+ params[:class] + ">"] if  params[:class].index("<") == nil
    source = Source.new(params)

    if $cluster != nil
    klasses =  source.get_clusters($cluster,klasses[0])
    end

    klasses[0..1].each{|klass|
      puts "processing klass"
      puts "Obtaning all instances instances"

      $instances = source.set_instances(klass,totallimit)

      $alignments = []

      $alignments = $aligner.alignment_algorithm($instances)
      
    
      $aligner=nil
      puts "Alignments"
      puts $alignments
      t1 = Time.now()

       
      $limit = $instances.size if $limit == nil
      puts" $limit"
      puts $limit
      eval(params[:searcher]).new($instances[0..$limit],$alignments,nil,ranker, selector,$learning,$transitionfailurerate).search()

      
    }
   
  end

end
