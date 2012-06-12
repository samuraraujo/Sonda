# ruby serimi.rb -s imdb -t dbpedia -c http://data.linkedmdb.org/resource/movie/film -f nt
$current_dir = File.dirname(__FILE__)
require  File.dirname(__FILE__)+'/../modules/initializer.rb'
require  File.dirname(__FILE__)+'/../modules/experiment/results.rb'

##################### SET THE PARAMETER FOR THIS EXPERIMENT #################
@options = {"verbose".to_sym => false,
"logfile".to_sym => nil ,
"source".to_sym => "sider",
# "target".to_sym => "dbpedia_local",
"target".to_sym => "tcm",
:class=>" <http://www4.wiwiss.fu-berlin.de/sider/resource/sider/side_effects> ",
 
"append".to_sym => "a",
"format".to_sym => "txt",
"chunk".to_sym => 150,
"topk".to_sym => 0,
"offset".to_sym => 0,
"stringthreshold".to_sym => 0.7,
"usepivot".to_sym => 'true',
"blocking".to_sym => 'true' ,
"transitionupdate".to_sym => 'false',
"globalrecall".to_sym => 'true',
"aligner".to_sym => 'HierarchicalClusterAligner',
"ranker".to_sym =>'TimeBasedTransitionRanking',
"selector".to_sym =>'DecisionTreeSelectionAlgorithm',
"searcher".to_sym =>'BranchAndBound',
"learningpercent".to_sym => 0.20,
"transitionfailurerate".to_sym => 1.0,
"qconly".to_sym => 'false',
}

def experiment(orderby, predicate)
  $experiment=true
  $number_homonyms=0
  $list_number_homonyms=[]
  $orderby=nil
  $shuffle=false
  $t1 = Time.now()
  $orderbyclause=" ?s <#{predicate}> ?oo . }  " if predicate != nil
  $orderby=" order by ?oo " if orderby 
  
  $shuffle=!orderby
 
  Initializer.new(@options)
  puts "RESULTS"
  $xresults = check_result()
  summary() 

end

def experiment_instances(instances)
  # $instances = shuffle($instances, $sample_size) if $experiment
  instances = instances.shuffle if $experiment && $shuffle

  ref_sub=reference_subjects()
  ref_sub.map!{|x| "<#{x}>"}

  instances = instances & ref_sub
  return instances
end

def reference_subjects()
  reference_subjects=[]
  File.open("#{$current_dir}/../reference/reference.txt", 'r').each { |line|
    reference_subjects << line.split("=")[0]
  }
  return reference_subjects.uniq
end 
def ww(str)
  if str.instance_of? Array
    str.each{|x|
      $results.write(x.to_s)
      $results.write("\n")
    }
  else
    $results.write(str.to_s)
    $results.write("\n")
  end

end
predicate = nil
# predicate="http://www.w3.org/2003/01/geo/wgs84_pos#long"
p "SYSTEM EVALUATION"
experiment(false,predicate)
 
